import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../bin/server.dart';

void main() {
  group('MedCare backend API', () {
    late Directory tempDir;
    late MedicalServerDatabase database;
    late HttpServer httpServer;
    late Uri baseUri;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('medcare_backend_test');
      database = MedicalServerDatabase('${tempDir.path}/test.sqlite');
      database.migrate();
      database.seed();

      final auth = AuthService(database, 'test-secret');
      final app = ApiServer(
        database,
        auth,
        QueueRealtimeHub(),
        const GeminiAiService(apiKey: '', model: 'gemini-3.8-flash'),
        RssNewsService(feedUrls: const []),
      );
      httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      httpServer.listen(app.handle);
      baseUri =
          Uri.parse('http://${httpServer.address.host}:${httpServer.port}');
    });

    tearDown(() async {
      await httpServer.close(force: true);
      database.dispose();
      await tempDir.delete(recursive: true);
    });

    test('enforces JWT auth, refresh tokens and server-side role gates',
        () async {
      final patient = await _post(baseUri, '/auth/login', {
        'identifier': 'vu@example.com',
        'password': '123456',
      });
      expect(patient.statusCode, 200);
      final patientToken = patient.json['accessToken'] as String;
      final refreshToken = patient.json['refreshToken'] as String;
      expect(patient.json['user'], containsPair('role', 'patient'));

      final me = await _get(baseUri, '/me', token: patientToken);
      expect(me.statusCode, 200);
      expect(me.json['user'], containsPair('identifier', 'vu@example.com'));

      final appointment = await _post(
        baseUri,
        '/appointments',
        {
          'doctorId': 'doctor-1',
          'doctorName': 'BS Tran Minh',
          'specialty': 'Tim mach',
          'appointmentTime': DateTime.now()
              .toUtc()
              .add(const Duration(days: 2))
              .toIso8601String(),
          'reason': 'Tai kham',
        },
        token: patientToken,
      );
      expect(appointment.statusCode, 201);
      expect(
        appointment.json['appointment'],
        containsPair('status', 'confirmed'),
      );

      final appointmentId = (appointment.json['appointment']
          as Map<String, Object?>)['id'] as String;
      final rescheduled = await _patch(
        baseUri,
        '/appointments/$appointmentId',
        {
          'appointmentTime': DateTime.now()
              .toUtc()
              .add(const Duration(days: 3))
              .toIso8601String(),
        },
        token: patientToken,
      );
      expect(rescheduled.statusCode, 200);
      expect(
        (rescheduled.json['appointment']
            as Map<String, Object?>)['appointmentTime'],
        isA<String>(),
      );

      final cancelled = await _patch(
        baseUri,
        '/appointments/$appointmentId',
        {'status': 'cancelled'},
        token: patientToken,
      );
      expect(cancelled.statusCode, 200);
      expect(
        (cancelled.json['appointment'] as Map<String, Object?>)['status'],
        'cancelled',
      );

      final payment = await _post(
        baseUri,
        '/payments/confirm',
        {
          'clientTransactionId': 'TXN-test-001',
          'amount': 250000,
          'method': 'vietQr',
        },
        token: patientToken,
      );
      expect(payment.statusCode, 200);
      expect(
        (payment.json['payment'] as Map<String, Object?>)['status'],
        'pending',
      );

      final support = await _post(
        baseUri,
        '/support/requests',
        {
          'category': 'Lịch khám',
          'message': 'Tôi cần hỗ trợ đổi khung giờ khám.',
        },
        token: patientToken,
      );
      expect(support.statusCode, 201);
      expect(
        (support.json['request'] as Map<String, Object?>)['status'],
        'open',
      );

      final denied = await _post(
        baseUri,
        '/queue/call-next',
        <String, Object?>{},
        token: patientToken,
      );
      expect(denied.statusCode, 403);

      final refreshed = await _post(baseUri, '/auth/refresh', {
        'refreshToken': refreshToken,
      });
      expect(refreshed.statusCode, 200);
      expect(refreshed.json['accessToken'], isA<String>());

      final doctor = await _post(baseUri, '/auth/login', {
        'identifier': 'doctor@medcare.vn',
        'password': '123456',
      });
      final doctorToken = doctor.json['accessToken'] as String;
      final queue = await _post(
        baseUri,
        '/queue/call-next',
        <String, Object?>{},
        token: doctorToken,
      );
      expect(queue.statusCode, 200);
      expect(
        (queue.json['queue'] as Map<String, Object?>)['currentNumber'],
        greaterThan(0),
      );

      final admin = await _post(baseUri, '/auth/login', {
        'identifier': 'admin@medcare.vn',
        'password': 'admin123',
      });
      final audit = await _get(
        baseUri,
        '/audit',
        token: admin.json['accessToken'] as String,
      );
      expect(audit.statusCode, 200);
      expect(audit.json['logs'], isNotEmpty);
    });

    test('serves public hospital news feed with fallback content', () async {
      final news = await _get(baseUri, '/news');
      expect(news.statusCode, 200);
      expect(news.json['articles'], isA<List>());
      expect(news.json['articles'], isNotEmpty);
      expect(
        (news.json['articles'] as List).first,
        containsPair('category', 'Tin bệnh viện'),
      );
    });

    test('serves the real doctor catalog, search and appointment slots',
        () async {
      final doctors = await _get(baseUri, '/doctors');
      expect(doctors.statusCode, 200);
      expect(doctors.json['count'], 20);
      final doctorList = doctors.json['doctors'] as List;
      expect(doctorList.first, containsPair('id', 'doc-01'));
      expect(doctorList.first, containsPair('specialty', 'Tim mạch'));
      expect(doctorList.first, containsPair('price', 450000));

      final filtered = await _get(
        baseUri,
        '/doctors?specialty=${Uri.encodeQueryComponent('Tim mạch')}',
      );
      expect(filtered.statusCode, 200);
      expect(filtered.json['count'], 2);
      expect(
        (filtered.json['doctors'] as List)
            .every((item) => (item as Map)['specialty'] == 'Tim mạch'),
        isTrue,
      );

      final detail = await _get(baseUri, '/doctors/doc-05');
      expect(detail.statusCode, 200);
      expect(
        (detail.json['doctor'] as Map)['name'],
        'PGS.TS.BS Nguyễn Văn An',
      );

      final slots = await _get(
        baseUri,
        '/doctors/doc-05/slots?date=2026-12-10',
      );
      expect(slots.statusCode, 200);
      expect(slots.json['slots'], hasLength(6));
      expect((slots.json['slots'] as List).first, containsPair('capacity', 5));

      final missing = await _get(baseUri, '/doctors/not-found');
      expect(missing.statusCode, 404);
    });

    test('keeps unconfigured payment pending for manual admin approval',
        () async {
      final patient = await _post(baseUri, '/auth/login', {
        'identifier': 'vu@example.com',
        'password': '123456',
      });
      final patientToken = patient.json['accessToken'] as String;
      final appointment = await _post(
        baseUri,
        '/appointments',
        {
          'doctorId': 'doc-01',
          'doctorName': 'PGS.TS.BS Trần Minh Đức',
          'specialty': 'Tim mạch',
          'appointmentTime': DateTime.now()
              .toUtc()
              .add(const Duration(days: 5))
              .toIso8601String(),
          'reason': 'Khám định kỳ',
          'packageId': 'pass-vip',
          'packageTitle': 'Gói VIP Ưu Tiên Nhanh',
          'priorityLevel': 100,
          'fee': 600000,
        },
        token: patientToken,
      );
      expect(appointment.statusCode, 201);
      final appointmentData =
          appointment.json['appointment'] as Map<String, Object?>;
      expect(appointmentData['status'], 'awaiting_payment');
      expect(appointmentData['packageId'], 'pass-vip');
      expect(appointmentData['priorityLevel'], 100);

      const transactionId = 'TXN-manual-approval-001';
      final pending = await _post(
        baseUri,
        '/payments/confirm',
        {
          'clientTransactionId': transactionId,
          'appointmentId': appointmentData['id'],
          'amount': 600000,
          'method': 'vietQr',
        },
        token: patientToken,
      );
      expect(pending.statusCode, 200);
      expect((pending.json['payment'] as Map)['status'], 'pending');

      final admin = await _post(baseUri, '/auth/login', {
        'identifier': 'admin@medcare.vn',
        'password': 'admin123',
      });
      final adminToken = admin.json['accessToken'] as String;
      final review = await _patch(
        baseUri,
        '/payments/$transactionId',
        {'status': 'success', 'receiptCode': 'RC-MANUAL-001'},
        token: adminToken,
      );
      expect(review.statusCode, 200);
      expect((review.json['payment'] as Map)['status'], 'success');
      expect((review.json['payment'] as Map)['packageTitle'],
          'Gói VIP Ưu Tiên Nhanh');

      final updatedAppointment = await _get(
        baseUri,
        '/appointments',
        token: patientToken,
      );
      expect(updatedAppointment.statusCode, 200);
      expect(
        (updatedAppointment.json['appointments'] as List).whereType<Map>().any(
            (item) =>
                item['id'] == appointmentData['id'] &&
                item['status'] == 'confirmed'),
        isTrue,
      );
    });

    test('admin manages doctors and doctors upload protected medical files',
        () async {
      final adminLogin = await _post(baseUri, '/auth/login', {
        'identifier': 'admin',
        'password': '123456',
      });
      final adminToken = adminLogin.json['accessToken'] as String;
      final created = await _post(
        baseUri,
        '/admin/doctors',
        {
          'name': 'BS Test MedCare',
          'specialty': 'Nội khoa',
          'experience': '10 năm kinh nghiệm',
          'price': 300000,
        },
        token: adminToken,
      );
      expect(created.statusCode, 201);
      final createdDoctor = created.json['doctor'] as Map<String, Object?>;
      final createdDoctorId = createdDoctor['id'] as String;
      expect(createdDoctor['name'], 'BS Test MedCare');

      final disabled = await _patch(
        baseUri,
        '/admin/doctors/$createdDoctorId',
        {'active': false},
        token: adminToken,
      );
      expect(disabled.statusCode, 200);
      expect((disabled.json['doctor'] as Map)['active'], false);
      expect(
          (await _get(baseUri, '/doctors/$createdDoctorId')).statusCode, 404);

      final patientLogin = await _post(baseUri, '/auth/login', {
        'identifier': 'vu@example.com',
        'password': '123456',
      });
      final patientToken = patientLogin.json['accessToken'] as String;
      final appointment = await _post(
        baseUri,
        '/appointments',
        {
          'doctorId': 'doctor-001',
          'doctorName': 'PGS.TS.BS Trần Minh Đức',
          'specialty': 'Tim mạch',
          'appointmentTime': '2026-12-10T09:30:00Z',
          'reason': 'Upload hồ sơ test',
        },
        token: patientToken,
      );
      final appointmentId =
          (appointment.json['appointment'] as Map)['id'] as String;
      final doctorLogin = await _post(baseUri, '/auth/login', {
        'identifier': 'doctor@medcare.vn',
        'password': '123456',
      });
      final doctorToken = doctorLogin.json['accessToken'] as String;
      final upload = await _post(
        baseUri,
        '/medical-files',
        {
          'patientId': 'MC-89241',
          'appointmentId': appointmentId,
          'category': 'X-quang',
          'findings': 'Không phát hiện bất thường trong ảnh test.',
          'fileName': 'x-quang-test.png',
          'mimeType': 'image/png',
          'dataBase64': 'aGVsbG8=',
        },
        token: doctorToken,
      );
      expect(upload.statusCode, 201);
      final file = upload.json['file'] as Map<String, Object?>;
      expect(file['sizeBytes'], 5);

      final patientFiles = await _get(
        baseUri,
        '/medical-files',
        token: patientToken,
      );
      expect(patientFiles.statusCode, 200);
      expect(patientFiles.json['files'], hasLength(1));
      final fileId = file['id'] as String;
      final content = await _get(
        baseUri,
        '/medical-files/$fileId/content',
        token: patientToken,
      );
      expect(content.statusCode, 200);
      expect(content.bodyBytes, [104, 101, 108, 108, 111]);
    });

    test('persists F15-F29 workflow records with ownership and statuses',
        () async {
      final login = await _post(baseUri, '/auth/login', {
        'identifier': 'vu@example.com',
        'password': '123456',
      });
      final token = login.json['accessToken'] as String;
      final appointment = await _post(
          baseUri,
          '/appointments',
          {
            'doctorId': 'doctor-001',
            'doctorName': 'BS Workflow',
            'specialty': 'Noi khoa',
            'appointmentTime': '2026-12-10T09:30:00Z',
            'reason': 'Check-in test',
          },
          token: token);
      final appointmentId = (appointment.json['appointment']
          as Map<String, Object?>)['id'] as String;

      final checkIn = await _post(
          baseUri,
          '/check-ins',
          {
            'appointmentId': appointmentId,
          },
          token: token);
      expect(checkIn.statusCode, 201);
      final checkInBody = checkIn.json['checkIn'] as Map<String, Object?>;
      expect(checkInBody['status'], 'issued');
      expect(checkInBody['token'], isA<String>());
      final publicCheckIn = await _get(
        baseUri,
        '/check-ins/${checkInBody['id']}',
        token: token,
      );
      expect(publicCheckIn.statusCode, 200);
      expect(
        (publicCheckIn.json['checkIn'] as Map<String, Object?>)['payload'],
        isNot(containsPair('tokenHash', anything)),
      );

      final doctorLogin = await _post(baseUri, '/auth/login', {
        'identifier': 'doctor@medcare.vn',
        'password': '123456',
      });
      final doctorToken = doctorLogin.json['accessToken'] as String;
      final verified = await _post(
        baseUri,
        '/check-ins/${checkInBody['id']}/verify',
        {'token': checkInBody['token']},
        token: doctorToken,
      );
      expect(verified.statusCode, 200);
      expect(
        (verified.json['checkIn'] as Map<String, Object?>)['status'],
        'checked_in',
      );

      final queue = await _post(
        baseUri,
        '/queues/$appointmentId/join',
        <String, Object?>{},
        token: token,
      );
      expect(queue.statusCode, 201);
      expect(
          (queue.json['queue'] as Map<String, Object?>)['status'], 'waiting');

      final reminder = await _post(
          baseUri,
          '/medication-reminders',
          {
            'prescriptionId': 'rx-test',
            'medicineId': 'med-1',
            'time': '08:00',
          },
          token: token);
      expect(reminder.statusCode, 201);
      expect((reminder.json['reminder'] as Map<String, Object?>)['status'],
          'active');

      final health = await _post(
          baseUri,
          '/health-entries',
          {
            'type': 'blood_pressure',
            'value': '120/80',
            'unit': 'mmHg',
          },
          token: token);
      expect(health.statusCode, 201);

      final feedback = await _post(
          baseUri,
          '/feedback',
          {
            'appointmentId': appointmentId,
            'rating': 5,
            'comment': 'Quy trình tốt',
          },
          token: token);
      expect(feedback.statusCode, 201);

      final documents = await _post(
          baseUri,
          '/medical-document-requests',
          {
            'documentType': 'visit_summary',
            'purpose': 'Ho so ca nhan',
          },
          token: token);
      expect(documents.statusCode, 201);

      final caregiver = await _post(
          baseUri,
          '/caregiver-invitations',
          {
            'inviteeIdentifier': 'nguoi-than@example.com',
            'permissions': ['appointments'],
          },
          token: token);
      expect(caregiver.statusCode, 201);

      final supportList = await _get(
        baseUri,
        '/support/requests',
        token: token,
      );
      expect(supportList.statusCode, 200);
      expect(supportList.json['requests'], isA<List>());

      final support = await _post(
          baseUri,
          '/support/requests',
          {
            'category': 'Hồ sơ y tế',
            'message': 'Cần giải thích kết quả xét nghiệm.',
          },
          token: token);
      final supportId =
          (support.json['request'] as Map<String, Object?>)['id'] as String;
      final supportMessage = await _post(
        baseUri,
        '/support/requests/$supportId/messages',
        {'message': 'Tôi bổ sung thêm thông tin.'},
        token: token,
      );
      expect(supportMessage.statusCode, 201);
      final supportDetail = await _get(
        baseUri,
        '/support/requests/$supportId',
        token: token,
      );
      expect(
        (supportDetail.json['request'] as Map<String, Object?>)['messages'],
        isA<List>(),
      );

      final caregiverInvite = await _post(
        baseUri,
        '/caregiver-invitations',
        {
          'inviteeIdentifier': 'caregiver@medcare.vn',
          'permissions': ['appointments'],
        },
        token: token,
      );
      final invitationId = (caregiverInvite.json['invitation']
          as Map<String, Object?>)['id'] as String;
      final caregiverLogin = await _post(baseUri, '/auth/login', {
        'identifier': 'caregiver@medcare.vn',
        'password': '123456',
      });
      final caregiverToken = caregiverLogin.json['accessToken'] as String;
      final accepted = await _post(
        baseUri,
        '/caregiver-invitations/$invitationId/accept',
        <String, Object?>{},
        token: caregiverToken,
      );
      expect(accepted.statusCode, 200);
      final permissions = await _get(
        baseUri,
        '/caregiver-permissions',
        token: caregiverToken,
      );
      expect(permissions.statusCode, 200);
      expect(permissions.json['permissions'], isNotEmpty);

      final clinicalAction = await _post(
        baseUri,
        '/clinical-actions',
        {
          'patientId': 'MC-89241',
          'action': 'PHYSICAL_EXAM',
          'payload': {'notes': 'Tim phoi trong gioi han'},
        },
        token: doctorToken,
      );
      expect(clinicalAction.statusCode, 201);
      expect(
        (clinicalAction.json['action'] as Map<String, Object?>)['action'],
        'PHYSICAL_EXAM',
      );
      final patientActions = await _get(
        baseUri,
        '/clinical-actions',
        token: token,
      );
      expect(patientActions.statusCode, 200);
      expect(patientActions.json['actions'], isNotEmpty);

      final adminLogin = await _post(baseUri, '/auth/login', {
        'identifier': 'admin',
        'password': '123456',
      });
      final adminToken = adminLogin.json['accessToken'] as String;
      final overview = await _get(
        baseUri,
        '/admin/overview',
        token: adminToken,
      );
      expect(overview.statusCode, 200);
      expect(
          overview.json['overview'], containsPair('totalClinicalActions', 1));
      final lockdown = await _post(
        baseUri,
        '/admin/lockdown',
        {'enabled': true},
        token: adminToken,
      );
      expect(lockdown.statusCode, 200);
    });
  });
}

