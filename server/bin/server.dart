import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';
import 'package:sqlite3/sqlite3.dart';

const _issuer = 'medcare-backend';
const _accessTtl = Duration(minutes: 15);
const _refreshTtl = Duration(days: 30);

void main(List<String> args) async {
  final config = ServerConfig.fromEnvironment();
  final database = MedicalServerDatabase(
    config.databasePath,
    fileStorageDirectory: config.fileStorageDirectory,
  );
  database.migrate();
  database.seed();

  final auth = AuthService(database, config.jwtSecret);
  final realtime = QueueRealtimeHub();
  final gemini = GeminiAiService(
    apiKey: config.geminiApiKey,
    model: config.geminiModel,
  );
  final infermedica = InfermedicaAiService(
    appId: config.infermedicaAppId,
    appKey: config.infermedicaAppKey,
  );
  final news = RssNewsService(feedUrls: config.newsFeedUrls);
  final app = ApiServer(
    database,
    auth,
    realtime,
    gemini,
    news,
    infermedica: infermedica,
    smsOtp: SmsOtpService(
      accountSid: config.twilioAccountSid,
      authToken: config.twilioAuthToken,
      verifyServiceSid: config.twilioVerifyServiceSid,
    ),
    paymentWebhookSecret: config.paymentWebhookSecret,
    emrSigningSecret: config.emrSigningSecret,
    emailOtp: EmailOtpService(
      username: config.emailSmtpUsername,
      password: config.emailSmtpPassword,
      fromName: config.emailFromName,
    ),
  );

  final server = await HttpServer.bind(config.host, config.port);
  print('MedCare backend listening on http://${config.host}:${config.port}');
  print('SQLite database: ${config.databasePath}');
  print(
      'Email OTP: ${config.emailSmtpUsername.isNotEmpty && config.emailSmtpPassword.isNotEmpty ? 'configured' : 'not configured'}');

  await for (final request in server) {
    unawaited(app.handle(request));
  }
}

class ServerConfig {
  const ServerConfig({
    required this.host,
    required this.port,
    required this.databasePath,
    required this.jwtSecret,
    required this.geminiApiKey,
    required this.geminiModel,
    required this.infermedicaAppId,
    required this.infermedicaAppKey,
    required this.newsFeedUrls,
    required this.twilioAccountSid,
    required this.twilioAuthToken,
    required this.twilioVerifyServiceSid,
    required this.paymentWebhookSecret,
    this.emrSigningSecret = '',
    this.emailSmtpUsername = '',
    this.emailSmtpPassword = '',
    this.emailFromName = 'MedCare Hospital',
    this.fileStorageDirectory = 'medcare_uploads',
  });

  final String host;
  final int port;
  final String databasePath;
  final String jwtSecret;
  final String geminiApiKey;
  final String geminiModel;
  final String infermedicaAppId;
  final String infermedicaAppKey;
  final List<Uri> newsFeedUrls;
  final String twilioAccountSid;
  final String twilioAuthToken;
  final String twilioVerifyServiceSid;
  final String paymentWebhookSecret;
  final String emrSigningSecret;
  final String emailSmtpUsername;
  final String emailSmtpPassword;
  final String emailFromName;
  final String fileStorageDirectory;

  factory ServerConfig.fromEnvironment() {
    final env = Platform.environment;
    return ServerConfig(
      // Bind all local interfaces so a physical Android phone on the same
      // Wi-Fi can reach the development server. Chrome can still use
      // http://127.0.0.1:8080 and the Android emulator uses 10.0.2.2:8080.
      host: env['MEDCARE_HOST'] ?? '0.0.0.0',
      port: int.tryParse(env['MEDCARE_PORT'] ?? '') ?? 8080,
      databasePath: env['MEDCARE_DB_PATH'] ?? 'medcare_server.sqlite',
      jwtSecret:
          env['MEDCARE_JWT_SECRET'] ?? 'dev-secret-change-me-before-production',
      geminiApiKey:
          (env['GEMINI_API_KEY'] ?? env['GOOGLE_API_KEY'] ?? '').trim(),
      geminiModel: (env['MEDCARE_GEMINI_MODEL'] ?? 'gemini-3.8-flash').trim(),
      infermedicaAppId: (env['INFERMEDICA_APP_ID'] ?? '').trim(),
      infermedicaAppKey: (env['INFERMEDICA_APP_KEY'] ?? '').trim(),
      newsFeedUrls: _parseNewsFeeds(env['MEDCARE_NEWS_FEEDS']),
      twilioAccountSid: (env['TWILIO_ACCOUNT_SID'] ?? '').trim(),
      twilioAuthToken: (env['TWILIO_AUTH_TOKEN'] ?? '').trim(),
      twilioVerifyServiceSid: (env['TWILIO_VERIFY_SERVICE_SID'] ?? '').trim(),
      paymentWebhookSecret:
          (env['MEDCARE_PAYMENT_WEBHOOK_SECRET'] ?? '').trim(),
      emrSigningSecret: (env['MEDCARE_EMR_SIGNING_SECRET'] ??
              env['MEDCARE_JWT_SECRET'] ??
              'dev-emr-signing-secret')
          .trim(),
      emailSmtpUsername:
          (env['MEDCARE_EMAIL_USERNAME'] ?? env['GMAIL_USERNAME'] ?? '').trim(),
      emailSmtpPassword:
          (env['MEDCARE_EMAIL_APP_PASSWORD'] ?? env['GMAIL_APP_PASSWORD'] ?? '')
              .replaceAll(RegExp(r'\s+'), '')
              .trim(),
      emailFromName:
          (env['MEDCARE_EMAIL_FROM_NAME'] ?? 'MedCare Hospital').trim(),
      fileStorageDirectory:
          (env['MEDCARE_FILE_STORAGE_DIR'] ?? 'medcare_uploads').trim(),
    );
  }

  static List<Uri> _parseNewsFeeds(String? raw) {
    final values = (raw == null || raw.trim().isEmpty)
        ? const [
            'https://vnexpress.net/rss/suc-khoe.rss',
            'https://suckhoedoisong.vn/y-te.rss',
            'https://vnexpress.net/rss/khoa-hoc.rss',
            'https://www.who.int/rss-feeds/news-english.xml',
            'https://www.nature.com/subjects/medical-research.rss',
            'https://www.sciencedaily.com/rss/health_medicine/medical_research.xml',
          ]
        : raw.split(',');
    return values
        .map((item) => Uri.tryParse(item.trim()))
        .whereType<Uri>()
        .where((uri) => uri.hasScheme && uri.host.isNotEmpty)
        .toList(growable: false);
  }
}

class ApiServer {
  ApiServer(
    this.db,
    this.auth,
    this.realtime,
    this.gemini,
    this.news, {
    InfermedicaAiService? infermedica,
    SmsOtpService? smsOtp,
    this.paymentWebhookSecret = '',
    this.emrSigningSecret = '',
    EmailOtpService? emailOtp,
  })  : infermedica = infermedica ?? const InfermedicaAiService.disabled(),
        smsOtp = smsOtp ?? const SmsOtpService.disabled(),
        emailOtp = emailOtp ?? EmailOtpService.disabled();

  final MedicalServerDatabase db;
  final AuthService auth;
  final QueueRealtimeHub realtime;
  final GeminiAiService gemini;
  final InfermedicaAiService infermedica;
  final RssNewsService news;
  final SmsOtpService smsOtp;
  final EmailOtpService emailOtp;
  final String paymentWebhookSecret;
  final String emrSigningSecret;

  Future<void> handle(HttpRequest request) async {
    request.response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Headers', 'Authorization, Content-Type')
      ..set('Access-Control-Allow-Methods', 'GET, POST, PATCH, OPTIONS');

    if (request.method == 'OPTIONS') {
      await _json(request, 204, null);
      return;
    }

    try {
      final path = request.uri.path;
      final method = request.method;

      if (method == 'GET' && path == '/health') {
        await _json(request, 200, {
          'ok': true,
          'service': 'medcare-backend',
          'time': DateTime.now().toUtc().toIso8601String(),
        });
        return;
      }

      if (method == 'POST' && path == '/payments/webhook') {
        if (paymentWebhookSecret.isEmpty ||
            request.headers.value('x-medcare-webhook-secret') !=
                paymentWebhookSecret) {
          throw ApiException(401, 'Invalid payment webhook secret');
        }
        final body = await _readJson(request);
        final payment = db.applyPaymentWebhook(body);
        await _json(request, 200, {'payment': payment});
        return;
      }

      if (method == 'POST' && path == '/auth/login') {
        await _login(request);
        return;
      }
      if (method == 'POST' && path == '/auth/register/request-otp') {
        await _requestRegistrationOtp(request);
        return;
      }
      if (method == 'POST' && path == '/auth/register/verify-otp') {
        await _verifyRegistrationOtp(request);
        return;
      }
      if (method == 'POST' && path == '/auth/refresh') {
        await _refresh(request);
        return;
      }
      if (method == 'POST' && path == '/auth/logout') {
        await _logout(request);
        return;
      }

      if (method == 'GET' && path == '/queue/events') {
        final user = _requireAuth(request);
        await realtime.attach(request, user);
        return;
      }

      if (method == 'GET' && path == '/news') {
        final limit = int.tryParse(request.uri.queryParameters['limit'] ?? '');
        final articles = await news.latest(limit: limit ?? 12);
        await _json(request, 200, {
          'articles': articles,
          'count': articles.length,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        });
        return;
      }

      // Danh mục bác sĩ là dữ liệu dùng chung cho bệnh nhân, bác sĩ và admin.
      // Cho phép đọc công khai để màn hình tìm bác sĩ vẫn hoạt động trước khi
      // bệnh nhân đăng nhập; các thao tác đặt lịch phía dưới vẫn bắt buộc JWT.
      if (method == 'GET' && path == '/doctors') {
        final doctors = db.listDoctors(
          specialty: request.uri.queryParameters['specialty'],
          search: request.uri.queryParameters['search'],
        );
        await _json(request, 200, {
          'doctors': doctors,
          'count': doctors.length,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        });
        return;
      }
      if (method == 'GET' &&
          path.startsWith('/doctors/') &&
          path.endsWith('/slots')) {
        final doctorId =
            path.substring('/doctors/'.length, path.length - '/slots'.length);
        if (doctorId.trim().isEmpty) {
          throw ApiException(400, 'doctorId is required');
        }
        final date = request.uri.queryParameters['date'];
        if (date == null || date.trim().isEmpty) {
          throw ApiException(400, 'date is required');
        }
        final doctor = db.getDoctor(doctorId);
        if (doctor == null) throw ApiException(404, 'Doctor not found');
        final slotDoctorId = db.resolveDoctorSlotId(doctorId);
        await _json(request, 200, {
          'doctor': doctor,
          'slots': db.listAppointmentSlots(slotDoctorId, date),
        });
        return;
      }
      if (method == 'GET' && path.startsWith('/doctors/')) {
        final doctorId = path.substring('/doctors/'.length);
        final doctor = db.getDoctor(doctorId);
        if (doctor == null) throw ApiException(404, 'Doctor not found');
        await _json(request, 200, {'doctor': doctor});
        return;
      }

      final user = _requireAuth(request);

      if (method == 'GET' && path == '/me') {
        await _json(request, 200, {'user': user.toJson()});
        return;
      }

      if (method == 'GET' && path == '/notifications') {
        await _json(request, 200, {
          'notifications': db.listNotifications(user),
        });
        return;
      }
      if (method == 'PATCH' && path.startsWith('/notifications/')) {
        final id = path.split('/').last;
        final notification = db.markNotificationRead(id, user);
        await _json(request, 200, {'notification': notification});
        return;
      }

      if (method == 'GET' && path == '/appointments') {
        await _json(request, 200, {
          'appointments': db.listAppointments(user).map((e) => e).toList(),
        });
        return;
      }
      if (method == 'POST' && path == '/consultations/complete') {
        _requireAnyRole(user, const {'doctor', 'admin'});
        final body = await _readJson(request);
        final consultation = db.completeConsultation(user, body);
        db.audit(
          user,
          'CONSULTATION_COMPLETE',
          'appointments/${consultation['appointmentId']}',
          'patient=${consultation['patientId']}',
        );
        await _json(request, 201, {'consultation': consultation});
        return;
      }
      if (method == 'GET' && path == '/payments') {
        _requireRole(user, 'admin');
        await _json(request, 200, {'payments': db.listPayments()});
        return;
      }
      if (method == 'GET' && path == '/wallet') {
        await _json(request, 200, {'wallet': db.wallet(user)});
        return;
      }
      if (method == 'POST' && path == '/wallet/charge') {
        final body = await _readJson(request);
        final charge = db.chargeWallet(user, body);
        db.audit(user, 'WALLET_CHARGE', 'wallet/${charge['id']}',
            charge['description'] as String? ?? 'charge');
        await _json(
            request, 201, {'transaction': charge, 'wallet': db.wallet(user)});
        return;
      }
      if (method == 'POST' && path == '/appointments') {
        await _createAppointment(request, user);
        return;
      }
      if (method == 'POST' && path == '/doctor/follow-ups') {
        _requireRole(user, 'doctor');
        final body = await _readJson(request);
        final appointment = db.createDoctorFollowUp(user, body);
        db.audit(
          user,
          'FOLLOW_UP_APPOINTMENT_CREATE',
          'appointments/${appointment['id']}',
          'source=${body['appointmentId']}',
        );
        await _json(request, 201, {'appointment': appointment});
        return;
      }
      if (method == 'POST' && path == '/payments/confirm') {
        final body = await _readJson(request);
        final payment = db.createPaymentVerificationRequest(user, body);
        db.audit(user, 'PAYMENT_CONFIRM', 'payments/${payment['id']}',
            payment['status'] as String);
        await _json(request, 200, {'payment': payment});
        return;
      }
      if (method == 'GET' && path.startsWith('/payments/')) {
        final clientTransactionId = path.substring('/payments/'.length);
        final payment = db.getPaymentStatus(user, clientTransactionId);
        await _json(request, 200, {'payment': payment});
        return;
      }
      if (method == 'PATCH' && path.startsWith('/payments/')) {
        _requireRole(user, 'admin');
        final clientTransactionId = path.substring('/payments/'.length);
        final body = await _readJson(request);
        final payment = db.reviewPayment(clientTransactionId, body);
        db.audit(
          user,
          'PAYMENT_REVIEW',
          'payments/$clientTransactionId',
          payment['status'] as String? ?? 'pending',
        );
        await _json(request, 200, {'payment': payment});
        return;
      }
      if (method == 'POST' && path == '/support/requests') {
        final body = await _readJson(request);
        final support = db.createSupportRequest(user, body);
        db.audit(
            user, 'SUPPORT_REQUEST', 'support/${support['id']}', 'created');
        await _json(request, 201, {'request': support});
        return;
      }
      if (method == 'GET' && path == '/support/requests') {
        await _json(request, 200, {
          'requests': db.listSupportRequests(user),
        });
        return;
      }
      if (method == 'GET' && path.startsWith('/support/requests/')) {
        final id = path.split('/')[3];
        await _json(request, 200, {
          'request': db.getSupportRequest(id, user),
        });
        return;
      }
      if (method == 'POST' &&
          path.startsWith('/support/requests/') &&
          path.endsWith('/messages')) {
        final id = path.split('/')[3];
        final body = await _readJson(request);
        final message = db.addSupportMessage(id, user, body);
        await _json(request, 201, {'message': message});
        return;
      }
      if (method == 'PATCH' && path.startsWith('/support/requests/')) {
        _requireAnyRole(user, const {'doctor', 'admin'});
        final id = path.split('/')[3];
        final body = await _readJson(request);
        final item = db.updateSupportStatus(id, user, body);
        await _json(request, 200, {'request': item});
        return;
      }
      if (method == 'POST' && path == '/check-ins') {
        final body = await _readJson(request);
        final checkIn = db.createCheckIn(user, body);
        db.audit(user, 'CHECK_IN_CREATE', 'check-ins/${checkIn['id']}',
            checkIn['status'] as String);
        await _json(request, 201, {'checkIn': checkIn});
        return;
      }
      if (method == 'GET' && path.startsWith('/check-ins/')) {
        final id = path.split('/').last;
        await _json(request, 200, {
          'checkIn': db.getFeatureRecord('check_in', id, user),
        });
        return;
      }
      if (method == 'POST' &&
          path.startsWith('/check-ins/') &&
          path.endsWith('/verify')) {
        _requireAnyRole(user, const {'doctor', 'admin'});
        final parts = path.split('/');
        final id = parts[2];
        final body = await _readJson(request);
        final checkIn = db.verifyCheckIn(id, body, user);
        db.audit(user, 'CHECK_IN_VERIFY', 'check-ins/$id', 'verified');
        await _json(request, 200, {'checkIn': checkIn});
        return;
      }
      if (method == 'POST' &&
          path.startsWith('/queues/') &&
          path.endsWith('/join')) {
        final appointmentId = path.split('/')[2];
        final ticket = db.joinQueue(user, appointmentId);
        final ticketPayload = ticket['payload'] is Map
            ? Map<String, Object?>.from(ticket['payload'] as Map)
            : const <String, Object?>{};
        realtime.broadcast(
          db.queueState(ticketPayload['queueId'] as String? ?? 'main'),
        );
        await _json(request, 201, {'queue': ticket});
        return;
      }
      if (method == 'GET' && path.startsWith('/queues/')) {
        final appointmentId = path.split('/').last;
        await _json(request, 200, {
          'queue': db.getQueueForAppointment(user, appointmentId),
        });
        return;
      }
      if (method == 'GET' && path == '/teleconsultations') {
        await _json(request, 200, {
          'teleconsultations': db.listFeatureRecords('teleconsultation', user),
        });
        return;
      }
      if (method == 'POST' && path == '/teleconsultations') {
        final body = await _readJson(request);
        final session = db.createFeatureRecord(
          'teleconsultation',
          user,
          body,
          initialStatus: 'scheduled',
        );
        await _json(request, 201, {'teleconsultation': session});
        return;
      }
      if (method == 'PATCH' && path.startsWith('/teleconsultations/')) {
        final id = path.split('/').last;
        final body = await _readJson(request);
        final session = db.updateFeatureRecord(
          'teleconsultation',
          id,
          user,
          body,
        );
        await _json(request, 200, {'teleconsultation': session});
        return;
      }
      if (method == 'GET' && path == '/medication-reminders') {
        await _json(request, 200, {
          'reminders': db.listFeatureRecords('medication_reminder', user),
        });
        return;
      }
      if (method == 'POST' && path == '/medication-reminders') {
        final body = await _readJson(request);
        final reminder = db.createFeatureRecord(
          'medication_reminder',
          user,
          body,
          initialStatus: 'active',
        );
        await _json(request, 201, {'reminder': reminder});
        return;
      }
      if (method == 'PATCH' && path.startsWith('/medication-reminders/')) {
        final id = path.split('/').last;
        final body = await _readJson(request);
        final reminder = db.updateFeatureRecord(
          'medication_reminder',
          id,
          user,
          body,
        );
        await _json(request, 200, {'reminder': reminder});
        return;
      }
      if (method == 'GET' && path == '/preparation-guides') {
        await _json(request, 200, {
          'guides': db.listFeatureRecords('preparation_guide', user),
        });
        return;
      }
      if (method == 'POST' &&
          path.startsWith('/preparation-guides/') &&
          path.endsWith('/acknowledge')) {
        final id = path.split('/')[2];
        final guide = db.updateFeatureRecord(
          'preparation_guide',
          id,
          user,
          {'acknowledged': true},
        );
        await _json(request, 200, {'guide': guide});
        return;
      }
      if (method == 'GET' && path == '/imaging-studies') {
        await _json(request, 200, {
          'studies': db.listFeatureRecords('imaging_study', user),
        });
        return;
      }
      if (method == 'POST' && path == '/medical-files') {
        _requireAnyRole(user, const {'doctor', 'admin'});
        final body = await _readJson(request);
        final file = db.uploadMedicalFile(user, body);
        db.audit(user, 'MEDICAL_FILE_UPLOAD', 'medical-files/${file['id']}',
            '${file['category']} ${file['sizeBytes']} bytes');
        await _json(request, 201, {'file': file});
        return;
      }
      if (method == 'GET' && path == '/medical-files') {
        await _json(request, 200, {
          'files': db.listMedicalFiles(
            user,
            patientId: request.uri.queryParameters['patientId'],
          ),
        });
        return;
      }
      if (method == 'GET' &&
          path.startsWith('/medical-files/') &&
          path.endsWith('/content')) {
        final id = path.substring(
            '/medical-files/'.length, path.length - '/content'.length);
        final content = db.readMedicalFileContent(id, user);
        request.response
          ..statusCode = 200
          ..headers.contentType =
              ContentType.parse(content['mimeType'] as String)
          ..headers.contentLength = (content['bytes'] as List<int>).length;
        request.response.add(content['bytes'] as List<int>);
        await request.response.close();
        return;
      }
      if (method == 'GET' && path.startsWith('/medical-files/')) {
        final id = path.substring('/medical-files/'.length);
        await _json(request, 200, {'file': db.getMedicalFile(id, user)});
        return;
      }
      if (method == 'GET' && path == '/insurance-profiles') {
        await _json(request, 200, {
          'profiles': db.listFeatureRecords('insurance_profile', user),
        });
        return;
      }
      if (method == 'POST' && path == '/insurance-profiles') {
        final body = await _readJson(request);
        final profile = db.createFeatureRecord(
          'insurance_profile',
          user,
          body,
          initialStatus: 'pending_verification',
        );
        await _json(request, 201, {'profile': profile});
        return;
      }
      if (method == 'GET' && path == '/cashless-claims') {
        await _json(request, 200, {
          'claims': db.listFeatureRecords('cashless_claim', user),
        });
        return;
      }
      if (method == 'POST' && path == '/cashless-claims') {
        final body = await _readJson(request);
        final claim = db.createFeatureRecord(
          'cashless_claim',
          user,
          body,
          initialStatus: 'pending_verification',
        );
        db.audit(user, 'CASHLESS_CLAIM_SUBMIT', 'cashless/${claim['id']}',
            'pending_verification');
        await _json(request, 201, {'claim': claim});
        return;
      }
      if (method == 'PATCH' && path.startsWith('/cashless-claims/')) {
        _requireAnyRole(user, const {'doctor', 'admin'});
        final id = path.split('/').last;
        final body = await _readJson(request);
        final claim = db.updateFeatureRecord(
          'cashless_claim',
          id,
          user,
          body,
          allowForeignAdmin: true,
        );
        db.audit(
          user,
          'CASHLESS_CLAIM_REVIEW',
          'cashless/$id',
          claim['status']?.toString() ?? 'pending_verification',
        );
        await _json(request, 200, {'claim': claim});
        return;
      }
      if (method == 'GET' && path == '/invoices') {
        await _json(request, 200, {
          'invoices': db.listFeatureRecords('invoice', user),
        });
        return;
      }
      if (method == 'GET' && path.startsWith('/invoices/')) {
        final id = path.split('/').last;
        await _json(request, 200, {
          'invoice': db.getFeatureRecord('invoice', id, user),
        });
        return;
      }
      if (method == 'POST' && path == '/feedback') {
        final body = await _readJson(request);
        final feedback = db.createFeatureRecord(
          'feedback',
          user,
          body,
          initialStatus: 'submitted',
        );
        await _json(request, 201, {'feedback': feedback});
        return;
      }
      if (method == 'GET' && path == '/feedback') {
        await _json(request, 200, {
          'feedback': db.listFeatureRecords('feedback', user),
        });
        return;
      }
      if (method == 'GET' && path == '/facility-locations') {
        await _json(request, 200, {
          'locations': db.listFeatureRecords('facility_location', user),
        });
        return;
      }
      if (method == 'POST' && path == '/refund-requests') {
        final body = await _readJson(request);
        final refund = db.createFeatureRecord(
          'refund_request',
          user,
          body,
          initialStatus: 'submitted',
        );
        await _json(request, 201, {'refund': refund});
        return;
      }
      if (method == 'GET' && path == '/refund-requests') {
        await _json(request, 200, {
          'refunds': db.listFeatureRecords('refund_request', user),
        });
        return;
      }
      if (method == 'GET' && path == '/health-entries') {
        await _json(request, 200, {
          'entries': db.listFeatureRecords('health_entry', user),
        });
        return;
      }
      if (method == 'POST' && path == '/health-entries') {
        final body = await _readJson(request);
        final entry = db.createFeatureRecord(
          'health_entry',
          user,
          body,
          initialStatus: 'active',
        );
        await _json(request, 201, {'entry': entry});
        return;
      }
      if (method == 'PATCH' && path.startsWith('/health-entries/')) {
        final id = path.split('/').last;
        final body = await _readJson(request);
        final entry = db.updateFeatureRecord('health_entry', id, user, body);
        await _json(request, 200, {'entry': entry});
        return;
      }
      if (method == 'DELETE' && path.startsWith('/health-entries/')) {
        final id = path.split('/').last;
        db.deleteFeatureRecord('health_entry', id, user);
        await _json(request, 204, null);
        return;
      }
      if (method == 'POST' && path == '/medical-document-requests') {
        final body = await _readJson(request);
        final item = db.createFeatureRecord(
          'medical_document_request',
          user,
          body,
          initialStatus: 'submitted',
        );
        await _json(request, 201, {'request': item});
        return;
      }
      if (method == 'GET' && path == '/medical-document-requests') {
        await _json(request, 200, {
          'requests': db.listFeatureRecords('medical_document_request', user),
        });
        return;
      }
      if (method == 'POST' && path == '/caregiver-invitations') {
        final body = await _readJson(request);
        final invitation = db.createFeatureRecord(
          'caregiver_invitation',
          user,
          body,
          initialStatus: 'pending',
        );
        await _json(request, 201, {'invitation': invitation});
        return;
      }
      if (method == 'GET' && path == '/caregiver-permissions') {
        await _json(request, 200, {
          'permissions': db.listCaregiverPermissions(user),
        });
        return;
      }
      if (method == 'POST' &&
          path.startsWith('/caregiver-invitations/') &&
          path.endsWith('/accept')) {
        final id = path.split('/')[2];
        final permission = db.acceptCaregiverInvitation(id, user);
        await _json(request, 200, {'permission': permission});
        return;
      }
      if (method == 'DELETE' && path.startsWith('/caregiver-permissions/')) {
        final id = path.split('/').last;
        db.revokeCaregiverPermission(id, user);
        await _json(request, 204, null);
        return;
      }
      if (method == 'PATCH' && path.startsWith('/appointments/')) {
        final id = path.split('/').last;
        final body = await _readJson(request);
        final status = body['status'] as String?;
        final appointmentTime = body['appointmentTime'] as String?;
        if ((status == null || status.trim().isEmpty) &&
            (appointmentTime == null || appointmentTime.trim().isEmpty)) {
          throw ApiException(400, 'status or appointmentTime is required');
        }
        late final Map<String, Object?> updated;
        if (user.role == 'patient') {
          if (status != null && status != 'cancelled') {
            throw ApiException(
              403,
              'Patient can only cancel or reschedule their own appointment',
            );
          }
          updated = db.updatePatientAppointment(
            id,
            user,
            status: status,
            appointmentTime: appointmentTime,
          );
        } else {
          _requireAnyRole(user, const {'doctor', 'admin'});
          updated = db.updateAppointmentStatus(
            id,
            status ?? 'confirmed',
            appointmentTime: appointmentTime,
            doctorId: user.role == 'doctor' ? user.id : null,
          );
        }
        db.audit(
          user,
          'APPOINTMENT_UPDATE',
          'appointments/$id',
          status ?? 'rescheduled',
        );
        await _json(request, 200, {'appointment': updated});
        return;
      }

      if (method == 'GET' && path == '/prescriptions') {
        await _json(request, 200, {
          'prescriptions': db.listPrescriptions(user).map((e) => e).toList(),
        });
        return;
      }
      if (method == 'POST' && path == '/prescriptions') {
        _requireAnyRole(user, const {'doctor', 'admin'});
        final body = await _readJson(request);
        final item = db.createPrescription(user, body);
        db.audit(user, 'PRESCRIPTION_CREATE', 'prescriptions/${item['id']}',
            item['patientId'] as String? ?? '');
        await _json(request, 201, {'prescription': item});
        return;
      }

      if (method == 'GET' && path == '/records') {
        await _json(request, 200, {
          'records': db.listRecords(user).map((e) => e).toList(),
        });
        return;
      }
      if (method == 'POST' && path == '/records') {
        _requireAnyRole(user, const {'doctor', 'admin'});
        final body = await _readJson(request);
        final item = db.createRecord(user, body);
        db.audit(user, 'MEDICAL_RECORD_CREATE', 'records/${item['id']}',
            item['patientId'] as String? ?? '');
        await _json(request, 201, {'record': item});
        return;
      }

      if (method == 'GET' && path == '/clinical-actions') {
        _requireAnyRole(user, const {'patient', 'doctor', 'admin'});
        final patientId = request.uri.queryParameters['patientId'];
        await _json(request, 200, {
          'actions': db.listClinicalActions(user, patientId: patientId),
        });
        return;
      }
      if (method == 'POST' && path == '/clinical-actions') {
        _requireAnyRole(user, const {'doctor', 'admin'});
        final body = await _readJson(request);
        final item = db.createClinicalAction(user, body);
        db.audit(
          user,
          'CLINICAL_ACTION_CREATE',
          'clinical-actions/${item['id']}',
          '${item['action']} patient=${item['patientId']}',
        );
        await _json(request, 201, {'action': item});
        return;
      }
      if (method == 'POST' && path == '/clinical-actions/sign-emr') {
        _requireAnyRole(user, const {'doctor', 'admin'});
        final body = await _readJson(request);
        final item = db.signEmr(
          user,
          body,
          signingSecret: emrSigningSecret,
        );
        db.audit(
          user,
          'EMR_DIGITAL_SIGNATURE',
          'clinical-actions/${item['id']}',
          'HMAC-SHA256 signed',
        );
        await _json(request, 201, {'action': item});
        return;
      }

      if (method == 'GET' && path == '/admin/overview') {
        _requireRole(user, 'admin');
        await _json(request, 200, {'overview': db.adminOverview()});
        return;
      }
      if (method == 'GET' && path == '/admin/users') {
        _requireRole(user, 'admin');
        await _json(request, 200, {
          'users': db.listAdminUsers(
            role: request.uri.queryParameters['role'],
          ),
        });
        return;
      }
      if (method == 'PATCH' && path.startsWith('/admin/users/')) {
        _requireRole(user, 'admin');
        final id = path.substring('/admin/users/'.length);
        final body = await _readJson(request);
        final item = db.updateAdminUser(user, id, body);
        db.audit(
          user,
          'ADMIN_USER_UPDATE',
          'users/$id',
          'active=${item['active']}',
        );
        await _json(request, 200, {'user': item});
        return;
      }
      if (method == 'GET' && path == '/admin/doctors') {
        _requireRole(user, 'admin');
        await _json(request, 200, {
          'doctors': db.listDoctors(includeInactive: true),
        });
        return;
      }
      if (method == 'POST' && path == '/admin/doctors') {
        _requireRole(user, 'admin');
        final body = await _readJson(request);
        final doctor = db.createDoctor(user, body);
        db.audit(user, 'DOCTOR_CREATE', 'doctors/${doctor['id']}', 'created');
        await _json(request, 201, {'doctor': doctor});
        return;
      }
      if (method == 'PATCH' && path.startsWith('/admin/doctors/')) {
        _requireRole(user, 'admin');
        final id = path.substring('/admin/doctors/'.length);
        final body = await _readJson(request);
        final doctor = db.updateDoctor(user, id, body);
        db.audit(
          user,
          'DOCTOR_UPDATE',
          'doctors/$id',
          'active=${doctor['active']}',
        );
        await _json(request, 200, {'doctor': doctor});
        return;
      }
      if (method == 'POST' && path == '/admin/lockdown') {
        _requireRole(user, 'admin');
        final body = await _readJson(request);
        final enabled = body['enabled'];
        if (enabled is! bool) {
          throw ApiException(400, 'enabled must be boolean');
        }
        final control =
            db.setSystemControl(user, 'emergency_lockdown', enabled);
        db.audit(
          user,
          enabled ? 'EMERGENCY_LOCKDOWN_ON' : 'EMERGENCY_LOCKDOWN_OFF',
          'system/emergency-lockdown',
          enabled ? 'write operations restricted' : 'system resumed',
        );
        await _json(request, 200, {'control': control});
        return;
      }

      if (method == 'GET' && path == '/queue') {
        await _json(request, 200, {'queue': db.queueState()});
        return;
      }
      if (method == 'GET' && path == '/queue/tickets') {
        _requireAnyRole(user, const {'doctor', 'admin'});
        await _json(request, 200, {'tickets': db.listQueueTickets(user)});
        return;
      }
      if (method == 'GET' && path == '/admin/slots') {
        _requireRole(user, 'admin');
        final doctorId = request.uri.queryParameters['doctorId'];
        final date = request.uri.queryParameters['date'];
        if (doctorId == null || date == null) {
          throw ApiException(400, 'doctorId and date are required');
        }
        await _json(request, 200, {
          'slots': db.listAppointmentSlots(doctorId, date),
        });
        return;
      }
      if (method == 'PATCH' && path == '/admin/slots') {
        _requireRole(user, 'admin');
        final body = await _readJson(request);
        final slot = db.updateAppointmentSlot(user, body);
        await _json(request, 200, {'slot': slot});
        return;
      }
      if (method == 'POST' && path == '/queue/call-next') {
        _requireAnyRole(user, const {'doctor', 'admin'});
        final queueId = user.role == 'doctor' ? user.id : 'main';
        final queue = db.callNextQueueNumber(queueId);
        db.audit(user, 'QUEUE_CALL_NEXT', 'queue/$queueId',
            'current=${queue['currentNumber']}');
        realtime.broadcast(queue);
        await _json(request, 200, {'queue': queue});
        return;
      }

      if (method == 'POST' && path == '/sync') {
        final body = await _readJson(request);
        final id = db.storeSyncSnapshot(user, body);
        db.audit(user, 'SYNC_SNAPSHOT', 'sync/$id', 'accepted');
        await _json(request, 202, {'syncId': id, 'accepted': true});
        return;
      }

      if (method == 'POST' && path == '/ai/chat') {
        await _aiChat(request, user);
        return;
      }

      if (method == 'GET' && path == '/audit') {
        _requireRole(user, 'admin');
        await _json(request, 200, {'logs': db.auditLogs()});
        return;
      }

      throw ApiException(404, 'Route not found');
    } on ApiException catch (error) {
      await _json(request, error.statusCode, {'error': error.message});
    } catch (error, stack) {
      stderr.writeln(error);
      stderr.writeln(stack);
      await _json(request, 500, {'error': 'Internal server error'});
    }
  }

  Future<void> _login(HttpRequest request) async {
    final body = await _readJson(request);
    final identifier = body['identifier'] as String?;
    final password = body['password'] as String?;
    if (identifier == null || password == null) {
      throw ApiException(400, 'identifier and password are required');
    }
    final session = auth.login(identifier, password);
    db.audit(session.user, 'LOGIN_SUCCESS', 'auth/login', session.user.role);
    await _json(request, 200, session.toJson());
  }

  Future<void> _requestRegistrationOtp(HttpRequest request) async {
    final body = await _readJson(request);
    final phone = _e164VietnamPhone(_required(body, 'phone'));
    final email = _required(body, 'email').toLowerCase();
    final name = _required(body, 'name');
    final password = _required(body, 'password');
    final channel = (body['channel'] as String? ?? 'sms').trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      throw ApiException(400, 'Email không hợp lệ');
    }
    if (name.length < 2 || password.length < 6) {
      throw ApiException(400, 'Thông tin đăng ký không hợp lệ');
    }
    if (db.findUserByIdentifier(email) != null) {
      throw ApiException(409,
          'Email này đã được đăng ký. Hãy đăng nhập hoặc dùng email khác.');
    }
    if (db.findUserByPhone(phone) != null) {
      throw ApiException(409,
          'Số điện thoại này đã được đăng ký. Hãy dùng số khác hoặc đăng nhập tài khoản cũ.');
    }
    switch (channel) {
      case 'sms':
        await smsOtp.send(phone);
      case 'email':
        await emailOtp.send(email, name);
      default:
        throw ApiException(400, 'Kênh xác thực không hợp lệ');
    }
    await _json(request, 202, {
      'sent': true,
      'channel': channel,
      'destination': channel == 'email' ? email : phone,
    });
  }

  Future<void> _verifyRegistrationOtp(HttpRequest request) async {
    final body = await _readJson(request);
    final phone = _e164VietnamPhone(_required(body, 'phone'));
    final email = _required(body, 'email').toLowerCase();
    final name = _required(body, 'name');
    final password = _required(body, 'password');
    final code = _required(body, 'code');
    final channel = (body['channel'] as String? ?? 'sms').trim().toLowerCase();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw ApiException(400, 'Mã OTP phải gồm 6 chữ số');
    }
    switch (channel) {
      case 'sms':
        await smsOtp.verify(phone, code);
      case 'email':
        emailOtp.verify(email, code);
      default:
        throw ApiException(400, 'Kênh xác thực không hợp lệ');
    }
    final user = db.createPatientUser(
      name: name,
      phone: phone,
      email: email,
      password: password,
    );
    final session = auth.issueSession(user);
    db.audit(
      user,
      'REGISTER_PATIENT',
      'auth/register',
      '${channel}_otp_verified',
    );
    await _json(request, 201, session.toJson());
  }

  Future<void> _refresh(HttpRequest request) async {
    final body = await _readJson(request);
    final refreshToken = body['refreshToken'] as String?;
    if (refreshToken == null) {
      throw ApiException(400, 'refreshToken is required');
    }
    await _json(request, 200, auth.refresh(refreshToken).toJson());
  }

  Future<void> _logout(HttpRequest request) async {
    final body = await _readJson(request);
    final refreshToken = body['refreshToken'] as String?;
    if (refreshToken != null) auth.revokeRefreshToken(refreshToken);
    await _json(request, 200, {'ok': true});
  }

  Future<void> _createAppointment(HttpRequest request, AuthUser user) async {
    _requireRole(user, 'patient');
    final body = await _readJson(request);
    final item = db.createAppointment(user, body);
    db.audit(user, 'APPOINTMENT_CREATE', 'appointments/${item['id']}',
        item['doctorId'] as String? ?? '');
    await _json(request, 201, {'appointment': item});
  }

  Future<void> _aiChat(HttpRequest request, AuthUser user) async {
    try {
      final body = await _readJson(request);
      final message = body['message'] as String?;
      if (message == null || message.trim().isEmpty) {
        throw ApiException(400, 'message is required');
      }
      final history = (body['history'] as List?)
              ?.whereType<Map>()
              .map(
                (item) => item.map(
                  (key, value) => MapEntry(key.toString(), value.toString()),
                ),
              )
              .toList(growable: false) ??
          const <Map<String, String>>[];

      final age = (body['age'] as num?)?.toInt();
      final sex = body['sex'] as String?;
      String text;
      String provider;
      final infermedicaText = await infermedica.assess(
        message: message.trim(),
        age: age,
        sex: sex,
      );
      if (infermedicaText != null) {
        text = infermedicaText;
        provider = 'infermedica';
      } else {
        text = await gemini.chat(
          user: user,
          message: message.trim(),
          history: history,
        );
        provider = 'google-ai-studio';
      }
      db.audit(user, 'AI_CHAT', 'ai/chat', 'provider=$provider');
      await _json(request, 200, {
        'text': text,
        'model': provider == 'infermedica' ? 'engine-api-v3' : gemini.model,
        'provider': provider,
      });
    } on ApiException {
      rethrow;
    } catch (error, stack) {
      stderr.writeln('AI chat failure: $error');
      stderr.writeln(stack);
      throw ApiException(502, 'AI chat failure: $error');
    }
  }

  AuthUser _requireAuth(HttpRequest request) {
    final header = request.headers.value(HttpHeaders.authorizationHeader);
    if (header == null || !header.startsWith('Bearer ')) {
      throw ApiException(401, 'Missing bearer token');
    }
    return auth.verifyAccessToken(header.substring('Bearer '.length));
  }

  void _requireRole(AuthUser user, String role) {
    if (user.role != role) {
      throw ApiException(403, 'Requires $role role');
    }
  }

  void _requireAnyRole(AuthUser user, Set<String> roles) {
    if (!roles.contains(user.role)) {
      throw ApiException(403, 'Requires one of roles: ${roles.join(', ')}');
    }
  }
}

class MedicalServerDatabase {
  MedicalServerDatabase(
    String path, {
    String fileStorageDirectory = 'medcare_uploads',
  })  : database = sqlite3.open(path),
        fileStorageDirectory = fileStorageDirectory.trim().isEmpty
            ? 'medcare_uploads'
            : fileStorageDirectory.trim();

  final Database database;
  final String fileStorageDirectory;

  void dispose() => database.dispose();