Future<_ApiResponse> _get(Uri baseUri, String path, {String? token}) async {
  final client = HttpClient();
  try {
    final relative = Uri.parse(path);
    final request = await client.getUrl(
      baseUri.replace(path: relative.path, query: relative.query),
    );
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    return await _readResponse(await request.close());
  } finally {
    client.close(force: true);
  }
}

Future<_ApiResponse> _post(
  Uri baseUri,
  String path,
  Map<String, Object?> body, {
  String? token,
}) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(baseUri.replace(path: path));
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    request.add(utf8.encode(jsonEncode(body)));
    return await _readResponse(await request.close());
  } finally {
    client.close(force: true);
  }
}

Future<_ApiResponse> _patch(
  Uri baseUri,
  String path,
  Map<String, Object?> body, {
  String? token,
}) async {
  final client = HttpClient();
  try {
    final request = await client.patchUrl(baseUri.replace(path: path));
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    request.add(utf8.encode(jsonEncode(body)));
    return await _readResponse(await request.close());
  } finally {
    client.close(force: true);
  }
}

Future<_ApiResponse> _readResponse(HttpClientResponse response) async {
  final bodyBytes = <int>[];
  await for (final chunk in response) {
    bodyBytes.addAll(chunk);
  }
  final body = utf8.decode(bodyBytes, allowMalformed: true);
  return _ApiResponse(
    response.statusCode,
    response.headers.contentType?.mimeType == 'application/json' &&
            body.isNotEmpty
        ? jsonDecode(body) as Map<String, Object?>
        : <String, Object?>{},
    bodyBytes: bodyBytes,
  );
}

class _ApiResponse {
  const _ApiResponse(this.statusCode, this.json, {this.bodyBytes = const []});

  final int statusCode;
  final Map<String, Object?> json;
  final List<int> bodyBytes;
}