  void migrate() {
    database.execute('PRAGMA foreign_keys = ON');
    database.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        identifier TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL CHECK(role IN ('patient', 'doctor', 'admin')),
        display_name TEXT NOT NULL,
        patient_id TEXT,
        phone TEXT
      )
    ''');
    _ensureUserPhoneColumn();
    database.execute('''
      CREATE TABLE IF NOT EXISTS refresh_tokens (
        token_hash TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        expires_at TEXT NOT NULL,
        revoked INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS doctors (
        id TEXT PRIMARY KEY,
        account_id TEXT,
        name TEXT NOT NULL,
        specialty TEXT NOT NULL,
        experience TEXT NOT NULL,
        rating REAL NOT NULL DEFAULT 0,
        price INTEGER NOT NULL DEFAULT 0,
        location TEXT NOT NULL,
        availability TEXT NOT NULL,
        education TEXT NOT NULL,
        working_days TEXT NOT NULL,
        total_patients TEXT NOT NULL,
        image_url TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS medical_files (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        uploaded_by TEXT NOT NULL,
        appointment_id TEXT,
        category TEXT NOT NULL,
        findings TEXT NOT NULL,
        file_name TEXT NOT NULL,
        mime_type TEXT NOT NULL,
        size_bytes INTEGER NOT NULL,
        storage_path TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_medical_files_patient
      ON medical_files(patient_id, created_at)
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS appointments (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        doctor_id TEXT NOT NULL,
        doctor_name TEXT NOT NULL,
        specialty TEXT NOT NULL,
        appointment_time TEXT NOT NULL,
        reason TEXT NOT NULL,
        package_id TEXT,
        package_title TEXT,
        priority_level INTEGER NOT NULL DEFAULT 0,
        insurance_applied INTEGER NOT NULL,
        fee INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        ticket_number TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS appointment_slots (
        id TEXT PRIMARY KEY,
        doctor_id TEXT NOT NULL,
        slot_date TEXT NOT NULL,
        slot_time TEXT NOT NULL,
        capacity INTEGER NOT NULL CHECK(capacity BETWEEN 1 AND 50),
        updated_at TEXT NOT NULL,
        UNIQUE(doctor_id, slot_date, slot_time)
      )
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS prescriptions (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        doctor_id TEXT NOT NULL,
        appointment_id TEXT,
        diagnosis TEXT NOT NULL,
        medicines_json TEXT NOT NULL,
        signed_token TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS medical_records (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        doctor_id TEXT NOT NULL,
        appointment_id TEXT,
        diagnosis TEXT NOT NULL,
        record_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    _ensureClinicalColumns();
    _ensureAppointmentAndPaymentColumns();
    database.execute('''
      CREATE TABLE IF NOT EXISTS queue_state (
        id TEXT PRIMARY KEY,
        department TEXT NOT NULL,
        room TEXT NOT NULL,
        doctor_name TEXT NOT NULL,
        current_number INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS sync_snapshots (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS audit_logs (
        id TEXT PRIMARY KEY,
        actor_id TEXT NOT NULL,
        role TEXT NOT NULL,
        action TEXT NOT NULL,
        resource TEXT NOT NULL,
        details TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        client_transaction_id TEXT UNIQUE NOT NULL,
        amount INTEGER NOT NULL,
        appointment_id TEXT,
        method TEXT NOT NULL,
        status TEXT NOT NULL,
        receipt_code TEXT NOT NULL,
        purpose TEXT NOT NULL DEFAULT 'appointment',
        created_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS wallet_accounts (
        patient_id TEXT PRIMARY KEY,
        balance INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS wallet_transactions (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount INTEGER NOT NULL,
        description TEXT NOT NULL,
        source_payment_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS support_requests (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        category TEXT NOT NULL,
        message TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS support_messages (
        id TEXT PRIMARY KEY,
        request_id TEXT NOT NULL REFERENCES support_requests(id) ON DELETE CASCADE,
        sender_id TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS feature_records (
        id TEXT PRIMARY KEY,
        feature_type TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        status TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_feature_records_owner
      ON feature_records(feature_type, owner_id, updated_at)
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS clinical_actions (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        actor_id TEXT NOT NULL,
        appointment_id TEXT,
        action TEXT NOT NULL,
        status TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_clinical_actions_patient
      ON clinical_actions(patient_id, updated_at)
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS system_controls (
        control_key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_by TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  void seed() {
    _seedUser('patient-001', 'vu@example.com', '123456', 'patient',
        'Nguyen Hoang Vu', 'MC-89241');
    _seedUser(
      'patient-003',
      '0969261252',
      'vu12345',
      'patient',
      'Nguyen Hoang Vu',
      'MC-89241',
      phone: '+84969261252',
    );
    _seedUser('patient-002', 'caregiver@medcare.vn', '123456', 'patient',
        'Nguoi cham soc MedCare', 'MC-CAREGIVER');
    _seedUser('doctor-001', 'doctor@medcare.vn', '123456', 'doctor',
        'Bac si MedCare', null);
    _seedUser('doctor-002', 'bacsi@medcare.vn', '123456', 'doctor',
        'Bac si MedCare', null);
    _seedUser(
        'doctor-short', 'bacsi', '123456', 'doctor', 'Bac si MedCare', null);
    _seedUser('admin-001', 'admin@medcare.vn', 'admin123', 'admin',
        'Quan tri MedCare', null);
    _seedUser(
        'admin-short', 'admin', '123456', 'admin', 'Quan tri MedCare', null);
    _seedDoctors();
    database.execute('''
      UPDATE appointments
      SET doctor_id = (
        SELECT account_id FROM doctors
        WHERE doctors.id = appointments.doctor_id
      )
      WHERE doctor_id LIKE 'doc-%'
        AND EXISTS (
          SELECT 1 FROM doctors
          WHERE doctors.id = appointments.doctor_id
            AND doctors.account_id IS NOT NULL
        )
    ''');

    final queueExists = database.select(
      'SELECT id FROM queue_state WHERE id = ?',
      ['main'],
    );
    if (queueExists.isEmpty) {
      database.execute(
        '''
        INSERT INTO queue_state (
          id, department, room, doctor_name, current_number, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
        [
          'main',
          'Khoa Tieu hoa & Gan Mat',
          'Phong 305',
          'BS Nguyen Van An',
          18,
          _now(),
        ],
      );
    }
    _repairActiveQueueTickets();
  }

  void _seedDoctors() {
    // id|name|specialty|experience|education|workingDays|totalPatients|
    // rating|price|location|availability
    const rows = <String>[
      'doc-01|PGS.TS.BS Trần Minh Đức|Tim mạch|Trưởng khoa Tim mạch • 22 năm kinh nghiệm|Phó Giáo sư, Tiến sĩ Y khoa - Viện Tim mạch Quốc gia|Thứ 2, 4, 6 (08:00 - 16:30)|3.800+|4.9|450000|Phòng 402, Tòa A|Đang có lịch hôm nay',
      'doc-02|ThS.BS Lê Thu Trang|Nhi khoa|Phó khoa Nhi • 14 năm kinh nghiệm|Thạc sĩ Nhi khoa - Bệnh viện Nhi Trung ương|Thứ 2 đến Thứ 7 (07:30 - 17:00)|4.200+|5.0|350000|Phòng 202, Tòa A|Còn 3 khung giờ',
      'doc-03|BSCKII Hoàng Quốc Việt|Cơ xương khớp|Trưởng khoa Xương Khớp • 18 năm kinh nghiệm|Bác sĩ Chuyên khoa II - BV Chấn thương Chỉnh hình|Thứ 3, 5, 7 (08:00 - 17:00)|2.900+|4.8|400000|Phòng 205, Tòa C|Lịch trống chiều nay',
      'doc-04|TS.BS Đỗ Phương Linh|Da liễu|Chuyên gia Da liễu & Thẩm mỹ • 11 năm kinh nghiệm|Tiến sĩ Da liễu - Bệnh viện Da liễu Trung ương|Thứ 2 đến Thứ 6 (08:00 - 16:30)|3.100+|4.9|350000|Tầng 3, Nhà B - Khoa Da liễu|Khám theo hẹn',
      'doc-05|PGS.TS.BS Nguyễn Văn An|Tiêu hóa|Chuyên gia Tiêu hóa & Gan mật • 20 năm kinh nghiệm|Phó Giáo sư Y khoa - Trưởng đơn vị Nội soi Can thiệp|Thứ 2, 3, 5, 7 (08:00 - 16:00)|4.500+|4.9|500000|Phòng 305, Tòa B - Khoa Tiêu hóa|Đang có lịch hôm nay',
      'doc-06|TS.BS Phạm Đức Thắng|Tai Mũi Họng|Phẫu thuật viên Tai Mũi Họng • 15 năm kinh nghiệm|Tiến sĩ Y khoa - BV Tai Mũi Họng Trung ương|Thứ 2 đến Thứ 6 (08:00 - 17:00)|2.700+|4.8|350000|Phòng 104, Tòa A|Còn 5 khung giờ',
      'doc-07|BSCKII Vũ Thị Bích Ngọc|Mắt|Chuyên gia Khúc xạ & Phaco • 16 năm kinh nghiệm|Bác sĩ Chuyên khoa II - Bệnh viện Mắt Trung ương|Thứ 3, 5, 7 (08:00 - 16:30)|3.400+|4.9|400000|Phòng 208, Tòa B|Lịch trống sáng nay',
      'doc-08|TS.BS Đặng Minh Tuấn|Thần kinh|Nội thần kinh & Đột quỵ • 19 năm kinh nghiệm|Tiến sĩ Y học Thần kinh - Bệnh viện Bạch Mai|Thứ 2, 4, 6 (08:30 - 17:00)|2.600+|4.9|450000|Phòng 405, Tòa A|Đang tiếp nhận',
      'doc-09|ThS.BSCKII Ngô Kim Oanh|Sản phụ khoa|Trưởng khoa Sản Phụ • 21 năm kinh nghiệm|Thạc sĩ - Bác sĩ Chuyên khoa II Phụ sản|Thứ 2 đến Thứ 7 (07:30 - 16:30)|5.100+|5.0|400000|Phòng 102, Tòa C|Khám theo hẹn',
      'doc-10|BSCKII Bùi Thanh Tùng|Răng Hàm Mặt|Phục hình răng & Chỉnh nha • 17 năm kinh nghiệm|Bác sĩ Chuyên khoa II - Viện Răng Hàm Mặt Quốc gia|Thứ 2 đến Thứ 7 (08:30 - 18:00)|3.200+|4.8|350000|Tầng 2, Tòa C|Khám theo hẹn',
      'doc-11|GS.TS.BS Nguyễn Chấn Hùng|Ung bướu & Xạ trị|Chuyên gia Cấp cao Ung bướu • 35 năm kinh nghiệm|Giáo sư Y học, Tiến sĩ - Chủ tịch Hội Ung thư Việt Nam|Thứ 3, 5 (08:30 - 16:00)|6.800+|5.0|600000|Phòng 501, Tòa A - Trung tâm Ung bướu|Đặt trước 2 ngày',
      'doc-12|PGS.TS.BS Phan Thu Phương|Hô hấp & Phổi|Giám đốc Trung tâm Hô hấp • 24 năm kinh nghiệm|Phó Giáo sư, Tiến sĩ Y khoa - Bệnh viện Bạch Mai|Thứ 2, 4, 6 (08:00 - 16:30)|4.900+|4.9|500000|Phòng 408, Tòa A|Đang có lịch hôm nay',
      'doc-13|BSCKII Nguyễn Thị Mai Hoa|Tim mạch|Chuyên gia Can thiệp Tim mạch • 19 năm kinh nghiệm|Bác sĩ Chuyên khoa II - Viện Tim mạch TP.HCM|Thứ 2 đến Thứ 6 (08:00 - 17:00)|3.600+|4.9|450000|Phòng 401, Tòa A|Còn 4 khung giờ',
      'doc-14|TS.BS Vũ Đình Thắng|Nhi khoa|Hồi sức Cấp cứu Nhi & Sơ sinh • 16 năm kinh nghiệm|Tiến sĩ Nhi khoa - Đại học Y Dược|Thứ 2 đến Thứ 7 (07:30 - 16:30)|3.900+|4.8|350000|Phòng 203, Tòa A|Đang có lịch hôm nay',
      'doc-15|BSCKII Phạm Hoài Nam|Tiêu hóa|Chuyên gia Gan Mật & Tụy • 21 năm kinh nghiệm|Bác sĩ Chuyên khoa II - BV Chợ Rẫy|Thứ 3, 5, 7 (08:00 - 17:00)|4.100+|4.9|450000|Phòng 306, Tòa B|Còn 2 khung giờ',
      'doc-16|ThS.BS Đặng Xuân Thành|Cơ xương khớp|Phẫu thuật Cột sống & Nội soi khớp • 13 năm kinh nghiệm|Thạc sĩ Chấn thương Chỉnh hình - BV Việt Đức|Thứ 2, 4, 6 (08:00 - 16:30)|2.400+|4.8|350000|Phòng 206, Tòa C|Khám theo hẹn',
      'doc-17|ThS.BS Nguyễn Khánh Vy|Da liễu|Laser Thẩm mỹ da & Dị ứng • 12 năm kinh nghiệm|Thạc sĩ Da liễu Lâm sàng - BV Da liễu|Thứ 2 đến Thứ 6 (08:30 - 17:30)|3.000+|4.9|350000|Tầng 3, Nhà B|Đang có lịch hôm nay',
      'doc-18|TS.BS Hoàng Trọng Hải|Mắt|Phẫu thuật Lasik & Thủy tinh thể • 18 năm kinh nghiệm|Tiến sĩ Nhãn khoa - Đại học Y Hà Nội|Thứ 2, 3, 5, 7 (08:00 - 16:00)|3.700+|4.9|400000|Phòng 209, Tòa B|Lịch trống chiều nay',
      'doc-19|BSCKII Trần Thu Hà|Tai Mũi Họng|Nội soi Vi phẫu Tai Mũi Họng • 15 năm kinh nghiệm|Bác sĩ Chuyên khoa II - BV Tai Mũi Họng|Thứ 2 đến Thứ 6 (08:00 - 17:00)|2.800+|4.8|350000|Phòng 105, Tòa A|Còn 3 khung giờ',
      'doc-20|PGS.TS.BS Lê Thị Cúc|Sản phụ khoa|Chuyên gia Hiếm muộn & Sản khoa • 26 năm kinh nghiệm|Phó Giáo sư Sản phụ khoa - BV Phụ sản Trung ương|Thứ 2, 4, 6 (08:00 - 16:00)|5.600+|5.0|550000|Phòng 103, Tòa C|Đặt trước 1 ngày',
    ];
    final now = _now();
    for (final raw in rows) {
      final fields = raw.split('|');
      if (fields.length != 11) continue;
      final doctorId = fields[0];
      final doctorNumber = int.tryParse(doctorId.replaceFirst('doc-', '')) ?? 0;
      final accountId = switch (doctorNumber) {
        1 => 'doctor-001',
        2 => 'doctor-002',
        _ => 'doctor-${doctorNumber.toString().padLeft(3, '0')}',
      };
      final identifier = switch (doctorNumber) {
        1 => 'doctor@medcare.vn',
        2 => 'bacsi@medcare.vn',
        _ => 'doctor${doctorNumber.toString().padLeft(2, '0')}@medcare.vn',
      };
      _seedUser(
        accountId,
        identifier,
        '123456',
        'doctor',
        fields[1],
        null,
      );
      database.execute(
        '''INSERT OR IGNORE INTO doctors
           (id, account_id, name, specialty, experience, rating, price,
            location, availability, education, working_days, total_patients,
            image_url, active, created_at, updated_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, 1, ?, ?)''',
        [
          doctorId,
          accountId,
          fields[1],
          fields[2],
          fields[3],
          double.parse(fields[7]),
          int.parse(fields[8]),
          fields[9],
          fields[10],
          fields[4],
          fields[5],
          fields[6],
          now,
          now,
        ],
      );
      database.execute(
        'UPDATE doctors SET account_id = ? WHERE id = ? AND (account_id IS NULL OR account_id = ?)',
        [accountId, doctorId, ''],
      );
    }
  }

  List<Map<String, Object?>> listDoctors({
    String? specialty,
    String? search,
    bool includeInactive = false,
  }) {
    final filters = <String>[];
    if (!includeInactive) filters.add('active = 1');
    final args = <Object?>[];
    final cleanSpecialty = specialty?.trim() ?? '';
    final cleanSearch = search?.trim() ?? '';
    if (cleanSpecialty.isNotEmpty && cleanSpecialty.toLowerCase() != 'tất cả') {
      filters.add('lower(specialty) = lower(?)');
      args.add(cleanSpecialty);
    }
    if (cleanSearch.isNotEmpty) {
      filters
          .add('''(lower(name) LIKE lower(?) OR lower(specialty) LIKE lower(?)
                     OR lower(experience) LIKE lower(?))''');
      final pattern = '%$cleanSearch%';
      args.addAll([pattern, pattern, pattern]);
    }
    final where = filters.isEmpty ? '' : 'WHERE ${filters.join(' AND ')}';
    final rows = database.select(
      // Giữ thứ tự danh mục ổn định để không làm đảo vị trí bác sĩ trong UI.
      'SELECT * FROM doctors $where ORDER BY id',
      args,
    );
    return rows.map(_doctorFromRow).toList(growable: false);
  }

  Map<String, Object?> createDoctor(AuthUser actor, Map<String, Object?> body) {
    final name = _required(body, 'name');
    final specialty = _required(body, 'specialty');
    final id = (body['id'] as String?)?.trim().isNotEmpty == true
        ? (body['id'] as String).trim()
        : _id('doctor');
    if (database.select(
        'SELECT id FROM doctors WHERE id = ? LIMIT 1', [id]).isNotEmpty) {
      throw ApiException(409, 'Doctor id already exists');
    }
    final accountId = _validateDoctorAccount(body['accountId']);
    final rating = _number(body['rating'], fallback: 0).clamp(0, 5).toDouble();
    final price = _number(body['price'], fallback: 0).toInt();
    if (price < 0) throw ApiException(400, 'price must be non-negative');
    final now = _now();
    database.execute(
      '''INSERT INTO doctors
         (id, account_id, name, specialty, experience, rating, price,
          location, availability, education, working_days, total_patients,
          image_url, active, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id,
        accountId,
        name,
        specialty,
        body['experience']?.toString() ?? '',
        rating,
        price,
        body['location']?.toString() ?? 'Bệnh viện MedCare',
        body['availability']?.toString() ?? 'Đang nhận lịch',
        body['education']?.toString() ?? 'Bác sĩ chuyên khoa',
        body['workingDays']?.toString() ?? 'Đang cập nhật',
        body['totalPatients']?.toString() ?? '0',
        body['imageUrl']?.toString(),
        body['active'] == false ? 0 : 1,
        now,
        now,
      ],
    );
    return getDoctorForAdmin(id)!;
  }

  Map<String, Object?> updateDoctor(
    AuthUser actor,
    String id,
    Map<String, Object?> patch,
  ) {
    final existing = database.select(
      'SELECT id FROM doctors WHERE id = ? LIMIT 1',
      [id],
    );
    if (existing.isEmpty) throw ApiException(404, 'Doctor not found');
    final updates = <String, Object?>{};
    const fields = <String, String>{
      'accountId': 'account_id',
      'name': 'name',
      'specialty': 'specialty',
      'experience': 'experience',
      'rating': 'rating',
      'price': 'price',
      'location': 'location',
      'availability': 'availability',
      'education': 'education',
      'workingDays': 'working_days',
      'totalPatients': 'total_patients',
      'imageUrl': 'image_url',
    };
    for (final entry in fields.entries) {
      if (!patch.containsKey(entry.key)) continue;
      if (entry.key == 'accountId') {
        updates[entry.value] = _validateDoctorAccount(patch[entry.key]);
      } else if (entry.key == 'rating') {
        final value = _number(patch[entry.key], fallback: -1);
        if (value < 0 || value > 5) {
          throw ApiException(400, 'rating must be between 0 and 5');
        }
        updates[entry.value] = value.toDouble();
      } else if (entry.key == 'price') {
        final value = _number(patch[entry.key], fallback: -1).toInt();
        if (value < 0) throw ApiException(400, 'price must be non-negative');
        updates[entry.value] = value;
      } else {
        final value = patch[entry.key]?.toString().trim() ?? '';
        if (value.isEmpty) {
          throw ApiException(400, '${entry.key} cannot be empty');
        }
        updates[entry.value] = value;
      }
    }
    if (patch.containsKey('active')) {
      if (patch['active'] is! bool) {
        throw ApiException(400, 'active must be boolean');
      }
      updates['active'] = patch['active'] == true ? 1 : 0;
    }
    if (updates.isEmpty) throw ApiException(400, 'No doctor fields to update');
    updates['updated_at'] = _now();
    final assignments = updates.keys.map((key) => '$key = ?').join(', ');
    database.execute(
      'UPDATE doctors SET $assignments WHERE id = ?',
      [...updates.values, id],
    );
    return getDoctorForAdmin(id)!;
  }

  Map<String, Object?>? getDoctorForAdmin(String id) {
    final rows = database.select(
      'SELECT * FROM doctors WHERE id = ? LIMIT 1',
      [id],
    );
    return rows.isEmpty ? null : _doctorFromRow(rows.first);
  }

  String? _validateDoctorAccount(Object? value) {
    final accountId = value?.toString().trim() ?? '';
    if (accountId.isEmpty) return null;
    final rows = database.select(
      "SELECT id FROM users WHERE id = ? AND role = 'doctor' LIMIT 1",
      [accountId],
    );
    if (rows.isEmpty) {
      throw ApiException(400, 'accountId must belong to a doctor');
    }
    return accountId;
  }

  num _number(Object? value, {required num fallback}) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Map<String, Object?>? getDoctor(String id) {
    final rows = database.select(
      'SELECT * FROM doctors WHERE (id = ? OR account_id = ?) AND active = 1 LIMIT 1',
      [id, id],
    );
    return rows.isEmpty ? null : _doctorFromRow(rows.first);
  }

  String resolveDoctorSlotId(String id) {
    final rows = database.select(
      'SELECT id, account_id FROM doctors WHERE (id = ? OR account_id = ?) AND active = 1 LIMIT 1',
      [id, id],
    );
    if (rows.isEmpty) return id;
    return rows.first['account_id'] as String? ?? rows.first['id'] as String;
  }

  void _repairActiveQueueTickets() {
    final queue = queueState();
    var nextNumber = (queue['currentNumber'] as int? ?? 0) + 1;
    final usedNumbers = <int>{};
    final rows = database.select(
      '''SELECT id, payload_json FROM feature_records
         WHERE feature_type = 'queue_ticket'
           AND status NOT IN ('completed', 'skipped')
         ORDER BY created_at ASC''',
    );
    for (final row in rows) {
      final decoded = jsonDecode(row['payload_json'] as String);
      if (decoded is! Map) continue;
      final payload = Map<String, Object?>.from(decoded);
      var patientNumber = (payload['patientNumber'] as num?)?.toInt();
      if (patientNumber == null ||
          patientNumber <= (queue['currentNumber'] as int? ?? 0) ||
          usedNumbers.contains(patientNumber)) {
        while (usedNumbers.contains(nextNumber)) {
          nextNumber++;
        }
        patientNumber = nextNumber;
        nextNumber++;
      }
      usedNumbers.add(patientNumber);
      final expectedTicket = 'Q-${patientNumber.toString().padLeft(4, '0')}';
      final changed = payload['patientNumber'] != patientNumber ||
          payload['ticketNumber'] != expectedTicket;
      if (!changed) continue;
      payload['patientNumber'] = patientNumber;
      payload['ticketNumber'] = expectedTicket;
      payload['estimatedMinutes'] =
          ((patientNumber - (queue['currentNumber'] as int? ?? 0)) * 4)
              .clamp(0, 240);
      database.execute(
        '''UPDATE feature_records
           SET payload_json = ?, updated_at = ? WHERE id = ?''',
        [jsonEncode(payload), _now(), row['id']],
      );
    }
  }

  void _seedUser(
    String id,
    String identifier,
    String password,
    String role,
    String displayName,
    String? patientId, {
    String? phone,
  }) {
    final exists = database
        .select('SELECT id FROM users WHERE identifier = ?', [identifier]);
    if (exists.isNotEmpty) return;
    database.execute(
      '''
      INSERT INTO users (
        id, identifier, password_hash, role, display_name, patient_id, phone
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        id,
        identifier,
        PasswordHasher.hash(identifier, password),
        role,
        displayName,
        patientId,
        phone,
      ],
    );
  }

  AuthUser? findUserByIdentifier(String identifier) {
    final rows = database.select(
      'SELECT * FROM users WHERE lower(identifier) = lower(?) LIMIT 1',
      [identifier],
    );
    if (rows.isEmpty) return null;
    return AuthUser.fromRow(rows.first);
  }

  AuthUser? findUserByPhone(String phone) {
    final rows = database.select(
      'SELECT * FROM users WHERE phone = ? LIMIT 1',
      [phone],
    );
    if (rows.isEmpty) return null;
    return AuthUser.fromRow(rows.first);
  }

  AuthUser createPatientUser({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) {
    final cleanName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = _e164VietnamPhone(phone);
    if (cleanName.length < 2 || cleanEmail.isEmpty || password.length < 6) {
      throw ApiException(400, 'Thông tin đăng ký không hợp lệ');
    }
    if (findUserByIdentifier(cleanEmail) != null) {
      throw ApiException(409, 'Email này đã được đăng ký');
    }
    if (findUserByPhone(cleanPhone) != null) {
      throw ApiException(409, 'Số điện thoại này đã được đăng ký');
    }
    final id = _id('patient');
    final patientId = 'MC-${DateTime.now().millisecondsSinceEpoch}';
    database.execute(
      '''
      INSERT INTO users (
        id, identifier, password_hash, role, display_name, patient_id, phone
      ) VALUES (?, ?, ?, 'patient', ?, ?, ?)
      ''',
      [
        id,
        cleanEmail,
        PasswordHasher.hash(cleanEmail, password),
        cleanName,
        patientId,
        cleanPhone,
      ],
    );
    return findUserById(id)!;
  }

  List<Map<String, Object?>> listAdminUsers({String? role}) {
    final normalizedRole = role?.trim().toLowerCase();
    final rows = normalizedRole == null || normalizedRole.isEmpty
        ? database.select('SELECT * FROM users ORDER BY role, display_name')
        : database.select(
            'SELECT * FROM users WHERE role = ? ORDER BY display_name',
            [normalizedRole],
          );
    return rows.map(_adminUserFromRow).toList(growable: false);
  }

  Map<String, Object?> updateAdminUser(
    AuthUser actor,
    String id,
    Map<String, Object?> patch,
  ) {
    if (id == actor.id) {
      throw ApiException(400, 'Admin không thể tự khóa tài khoản hiện tại');
    }
    final rows =
        database.select('SELECT * FROM users WHERE id = ? LIMIT 1', [id]);
    if (rows.isEmpty) throw ApiException(404, 'User not found');
    final active = patch['active'];
    final displayName = patch['displayName'];
    if (active is! bool && displayName is! String) {
      throw ApiException(400, 'active hoặc displayName là bắt buộc');
    }
    if (active is bool) {
      database.execute('UPDATE users SET active = ? WHERE id = ?', [
        active ? 1 : 0,
        id,
      ]);
    }
    if (displayName is String && displayName.trim().length >= 2) {
      database.execute('UPDATE users SET display_name = ? WHERE id = ?', [
        displayName.trim(),
        id,
      ]);
    }
    return _adminUserFromRow(
      database.select('SELECT * FROM users WHERE id = ? LIMIT 1', [id]).first,
    );
  }

  void _ensureUserPhoneColumn() {
    final columns = database.select('PRAGMA table_info(users)');
    if (!columns.any((row) => row['name'] == 'phone')) {
      database.execute('ALTER TABLE users ADD COLUMN phone TEXT');
    }
    if (!columns.any((row) => row['name'] == 'active')) {
      database.execute(
        'ALTER TABLE users ADD COLUMN active INTEGER NOT NULL DEFAULT 1',
      );
    }
  }

  void _ensureClinicalColumns() {
    final actionTable = database.select(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'clinical_actions'",
    );
    if (actionTable.isNotEmpty) {
      final actionColumns =
          database.select('PRAGMA table_info(clinical_actions)');
      if (!actionColumns.any((row) => row['name'] == 'appointment_id')) {
        database.execute(
          'ALTER TABLE clinical_actions ADD COLUMN appointment_id TEXT',
        );
      }
    }
    final prescriptionColumns =
        database.select('PRAGMA table_info(prescriptions)');
    if (!prescriptionColumns.any((row) => row['name'] == 'appointment_id')) {
      database.execute(
        'ALTER TABLE prescriptions ADD COLUMN appointment_id TEXT',
      );
    }
    final recordColumns = database.select('PRAGMA table_info(medical_records)');
    if (!recordColumns.any((row) => row['name'] == 'appointment_id')) {
      database.execute(
        'ALTER TABLE medical_records ADD COLUMN appointment_id TEXT',
      );
    }
  }

  void _ensureAppointmentAndPaymentColumns() {
    final appointmentColumns =
        database.select('PRAGMA table_info(appointments)');
    if (!appointmentColumns.any((row) => row['name'] == 'fee')) {
      database.execute(
        'ALTER TABLE appointments ADD COLUMN fee INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!appointmentColumns.any((row) => row['name'] == 'package_id')) {
      database.execute('ALTER TABLE appointments ADD COLUMN package_id TEXT');
    }
    if (!appointmentColumns.any((row) => row['name'] == 'package_title')) {
      database.execute(
        'ALTER TABLE appointments ADD COLUMN package_title TEXT',
      );
    }
    if (!appointmentColumns.any((row) => row['name'] == 'priority_level')) {
      database.execute(
        'ALTER TABLE appointments ADD COLUMN priority_level INTEGER NOT NULL DEFAULT 0',
      );
    }
    final paymentColumns = database.select('PRAGMA table_info(payments)');
    if (paymentColumns.isNotEmpty &&
        !paymentColumns.any((row) => row['name'] == 'appointment_id')) {
      database.execute('ALTER TABLE payments ADD COLUMN appointment_id TEXT');
    }
    if (paymentColumns.isNotEmpty &&
        !paymentColumns.any((row) => row['name'] == 'purpose')) {
      database.execute(
        "ALTER TABLE payments ADD COLUMN purpose TEXT NOT NULL DEFAULT 'appointment'",
      );
    }
  }

  AuthUser? findUserById(String id) {
    final rows =
        database.select('SELECT * FROM users WHERE id = ? LIMIT 1', [id]);
    if (rows.isEmpty) return null;
    return AuthUser.fromRow(rows.first);
  }

  void storeRefreshToken(String token, AuthUser user, DateTime expiresAt) {
    database.execute(
      '''
      INSERT INTO refresh_tokens (
        token_hash, user_id, expires_at, revoked, created_at
      ) VALUES (?, ?, ?, 0, ?)
      ''',
      [sha256Text(token), user.id, expiresAt.toUtc().toIso8601String(), _now()],
    );
  }

  AuthUser? userForRefreshToken(String token) {
    final rows = database.select(
      '''
      SELECT u.* FROM refresh_tokens rt
      JOIN users u ON u.id = rt.user_id
      WHERE rt.token_hash = ?
        AND rt.revoked = 0
        AND rt.expires_at > ?
      LIMIT 1
      ''',
      [sha256Text(token), _now()],
    );
    if (rows.isEmpty) return null;
    return AuthUser.fromRow(rows.first);
  }

  void revokeRefreshToken(String token) {
    database.execute(
      'UPDATE refresh_tokens SET revoked = 1 WHERE token_hash = ?',
      [sha256Text(token)],
    );
  }

  List<Map<String, Object?>> listAppointments(AuthUser user) {
    final rows = switch (user.role) {
      'patient' => database.select(
          '''SELECT a.*,
             COALESCE((SELECT display_name FROM users
                       WHERE patient_id = a.patient_id LIMIT 1), a.patient_id)
               AS patient_name
             FROM appointments a
             WHERE a.patient_id = ? ORDER BY a.appointment_time DESC''',
          [user.patientId ?? user.id],
        ),
      'doctor' => database.select(
          '''SELECT a.*,
             COALESCE((SELECT display_name FROM users
                       WHERE patient_id = a.patient_id LIMIT 1), a.patient_id)
               AS patient_name
             FROM appointments a
             WHERE a.doctor_id = ? ORDER BY a.appointment_time DESC''',
          [user.id],
        ),
      _ => database.select(
          '''SELECT a.*,
             COALESCE((SELECT display_name FROM users
                       WHERE patient_id = a.patient_id LIMIT 1), a.patient_id)
               AS patient_name
             FROM appointments a
             ORDER BY a.appointment_time DESC''',
        ),
    };
    return rows.map(_appointmentFromRow).toList();
  }

  Map<String, Object?> completeConsultation(
    AuthUser user,
    Map<String, Object?> body,
  ) {
    final appointmentId = _required(body, 'appointmentId');
    final rows = database.select(
      'SELECT * FROM appointments WHERE id = ? LIMIT 1',
      [appointmentId],
    );
    if (rows.isEmpty) throw ApiException(404, 'Appointment not found');
    final appointment = rows.first;
    if (user.role == 'doctor' && appointment['doctor_id'] != user.id) {
      throw ApiException(403, 'Appointment does not belong to this doctor');
    }
    if (appointment['status'] == 'cancelled') {
      throw ApiException(409, 'Cannot complete a cancelled appointment');
    }

    final patientId = appointment['patient_id'] as String;
    final diagnosis = _required(body, 'diagnosis');
    final rawRecord = body['record'];
    final record = rawRecord is Map
        ? Map<String, Object?>.from(rawRecord)
        : <String, Object?>{};
    record['appointmentId'] = appointmentId;
    record['patientId'] = patientId;
    record['doctorId'] = user.id;
    record['signedAt'] = _now();
    final rawMedicines = body['medicines'];
    final medicines = rawMedicines is List
        ? rawMedicines
            .whereType<Map>()
            .map((item) => Map<String, Object?>.from(item))
            .toList(growable: false)
        : const <Map<String, Object?>>[];
    final medicineTotal = medicines.fold<int>(0, (total, medicine) {
      final price = (medicine['price'] as num?)?.toInt() ?? 0;
      final quantityText = medicine['quantity']?.toString() ?? '';
      final quantity = int.tryParse(
            RegExp(r'\d+').firstMatch(quantityText)?.group(0) ?? '1',
          ) ??
          1;
      return total + price * quantity;
    });
    record['prescribedMedicines'] = medicines;
    record['medicineTotal'] = medicineTotal;
    final now = _now();
    final recordId = _id('emr');
    final prescriptionId = _id('rx');
    final signedToken = 'RX-SHA256-${DateTime.now().millisecondsSinceEpoch}';

    database.execute('''
      INSERT INTO medical_records (
        id, patient_id, doctor_id, appointment_id, diagnosis, record_json, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', [
      recordId,
      patientId,
      user.id,
      appointmentId,
      diagnosis,
      jsonEncode(record),
      now,
    ]);
    database.execute('''
      INSERT INTO prescriptions (
        id, patient_id, doctor_id, appointment_id, diagnosis, medicines_json,
        signed_token, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      prescriptionId,
      patientId,
      user.id,
      appointmentId,
      diagnosis,
      jsonEncode(medicines),
      signedToken,
      now,
    ]);
    database.execute(
      "UPDATE appointments SET status = 'completed' WHERE id = ?",
      [appointmentId],
    );
    database.execute(
      '''UPDATE feature_records
         SET status = 'completed', updated_at = ?
         WHERE feature_type = 'queue_ticket'
           AND json_extract(payload_json, '\$.appointmentId') = ?
           AND status NOT IN ('completed', 'skipped')''',
      [_now(), appointmentId],
    );
    _notifyPatient(
      patientId,
      title: 'Bác sĩ đã hoàn tất ca khám',
      body: 'Bệnh án, chẩn đoán và đơn thuốc của ca khám đã được cập nhật.',
      type: 'consultation_completed',
      appointmentId: appointmentId,
      sourceId: recordId,
    );
    return {
      'appointmentId': appointmentId,
      'patientId': patientId,
      'record': {
        'id': recordId,
        'patientId': patientId,
        'doctorId': user.id,
        'appointmentId': appointmentId,
        'diagnosis': diagnosis,
        'record': record,
        'createdAt': now,
      },
      'prescription': {
        'id': prescriptionId,
        'patientId': patientId,
        'doctorId': user.id,
        'appointmentId': appointmentId,
        'diagnosis': diagnosis,
        'medicines': medicines,
        'signedToken': signedToken,
        'createdAt': now,
      },
      'appointmentStatus': 'completed',
    };
  }

  Map<String, Object?> createAppointment(
      AuthUser user, Map<String, Object?> body) {
    final patientId = user.patientId ?? user.id;
    final doctorId = _required(body, 'doctorId');
    final appointmentTime = _required(body, 'appointmentTime');
    final parsedTime = DateTime.tryParse(appointmentTime)?.toLocal();
    if (parsedTime == null || !parsedTime.isAfter(DateTime.now())) {
      throw ApiException(
          400, 'appointmentTime phải là thời gian trong tương lai');
    }
    final duplicate = database.select(
      '''
      SELECT * FROM appointments
      WHERE patient_id = ?
        AND doctor_id = ?
        AND appointment_time = ?
        AND status <> 'cancelled'
      LIMIT 1
      ''',
      [patientId, doctorId, appointmentTime],
    );
    if (duplicate.isNotEmpty) return _appointmentFromRow(duplicate.first);

    final date = _dateKey(parsedTime);
    final time = _timeKey(parsedTime);
    final matchingSlots = listAppointmentSlots(doctorId, date)
        .where((slot) => slot['time'] == time)
        .toList(growable: false);
    final configured = matchingSlots.isEmpty ? null : matchingSlots.first;
    if (configured != null &&
        (configured['booked'] as int) >= (configured['capacity'] as int)) {
      throw ApiException(409, 'Khung giờ này đã hết chỗ');
    }
    final fee = (body['fee'] as num?)?.toInt() ?? 0;
    if (fee < 0) throw ApiException(400, 'fee không hợp lệ');
    final packageId = (body['packageId'] as String?)?.trim();
    final packageTitle = (body['packageTitle'] as String?)?.trim();
    final priorityLevel = (body['priorityLevel'] as num?)?.toInt() ?? 0;
    if (priorityLevel < 0 || priorityLevel > 100) {
      throw ApiException(400, 'priorityLevel không hợp lệ');
    }
    final id = _id('appt');
    final item = {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': _required(body, 'doctorName'),
      'specialty': _required(body, 'specialty'),
      'appointmentTime': appointmentTime,
      'reason': _required(body, 'reason'),
      'packageId': packageId,
      'packageTitle': packageTitle,
      'priorityLevel': priorityLevel,
      'insuranceApplied': body['insuranceApplied'] == true,
      'fee': fee,
      // Lịch miễn phí được xác nhận ngay. Lịch có phí phải chờ callback
      // thanh toán thành công trước khi được check-in.
      'status': fee > 0 ? 'awaiting_payment' : 'confirmed',
      'ticketNumber': 'KB-${Random.secure().nextInt(9000) + 1000}',
      'createdAt': _now(),
    };
    database.execute(
      '''
      INSERT INTO appointments (
        id, patient_id, doctor_id, doctor_name, specialty, appointment_time,
        reason, package_id, package_title, priority_level, insurance_applied,
        fee, status, ticket_number, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        item['id'],
        item['patientId'],
        item['doctorId'],
        item['doctorName'],
        item['specialty'],
        item['appointmentTime'],
        item['reason'],
        item['packageId'],
        item['packageTitle'],
        item['priorityLevel'],
        item['insuranceApplied'] == true ? 1 : 0,
        item['fee'],
        item['status'],
        item['ticketNumber'],
        item['createdAt'],
      ],
    );
    _notifyPatient(
      patientId,
      title: 'Đã ghi nhận đăng ký lịch khám',
      body:
          '${item['doctorName']} • ${item['specialty']} • Mã lịch ${item['ticketNumber']}. '
          '${fee > 0 ? 'Vui lòng gửi yêu cầu thanh toán để admin duyệt.' : 'Lịch khám đã được xác nhận.'}',
      type: 'appointment_created',
      appointmentId: id,
      sourceId: id,
    );
    return item;
  }

  Map<String, Object?> createDoctorFollowUp(
    AuthUser user,
    Map<String, Object?> body,
  ) {
    final sourceId = _required(body, 'appointmentId');
    final sourceRows = database.select(
      'SELECT * FROM appointments WHERE id = ? AND doctor_id = ? LIMIT 1',
      [sourceId, user.id],
    );
    if (sourceRows.isEmpty) {
      throw ApiException(403, 'Lịch hẹn không thuộc bác sĩ hiện tại');
    }
    final source = sourceRows.first;
    final appointmentTime = _required(body, 'appointmentTime');
    final parsedTime = DateTime.tryParse(appointmentTime)?.toLocal();
    if (parsedTime == null || !parsedTime.isAfter(DateTime.now())) {
      throw ApiException(400, 'Thời gian tái khám phải ở tương lai');
    }
    final date = _dateKey(parsedTime);
    final time = _timeKey(parsedTime);
    final matchingSlots = listAppointmentSlots(user.id, date)
        .where((item) => item['time'] == time)
        .toList(growable: false);
    final slot = matchingSlots.isEmpty ? null : matchingSlots.first;
    if (slot != null && (slot['booked'] as int) >= (slot['capacity'] as int)) {
      throw ApiException(409, 'Khung giờ tái khám đã hết chỗ');
    }
    final id = _id('appt');
    final item = <String, Object?>{
      'id': id,
      'patientId': source['patient_id'],
      'doctorId': user.id,
      'doctorName': body['doctorName'] as String? ?? source['doctor_name'],
      'specialty': body['specialty'] as String? ?? source['specialty'],
      'appointmentTime': appointmentTime,
      'reason': _required(body, 'reason'),
      'insuranceApplied': false,
      'fee': 0,
      'status': 'confirmed',
      'ticketNumber': 'KB-${Random.secure().nextInt(9000) + 1000}',
      'createdAt': _now(),
    };
    database.execute(
      '''INSERT INTO appointments
         (id, patient_id, doctor_id, doctor_name, specialty, appointment_time,
          reason, insurance_applied, fee, status, ticket_number, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        item['id'],
        item['patientId'],
        item['doctorId'],
        item['doctorName'],
        item['specialty'],
        item['appointmentTime'],
        item['reason'],
        0,
        item['fee'],
        item['status'],
        item['ticketNumber'],
        item['createdAt'],
      ],
    );
    _notifyPatient(
      item['patientId'] as String,
      title: 'Bác sĩ đã tạo lịch tái khám',
      body: 'Lịch tái khám mới đã được thêm vào danh sách lịch hẹn của bạn.',
      type: 'follow_up_created',
      appointmentId: item['id'] as String,
      sourceId: sourceId,
    );
    return item;
  }

  Map<String, Object?> updateAppointmentStatus(
    String id,
    String status, {
    String? appointmentTime,
    String? doctorId,
  }) {
    if (doctorId != null) {
      final owned = database.select(
        'SELECT id FROM appointments WHERE id = ? AND doctor_id = ? LIMIT 1',
        [id, doctorId],
      );
      if (owned.isEmpty) {
        throw ApiException(403, 'Appointment does not belong to this doctor');
      }
    }
    database.execute(
      '''
      UPDATE appointments
      SET status = ?, appointment_time = COALESCE(?, appointment_time)
      WHERE id = ?
      ''',
      [status, appointmentTime, id],
    );
    if (status == 'completed') {
      database.execute(
        '''UPDATE feature_records
           SET status = 'completed', updated_at = ?
           WHERE feature_type = 'queue_ticket'
             AND json_extract(payload_json, '\$.appointmentId') = ?
             AND status NOT IN ('completed', 'skipped')''',
        [_now(), id],
      );
    }
    final rows = database
        .select('SELECT * FROM appointments WHERE id = ? LIMIT 1', [id]);
    if (rows.isEmpty) throw ApiException(404, 'Appointment not found');
    return _appointmentFromRow(rows.first);
  }

  Map<String, Object?> updatePatientAppointment(
    String id,
    AuthUser user, {
    String? status,
    String? appointmentTime,
  }) {
    final rows = database.select(
      'SELECT patient_id, status FROM appointments WHERE id = ? LIMIT 1',
      [id],
    );
    if (rows.isEmpty) throw ApiException(404, 'Appointment not found');
    if (rows.first['patient_id'] != (user.patientId ?? user.id)) {
      throw ApiException(403, 'Appointment does not belong to this patient');
    }
    return updateAppointmentStatus(
      id,
      status ?? rows.first['status'] as String,
      appointmentTime: appointmentTime,
    );
  }

  Map<String, Object?> createPaymentVerificationRequest(
    AuthUser user,
    Map<String, Object?> body,
  ) {
    final clientTransactionId = _required(body, 'clientTransactionId');
    final appointmentId = body['appointmentId'] as String?;
    Map<String, Object?>? appointment;
    if (appointmentId != null && appointmentId.trim().isNotEmpty) {
      final rows = database.select(
        'SELECT * FROM appointments WHERE id = ? LIMIT 1',
        [appointmentId],
      );
      if (rows.isEmpty) throw ApiException(404, 'Appointment not found');
      final row = rows.first;
      if (row['patient_id'] != (user.patientId ?? user.id)) {
        throw ApiException(403, 'Appointment does not belong to this patient');
      }
      if (row['status'] == 'cancelled' || row['status'] == 'completed') {
        throw ApiException(409, 'Appointment is not payable');
      }
      appointment = _appointmentFromRow(row);
    }
    final amount = body['amount'];
    if (amount is! num || amount <= 0) {
      throw ApiException(400, 'amount must be a positive number');
    }
    final existing = database.select(
      'SELECT * FROM payments WHERE client_transaction_id = ? LIMIT 1',
      [clientTransactionId],
    );
    if (existing.isNotEmpty) return _paymentFromRow(existing.first);
    if (appointment != null &&
        (appointment['fee'] as num? ?? 0) > 0 &&
        amount.toInt() != (appointment['fee'] as num).toInt()) {
      throw ApiException(409, 'Số tiền thanh toán không khớp phí khám');
    }

    final id = _id('payment');
    final purpose = (body['purpose'] as String?)?.trim().isNotEmpty == true
        ? (body['purpose'] as String).trim()
        : 'appointment';
    const receipt = '';
    database.execute(
      '''
      INSERT INTO payments (
        id, patient_id, client_transaction_id, amount, method, status,
        appointment_id, receipt_code, purpose, created_at
      ) VALUES (?, ?, ?, ?, ?, 'pending', ?, ?, ?, ?)
      ''',
      [
        id,
        user.patientId ?? user.id,
        clientTransactionId,
        amount.toInt(),
        body['method'] as String? ?? 'manual',
        appointmentId,
        receipt,
        purpose,
        _now(),
      ],
    );
    return {
      'id': id,
      'clientTransactionId': clientTransactionId,
      'amount': amount.toInt(),
      'method': body['method'] as String? ?? 'manual',
      'appointmentId': appointmentId,
      'purpose': purpose,
      'status': 'pending',
      'receiptCode': receipt,
      'createdAt': _now(),
    };
  }

  Map<String, Object?> getPaymentStatus(
    AuthUser user,
    String clientTransactionId,
  ) {
    final rows = database.select(
      'SELECT * FROM payments WHERE client_transaction_id = ? LIMIT 1',
      [clientTransactionId],
    );
    if (rows.isEmpty) throw ApiException(404, 'Payment not found');
    final row = rows.first;
    if (row['patient_id'] != (user.patientId ?? user.id) &&
        user.role != 'admin') {
      throw ApiException(403, 'Payment does not belong to this patient');
    }
    return _paymentFromRow(row);
  }

  Map<String, Object?> applyPaymentWebhook(Map<String, Object?> body) {
    final clientTransactionId = _required(body, 'clientTransactionId');
    final status = _required(body, 'status').toLowerCase();
    const allowed = {'pending', 'success', 'failed', 'refunded'};
    if (!allowed.contains(status)) {
      throw ApiException(400, 'Invalid payment status');
    }
    final rows = database.select(
      'SELECT * FROM payments WHERE client_transaction_id = ? LIMIT 1',
      [clientTransactionId],
    );
    if (rows.isEmpty) throw ApiException(404, 'Payment not found');
    final previousStatus = rows.first['status'] as String? ?? 'pending';
    final webhookAmount = body['amount'];
    if (webhookAmount is num &&
        webhookAmount.toInt() != (rows.first['amount'] as int)) {
      throw ApiException(409, 'Số tiền webhook không khớp giao dịch');
    }
    if (previousStatus == status) return _paymentFromRow(rows.first);
    final validTransition = switch (previousStatus) {
      'pending' => status == 'success' || status == 'failed',
      'failed' => status == 'pending',
      'success' => status == 'refunded',
      'refunded' => false,
      _ => false,
    };
    if (!validTransition) {
      throw ApiException(
        409,
        'Không thể chuyển trạng thái thanh toán từ $previousStatus sang $status',
      );
    }
    final submittedReceipt = body['receiptCode'] as String? ?? '';
    final receiptCode = submittedReceipt.trim().isNotEmpty
        ? submittedReceipt.trim()
        : status == 'success'
            ? 'RC-${DateTime.now().millisecondsSinceEpoch}'
            : '';
    database.execute(
      '''UPDATE payments SET status = ?, receipt_code = ?
         WHERE client_transaction_id = ?''',
      [status, receiptCode, clientTransactionId],
    );
    final updated = database.select(
      'SELECT * FROM payments WHERE client_transaction_id = ? LIMIT 1',
      [clientTransactionId],
    ).first;
    if (status == 'success') {
      final appointmentId = updated['appointment_id'] as String?;
      if (appointmentId != null && appointmentId.isNotEmpty) {
        database.execute(
          "UPDATE appointments SET status = 'confirmed' WHERE id = ? AND status = 'awaiting_payment'",
          [appointmentId],
        );
      }
      if ((updated['purpose'] as String? ?? '') == 'wallet_topup') {
        _creditWalletFromPayment(updated);
      }
    }
    if (previousStatus != status) {
      final patientId = updated['patient_id'] as String;
      if (status == 'success') {
        final isWalletTopUp =
            (updated['purpose'] as String? ?? '') == 'wallet_topup';
        final isPharmacyOrder =
            (updated['purpose'] as String? ?? '') == 'pharmacy_order';
        _notifyPatient(
          patientId,
          title: isWalletTopUp
              ? 'Nạp ví MedCare Pay đã được admin duyệt'
              : isPharmacyOrder
                  ? 'Thanh toán đơn thuốc đã được admin duyệt'
                  : 'Thanh toán đã được admin duyệt',
          body: isWalletTopUp
              ? 'Số dư ví đã được cộng ${updated['amount']}đ${receiptCode.isEmpty ? '' : ' • Biên lai: $receiptCode'}.'
              : isPharmacyOrder
                  ? 'Thanh toán đơn thuốc/giao thuốc đã được xác nhận${receiptCode.isEmpty ? '' : ' • Biên lai: $receiptCode'}. Vui lòng theo dõi trạng thái giao thuốc.'
                  : 'Viện phí đã được xác nhận${receiptCode.isEmpty ? '' : ' • Biên lai: $receiptCode'}. Lịch khám đã mở mã QR check-in và nhận số thứ tự.',
          type: isWalletTopUp
              ? 'wallet_topup_approved'
              : isPharmacyOrder
                  ? 'pharmacy_payment_approved'
                  : 'payment_approved',
          appointmentId: updated['appointment_id'] as String?,
          sourceId: updated['id'] as String?,
        );
      } else if (status == 'failed') {
        _notifyPatient(
          patientId,
          title: 'Thanh toán chưa được duyệt',
          body:
              'Yêu cầu thanh toán cần được kiểm tra lại. Vui lòng xem chi tiết và gửi lại giao dịch.',
          type: 'payment_rejected',
          appointmentId: updated['appointment_id'] as String?,
          sourceId: updated['id'] as String?,
        );
      } else if (status == 'refunded') {
        _notifyPatient(
          patientId,
          title: 'Thanh toán đã được hoàn tiền',
          body:
              'Giao dịch ${updated['client_transaction_id']} đã được hoàn tiền.',
          type: 'payment_refunded',
          appointmentId: updated['appointment_id'] as String?,
          sourceId: updated['id'] as String?,
        );
      }
    }
    return _paymentFromRow(updated);
  }

  Map<String, Object?> reviewPayment(
    String clientTransactionId,
    Map<String, Object?> body,
  ) {
    return applyPaymentWebhook({
      ...body,
      'clientTransactionId': clientTransactionId,
    });
  }

  Map<String, Object?> wallet(AuthUser user) {
    final patientId = user.patientId ?? user.id;
    database.execute(
      '''INSERT OR IGNORE INTO wallet_accounts (patient_id, balance, updated_at)
         VALUES (?, 0, ?)''',
      [patientId, _now()],
    );
    final account = database.select(
      'SELECT * FROM wallet_accounts WHERE patient_id = ? LIMIT 1',
      [patientId],
    ).first;
    final rows = database.select(
      '''SELECT * FROM wallet_transactions WHERE patient_id = ?
         ORDER BY created_at DESC LIMIT 100''',
      [patientId],
    );
    return {
      'patientId': patientId,
      'balance': account['balance'],
      'transactions': rows.map(_walletTransactionFromRow).toList(),
    };
  }

  void _creditWalletFromPayment(Row payment) {
    final patientId = payment['patient_id'] as String;
    final paymentId = payment['id'] as String;
    final exists = database.select(
      '''SELECT id FROM wallet_transactions
         WHERE source_payment_id = ? LIMIT 1''',
      [paymentId],
    );
    if (exists.isNotEmpty) return;
    database.execute(
      '''INSERT OR IGNORE INTO wallet_accounts (patient_id, balance, updated_at)
         VALUES (?, 0, ?)''',
      [patientId, _now()],
    );
    final txId = _id('wallet');
    database.execute(
      '''INSERT INTO wallet_transactions
         (id, patient_id, type, amount, description, source_payment_id, created_at)
         VALUES (?, ?, 'credit', ?, ?, ?, ?)''',
      [
        txId,
        patientId,
        payment['amount'],
        'Nạp ví MedCare Pay đã được duyệt',
        paymentId,
        _now()
      ],
    );
    database.execute(
      'UPDATE wallet_accounts SET balance = balance + ?, updated_at = ? WHERE patient_id = ?',
      [payment['amount'], _now(), patientId],
    );
  }

  Map<String, Object?> chargeWallet(AuthUser user, Map<String, Object?> body) {
    final patientId = user.patientId ?? user.id;
    final amount = (body['amount'] as num?)?.toInt() ?? 0;
    final description = _required(body, 'description');
    if (amount <= 0) throw ApiException(400, 'amount must be positive');
    database.execute(
      '''INSERT OR IGNORE INTO wallet_accounts (patient_id, balance, updated_at)
         VALUES (?, 0, ?)''',
      [patientId, _now()],
    );
    final account = database.select(
      'SELECT balance FROM wallet_accounts WHERE patient_id = ? LIMIT 1',
      [patientId],
    ).first;
    if ((account['balance'] as int) < amount) {
      throw ApiException(409, 'Số dư ví không đủ để thanh toán');
    }
    final id = _id('wallet');
    database.execute(
      '''UPDATE wallet_accounts SET balance = balance - ?, updated_at = ?
         WHERE patient_id = ? AND balance >= ?''',
      [amount, _now(), patientId, amount],
    );
    database.execute(
      '''INSERT INTO wallet_transactions
         (id, patient_id, type, amount, description, source_payment_id, created_at)
         VALUES (?, ?, 'debit', ?, ?, NULL, ?)''',
      [id, patientId, amount, description, _now()],
    );
    _notifyPatient(patientId,
        title: 'Đã thanh toán bằng ví MedCare Pay',
        body: '$description • ${amount}đ',
        type: 'wallet_charge',
        sourceId: id);
    return {
      'id': id,
      'patientId': patientId,
      'amount': amount,
      'description': description,
      'type': 'debit',
      'createdAt': _now()
    };
  }

  Map<String, Object?> _walletTransactionFromRow(Row row) => {
        'id': row['id'],
        'type': row['type'],
        'amount': row['amount'],
        'description': row['description'],
        'sourcePaymentId': row['source_payment_id'],
        'createdAt': row['created_at'],
      };

  Map<String, Object?> createSupportRequest(
    AuthUser user,
    Map<String, Object?> body,
  ) {
    final category = _required(body, 'category');
    final message = _required(body, 'message');
    if (message.length < 3) {
      throw ApiException(400, 'message is too short');
    }
    final item = {
      'id': 'HT-${Random.secure().nextInt(900000) + 100000}',
      'category': category,
      'message': message,
      'status': 'open',
      'createdAt': _now(),
    };
    database.execute(
      '''
      INSERT INTO support_requests (
        id, user_id, category, message, status, created_at
      ) VALUES (?, ?, ?, ?, ?, ?)
      ''',
      [
        item['id'],
        user.id,
        item['category'],
        item['message'],
        item['status'],
        item['createdAt'],
      ],
    );
    return item;
  }

  List<Map<String, Object?>> listSupportRequests(AuthUser user) {
    final rows = user.role == 'admin'
        ? database.select(
            'SELECT * FROM support_requests ORDER BY created_at DESC',
          )
        : database.select(
            '''SELECT * FROM support_requests
               WHERE user_id = ? ORDER BY created_at DESC''',
            [user.id],
          );
    return rows
        .map(
          (row) => <String, Object?>{
            'id': row['id'],
            'category': row['category'],
            'message': row['message'],
            'status': row['status'],
            'createdAt': row['created_at'],
          },
        )
        .toList();
  }

  Map<String, Object?> getSupportRequest(String id, AuthUser user) {
    final rows = database.select(
      'SELECT * FROM support_requests WHERE id = ? LIMIT 1',
      [id],
    );
    if (rows.isEmpty) throw ApiException(404, 'Support request not found');
    if (user.role != 'admin' && rows.first['user_id'] != user.id) {
      throw ApiException(403, 'Support request does not belong to this user');
    }
    final messages = database.select(
      '''SELECT id, sender_id, message, created_at
         FROM support_messages WHERE request_id = ? ORDER BY created_at ASC''',
      [id],
    );
    return {
      'id': rows.first['id'],
      'category': rows.first['category'],
      'message': rows.first['message'],
      'status': rows.first['status'],
      'createdAt': rows.first['created_at'],
      'messages': messages
          .map(
            (row) => <String, Object?>{
              'id': row['id'],
              'senderId': row['sender_id'],
              'message': row['message'],
              'createdAt': row['created_at'],
            },
          )
          .toList(),
    };
  }

  Map<String, Object?> addSupportMessage(
    String id,
    AuthUser user,
    Map<String, Object?> body,
  ) {
    final request = getSupportRequest(id, user);
    final message = _required(body, 'message');
    if (request['status'] == 'closed') {
      throw ApiException(409, 'Support request is closed');
    }
    final item = {
      'id': _id('support-message'),
      'senderId': user.id,
      'message': message,
      'createdAt': _now(),
    };
    database.execute(
      '''INSERT INTO support_messages
         (id, request_id, sender_id, message, created_at)
         VALUES (?, ?, ?, ?, ?)''',
      [item['id'], id, user.id, message, item['createdAt']],
    );
    database.execute(
      '''UPDATE support_requests SET status = ?, created_at = created_at
         WHERE id = ?''',
      [user.role == 'admin' ? 'waiting_for_user' : 'open', id],
    );
    return item;
  }

  Map<String, Object?> updateSupportStatus(
    String id,
    AuthUser user,
    Map<String, Object?> body,
  ) {
    final status = _required(body, 'status');
    const allowed = {
      'open',
      'assigned',
      'in_progress',
      'waiting_for_user',
      'resolved',
      'closed',
    };
    if (!allowed.contains(status)) {
      throw ApiException(400, 'Invalid support status');
    }
    getSupportRequest(id, user);
    database.execute(
      'UPDATE support_requests SET status = ? WHERE id = ?',
      [status, id],
    );
    return getSupportRequest(id, user);
  }

  List<Map<String, Object?>> listCaregiverPermissions(AuthUser user) {
    final rows = database.select(
      '''SELECT * FROM feature_records
         WHERE feature_type = 'caregiver_permission'
         ORDER BY updated_at DESC''',
    );
    return rows.map(_featureFromRow).where((item) {
      final payload = Map<String, Object?>.from(item['payload'] as Map);
      return item['ownerId'] == user.id || payload['caregiverId'] == user.id;
    }).toList();
  }

  Map<String, Object?> acceptCaregiverInvitation(
    String id,
    AuthUser user,
  ) {
    final rows = database.select(
      '''SELECT * FROM feature_records
         WHERE feature_type = 'caregiver_invitation' AND id = ? LIMIT 1''',
      [id],
    );
    if (rows.isEmpty) throw ApiException(404, 'Invitation not found');
    final invitation = _featureFromRow(rows.first);
    final payload = Map<String, Object?>.from(invitation['payload'] as Map);
    if (invitation['status'] != 'pending') {
      throw ApiException(409, 'Invitation is no longer pending');
    }
    if (payload['inviteeIdentifier'] != user.identifier) {
      throw ApiException(403, 'Invitation is not addressed to this user');
    }
    database.execute(
      'UPDATE feature_records SET status = ?, updated_at = ? WHERE id = ?',
      ['accepted', _now(), id],
    );
    payload['invitationId'] = id;
    payload['caregiverId'] = user.id;
    payload['acceptedAt'] = _now();
    return _insertFeatureForOwner(
      'caregiver_permission',
      invitation['ownerId'] as String,
      payload,
      status: 'active',
    );
  }

  void revokeCaregiverPermission(String id, AuthUser user) {
    final rows = database.select(
      '''SELECT * FROM feature_records
         WHERE feature_type = 'caregiver_permission' AND id = ? LIMIT 1''',
      [id],
    );
    if (rows.isEmpty) throw ApiException(404, 'Permission not found');
    final payload = jsonDecode(rows.first['payload_json'] as String) as Map;
    final allowed = rows.first['owner_id'] == user.id ||
        payload['caregiverId'] == user.id ||
        user.role == 'admin';
    if (!allowed) throw ApiException(403, 'Permission cannot be revoked');
    database.execute(
      'UPDATE feature_records SET status = ?, updated_at = ? WHERE id = ?',
      ['revoked', _now(), id],
    );
  }

  Map<String, Object?> createCheckIn(
    AuthUser user,
    Map<String, Object?> body,
  ) {
    final appointmentId = _required(body, 'appointmentId');
    final rows = database.select(
      'SELECT * FROM appointments WHERE id = ? LIMIT 1',
      [appointmentId],
    );
    if (rows.isEmpty) throw ApiException(404, 'Appointment not found');
    final appointment = rows.first;
    if (appointment['patient_id'] != (user.patientId ?? user.id)) {
      throw ApiException(403, 'Appointment does not belong to this patient');
    }
    if (appointment['status'] != 'confirmed') {
      throw ApiException(409, 'Appointment is not eligible for check-in');
    }
    final existing = database.select(
      '''SELECT * FROM feature_records
         WHERE feature_type = 'check_in' AND owner_id = ?
         AND json_extract(payload_json, '\$.appointmentId') = ?
         AND status IN ('issued', 'checked_in')
         ORDER BY created_at DESC LIMIT 1''',
      [user.id, appointmentId],
    );
    if (existing.isNotEmpty) {
      if (existing.first['status'] == 'checked_in') {
        return _featureFromRow(existing.first);
      }
      database.execute(
        '''UPDATE feature_records SET status = 'revoked', updated_at = ?
           WHERE id = ?''',
        [_now(), existing.first['id']],
      );
    }

    final token = _secureToken();
    final now = DateTime.now().toUtc();
    final expires = now.add(const Duration(minutes: 10));
    final result = _insertFeature(
      'check_in',
      user,
      {
        'appointmentId': appointmentId,
        'tokenHash': sha256Text(token),
        'expiresAt': expires.toIso8601String(),
        'checkedInAt': null,
        'receptionPointId': body['receptionPointId'],
      },
      status: 'issued',
    );
    result['token'] = token;
    return result;
  }

  Map<String, Object?> verifyCheckIn(
    String id,
    Map<String, Object?> body,
    AuthUser user,
  ) {
    final record = getFeatureRecord(
      'check_in',
      id,
      user,
      allowForeignAdmin: true,
      includeSensitive: true,
    );
    if (record['status'] == 'checked_in') return record;
    final payload = Map<String, Object?>.from(
      (record['payload'] as Map?)?.cast<String, Object?>() ?? {},
    );
    final token = _required(body, 'token');
    if (sha256Text(token) != payload['tokenHash']) {
      throw ApiException(401, 'Invalid check-in token');
    }
    final expiresAt = DateTime.tryParse(payload['expiresAt'] as String? ?? '');
    if (expiresAt == null || expiresAt.isBefore(DateTime.now().toUtc())) {
      throw ApiException(410, 'Check-in token expired');
    }
    payload['checkedInAt'] = _now();
    payload.remove('token');
    return updateFeatureRecord(
      'check_in',
      id,
      user,
      payload,
      overrideStatus: 'checked_in',
      allowForeignAdmin: true,
    );
  }

  Map<String, Object?> joinQueue(AuthUser user, String appointmentId) {
    final appointment = database.select(
      'SELECT * FROM appointments WHERE id = ? LIMIT 1',
      [appointmentId],
    );
    if (appointment.isEmpty) throw ApiException(404, 'Appointment not found');
    if (appointment.first['patient_id'] != (user.patientId ?? user.id)) {
      throw ApiException(403, 'Appointment does not belong to this patient');
    }
    final checkedIn = database.select(
      '''SELECT id FROM feature_records
         WHERE feature_type = 'check_in' AND owner_id = ?
         AND json_extract(payload_json, '\$.appointmentId') = ?
         AND status = 'checked_in' LIMIT 1''',
      [user.id, appointmentId],
    );
    if (checkedIn.isEmpty) {
      throw ApiException(409, 'Patient must complete check-in first');
    }
    final existing = database.select(
      '''SELECT * FROM feature_records
         WHERE feature_type = 'queue_ticket' AND owner_id = ?
         AND json_extract(payload_json, '\$.appointmentId') = ?
         AND status NOT IN ('completed', 'skipped')
         LIMIT 1''',
      [user.id, appointmentId],
    );
    if (existing.isNotEmpty) return _featureFromRow(existing.first);
    final queueId = appointment.first['doctor_id'] as String;
    final queue = queueState(queueId);
    final activeTicketRows = database.select(
      '''SELECT json_extract(payload_json, '\$.patientNumber') AS patient_number
         FROM feature_records
         WHERE feature_type = 'queue_ticket'
           AND json_extract(payload_json, '\$.queueId') = ?
           AND status NOT IN ('completed', 'skipped')''',
      [queueId],
    );
    var nextPatientNumber = (queue['currentNumber'] as int? ?? 0) + 1;
    for (final row in activeTicketRows) {
      final number = (row['patient_number'] as num?)?.toInt();
      if (number != null && number >= nextPatientNumber) {
        nextPatientNumber = number + 1;
      }
    }
    return _insertFeature(
      'queue_ticket',
      user,
      {
        'appointmentId': appointmentId,
        'queueId': queueId,
        'ticketNumber': 'Q-${nextPatientNumber.toString().padLeft(4, '0')}',
        'priorityLevel': (appointment.first['priority_level'] as int?) ?? 0,
        'currentNumber': queue['currentNumber'],
        'patientNumber': nextPatientNumber,
        'estimatedMinutes':
            ((nextPatientNumber - (queue['currentNumber'] as int? ?? 0)) * 4)
                .clamp(0, 240),
        'department': queue['department'],
        'room': queue['room'],
        'doctorName': queue['doctorName'],
      },
      status: 'waiting',
    );
  }

  Map<String, Object?> getQueueForAppointment(
    AuthUser user,
    String appointmentId,
  ) {
    final rows = database.select(
      '''SELECT * FROM feature_records
         WHERE feature_type = 'queue_ticket' AND owner_id = ?
         AND json_extract(payload_json, '\$.appointmentId') = ?
         ORDER BY created_at DESC LIMIT 1''',
      [user.id, appointmentId],
    );
    if (rows.isEmpty) throw ApiException(404, 'Queue ticket not found');
    final ticket = _featureFromRow(rows.first);
    final payload = ticket['payload'] is Map
        ? Map<String, Object?>.from(ticket['payload'] as Map)
        : <String, Object?>{};
    // currentNumber phải lấy từ queue_state vì ticket được tạo trước khi
    // bác sĩ gọi số tiếp theo.
    final queueId = payload['queueId']?.toString() ?? 'main';
    final liveQueue = queueState(queueId);
    payload['currentNumber'] = liveQueue['currentNumber'];
    payload['department'] = liveQueue['department'];
    payload['room'] = liveQueue['room'];
    payload['doctorName'] = liveQueue['doctorName'];
    final patientNumber = (payload['patientNumber'] as num?)?.toInt();
    if (patientNumber != null) {
      payload['estimatedMinutes'] =
          ((patientNumber - (liveQueue['currentNumber'] as int)) * 4)
              .clamp(0, 240);
    }
    ticket['payload'] = payload;
    return ticket;
  }

  Map<String, Object?> createFeatureRecord(
    String type,
    AuthUser user,
    Map<String, Object?> payload, {
    required String initialStatus,
  }) {
    return _insertFeature(type, user, payload, status: initialStatus);
  }

  Map<String, Object?> uploadMedicalFile(
    AuthUser user,
    Map<String, Object?> body,
  ) {
    final patientId = _required(body, 'patientId');
    final category = _required(body, 'category');
    final fileName = _required(body, 'fileName');
    final mimeType = _required(body, 'mimeType').toLowerCase();
    final rawBase64 = _required(body, 'dataBase64');
    const allowedMimeTypes = {
      'image/jpeg',
      'image/png',
      'image/webp',
      'application/pdf',
    };
    if (!allowedMimeTypes.contains(mimeType)) {
      throw ApiException(400, 'Unsupported medical file type');
    }
    final patient = database.select(
      'SELECT id, patient_id, role FROM users WHERE id = ? OR patient_id = ? LIMIT 1',
      [patientId, patientId],
    );
    if (patient.isEmpty || patient.first['role'] != 'patient') {
      throw ApiException(404, 'Patient not found');
    }
    final canonicalPatientId =
        patient.first['patient_id'] as String? ?? patient.first['id'] as String;
    final appointmentId = body['appointmentId']?.toString().trim();
    if (user.role == 'doctor') {
      if (appointmentId == null || appointmentId.isEmpty) {
        throw ApiException(400, 'appointmentId is required for doctor upload');
      }
      final appointment = database.select(
        '''SELECT id FROM appointments
           WHERE id = ? AND patient_id = ? AND doctor_id = ?
           AND status NOT IN ('cancelled') LIMIT 1''',
        [appointmentId, canonicalPatientId, user.id],
      );
      if (appointment.isEmpty) {
        throw ApiException(403, 'Doctor cannot upload for this appointment');
      }
    }
    final encoded = rawBase64.contains(',')
        ? rawBase64.substring(rawBase64.indexOf(',') + 1)
        : rawBase64;
    late List<int> bytes;
    try {
      bytes = base64Decode(encoded.replaceAll(RegExp(r'\s+'), ''));
    } catch (_) {
      throw ApiException(400, 'dataBase64 is invalid');
    }
    if (bytes.isEmpty || bytes.length > 12 * 1024 * 1024) {
      throw ApiException(400, 'Medical file must be between 1 byte and 12 MB');
    }
    final id = _id('medical-file');
    final extension = _safeFileExtension(fileName, mimeType);
    final directory = Directory(fileStorageDirectory);
    directory.createSync(recursive: true);
    final storagePath =
        File('${directory.path}${Platform.pathSeparator}$id$extension');
    storagePath.writeAsBytesSync(bytes, flush: true);
    final now = _now();
    database.execute(
      '''INSERT INTO medical_files
         (id, patient_id, uploaded_by, appointment_id, category, findings,
          file_name, mime_type, size_bytes, storage_path, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id,
        canonicalPatientId,
        user.id,
        appointmentId,
        category,
        body['findings']?.toString() ?? '',
        fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_'),
        mimeType,
        bytes.length,
        storagePath.path,
        now,
      ],
    );
    _notifyPatient(
      canonicalPatientId,
      title: 'Bác sĩ đã gửi tệp hồ sơ y tế',
      body: '$category • $fileName',
      type: 'medical_file_uploaded',
      appointmentId: appointmentId,
      sourceId: id,
    );
    return _medicalFileFromRow(
      database.select('SELECT * FROM medical_files WHERE id = ?', [id]).first,
    );
  }

  List<Map<String, Object?>> listMedicalFiles(
    AuthUser user, {
    String? patientId,
  }) {
    final cleanPatientId = patientId?.trim() ?? '';
    final rows = switch (user.role) {
      'admin' => cleanPatientId.isEmpty
          ? database
              .select('SELECT * FROM medical_files ORDER BY created_at DESC')
          : database.select(
              'SELECT * FROM medical_files WHERE patient_id = ? ORDER BY created_at DESC',
              [cleanPatientId],
            ),
      'doctor' => cleanPatientId.isEmpty
          ? database.select(
              '''SELECT DISTINCT mf.* FROM medical_files mf
                 LEFT JOIN appointments a ON a.id = mf.appointment_id
                 WHERE mf.uploaded_by = ? OR a.doctor_id = ?
                 ORDER BY mf.created_at DESC''',
              [user.id, user.id],
            )
          : database.select(
              '''SELECT DISTINCT mf.* FROM medical_files mf
                 LEFT JOIN appointments a ON a.id = mf.appointment_id
                 WHERE mf.patient_id = ? AND (mf.uploaded_by = ? OR a.doctor_id = ?)
                 ORDER BY mf.created_at DESC''',
              [cleanPatientId, user.id, user.id],
            ),
      _ => database.select(
          'SELECT * FROM medical_files WHERE patient_id = ? ORDER BY created_at DESC',
          [user.patientId ?? user.id],
        ),
    };
    return rows.map(_medicalFileFromRow).toList(growable: false);
  }

  Map<String, Object?> getMedicalFile(String id, AuthUser user) {
    final rows = database.select(
      'SELECT * FROM medical_files WHERE id = ? LIMIT 1',
      [id],
    );
    if (rows.isEmpty) throw ApiException(404, 'Medical file not found');
    _assertMedicalFileAccess(rows.first, user);
    return _medicalFileFromRow(rows.first);
  }

  Map<String, Object?> readMedicalFileContent(String id, AuthUser user) {
    final rows = database.select(
      'SELECT * FROM medical_files WHERE id = ? LIMIT 1',
      [id],
    );
    if (rows.isEmpty) throw ApiException(404, 'Medical file not found');
    _assertMedicalFileAccess(rows.first, user);
    final path = rows.first['storage_path'] as String;
    final file = File(path);
    if (!file.existsSync()) {
      throw ApiException(410, 'Medical file content is missing');
    }
    return {
      'mimeType': rows.first['mime_type'],
      'bytes': file.readAsBytesSync(),
    };
  }

  void _assertMedicalFileAccess(Row row, AuthUser user) {
    if (user.role == 'admin' || row['uploaded_by'] == user.id) return;
    if (user.role == 'patient' &&
        row['patient_id'] == (user.patientId ?? user.id)) {
      return;
    }
    if (user.role == 'doctor') {
      final appointmentId = row['appointment_id'] as String?;
      if (appointmentId != null &&
          database.select(
            'SELECT id FROM appointments WHERE id = ? AND doctor_id = ? LIMIT 1',
            [appointmentId, user.id],
          ).isNotEmpty) {
        return;
      }
    }
    throw ApiException(403, 'Medical file does not belong to this user');
  }

  Map<String, Object?> _medicalFileFromRow(Row row) => {
        'id': row['id'],
        'patientId': row['patient_id'],
        'uploadedBy': row['uploaded_by'],
        'appointmentId': row['appointment_id'],
        'category': row['category'],
        'findings': row['findings'],
        'fileName': row['file_name'],
        'mimeType': row['mime_type'],
        'sizeBytes': row['size_bytes'],
        'downloadUrl': '/medical-files/${row['id']}/content',
        'createdAt': row['created_at'],
      };

  String _safeFileExtension(String fileName, String mimeType) {
    final raw = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.')).toLowerCase()
        : '';
    if (raw == '.jpg' ||
        raw == '.jpeg' ||
        raw == '.png' ||
        raw == '.webp' ||
        raw == '.pdf') {
      return raw;
    }
    return switch (mimeType) {
      'image/png' => '.png',
      'image/webp' => '.webp',
      'application/pdf' => '.pdf',
      _ => '.jpg',
    };
  }

  List<Map<String, Object?>> listFeatureRecords(
    String type,
    AuthUser user,
  ) {
    final rows = user.role == 'admin'
        ? database.select(
            'SELECT * FROM feature_records WHERE feature_type = ? ORDER BY updated_at DESC',
            [type],
          )
        : database.select(
            '''SELECT * FROM feature_records
               WHERE feature_type = ? AND owner_id = ?
               ORDER BY updated_at DESC''',
            [type, user.id],
          );
    return rows.map(_featureFromRow).toList();
  }

  List<Map<String, Object?>> listNotifications(AuthUser user) {
    // patient_notification thuộc tài khoản bệnh nhân; staff không đọc nhầm
    // danh sách này thành thông báo cá nhân của bác sĩ/admin.
    if (user.role == 'admin' || user.role == 'doctor') {
      return listFeatureRecords('staff_notification', user);
    }
    _backfillClinicalNotifications(user);
    return database
        .select(
          '''SELECT * FROM feature_records
             WHERE feature_type = 'patient_notification' AND owner_id = ?
             ORDER BY created_at DESC LIMIT 250''',
          [user.id],
        )
        .map(_featureFromRow)
        .toList(growable: false);
  }

  /// Bù notification cho các thao tác lâm sàng được ghi trước khi cơ chế
  /// thông báo được bật. Hồ sơ bệnh án vẫn là dữ liệu chi tiết; notification
  /// chỉ là một bản tin ngắn trỏ bệnh nhân về hồ sơ tương ứng.
  void _backfillClinicalNotifications(AuthUser user) {
    final patientId = user.patientId ?? user.id;
    final ownerId = user.id;
    final actions = database.select(
      '''SELECT id, patient_id, appointment_id, action
         FROM clinical_actions
         WHERE patient_id = ?
         ORDER BY created_at DESC LIMIT 250''',
      [patientId],
    );
    for (final action in actions) {
      final actionId = action['id'] as String;
      final exists = database.select(
        '''SELECT id FROM feature_records
           WHERE feature_type = 'patient_notification'
             AND owner_id = ?
             AND payload_json LIKE ?
           LIMIT 1''',
        [ownerId, '%"sourceId":"$actionId"%'],
      );
      if (exists.isNotEmpty) continue;
      final actionName = action['action'] as String;
      _notifyPatient(
        patientId,
        title: actionName == 'EMR_DIGITAL_SIGNATURE'
            ? 'Bệnh án điện tử đã được ký'
            : 'Bác sĩ vừa cập nhật hồ sơ',
        body: _patientActionMessage(actionName),
        type: 'clinical_update',
        appointmentId: action['appointment_id'] as String?,
        sourceId: actionId,
      );
    }
  }

  Map<String, Object?> markNotificationRead(String id, AuthUser user) {
    return updateFeatureRecord(
      'patient_notification',
      id,
      user,
      {'read': true},
      overrideStatus: 'read',
    );
  }

  String _patientUserId(String patientId) {
    final rows = database.select(
      'SELECT id FROM users WHERE id = ? OR patient_id = ? LIMIT 1',
      [patientId, patientId],
    );
    return rows.isEmpty ? patientId : rows.first['id'] as String;
  }

  String _patientActionMessage(String action) {
    switch (action) {
      case 'LAB_RESULT':
        return 'Kết quả xét nghiệm mới đã được trả và lưu trong mục Xét nghiệm gần nhất.';
      case 'IMAGING_RESULT':
      case 'IMAGING_ORDER_XRAY':
      case 'IMAGING_ORDER_ULTRASOUND':
      case 'IMAGING_ORDER_ECG':
      case 'IMAGING_ORDER_ECHO':
      case 'IMAGING_ORDER_CT':
        return 'Kết quả chẩn đoán hình ảnh/thăm dò chức năng đã được cập nhật.';
      case 'CLINICAL_ORDER':
        return 'Bác sĩ đã tạo một y lệnh cận lâm sàng cho ca khám.';
      case 'EMR_DIGITAL_SIGNATURE':
        return 'Bệnh án điện tử đã được bác sĩ ký số.';
      default:
        return 'Thông tin khám và điều trị mới đã được cập nhật trong hồ sơ của bạn.';
    }
  }

  void _notifyPatient(
    String patientId, {
    required String title,
    required String body,
    required String type,
    String? appointmentId,
    String? sourceId,
  }) {
    final ownerId = _patientUserId(patientId);
    _insertFeatureForOwner(
      'patient_notification',
      ownerId,
      {
        'title': title,
        'body': body,
        'type': type,
        'patientId': patientId,
        'appointmentId': appointmentId,
        'sourceId': sourceId,
        'read': false,
      },
      status: 'unread',
    );
  }

  Map<String, Object?> getFeatureRecord(
    String type,
    String id,
    AuthUser user, {
    bool allowForeignAdmin = false,
    bool includeSensitive = false,
  }) {
    final rows = database.select(
      'SELECT * FROM feature_records WHERE feature_type = ? AND id = ? LIMIT 1',
      [type, id],
    );
    if (rows.isEmpty) throw ApiException(404, 'Record not found');
    final staffAccess =
        allowForeignAdmin && (user.role == 'doctor' || user.role == 'admin');
    if (!staffAccess && rows.first['owner_id'] != user.id) {
      throw ApiException(403, 'Record does not belong to this user');
    }
    final result = _featureFromRow(rows.first);
    if (!includeSensitive && type == 'check_in') {
      final payload = Map<String, Object?>.from(result['payload'] as Map);
      payload.remove('tokenHash');
      result['payload'] = payload;
    }
    return result;
  }

  Map<String, Object?> updateFeatureRecord(
    String type,
    String id,
    AuthUser user,
    Map<String, Object?> patch, {
    String? overrideStatus,
    bool allowForeignAdmin = false,
  }) {
    final rows = database.select(
      'SELECT * FROM feature_records WHERE feature_type = ? AND id = ? LIMIT 1',
      [type, id],
    );
    if (rows.isEmpty) throw ApiException(404, 'Record not found');
    final staffAccess =
        allowForeignAdmin && (user.role == 'doctor' || user.role == 'admin');
    if (!staffAccess && rows.first['owner_id'] != user.id) {
      throw ApiException(403, 'Record does not belong to this user');
    }
    final oldPayload = Map<String, Object?>.from(
      jsonDecode(rows.first['payload_json'] as String) as Map,
    );
    oldPayload.addAll(patch);
    database.execute(
      '''UPDATE feature_records SET payload_json = ?, status = ?, updated_at = ?
         WHERE feature_type = ? AND id = ?''',
      [
        jsonEncode(oldPayload),
        overrideStatus ?? patch['status'] ?? rows.first['status'],
        _now(),
        type,
        id,
      ],
    );
    return getFeatureRecord(type, id, user,
        allowForeignAdmin: allowForeignAdmin);
  }

  void deleteFeatureRecord(String type, String id, AuthUser user) {
    final record = getFeatureRecord(type, id, user);
    if (record['ownerId'] != user.id && user.role != 'admin') {
      throw ApiException(403, 'Record does not belong to this user');
    }
    database.execute(
      'DELETE FROM feature_records WHERE feature_type = ? AND id = ?',
      [type, id],
    );
  }

  Map<String, Object?> _insertFeature(
    String type,
    AuthUser user,
    Map<String, Object?> payload, {
    required String status,
  }) {
    final id = _id(type.replaceAll('_', '-'));
    final now = _now();
    database.execute(
      '''INSERT INTO feature_records
         (id, feature_type, owner_id, status, payload_json, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?)''',
      [id, type, user.id, status, jsonEncode(payload), now, now],
    );
    return {
      'id': id,
      'featureType': type,
      'ownerId': user.id,
      'status': status,
      'payload': payload,
      'createdAt': now,
      'updatedAt': now,
    };
  }

  Map<String, Object?> _insertFeatureForOwner(
    String type,
    String ownerId,
    Map<String, Object?> payload, {
    required String status,
  }) {
    final id = _id(type.replaceAll('_', '-'));
    final now = _now();
    database.execute(
      '''INSERT INTO feature_records
         (id, feature_type, owner_id, status, payload_json, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?)''',
      [id, type, ownerId, status, jsonEncode(payload), now, now],
    );
    return {
      'id': id,
      'featureType': type,
      'ownerId': ownerId,
      'status': status,
      'payload': payload,
      'createdAt': now,
      'updatedAt': now,
    };
  }

  Map<String, Object?> _featureFromRow(Row row) => {
        'id': row['id'],
        'featureType': row['feature_type'],
        'ownerId': row['owner_id'],
        'status': row['status'],
        'payload': jsonDecode(row['payload_json'] as String),
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
      };

  void _ensureDoctorPatientAccess(
    AuthUser user,
    String patientId, {
    String? appointmentId,
  }) {
    if (user.role == 'admin') return;
    if (user.role != 'doctor') {
      throw ApiException(403, 'Only a doctor or admin can write clinical data');
    }
    final rows = appointmentId == null || appointmentId.trim().isEmpty
        ? database.select(
            '''SELECT id FROM appointments
               WHERE doctor_id = ? AND patient_id = ? AND status NOT IN ('cancelled')
               LIMIT 1''',
            [user.id, patientId],
          )
        : database.select(
            '''SELECT id FROM appointments
               WHERE id = ? AND doctor_id = ? AND patient_id = ?
                 AND status NOT IN ('cancelled') LIMIT 1''',
            [appointmentId, user.id, patientId],
          );
    if (rows.isEmpty) {
      throw ApiException(
          403, 'Bác sĩ không được ghi dữ liệu cho bệnh nhân này');
    }
  }

  List<Map<String, Object?>> listPrescriptions(AuthUser user) {
    final rows = user.role == 'patient'
        ? database.select(
            'SELECT * FROM prescriptions WHERE patient_id = ? ORDER BY created_at DESC',
            [user.patientId ?? user.id],
          )
        : user.role == 'doctor'
            ? database.select(
                'SELECT * FROM prescriptions WHERE doctor_id = ? ORDER BY created_at DESC',
                [user.id],
              )
            : database
                .select('SELECT * FROM prescriptions ORDER BY created_at DESC');
    return rows.map(_prescriptionFromRow).toList();
  }

  Map<String, Object?> createPrescription(
      AuthUser user, Map<String, Object?> body) {
    final patientId = _required(body, 'patientId');
    final appointmentId = body['appointmentId'] as String?;
    _ensureDoctorPatientAccess(user, patientId, appointmentId: appointmentId);
    final id = _id('rx');
    final item = {
      'id': id,
      'patientId': patientId,
      'doctorId': user.id,
      'appointmentId': appointmentId,
      'diagnosis': _required(body, 'diagnosis'),
      'medicines': body['medicines'] ?? <Object?>[],
      'signedToken': 'RX-SHA256-${DateTime.now().millisecondsSinceEpoch}',
      'createdAt': _now(),
    };
    database.execute(
      '''
      INSERT INTO prescriptions (
        id, patient_id, doctor_id, appointment_id, diagnosis, medicines_json,
        signed_token, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        item['id'],
        item['patientId'],
        item['doctorId'],
        item['appointmentId'],
        item['diagnosis'],
        jsonEncode(item['medicines']),
        item['signedToken'],
        item['createdAt'],
      ],
    );
    _notifyPatient(
      patientId,
      title: 'Bác sĩ đã cập nhật đơn thuốc',
      body: 'Đơn thuốc mới đã được ký và đồng bộ vào hồ sơ bệnh án điện tử.',
      type: 'prescription_updated',
      appointmentId: appointmentId,
      sourceId: id,
    );
    return item;
  }

  List<Map<String, Object?>> listRecords(AuthUser user) {
    final rows = user.role == 'patient'
        ? database.select(
            'SELECT * FROM medical_records WHERE patient_id = ? ORDER BY created_at DESC',
            [user.patientId ?? user.id],
          )
        : user.role == 'doctor'
            ? database.select(
                'SELECT * FROM medical_records WHERE doctor_id = ? ORDER BY created_at DESC',
                [user.id],
              )
            : database.select(
                'SELECT * FROM medical_records ORDER BY created_at DESC');
    return rows.map(_recordFromRow).toList();
  }

  Map<String, Object?> createRecord(AuthUser user, Map<String, Object?> body) {
    final patientId = _required(body, 'patientId');
    final appointmentId = body['appointmentId'] as String?;
    _ensureDoctorPatientAccess(user, patientId, appointmentId: appointmentId);
    final id = _id('emr');
    final item = {
      'id': id,
      'patientId': patientId,
      'doctorId': user.id,
      'appointmentId': appointmentId,
      'diagnosis': _required(body, 'diagnosis'),
      'record': body['record'] ?? <String, Object?>{},
      'createdAt': _now(),
    };
    database.execute(
      '''
      INSERT INTO medical_records (
        id, patient_id, doctor_id, appointment_id, diagnosis, record_json, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        item['id'],
        item['patientId'],
        item['doctorId'],
        item['appointmentId'],
        item['diagnosis'],
        jsonEncode(item['record']),
        item['createdAt'],
      ],
    );
    _notifyPatient(
      patientId,
      title: 'Bác sĩ đã cập nhật bệnh án',
      body: 'Một nội dung mới trong hồ sơ bệnh án điện tử đã được cập nhật.',
      type: 'medical_record_updated',
      appointmentId: appointmentId,
      sourceId: id,
    );
    return item;
  }

  List<Map<String, Object?>> listClinicalActions(
    AuthUser user, {
    String? patientId,
  }) {
    final effectivePatientId =
        user.role == 'patient' ? (user.patientId ?? user.id) : patientId;
    final rows = user.role == 'doctor'
        ? database.select(
            '''SELECT * FROM clinical_actions
               WHERE actor_id = ?
               ${effectivePatientId == null || effectivePatientId.trim().isEmpty ? '' : 'AND patient_id = ?'}
               ORDER BY updated_at DESC LIMIT 500''',
            effectivePatientId == null || effectivePatientId.trim().isEmpty
                ? [user.id]
                : [user.id, effectivePatientId],
          )
        : effectivePatientId == null || effectivePatientId.trim().isEmpty
            ? database.select(
                'SELECT * FROM clinical_actions ORDER BY updated_at DESC LIMIT 500',
              )
            : database.select(
                '''SELECT * FROM clinical_actions
                   WHERE patient_id = ? ORDER BY updated_at DESC LIMIT 500''',
                [effectivePatientId],
              );
    return rows.map(_clinicalActionFromRow).toList(growable: false);
  }

  Map<String, Object?> createClinicalAction(
    AuthUser user,
    Map<String, Object?> body,
  ) {
    final patientId = _required(body, 'patientId');
    final appointmentId = body['appointmentId'] as String?;
    _ensureDoctorPatientAccess(user, patientId, appointmentId: appointmentId);
    final action = _required(body, 'action');
    final rawPayload = body['payload'];
    final payload = rawPayload is Map
        ? Map<String, Object?>.from(rawPayload)
        : <String, Object?>{};
    if (appointmentId != null && appointmentId.isNotEmpty) {
      payload['appointmentId'] = appointmentId;
    }
    final status = (body['status'] as String?)?.trim().isNotEmpty == true
        ? body['status'] as String
        : 'completed';
    final id = _id('clinical-action');
    final now = _now();
    database.execute(
      '''INSERT INTO clinical_actions
         (id, patient_id, actor_id, appointment_id, action, status, payload_json, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id,
        patientId,
        user.id,
        appointmentId,
        action,
        status,
        jsonEncode(payload),
        now,
        now,
      ],
    );
    _notifyPatient(
      patientId,
      title: action == 'EMR_DIGITAL_SIGNATURE'
          ? 'Bệnh án điện tử đã được ký'
          : 'Bác sĩ vừa cập nhật hồ sơ',
      body: _patientActionMessage(action),
      type: 'clinical_update',
      appointmentId: appointmentId,
      sourceId: id,
    );
    return {
      'id': id,
      'patientId': patientId,
      'actorId': user.id,
      'action': action,
      'status': status,
      'payload': payload,
      'createdAt': now,
      'updatedAt': now,
    };
  }

  Map<String, Object?> signEmr(
    AuthUser user,
    Map<String, Object?> body, {
    required String signingSecret,
  }) {
    final patientId = _required(body, 'patientId');
    final appointmentId = body['appointmentId'] as String?;
    _ensureDoctorPatientAccess(user, patientId, appointmentId: appointmentId);
    if (signingSecret.trim().isEmpty) {
      throw ApiException(503, 'Chưa cấu hình khóa ký EMR trên máy chủ');
    }
    final rawDocument = body['document'];
    final document = rawDocument is Map
        ? Map<String, Object?>.from(rawDocument)
        : <String, Object?>{};
    final signedAt = _now();
    final canonical = jsonEncode({
      'patientId': patientId,
      'appointmentId': appointmentId,
      'document': document,
      'signedBy': user.id,
      'signedAt': signedAt,
    });
    final signature = Hmac(
      sha256,
      utf8.encode(signingSecret),
    ).convert(utf8.encode(canonical)).toString();
    final payload = <String, Object?>{
      'patientId': patientId,
      'appointmentId': appointmentId,
      'document': document,
      'signature': signature,
      'algorithm': 'HMAC-SHA256',
      'signedBy': user.id,
      'signedAt': signedAt,
    };
    final item = createClinicalAction(user, {
      'patientId': patientId,
      'appointmentId': appointmentId,
      'action': 'EMR_DIGITAL_SIGNATURE',
      'status': 'signed',
      'payload': payload,
    });
    return item;
  }

  Map<String, Object?> _clinicalActionFromRow(Row row) => {
        'id': row['id'],
        'patientId': row['patient_id'],
        'actorId': row['actor_id'],
        'action': row['action'],
        'status': row['status'],
        'payload': jsonDecode(row['payload_json'] as String),
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
      };

  Map<String, Object?> adminOverview() {
    int count(String table, [String? where]) {
      final sql = where == null
          ? 'SELECT COUNT(*) AS total FROM $table'
          : 'SELECT COUNT(*) AS total FROM $table WHERE $where';
      return (database.select(sql).first['total'] as int?) ?? 0;
    }

    final lockdown = database.select(
      'SELECT value FROM system_controls WHERE control_key = ? LIMIT 1',
      ['emergency_lockdown'],
    );
    final completed = count('appointments', "status = 'completed'");
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final todayPatients = count(
      'appointments',
      "substr(appointment_time, 1, 10) = '$today' AND status <> 'cancelled'",
    );
    final paid = database
        .select(
          "SELECT COALESCE(SUM(amount), 0) AS total FROM payments WHERE status = 'success'",
        )
        .first['total'];
    return {
      'todayPatients': todayPatients,
      'todayRevenue': paid is num ? paid.toInt() : 0,
      'completedConsultations': completed,
      'totalPrescriptions': count('prescriptions'),
      'totalMedicalRecords': count('medical_records'),
      'totalClinicalActions': count('clinical_actions'),
      'totalAuditLogs': count('audit_logs'),
      'emergencyLockdown': lockdown.isNotEmpty &&
          (lockdown.first['value'] as String).toLowerCase() == 'true',
    };
  }

  Map<String, Object?> setSystemControl(
    AuthUser user,
    String key,
    bool enabled,
  ) {
    final now = _now();
    database.execute(
      '''INSERT INTO system_controls (control_key, value, updated_by, updated_at)
         VALUES (?, ?, ?, ?)
         ON CONFLICT(control_key) DO UPDATE SET
           value = excluded.value, updated_by = excluded.updated_by,
           updated_at = excluded.updated_at''',
      [key, enabled.toString(), user.id, now],
    );
    return {
      'key': key,
      'enabled': enabled,
      'updatedBy': user.id,
      'updatedAt': now,
    };
  }

  List<Map<String, Object?>> listAppointmentSlots(
    String doctorId,
    String date,
  ) {
    const times = ['08:00', '09:00', '10:00', '14:00', '15:00', '16:00'];
    return times.map((time) {
      final configured = database.select(
        '''SELECT * FROM appointment_slots
           WHERE doctor_id = ? AND slot_date = ? AND slot_time = ? LIMIT 1''',
        [doctorId, date, time],
      );
      final booked = database.select(
            '''SELECT COUNT(*) AS total FROM appointments
           WHERE doctor_id = ? AND substr(appointment_time, 1, 10) = ?
             AND substr(appointment_time, 12, 5) = ?
             AND status <> 'cancelled' ''',
            [doctorId, date, time],
          ).first['total'] as int? ??
          0;
      final capacity =
          configured.isEmpty ? 5 : configured.first['capacity'] as int;
      return {
        'id': configured.isEmpty
            ? 'slot-$doctorId-$date-$time'
            : configured.first['id'],
        'doctorId': doctorId,
        'date': date,
        'time': time,
        'capacity': capacity,
        'booked': booked,
        'updatedAt': configured.isEmpty ? null : configured.first['updated_at'],
      };
    }).toList(growable: false);
  }

  Map<String, Object?> updateAppointmentSlot(
    AuthUser user,
    Map<String, Object?> body,
  ) {
    final doctorId = _required(body, 'doctorId');
    final date = _required(body, 'date');
    final time = _required(body, 'time');
    final rawCapacity = body['capacity'];
    if (rawCapacity is! num || rawCapacity < 1 || rawCapacity > 50) {
      throw ApiException(400, 'capacity must be between 1 and 50');
    }
    final current = listAppointmentSlots(doctorId, date)
        .firstWhere((slot) => slot['time'] == time);
    final capacity = rawCapacity.toInt();
    if (capacity < (current['booked'] as int)) {
      throw ApiException(409, 'capacity không thể nhỏ hơn số lượt đã đặt');
    }
    final now = _now();
    final existing = database.select(
      '''SELECT id FROM appointment_slots
         WHERE doctor_id = ? AND slot_date = ? AND slot_time = ? LIMIT 1''',
      [doctorId, date, time],
    );
    final id = existing.isEmpty ? _id('slot') : existing.first['id'] as String;
    if (existing.isEmpty) {
      database.execute(
        '''INSERT INTO appointment_slots
           (id, doctor_id, slot_date, slot_time, capacity, updated_at)
           VALUES (?, ?, ?, ?, ?, ?)''',
        [id, doctorId, date, time, capacity, now],
      );
    } else {
      database.execute(
        '''UPDATE appointment_slots
           SET capacity = ?, updated_at = ? WHERE id = ?''',
        [capacity, now, id],
      );
    }
    audit(user, 'SLOT_CAPACITY_UPDATE', 'slots/$doctorId/$date/$time',
        'capacity=$capacity');
    return {
      'id': id,
      'doctorId': doctorId,
      'date': date,
      'time': time,
      'capacity': capacity,
      'booked': current['booked'],
      'updatedAt': now,
    };
  }

  Map<String, Object?> queueState([String queueId = 'main']) {
    _ensureQueueState(queueId);
    final rows = database
        .select('SELECT * FROM queue_state WHERE id = ? LIMIT 1', [queueId]);
    final row = rows.first;
    return {
      'queueId': queueId,
      'department': row['department'],
      'room': row['room'],
      'doctorName': row['doctor_name'],
      'currentNumber': row['current_number'],
      'updatedAt': row['updated_at'],
    };
  }

  void _ensureQueueState(String queueId) {
    final existing = database.select(
      'SELECT id FROM queue_state WHERE id = ? LIMIT 1',
      [queueId],
    );
    if (existing.isNotEmpty) return;
    final base = database.select(
      'SELECT * FROM queue_state WHERE id = ? LIMIT 1',
      ['main'],
    ).first;
    final doctor = database.select(
      'SELECT display_name FROM users WHERE id = ? LIMIT 1',
      [queueId],
    );
    database.execute(
      '''INSERT INTO queue_state
         (id, department, room, doctor_name, current_number, updated_at)
         VALUES (?, ?, ?, ?, 0, ?)''',
      [
        queueId,
        base['department'],
        'Phòng khám $queueId',
        doctor.isEmpty ? base['doctor_name'] : doctor.first['display_name'],
        _now(),
      ],
    );
  }

  List<Map<String, Object?>> listQueueTickets(AuthUser user) {
    final rows = user.role == 'doctor'
        ? database.select(
            '''SELECT fr.*, a.patient_id, a.doctor_id, a.reason,
                      COALESCE((SELECT display_name FROM users
                                WHERE patient_id = a.patient_id LIMIT 1), a.patient_id)
                        AS patient_name
               FROM feature_records fr
               JOIN appointments a
                 ON json_extract(fr.payload_json, '\$.appointmentId') = a.id
               WHERE fr.feature_type = 'queue_ticket'
                 AND fr.status NOT IN ('completed', 'skipped')
                 AND a.doctor_id = ?
               ORDER BY CAST(json_extract(fr.payload_json, '\$.priorityLevel') AS INTEGER) DESC,
                        CAST(json_extract(fr.payload_json, '\$.patientNumber') AS INTEGER) ASC''',
            [user.id],
          )
        : database.select(
            '''SELECT fr.*, a.patient_id, a.doctor_id, a.reason,
                      COALESCE((SELECT display_name FROM users
                                WHERE patient_id = a.patient_id LIMIT 1), a.patient_id)
                        AS patient_name
               FROM feature_records fr
               JOIN appointments a
                 ON json_extract(fr.payload_json, '\$.appointmentId') = a.id
               WHERE fr.feature_type = 'queue_ticket'
                 AND fr.status NOT IN ('completed', 'skipped')
                ORDER BY CAST(json_extract(fr.payload_json, '\$.priorityLevel') AS INTEGER) DESC,
                         CAST(json_extract(fr.payload_json, '\$.patientNumber') AS INTEGER) ASC''',
          );
    return rows.map((row) {
      final item = _featureFromRow(row);
      final payload = item['payload'] is Map
          ? Map<String, Object?>.from(item['payload'] as Map)
          : <String, Object?>{};
      payload['patientId'] = row['patient_id'];
      payload['patientName'] = row['patient_name'];
      payload['doctorId'] = row['doctor_id'];
      payload['reason'] = row['reason'];
      item['payload'] = payload;
      return item;
    }).toList(growable: false);
  }

  Map<String, Object?> callNextQueueNumber([String queueId = 'main']) {
    _ensureQueueState(queueId);
    final waitingRows = database.select(
      '''SELECT id, payload_json FROM feature_records
         WHERE feature_type = 'queue_ticket'
           AND status = 'waiting'
           AND json_extract(payload_json, '\$.queueId') = ?
          ORDER BY CAST(json_extract(payload_json, '\$.priorityLevel') AS INTEGER) DESC,
                   created_at ASC''',
      [queueId],
    );
    var queue = queueState(queueId);
    if (waitingRows.isNotEmpty) {
      final row = waitingRows.first;
      final payload = jsonDecode(row['payload_json'] as String);
      if (payload is Map) {
        final updatedPayload = Map<String, Object?>.from(payload);
        final patientNumber =
            (updatedPayload['patientNumber'] as num?)?.toInt() ??
                (queue['currentNumber'] as int) + 1;
        updatedPayload['currentNumber'] = patientNumber;
        updatedPayload['calledAt'] = _now();
        database.execute(
          '''UPDATE feature_records
             SET status = ?, payload_json = ?, updated_at = ?
             WHERE id = ?''',
          ['called', jsonEncode(updatedPayload), _now(), row['id']],
        );
        database.execute(
          'UPDATE queue_state SET current_number = ?, updated_at = ? WHERE id = ?',
          [patientNumber, _now(), queueId],
        );
        queue = queueState(queueId);
      }
    } else {
      database.execute(
        '''UPDATE queue_state
           SET current_number = current_number + 1, updated_at = ?
           WHERE id = ?''',
        [_now(), queueId],
      );
      queue = queueState(queueId);
    }
    return queue;
  }

  String storeSyncSnapshot(AuthUser user, Map<String, Object?> payload) {
    final id = _id('sync');
    database.execute(
      '''
      INSERT INTO sync_snapshots (id, user_id, payload_json, created_at)
      VALUES (?, ?, ?, ?)
      ''',
      [id, user.id, jsonEncode(payload), _now()],
    );
    return id;
  }

  void audit(AuthUser user, String action, String resource, String details) {
    database.execute(
      '''
      INSERT INTO audit_logs (
        id, actor_id, role, action, resource, details, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [_id('audit'), user.id, user.role, action, resource, details, _now()],
    );
  }

  List<Map<String, Object?>> auditLogs() {
    final rows = database
        .select('SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT 200');
    return rows.map((row) => Map<String, Object?>.from(row)).toList();
  }

  Map<String, Object?> _appointmentFromRow(Row row) => {
        'id': row['id'],
        'patientId': row['patient_id'],
        'patientName': row['patient_name'],
        'doctorId': row['doctor_id'],
        'doctorName': row['doctor_name'],
        'specialty': row['specialty'],
        'appointmentTime': row['appointment_time'],
        'reason': row['reason'],
        'packageId': row['package_id'],
        'packageTitle': row['package_title'],
        'priorityLevel': row['priority_level'] ?? 0,
        'insuranceApplied': row['insurance_applied'] == 1,
        'fee': row['fee'] ?? 0,
        'status': row['status'],
        'ticketNumber': row['ticket_number'],
        'createdAt': row['created_at'],
      };

  Map<String, Object?> _adminUserFromRow(Row row) => {
        'id': row['id'],
        'identifier': row['identifier'],
        'role': row['role'],
        'displayName': row['display_name'],
        'patientId': row['patient_id'],
        'phone': row['phone'],
        'active': (row['active'] as int? ?? 1) == 1,
      };

  Map<String, Object?> _doctorFromRow(Row row) {
    final accountId = row['account_id'] as String?;
    final accountRows = accountId == null || accountId.isEmpty
        ? const <Row>[]
        : database.select(
            'SELECT identifier FROM users WHERE id = ? LIMIT 1',
            [accountId],
          );
    return {
      'id': row['id'],
      'accountId': accountId,
      'loginIdentifier':
          accountRows.isEmpty ? null : accountRows.first['identifier'],
      'name': row['name'],
      'specialty': row['specialty'],
      'experience': row['experience'],
      'rating': row['rating'],
      'price': row['price'],
      'location': row['location'],
      'availability': row['availability'],
      'education': row['education'],
      'workingDays': row['working_days'],
      'totalPatients': row['total_patients'],
      'imageUrl': row['image_url'],
      'active': (row['active'] as int? ?? 1) == 1,
      'updatedAt': row['updated_at'],
    };
  }

  List<Map<String, Object?>> listPayments() => database
      .select('SELECT * FROM payments ORDER BY created_at DESC')
      .map(_paymentFromRow)
      .toList(growable: false);

  Map<String, Object?> _paymentFromRow(Row row) {
    final appointmentId = row['appointment_id'] as String?;
    String? packageId;
    String? packageTitle;
    if (appointmentId != null && appointmentId.isNotEmpty) {
      final appointments = database.select(
        'SELECT package_id, package_title FROM appointments WHERE id = ? LIMIT 1',
        [appointmentId],
      );
      if (appointments.isNotEmpty) {
        packageId = appointments.first['package_id'] as String?;
        packageTitle = appointments.first['package_title'] as String?;
      }
    }
    return {
      'id': row['id'],
      'patientId': row['patient_id'],
      'clientTransactionId': row['client_transaction_id'],
      'amount': row['amount'],
      'appointmentId': appointmentId,
      'packageId': packageId,
      'packageTitle': packageTitle,
      'method': row['method'],
      'status': row['status'],
      'purpose': row['purpose'] ?? 'appointment',
      'receiptCode': row['receipt_code'],
      'createdAt': row['created_at'],
    };
  }

  Map<String, Object?> _prescriptionFromRow(Row row) => {
        'id': row['id'],
        'patientId': row['patient_id'],
        'doctorId': row['doctor_id'],
        'appointmentId': row['appointment_id'],
        'diagnosis': row['diagnosis'],
        'medicines': jsonDecode(row['medicines_json'] as String),
        'signedToken': row['signed_token'],
        'createdAt': row['created_at'],
      };

  Map<String, Object?> _recordFromRow(Row row) => {
        'id': row['id'],
        'patientId': row['patient_id'],
        'doctorId': row['doctor_id'],
        'appointmentId': row['appointment_id'],
        'diagnosis': row['diagnosis'],
        'record': jsonDecode(row['record_json'] as String),
        'createdAt': row['created_at'],
      };
}

class EmailOtpService {
  EmailOtpService({
    required this.username,
    required this.password,
    required this.fromName,
  });

  EmailOtpService.disabled()
      : username = '',
        password = '',
        fromName = 'MedCare Hospital';

  final String username;
  final String password;
  final String fromName;
  final Map<String, _EmailOtpChallenge> _challenges =
      <String, _EmailOtpChallenge>{};

  bool get isConfigured => username.isNotEmpty && password.isNotEmpty;

  Future<void> send(String email, String name) async {
    if (!isConfigured) {
      throw const ApiException(
        503,
        'Email OTP chưa được cấu hình. Hãy thiết lập MEDCARE_EMAIL_USERNAME và MEDCARE_EMAIL_APP_PASSWORD.',
      );
    }

    final code = (100000 + Random.secure().nextInt(900000)).toString();
    final normalizedEmail = email.trim().toLowerCase();
    _challenges[normalizedEmail] = _EmailOtpChallenge(
      codeHash: sha256.convert(utf8.encode(code)).toString(),
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
    );

    final message = mailer.Message()
      ..from = mailer.Address(username, fromName)
      ..recipients.add(normalizedEmail)
      ..subject = 'Mã xác nhận đăng ký MedCare'
      ..text = 'Xin chào $name, mã OTP đăng ký MedCare của bạn là: $code. '
          'Mã có hiệu lực trong 10 phút. Không chia sẻ mã này với bất kỳ ai.'
      ..html = '''
        <div style="font-family:Arial,sans-serif;line-height:1.6">
          <h2 style="color:#1264d8">MedCare Hospital</h2>
          <p>Xin chào <b>${_escapeHtml(name)}</b>,</p>
          <p>Mã OTP đăng ký tài khoản của bạn là:</p>
          <p style="font-size:28px;letter-spacing:8px;font-weight:700;color:#1264d8">$code</p>
          <p>Mã có hiệu lực trong <b>10 phút</b>. Không chia sẻ mã này với bất kỳ ai.</p>
        </div>
      ''';

    try {
      await mailer.send(message, gmail(username, password),
          timeout: const Duration(seconds: 15));
    } on Object catch (error, stackTrace) {
      stderr.writeln('Email OTP send failed: $error');
      stderr.writeln(stackTrace);
      _challenges.remove(normalizedEmail);
      throw const ApiException(502, 'Không thể gửi email OTP lúc này');
    }
  }

  void verify(String email, String code) {
    final normalizedEmail = email.trim().toLowerCase();
    final challenge = _challenges[normalizedEmail];
    if (challenge == null ||
        challenge.expiresAt.isBefore(DateTime.now().toUtc())) {
      _challenges.remove(normalizedEmail);
      throw const ApiException(
          400, 'Mã email OTP đã hết hạn hoặc chưa được gửi');
    }
    if (challenge.attempts >= 5) {
      _challenges.remove(normalizedEmail);
      throw const ApiException(429, 'Bạn đã nhập sai OTP quá số lần cho phép');
    }
    challenge.attempts += 1;
    final codeHash = sha256.convert(utf8.encode(code.trim())).toString();
    if (codeHash != challenge.codeHash) {
      throw const ApiException(400, 'Mã email OTP không đúng');
    }
    _challenges.remove(normalizedEmail);
  }

  static String _escapeHtml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

class _EmailOtpChallenge {
  _EmailOtpChallenge({required this.codeHash, required this.expiresAt});

  final String codeHash;
  final DateTime expiresAt;
  int attempts = 0;
}

class SmsOtpService {
  const SmsOtpService({
    required this.accountSid,
    required this.authToken,
    required this.verifyServiceSid,
  });

  const SmsOtpService.disabled()
      : accountSid = '',
        authToken = '',
        verifyServiceSid = '';

  final String accountSid;
  final String authToken;
  final String verifyServiceSid;

  bool get isConfigured =>
      accountSid.isNotEmpty &&
      authToken.isNotEmpty &&
      verifyServiceSid.isNotEmpty;

  Future<void> send(String phone) async {
    if (!isConfigured) {
      throw const ApiException(
        503,
        'SMS OTP chưa được cấu hình trên backend. Hãy thiết lập TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN và TWILIO_VERIFY_SERVICE_SID.',
      );
    }
    await _post(
      'https://verify.twilio.com/v2/Services/$verifyServiceSid/Verifications',
      {'To': phone, 'Channel': 'sms'},
      invalidCodeMessage: 'Không thể gửi SMS OTP lúc này',
    );
  }

  Future<void> verify(String phone, String code) async {
    if (!isConfigured) {
      throw const ApiException(
        503,
        'SMS OTP chưa được cấu hình trên backend.',
      );
    }
    final response = await _post(
      'https://verify.twilio.com/v2/Services/$verifyServiceSid/VerificationCheck',
      {'To': phone, 'Code': code},
      invalidCodeMessage: 'Mã OTP không đúng hoặc đã hết hạn',
    );
    if (response['status'] != 'approved') {
      throw const ApiException(400, 'Mã OTP không đúng hoặc đã hết hạn');
    }
  }

  Future<Map<String, Object?>> _post(
    String rawUrl,
    Map<String, String> fields, {
    required String invalidCodeMessage,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.postUrl(Uri.parse(rawUrl));
      request.headers
        ..contentType = ContentType('application', 'x-www-form-urlencoded')
        ..set(
          HttpHeaders.authorizationHeader,
          'Basic ${base64.encode(utf8.encode('$accountSid:$authToken'))}',
        );
      request.write(
        fields.entries
            .map((entry) =>
                '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}')
            .join('&'),
      );
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      final decoded =
          body.trim().isEmpty ? <String, Object?>{} : jsonDecode(body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
            response.statusCode == 400 ? 400 : 502, invalidCodeMessage);
      }
      if (decoded is! Map<String, Object?>) {
        throw ApiException(502, invalidCodeMessage);
      }
      return decoded;
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(502, 'Không thể kết nối nhà cung cấp SMS: $error');
    } finally {
      client.close(force: true);
    }
  }
}

class AuthService {
  AuthService(this.db, this.secret);

  final MedicalServerDatabase db;
  final String secret;

  AuthSession login(String identifier, String password) {
    final user = db.findUserByIdentifier(identifier.trim().toLowerCase());
    if (user == null ||
        !user.active ||
        !PasswordHasher.verify(user.identifier, password, user.passwordHash)) {
      throw ApiException(
          401,
          user?.active == false
              ? 'Tài khoản đã bị khóa'
              : 'Invalid credentials');
    }
    return _issueSession(user);
  }

  AuthSession refresh(String refreshToken) {
    final user = db.userForRefreshToken(refreshToken);
    if (user == null) throw ApiException(401, 'Invalid refresh token');
    db.revokeRefreshToken(refreshToken);
    return _issueSession(user);
  }

  void revokeRefreshToken(String refreshToken) {
    db.revokeRefreshToken(refreshToken);
  }

  AuthSession issueSession(AuthUser user) => _issueSession(user);

  AuthUser verifyAccessToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw ApiException(401, 'Invalid token');
    final expected = _sign('${parts[0]}.${parts[1]}');
    if (!_constantTimeEquals(expected, parts[2])) {
      throw ApiException(401, 'Invalid token signature');
    }
    final payload = jsonDecode(utf8.decode(base64Url.decode(_pad(parts[1]))))
        as Map<String, Object?>;
    if (payload['iss'] != _issuer) throw ApiException(401, 'Invalid issuer');
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      (payload['exp'] as int) * 1000,
      isUtc: true,
    );
    if (expiresAt.isBefore(DateTime.now().toUtc())) {
      throw ApiException(401, 'Token expired');
    }
    final subject = payload['sub'] as String?;
    if (subject == null) throw ApiException(401, 'Missing subject');
    final user = db.findUserById(subject);
    if (user == null) throw ApiException(401, 'User not found');
    return user;
  }

  AuthSession _issueSession(AuthUser user) {
    final accessToken = _jwt(user, DateTime.now().toUtc().add(_accessTtl));
    final refreshToken = _secureToken();
    db.storeRefreshToken(
      refreshToken,
      user,
      DateTime.now().toUtc().add(_refreshTtl),
    );
    return AuthSession(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresInSeconds: _accessTtl.inSeconds,
    );
  }

  String _jwt(AuthUser user, DateTime expiresAt) {
    final header = _b64Json({'alg': 'HS256', 'typ': 'JWT'});
    final payload = _b64Json({
      'iss': _issuer,
      'sub': user.id,
      'role': user.role,
      'iat': DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
      'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
    });
    final unsigned = '$header.$payload';
    return '$unsigned.${_sign(unsigned)}';
  }

  String _sign(String value) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    return _b64(hmac.convert(utf8.encode(value)).bytes);
  }
}

class QueueRealtimeHub {
  final _clients = <HttpResponse>{};

  Future<void> attach(HttpRequest request, AuthUser user) async {
    request.response.headers
      ..contentType = ContentType('text', 'event-stream', charset: 'utf-8')
      ..set('Cache-Control', 'no-cache')
      ..set('Connection', 'keep-alive');
    request.response.write('event: hello\n');
    request.response.write('data: ${jsonEncode({'role': user.role})}\n\n');
    await request.response.flush();
    _clients.add(request.response);
    request.response.done.whenComplete(() => _clients.remove(request.response));
  }

  void broadcast(Map<String, Object?> queue) {
    final dead = <HttpResponse>[];
    for (final client in _clients) {
      try {
        client.write('event: queue\n');
        client.write('data: ${jsonEncode(queue)}\n\n');
        client.flush();
      } catch (_) {
        dead.add(client);
      }
    }
    _clients.removeAll(dead);
  }
}

class InfermedicaAiService {
  const InfermedicaAiService({required this.appId, required this.appKey});

  const InfermedicaAiService.disabled()
      : appId = '',
        appKey = '';

  final String appId;
  final String appKey;

  bool get isConfigured => appId.trim().isNotEmpty && appKey.trim().isNotEmpty;

  Future<String?> assess({
    required String message,
    required int? age,
    required String? sex,
  }) async {
    if (!isConfigured || age == null || age < 1 || age > 130) return null;

    final interviewId = _uuidV4();
    final parseBody = <String, Object?>{
      'text': message.length > 2048 ? message.substring(0, 2048) : message,
      'age': {'value': age},
    };
    if (sex == 'male' || sex == 'female') parseBody['sex'] = sex;

    final parsed = await _post('/parse', parseBody, interviewId);
    final mentions = parsed['mentions'];
    if (mentions is! List) return null;

    final evidence = mentions
        .whereType<Map>()
        .map((item) {
          final id = item['id']?.toString();
          if (id == null || id.isEmpty) return null;
          return <String, Object?>{
            'id': id,
            'choice_id': item['choice_id']?.toString() ?? 'present',
          };
        })
        .whereType<Map<String, Object?>>()
        .toList(growable: false);
    if (evidence.isEmpty) return null;
    evidence.first['source'] = 'initial';

    final diagnosisBody = <String, Object?>{
      'age': {'value': age},
      'evidence': evidence,
    };
    if (sex == 'male' || sex == 'female') diagnosisBody['sex'] = sex;
    final diagnosis = await _post('/diagnosis', diagnosisBody, interviewId);
    return _formatResponse(parsed, diagnosis);
  }

  Future<Map<String, Object?>> _post(
    String path,
    Map<String, Object?> body,
    String interviewId,
  ) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.postUrl(
        Uri.parse('https://api.infermedica.com/v3$path'),
      );
      request.headers
        ..contentType = ContentType.json
        ..set(HttpHeaders.acceptHeader, ContentType.json.mimeType)
        ..set('App-Id', appId)
        ..set('App-Key', appKey)
        ..set('Interview-Id', interviewId);
      request.add(utf8.encode(jsonEncode(body)));
      final response = await request.close();
      final raw = await utf8.decodeStream(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          502,
          'Infermedica API loi HTTP ${response.statusCode}: $raw',
        );
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const ApiException(502, 'Infermedica khong tra ve JSON object.');
      }
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(502, 'Khong the goi Infermedica API: $error');
    } finally {
      client.close(force: true);
    }
  }

  String _formatResponse(
    Map<String, Object?> parsed,
    Map<String, Object?> diagnosis,
  ) {
    final mentions = (parsed['mentions'] as List? ?? const [])
        .whereType<Map>()
        .map((item) =>
            item['common_name']?.toString() ?? item['name']?.toString())
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final conditions = (diagnosis['conditions'] as List? ?? const [])
        .whereType<Map>()
        .take(3)
        .map((item) {
      final name = item['name']?.toString() ?? 'Chưa xác định';
      final probability = item['probability'];
      final percent = probability is num
          ? ' (${(probability * 100).toStringAsFixed(0)}%)'
          : '';
      return '$name$percent';
    }).toList(growable: false);
    final question = (diagnosis['question'] as Map?)?['text']?.toString();
    final buffer = StringBuffer(
      'Infermedica đã phân tích các dấu hiệu: ${mentions.join(', ')}.\n\n',
    );
    if (conditions.isNotEmpty) {
      buffer.writeln('Các khả năng cần bác sĩ đánh giá thêm:');
      for (final condition in conditions) {
        buffer.writeln('• $condition');
      }
    }
    if (question != null && question.trim().isNotEmpty) {
      buffer.write('\nCâu hỏi tiếp theo: $question\n');
    }
    buffer.write(
      '\nĐây là sàng lọc hỗ trợ, không phải chẩn đoán hoặc thay thế bác sĩ. '
      'Nếu có dấu hiệu nặng, hãy gọi cấp cứu ngay.',
    );
    return buffer.toString().trim();
  }

  String _uuidV4() {
    final random = Random.secure();
    String hex(int count) => List.generate(
          count,
          (_) => random.nextInt(16).toRadixString(16),
        ).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-a${hex(3)}-${hex(12)}';
  }
}

class GeminiAiService {
  const GeminiAiService({required this.apiKey, required this.model});

  final String apiKey;
  final String model;

  bool get isConfigured => apiKey.trim().isNotEmpty;

  Future<String> chat({
    required AuthUser user,
    required String message,
    required List<Map<String, String>> history,
  }) async {
    if (!isConfigured) {
      throw const ApiException(
        503,
        'GEMINI_API_KEY hoac GOOGLE_API_KEY chua duoc cau hinh tren backend.',
      );
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
    );
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.headers.set('x-goog-api-key', apiKey);
      request.add(utf8.encode(jsonEncode(_payload(user, message, history))));

      final response = await request.close();
      final raw = await utf8.decodeStream(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          response.statusCode,
          'Gemini API loi HTTP ${response.statusCode}: $raw',
        );
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        throw const ApiException(502, 'Gemini API khong tra ve JSON object.');
      }
      final text = _extractText(decoded);
      if (text.trim().isEmpty) {
        throw const ApiException(502, 'Gemini API khong co noi dung tra loi.');
      }
      return text.trim();
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(502, 'Khong the goi Gemini API: $error');
    } finally {
      client.close(force: true);
    }
  }

  Map<String, Object?> _payload(
    AuthUser user,
    String message,
    List<Map<String, String>> history,
  ) {
    final contents = <Map<String, Object?>>[
      for (final item in history.take(8))
        {
          'role': item['role'] == 'model' ? 'model' : 'user',
          'parts': [
            {'text': item['text'] ?? ''},
          ],
        },
      {
        'role': 'user',
        'parts': [
          {'text': message},
        ],
      },
    ];

    return {
      'systemInstruction': {
        'parts': [
          {
            'text': 'Ban la tro ly chat cua ung dung benh vien MedCare. '
                'Tra loi bang tieng Viet ngan gon, than thien, co cau truc. '
                'Khong chan doan chac chan, khong thay the bac si. '
                'Neu co dau hieu cap cuu nhu dau nguc nang, kho tho nang, ngat, '
                'co giat, liet, noi kho, chay mau nhieu thi khuyen nguoi dung lien he cap cuu. '
                'Neu phu hop, goi y chuyen khoa va buoc tiep theo trong app. '
                'Vai tro nguoi dung hien tai: ${user.role}.',
          },
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.35,
        'topP': 0.9,
        'maxOutputTokens': 650,
      },
    };
  }

  String _extractText(Map<String, Object?> decoded) {
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return '';
    final first = candidates.first;
    if (first is! Map) return '';
    final content = first['content'];
    if (content is! Map) return '';
    final parts = content['parts'];
    if (parts is! List) return '';
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        buffer.write(part['text']);
      }
    }
    return buffer.toString();
  }
}

class RssNewsService {
  RssNewsService({required this.feedUrls});

  final List<Uri> feedUrls;
  List<Map<String, Object?>> _cache = const [];
  DateTime? _cacheUntil;

  Future<List<Map<String, Object?>>> latest({int limit = 12}) async {
    final now = DateTime.now().toUtc();
    if (_cacheUntil != null && _cacheUntil!.isAfter(now) && _cache.isNotEmpty) {
      return _cache.take(limit).toList(growable: false);
    }

    final items = <Map<String, Object?>>[];
    for (final feed in feedUrls) {
      try {
        items.addAll(await _fetchFeed(feed));
      } catch (error) {
        stderr.writeln('News feed failure $feed: $error');
      }
      if (items.length >= limit) break;
    }

    _cache = items.isNotEmpty ? _dedupe(items) : _fallbackArticles();
    _cacheUntil = now.add(const Duration(minutes: 15));
    return _cache.take(limit).toList(growable: false);
  }

  Future<List<Map<String, Object?>>> _fetchFeed(Uri feed) async {
    if (feed.host.contains('umc.edu.vn')) {
      return _fetchHospitalNewsPage(feed);
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(feed);
      request.headers.set(HttpHeaders.acceptHeader,
          'application/rss+xml, application/xml, text/xml');
      request.headers
          .set(HttpHeaders.userAgentHeader, 'MedCareHospitalApp/1.0');
      final response = await request.close().timeout(
            const Duration(seconds: 8),
          );
      final bytes = await response
          .fold<BytesBuilder>(
            BytesBuilder(copy: false),
            (builder, chunk) => builder..add(chunk),
          )
          .timeout(const Duration(seconds: 8));
      final raw = utf8.decode(bytes.takeBytes(), allowMalformed: true);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          response.statusCode,
          'RSS HTTP ${response.statusCode}',
        );
      }
      return _parseRss(raw, feed);
    } finally {
      client.close(force: true);
    }
  }

  List<Map<String, Object?>> _parseRss(String raw, Uri feed) {
    final blocks = RegExp(
      r'<item\b[^>]*>(.*?)</item>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(raw);
    var index = 0;
    return blocks.map((match) {
      final block = match.group(1) ?? '';
      final title = _clean(_tag(block, 'title'));
      final link = _clean(_tag(block, 'link'));
      final description = _clean(_tag(block, 'description'));
      final content = _clean(_tag(block, 'content:encoded')).isNotEmpty
          ? _clean(_tag(block, 'content:encoded'))
          : description;
      final category = _clean(_tag(block, 'category'));
      final pubDate = _formatFeedDate(_clean(_tag(block, 'pubDate')));
      final summary = description.isNotEmpty
          ? description
          : _shorten(content, maxLength: 180);
      final mediaImage = _attribute(block, 'media:content', 'url');
      final enclosureImage = _attribute(block, 'enclosure', 'url');
      index++;
      return {
        'id':
            'rss-${feed.host}-${sha256Text(link.isNotEmpty ? link : title).substring(0, 12)}-$index',
        'title': title,
        'category': category.isNotEmpty ? category : 'Tin bệnh viện',
        'author': feed.host,
        'readTime': _readTime(content),
        'summary': summary,
        'content': content.isNotEmpty ? content : summary,
        'date': pubDate,
        'sourceUrl': link,
        'sourceName': feed.host,
        'imageUrl': mediaImage.isNotEmpty
            ? mediaImage
            : (enclosureImage.isNotEmpty ? enclosureImage : null),
        'isExternal': true,
      };
    }).where((item) {
      final title = item['title'];
      return title is String && title.trim().isNotEmpty;
    }).toList(growable: false);
  }

  Future<List<Map<String, Object?>>> _fetchHospitalNewsPage(Uri page) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(page);
      request.headers
        ..set(HttpHeaders.acceptHeader, 'text/html, application/xhtml+xml')
        ..set(HttpHeaders.userAgentHeader, 'MedCareHospitalApp/1.0');
      final response =
          await request.close().timeout(const Duration(seconds: 8));
      final html = await utf8.decodeStream(response).timeout(
            const Duration(seconds: 8),
          );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          response.statusCode,
          'Hospital news HTTP ${response.statusCode}',
        );
      }
      final anchorPattern = RegExp(
        r'''<a\b[^>]*href=["']([^"']+)["'][^>]*>(.*?)</a>''',
        caseSensitive: false,
        dotAll: true,
      );
      final result = <Map<String, Object?>>[];
      for (final match in anchorPattern.allMatches(html)) {
        final title = _clean(match.group(2) ?? '');
        if (title.length < 18 || _isNavigationLabel(title)) continue;
        final href = _absoluteUrl(page, match.group(1) ?? '');
        final contextStart = max(0, match.start - 140);
        final contextEnd = min(html.length, match.end + 260);
        final context = html.substring(contextStart, contextEnd);
        final dateMatch =
            RegExp(r'\b(\d{2}/\d{2}/\d{4})\b').firstMatch(context);
        final imageMatch = RegExp(
          r'''<img\b[^>]*src=["']([^"']+)["']''',
          caseSensitive: false,
        ).firstMatch(context);
        final imageUrl = imageMatch == null
            ? null
            : _absoluteUrl(page, imageMatch.group(1) ?? '');
        result.add({
          'id':
              'umc-${sha256Text(href.isNotEmpty ? href : title).substring(0, 12)}',
          'title': title,
          'category': 'Tin bệnh viện',
          'author': 'Bệnh viện Đại học Y Dược TP. Hồ Chí Minh',
          'readTime': '3 phút đọc',
          'summary': title,
          'content': title,
          'date': dateMatch?.group(1) ?? _formatDate(DateTime.now()),
          'sourceUrl': href,
          'sourceName': 'Bệnh viện Đại học Y Dược TP. Hồ Chí Minh',
          'imageUrl': imageUrl,
          'isExternal': true,
        });
        if (result.length >= 8) break;
      }
      return result;
    } finally {
      client.close(force: true);
    }
  }

  bool _isNavigationLabel(String title) => {
        'Tất cả',
        'Xem tất cả',
        'Tin tức & Sự kiện',
        'Đảng bộ - Đoàn thể',
        'Vinh danh',
      }.contains(title);

  String _absoluteUrl(Uri base, String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) return parsed.toString();
    return base.resolve(value).toString();
  }

  List<Map<String, Object?>> _dedupe(List<Map<String, Object?>> items) {
    final seen = <String>{};
    final result = <Map<String, Object?>>[];
    for (final item in items) {
      final key = ((item['sourceUrl'] as String?)?.trim().isNotEmpty == true)
          ? item['sourceUrl'] as String
          : item['title'] as String? ?? '';
      if (key.isEmpty || !seen.add(key)) continue;
      result.add(item);
    }
    return result;
  }

  List<Map<String, Object?>> _fallbackArticles() => [
        {
          'id': 'fallback-news-01',
          'title': 'MedCare cập nhật lịch khám chuyên khoa trong tuần',
          'category': 'Tin bệnh viện',
          'author': 'MedCare Hospital',
          'readTime': '2 phút đọc',
          'summary':
              'Hệ thống đang dùng tin dự phòng khi nguồn RSS bên ngoài tạm thời không phản hồi.',
          'content':
              'MedCare khuyến nghị người bệnh đặt lịch trước, chuẩn bị thẻ BHYT và hồ sơ bệnh án cũ để quá trình tiếp nhận diễn ra nhanh hơn.',
          'date': _formatDate(DateTime.now()),
          'sourceName': 'MedCare Hospital',
          'isExternal': false,
        },
      ];

  String _tag(String block, String tag) {
    final escaped = RegExp.escape(tag);
    final match = RegExp(
      '<$escaped\\b[^>]*>(.*?)</$escaped>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(block);
    return match?.group(1) ?? '';
  }

  String _attribute(String block, String tag, String attribute) {
    final tagMatch = RegExp(
      '<${RegExp.escape(tag)}\\b[^>]*>',
      caseSensitive: false,
    ).firstMatch(block);
    if (tagMatch == null) return '';
    final value = RegExp(
      '${RegExp.escape(attribute)}=["\\\']([^"\\\']+)["\\\']',
      caseSensitive: false,
    ).firstMatch(tagMatch.group(0) ?? '');
    return value?.group(1) ?? '';
  }

  String _clean(String input) {
    var value = input
        .replaceAllMapped(
          RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true),
          (match) => match.group(1) ?? '',
        )
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    value = _decodeXml(value);
    return value;
  }

  String _decodeXml(String input) => input
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ');

  String _shorten(String input, {required int maxLength}) {
    if (input.length <= maxLength) return input;
    return '${input.substring(0, maxLength).trimRight()}...';
  }

  String _readTime(String content) {
    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final minutes = max(1, (words.length / 180).ceil());
    return '$minutes phút đọc';
  }

  String _formatFeedDate(String raw) {
    if (raw.isEmpty) return _formatDate(DateTime.now());
    try {
      return _formatDate(HttpDate.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.identifier,
    required this.passwordHash,
    required this.role,
    required this.displayName,
    this.patientId,
    this.phone,
    this.active = true,
  });

  final String id;
  final String identifier;
  final String passwordHash;
  final String role;
  final String displayName;
  final String? patientId;
  final String? phone;
  final bool active;

  factory AuthUser.fromRow(Row row) => AuthUser(
        id: row['id'] as String,
        identifier: row['identifier'] as String,
        passwordHash: row['password_hash'] as String,
        role: row['role'] as String,
        displayName: row['display_name'] as String,
        patientId: row['patient_id'] as String?,
        phone: row['phone'] as String?,
        active: (row['active'] as int? ?? 1) == 1,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'identifier': identifier,
        'role': role,
        'displayName': displayName,
        'patientId': patientId,
        'phone': phone,
        'active': active,
      };
}

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
  });

  final AuthUser user;
  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;

  Map<String, Object?> toJson() => {
        'user': user.toJson(),
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'tokenType': 'Bearer',
        'expiresIn': expiresInSeconds,
      };
}

class PasswordHasher {
  static String hash(String identifier, String password) {
    final salt = sha256Text('medcare:$identifier');
    final digest = sha256Text('$salt:$password');
    return 'sha256:$salt:$digest';
  }

  static bool verify(String identifier, String password, String storedHash) {
    return _constantTimeEquals(hash(identifier, password), storedHash);
  }
}

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;
}

Future<Map<String, Object?>> _readJson(HttpRequest request) async {
  final bytes = await request.fold<BytesBuilder>(
    BytesBuilder(copy: false),
    (builder, chunk) => builder..add(chunk),
  );
  final raw = utf8.decode(bytes.takeBytes(), allowMalformed: true);
  if (raw.trim().isEmpty) return <String, Object?>{};
  final value = jsonDecode(raw);
  if (value is! Map<String, Object?>) {
    throw ApiException(400, 'JSON object expected');
  }
  return value;
}

Future<void> _json(HttpRequest request, int statusCode, Object? payload) async {
  request.response.statusCode = statusCode;
  if (payload == null) {
    await request.response.close();
    return;
  }
  request.response.headers.contentType = ContentType.json;
  request.response.write(jsonEncode(payload));
  await request.response.close();
}

String _required(Map<String, Object?> body, String key) {
  final value = body[key];
  if (value is! String || value.trim().isEmpty) {
    throw ApiException(400, '$key is required');
  }
  return value.trim();
}

String _now() => DateTime.now().toUtc().toIso8601String();

String _dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _timeKey(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _id(String prefix) =>
    '$prefix-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(9999)}';

String _secureToken() {
  final bytes = Uint8List(32);
  final random = Random.secure();
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = random.nextInt(256);
  }
  return _b64(bytes);
}

String sha256Text(String value) =>
    sha256.convert(utf8.encode(value)).toString();

String _e164VietnamPhone(String raw) {
  final value = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
  if (RegExp(r'^0[0-9]{9,10}$').hasMatch(value)) {
    return '+84${value.substring(1)}';
  }
  if (RegExp(r'^\+84[0-9]{9,10}$').hasMatch(value)) return value;
  throw const ApiException(400, 'Số điện thoại Việt Nam không hợp lệ');
}

String _b64Json(Map<String, Object?> value) =>
    _b64(utf8.encode(jsonEncode(value)));

String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

String _pad(String value) {
  final mod = value.length % 4;
  if (mod == 0) return value;
  return value.padRight(value.length + 4 - mod, '=');
}

bool _constantTimeEquals(String a, String b) {
  final aBytes = utf8.encode(a);
  final bBytes = utf8.encode(b);
  var diff = aBytes.length ^ bBytes.length;
  final maxLength = max(aBytes.length, bBytes.length);
  for (var i = 0; i < maxLength; i++) {
    final av = i < aBytes.length ? aBytes[i] : 0;
    final bv = i < bBytes.length ? bBytes[i] : 0;
    diff |= av ^ bv;
  }
  return diff == 0;
}
