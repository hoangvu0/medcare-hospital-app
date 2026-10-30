import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/medical_models.dart';

class MedicalApiClient {
  static const _requestTimeout = Duration(seconds: 15);

  MedicalApiClient({String? baseUrl})
    : _baseUri = Uri.tryParse(baseUrl ?? AppConfig.apiBaseUrl);

  final Uri? _baseUri;

  bool get isConfigured =>
      _baseUri != null &&
      _baseUri.toString().trim().isNotEmpty &&
      (_baseUri.scheme == 'http' || _baseUri.scheme == 'https');

  Future<MedicalApiAuthSession> login({
    required String identifier,
    required String password,
  }) async {
    final body = await _postJson(_apiUri('auth/login'), {
      'identifier': identifier,
      'password': password,
    }, authRequired: false);
    return MedicalApiAuthSession.fromJson(body);
  }

  Future<void> requestRegistrationOtp({
    required String name,
    required String phone,
    required String email,
    required String password,
    String channel = 'sms',
  }) async {
    await _postJson(_apiUri('auth/register/request-otp'), {
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'channel': channel,
    }, authRequired: false);
  }

  Future<MedicalApiAuthSession> registerPatient({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String code,
    String channel = 'sms',
  }) async {
    final body = await _postJson(_apiUri('auth/register/verify-otp'), {
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'code': code,
      'channel': channel,
    }, authRequired: false);
    return MedicalApiAuthSession.fromJson(body);
  }

  Future<MedicalApiAuthSession> refresh(String refreshToken) async {
    final body = await _postJson(_apiUri('auth/refresh'), {
      'refreshToken': refreshToken,
    }, authRequired: false);
    return MedicalApiAuthSession.fromJson(body);
  }

  Future<void> logout(String refreshToken) async {
    await _postJson(_apiUri('auth/logout'), {
      'refreshToken': refreshToken,
    }, authRequired: false);
  }

  Future<Map<String, Object?>> createAppointment({
    required String doctorId,
    required String doctorName,
    required String specialty,
    required DateTime appointmentTime,
    required String reason,
    required bool insuranceApplied,
    int? fee,
    String? packageId,
    String? packageTitle,
    int? priorityLevel,
    String? bearerToken,
  }) async {
    final body = await _postJson(_apiUri('appointments'), {
      'doctorId': doctorId,
      'doctorName': doctorName,
      'specialty': specialty,
      'appointmentTime': appointmentTime.toUtc().toIso8601String(),
      'reason': reason,
      'insuranceApplied': insuranceApplied,
      ...?fee == null ? null : <String, Object?>{'fee': fee},
      ...?packageId == null ? null : <String, Object?>{'packageId': packageId},
      ...?packageTitle == null
          ? null
          : <String, Object?>{'packageTitle': packageTitle},
      ...?priorityLevel == null
          ? null
          : <String, Object?>{'priorityLevel': priorityLevel},
    }, bearerToken: bearerToken);
    final appointment = body['appointment'];
    if (appointment is! Map<String, Object?>) {
      throw const MedicalApiException(
        'API /appointments khong tra ve appointment.',
      );
    }
    return appointment;
  }

  Future<Map<String, Object?>> createDoctorFollowUp({
    required String appointmentId,
    required DateTime appointmentTime,
    required String reason,
    required String doctorName,
    required String specialty,
    String? bearerToken,
  }) async {
    final body = await _postJson(_apiUri('doctor/follow-ups'), {
      'appointmentId': appointmentId,
      'appointmentTime': appointmentTime.toUtc().toIso8601String(),
      'reason': reason,
      'doctorName': doctorName,
      'specialty': specialty,
    }, bearerToken: bearerToken);
    return _mapField(
      body,
      'appointment',
      'API tái khám không trả về appointment.',
    );
  }

  Future<List<Map<String, Object?>>> fetchAppointments({
    String? bearerToken,
  }) async {
    final body = await _getJson(
      _apiUri('appointments'),
      bearerToken: bearerToken,
    );
    final items = body['appointments'];
    if (items is! List) {
      throw const MedicalApiException(
        'API /appointments khong tra ve appointments.',
      );
    }
    return items
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList(growable: false);
  }

  Future<Map<String, Object?>> updateAppointment({
    required String id,
    String? status,
    DateTime? appointmentTime,
    String? bearerToken,
  }) async {
    final payload = <String, Object?>{};
    if (status != null) payload['status'] = status;
    if (appointmentTime != null) {
      payload['appointmentTime'] = appointmentTime.toUtc().toIso8601String();
    }
    final body = await _patchJson(
      _apiUri('appointments/$id'),
      payload,
      bearerToken: bearerToken,
    );
    final appointment = body['appointment'];
    if (appointment is! Map<String, Object?>) {
      throw const MedicalApiException(
        'API cap nhat lich hen khong tra ve appointment.',
      );
    }
    return appointment;
  }

  Future<Map<String, Object?>> completeConsultation({
    required String appointmentId,
    required String diagnosis,
    required Map<String, Object?> record,
    required List<Map<String, Object?>> medicines,
    String? bearerToken,
  }) async {
    final body = await _postJson(_apiUri('consultations/complete'), {
      'appointmentId': appointmentId,
      'diagnosis': diagnosis,
      'record': record,
      'medicines': medicines,
    }, bearerToken: bearerToken);
    return _mapField(
      body,
      'consultation',
      'API hoàn tất ca khám không trả về consultation.',
    );
  }

  Future<Map<String, Object?>> submitPaymentVerification({
    required String clientTransactionId,
    required int amount,
    required String method,
    String? appointmentId,
    String? bearerToken,
  }) async {
    final body = await _postJson(_apiUri('payments/confirm'), {
      'clientTransactionId': clientTransactionId,
      'amount': amount,
      'method': method,
      ...?appointmentId == null
          ? null
          : <String, Object?>{'appointmentId': appointmentId},
    }, bearerToken: bearerToken);
    final payment = body['payment'];
    if (payment is! Map<String, Object?>) {
      throw const MedicalApiException(
        'API xác nhận thanh toán không trả về payment.',
      );
    }
    return payment;
  }

  Future<Map<String, Object?>> fetchPaymentStatus({
    required String clientTransactionId,
    String? bearerToken,
  }) async {
    final body = await _getJson(
      _apiUri('payments/$clientTransactionId'),
      bearerToken: bearerToken,
    );
    return _mapField(
      body,
      'payment',
      'API trạng thái thanh toán không trả về payment.',
    );
  }

  Future<List<Map<String, Object?>>> fetchAdminPayments({
    String? bearerToken,
  }) async {
    final body = await _getJson(_apiUri('payments'), bearerToken: bearerToken);
    return _listField(body, 'payments');
  }

  Future<Map<String, Object?>> reviewPayment({
    required String clientTransactionId,
    required String status,
    String? receiptCode,
    String? bearerToken,
  }) async {
    final body = await _patchJson(_apiUri('payments/$clientTransactionId'), {
      'status': status,
      ...?receiptCode == null
          ? null
          : <String, Object?>{'receiptCode': receiptCode},
    }, bearerToken: bearerToken);
    return _mapField(
      body,
      'payment',
      'API duyệt thanh toán không trả về payment.',
    );
  }

  Future<Map<String, Object?>> submitSupportRequest({
    required String category,
    required String message,
    String? bearerToken,
  }) async {
    final body = await _postJson(_apiUri('support/requests'), {
      'category': category,
      'message': message,
    }, bearerToken: bearerToken);
    final request = body['request'];
    if (request is! Map<String, Object?>) {
      throw const MedicalApiException(
        'API /support/requests khong tra ve request.',
      );
    }
    return request;
  }

  Future<List<Map<String, Object?>>> fetchSupportRequests({
    String? bearerToken,
  }) async {
    final body = await _getJson(
      _apiUri('support/requests'),
      bearerToken: bearerToken,
    );
    return _listField(body, 'requests');
  }

  Future<Map<String, Object?>> updateSupportRequestStatus({
    required String requestId,
    required String status,
    String? bearerToken,
  }) async {
    final body = await _patchJson(_apiUri('support/requests/$requestId'), {
      'status': status,
    }, bearerToken: bearerToken);
    return _mapField(
      body,
      'request',
      'API cập nhật yêu cầu hỗ trợ không trả về request.',
    );
  }

  Future<Map<String, Object?>> fetchSupportRequest(
    String id, {
    String? bearerToken,
  }) async {
    final body = await _getJson(
      _apiUri('support/requests/$id'),
      bearerToken: bearerToken,
    );
    return _mapField(
      body,
      'request',
      'API /support/requests/$id khong tra ve request.',
    );
  }

  Future<Map<String, Object?>> addSupportMessage({
    required String requestId,
    required String message,
    String? bearerToken,
  }) async {
    final body = await _postJson(
      _apiUri('support/requests/$requestId/messages'),
      {'message': message},
      bearerToken: bearerToken,
    );
    return _mapField(
      body,
      'message',
      'API support message khong tra ve message.',
    );
  }

  Future<Map<String, Object?>> createCheckIn({
    required String appointmentId,
    String? receptionPointId,
    String? bearerToken,
  }) async {
    final body = await _postJson(_apiUri('check-ins'), {
      'appointmentId': appointmentId,
      ...?receptionPointId == null
          ? null
          : <String, Object?>{'receptionPointId': receptionPointId},
    }, bearerToken: bearerToken);
    return _mapField(body, 'checkIn', 'API /check-ins khong tra ve checkIn.');
  }

  Future<Map<String, Object?>> joinAppointmentQueue({
    required String appointmentId,
    String? bearerToken,
  }) async {
    final body = await _postJson(
      _apiUri('queues/$appointmentId/join'),
      <String, Object?>{},
      bearerToken: bearerToken,
    );
    return _mapField(body, 'queue', 'API queue khong tra ve queue.');
  }

  Future<Map<String, Object?>> fetchAppointmentQueue({
    required String appointmentId,
    String? bearerToken,
  }) async {
    final body = await _getJson(
      _apiUri('queues/$appointmentId'),
      bearerToken: bearerToken,
    );
    return _mapField(body, 'queue', 'API queue khong tra ve queue.');
  }

  Future<Map<String, Object?>> getFeatureRecord(
    String path, {
    String? bearerToken,
  }) async {
    final body = await _getJson(_apiUri(path), bearerToken: bearerToken);
    return body;
  }

  Future<Map<String, Object?>> createFeatureRecord(
    String path,
    Map<String, Object?> payload, {
    String? bearerToken,
  }) async {
    return _postJson(_apiUri(path), payload, bearerToken: bearerToken);
  }

  Future<Map<String, Object?>> updateFeatureRecord(
    String path,
    Map<String, Object?> payload, {
    String? bearerToken,
  }) async {
    return _patchJson(_apiUri(path), payload, bearerToken: bearerToken);
  }

  Future<void> deleteFeatureRecord(String path, {String? bearerToken}) async {
    await _deleteJson(_apiUri(path), bearerToken: bearerToken);
  }

  Future<Map<String, Object?>> callNextQueue({String? bearerToken}) async {
    final body = await _postJson(
      _apiUri('queue/call-next'),
      <String, Object?>{},
      bearerToken: bearerToken,
    );
    final queue = body['queue'];
    if (queue is! Map<String, Object?>) {
      throw const MedicalApiException('API /queue/call-next thieu queue.');
    }
    return queue;
  }

  Future<List<Map<String, Object?>>> fetchQueueTickets({
    String? bearerToken,
  }) async {
    final body = await _getJson(
      _apiUri('queue/tickets'),
      bearerToken: bearerToken,
    );
    return _listField(body, 'tickets');
  }

  Future<List<Map<String, Object?>>> fetchAdminSlots({
    required String doctorId,
    required String date,
    String? bearerToken,
  }) async {
    final uri = _apiUri('admin/slots')
        .replace(queryParameters: {'doctorId': doctorId, 'date': date});
    final body = await _getJson(uri, bearerToken: bearerToken);
    return _listField(body, 'slots');
  }

  Future<Map<String, Object?>> updateAdminSlot({
    required String doctorId,
    required String date,
    required String time,
    required int capacity,
    String? bearerToken,
  }) async {
    final body = await _patchJson(_apiUri('admin/slots'), {
      'doctorId': doctorId,
      'date': date,
      'time': time,
      'capacity': capacity,
    }, bearerToken: bearerToken);
    return _mapField(body, 'slot', 'API admin slot khong tra ve slot.');
  }

  Future<Map<String, Object?>> createMedicalRecord({
    required String patientId,
    required String diagnosis,
    required Map<String, Object?> record,
    String? appointmentId,
    String? bearerToken,
  }) async {
    final body = await _postJson(_apiUri('records'), {
      'patientId': patientId,
      'diagnosis': diagnosis,
      'record': record,
      ...?appointmentId == null
          ? null
          : <String, Object?>{'appointmentId': appointmentId},
    }, bearerToken: bearerToken);
    return _mapField(body, 'record', 'API EMR khong tra ve record.');
  }

  Future<List<Map<String, Object?>>> fetchMedicalRecords({
    String? bearerToken,
  }) async {
    final body = await _getJson(_apiUri('records'), bearerToken: bearerToken);
    return _listField(body, 'records');
  }

  Future<Map<String, Object?>> createPrescription({
    required String patientId,
    required String diagnosis,
    required List<Map<String, Object?>> medicines,
    String? appointmentId,
    String? bearerToken,
  }) async {
    final body = await _postJson(_apiUri('prescriptions'), {
      'patientId': patientId,
      'diagnosis': diagnosis,
      'medicines': medicines,
      ...?appointmentId == null
          ? null
          : <String, Object?>{'appointmentId': appointmentId},
    }, bearerToken: bearerToken);
    return _mapField(
      body,
      'prescription',
      'API don thuoc khong tra ve prescription.',
    );
  }

  Future<List<Map<String, Object?>>> fetchPrescriptions({
    String? bearerToken,
  }) async {
    final body = await _getJson(
      _apiUri('prescriptions'),
      bearerToken: bearerToken,
    );
    return _listField(body, 'prescriptions');
  }

  Future<Map<String, Object?>> createClinicalAction({
    required String patientId,
    required String action,
    required Map<String, Object?> payload,
    String? appointmentId,
    String status = 'completed',
    String? bearerToken,
  }) async {
    final body = await _postJson(_apiUri('clinical-actions'), {
      'patientId': patientId,
      'action': action,
      'status': status,
      'payload': payload,
      ...?appointmentId == null
          ? null
          : <String, Object?>{'appointmentId': appointmentId},
    }, bearerToken: bearerToken);
    return _mapField(
      body,
      'action',
      'API clinical-actions khong tra ve action.',
    );
  }

  Future<Map<String, Object?>> signEmr({
    required String patientId,
    required String appointmentId,
    required Map<String, Object?> document,
    String? bearerToken,
  }) async {
    final body = await _postJson(_apiUri('clinical-actions/sign-emr'), {
      'patientId': patientId,
      'appointmentId': appointmentId,
      'document': document,
    }, bearerToken: bearerToken);
    return _mapField(body, 'action', 'API ký EMR không trả về action.');
  }

  Future<List<Map<String, Object?>>> fetchClinicalActions({
    String? patientId,
    String? bearerToken,
  }) async {
    final uri = _apiUri('clinical-actions');
    final query = <String, String>{};
    if (patientId != null && patientId.trim().isNotEmpty) {
      query['patientId'] = patientId;
    }
    final body = await _getJson(
      query.isEmpty ? uri : uri.replace(queryParameters: query),
      bearerToken: bearerToken,
    );
    return _listField(body, 'actions');
  }

  Future<List<Map<String, Object?>>> fetchNotifications({
    String? bearerToken,
  }) async {
    final body = await _getJson(
      _apiUri('notifications'),
      bearerToken: bearerToken,
    );
    return _listField(body, 'notifications');
  }

  Future<Map<String, Object?>> markNotificationRead({
    required String id,
    String? bearerToken,
  }) async {
    final body = await _patchJson(_apiUri('notifications/$id'), {
      'read': true,
    }, bearerToken: bearerToken);
    return _mapField(
      body,
      'notification',
      'API thông báo không trả về notification.',
    );
  }

  Future<Map<String, Object?>> fetchAdminOverview({String? bearerToken}) async {
    final body = await _getJson(
      _apiUri('admin/overview'),
      bearerToken: bearerToken,
    );
    return _mapField(
      body,
      'overview',
      'API admin overview khong tra ve overview.',
    );
  }

  Future<List<Map<String, Object?>>> fetchAdminUsers({
    String? role,
    String? bearerToken,
  }) async {
    final query = <String, String>{};
    if (role != null && role.trim().isNotEmpty) query['role'] = role.trim();
    final uri = _apiUri('admin/users').replace(queryParameters: query);
    final body = await _getJson(uri, bearerToken: bearerToken);
    return _listField(body, 'users');
  }

  Future<Map<String, Object?>> updateAdminUser({
    required String id,
    bool? active,
    String? displayName,
    String? bearerToken,
  }) async {
    final body = await _patchJson(_apiUri('admin/users/$id'), {
      ...?active == null ? null : <String, Object?>{'active': active},
      ...?displayName == null
          ? null
          : <String, Object?>{'displayName': displayName},
    }, bearerToken: bearerToken);
    return _mapField(body, 'user', 'API quản lý user không trả về user.');
  }

  Future<List<Map<String, Object?>>> fetchAdminDoctors({
    String? bearerToken,
  }) async {
    final body = await _getJson(
      _apiUri('admin/doctors'),
      bearerToken: bearerToken,
    );
    return _listField(body, 'doctors');
  }

  Future<Map<String, Object?>> createAdminDoctor(
    Map<String, Object?> doctor, {
    String? bearerToken,
  }) async {
    final body = await _postJson(
      _apiUri('admin/doctors'),
      doctor,
      bearerToken: bearerToken,
    );
    return _mapField(body, 'doctor', 'API tạo bác sĩ không trả về doctor.');
  }

  Future<Map<String, Object?>> updateAdminDoctor({
    required String id,
    required Map<String, Object?> patch,
    String? bearerToken,
  }) async {
    final body = await _patchJson(
      _apiUri('admin/doctors/$id'),
      patch,
      bearerToken: bearerToken,
    );
    return _mapField(
      body,
      'doctor',
      'API cập nhật bác sĩ không trả về doctor.',
    );
  }

  Future<List<Map<String, Object?>>> fetchMedicalFiles({
    String? patientId,
    String? bearerToken,
  }) async {
    final query = patientId == null || patientId.trim().isEmpty
        ? const <String, String>{}
        : <String, String>{'patientId': patientId.trim()};
    final body = await _getJson(
      _apiUri('medical-files').replace(queryParameters: query),
      bearerToken: bearerToken,
    );
    return _listField(body, 'files');
  }

  Future<Map<String, Object?>> uploadMedicalFile({
    required String patientId,
    required String category,
    required String fileName,
    required String mimeType,
    required String dataBase64,
    String? findings,
    String? appointmentId,
    String? bearerToken,
  }) async {
    final body = await _postJson(_apiUri('medical-files'), {
      'patientId': patientId,
      'category': category,
      'fileName': fileName,
      'mimeType': mimeType,
      'dataBase64': dataBase64,
      ...?findings == null ? null : <String, Object?>{'findings': findings},
      ...?appointmentId == null
          ? null
          : <String, Object?>{'appointmentId': appointmentId},
    }, bearerToken: bearerToken);
    return _mapField(body, 'file', 'API upload hồ sơ không trả về file.');
  }

  Future<Uint8List> downloadMedicalFile({
    required String id,
    String? bearerToken,
  }) async {
    if (!isConfigured) {
      throw const MedicalApiException('Backend API chưa được cấu hình.');
    }
    final headers = _headers(bearerToken);
    try {
      final response = await http
          .get(_apiUri('medical-files/$id/content'), headers: headers)
          .timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw MedicalApiException(
          'API tải hồ sơ trả về HTTP ${response.statusCode}: ${response.body}',
        );
      }
      return response.bodyBytes;
    } on MedicalApiException {
      rethrow;
    } catch (error) {
      throw MedicalApiException('Không thể tải hồ sơ y tế: $error');
    }
  }

  Future<Map<String, Object?>> setAdminLockdown({
    required bool enabled,
    String? bearerToken,
  }) async {
    final body = await _postJson(_apiUri('admin/lockdown'), {
      'enabled': enabled,
    }, bearerToken: bearerToken);
    return _mapField(
      body,
      'control',
      'API admin lockdown khong tra ve control.',
    );
  }

  Future<List<Map<String, Object?>>> fetchAuditLogs({
    String? bearerToken,
  }) async {
    final body = await _getJson(_apiUri('audit'), bearerToken: bearerToken);
    return _listField(body, 'logs');
  }

  Stream<Map<String, Object?>> watchQueue({String? bearerToken}) async* {
    if (!isConfigured) {
      throw const MedicalApiException(
        'MEDCARE_API_BASE_URL chua duoc cau hinh hoac khong hop le.',
      );
    }

    final token = (bearerToken != null && bearerToken.trim().isNotEmpty)
        ? bearerToken.trim()
        : AppConfig.apiBearerToken.trim();
    if (token.isEmpty) {
      throw const MedicalApiException(
        'Chua co access token backend de mo realtime queue.',
      );
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', _apiUri('queue/events'))
        ..headers.addAll({
          'Accept': 'text/event-stream',
          'Authorization': 'Bearer $token',
        });
      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = await response.stream.bytesToString();
        throw MedicalApiException(
          'API /queue/events tra ve HTTP ${response.statusCode}: $body',
        );
      }

      var eventName = '';
      final data = StringBuffer();
      await for (final line
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (line.trim().isEmpty) {
          if (eventName == 'queue' && data.isNotEmpty) {
            final decoded = jsonDecode(data.toString());
            if (decoded is Map<String, Object?>) yield decoded;
          }
          eventName = '';
          data.clear();
          continue;
        }
        if (line.startsWith('event:')) {
          eventName = line.substring('event:'.length).trim();
        } else if (line.startsWith('data:')) {
          data.write(line.substring('data:'.length).trim());
        }
      }
    } finally {
      client.close();
    }
  }

  Future<void> pushSyncSnapshot(
    Map<String, Object?> payload, {
    String? bearerToken,
  }) async {
    await _postJson(_apiUri('sync'), payload, bearerToken: bearerToken);
  }

  Future<List<HealthArticle>> fetchHealthNews({String? bearerToken}) async {
    final body = await _getJson(
      _apiUri('news'),
      bearerToken: bearerToken,
      authRequired: false,
    );
    final list = body['articles'];
    if (list is! List) {
      throw const MedicalApiException('API /news khong tra ve articles.');
    }
    return list
        .whereType<Map>()
        .map(
          (item) => HealthArticle.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .where((item) => item.title.trim().isNotEmpty)
        .toList(growable: false);
  }

  /// Danh sách bác sĩ thật từ backend. API này chỉ đọc dữ liệu công khai;
  /// đặt lịch vẫn dùng access token ở endpoint /appointments.
  Future<List<Map<String, Object?>>> fetchDoctors({
    String? specialty,
    String? search,
  }) async {
    final query = <String, String>{};
    if (specialty != null && specialty.trim().isNotEmpty) {
      query['specialty'] = specialty.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final uri = _apiUri('doctors').replace(queryParameters: query);
    final body = await _getJson(uri, authRequired: false);
    return _listField(body, 'doctors');
  }

  Future<Map<String, Object?>> fetchDoctorSlots({
    required String doctorId,
    required String date,
  }) async {
    final uri = _apiUri('doctors/$doctorId/slots')
        .replace(queryParameters: {'date': date});
    return _getJson(uri, authRequired: false);
  }

  Future<String> chatWithAi({
    required String message,
    List<Map<String, String>> history = const [],
    int? age,
    String? sex,
    String? bearerToken,
  }) async {
    final payload = <String, Object?>{
      'message': message,
      'history': history
          .map(
            (item) => {
              'role': item['role'] ?? 'user',
              'text': item['text'] ?? '',
            },
          )
          .toList(),
    };
    if (age != null) payload['age'] = age;
    if (sex != null && sex.trim().isNotEmpty) payload['sex'] = sex;
    final body = await _postJson(
      _apiUri('ai/chat'),
      payload,
      bearerToken: bearerToken,
    );
    final text = body['text'];
    if (text is! String || text.trim().isEmpty) {
      throw const MedicalApiException('API /ai/chat khong tra ve text.');
    }
    return text.trim();
  }

  Future<Map<String, Object?>> _getJson(
    Uri uri, {
    String? bearerToken,
    bool authRequired = true,
  }) async {
    if (!isConfigured) {
      throw const MedicalApiException(
        'MEDCARE_API_BASE_URL chua duoc cau hinh hoac khong hop le.',
      );
    }

    final headers = _headers(bearerToken, authRequired: authRequired);
    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(_requestTimeout);
      return _decodeResponse(uri, response);
    } on MedicalApiException {
      rethrow;
    } catch (error) {
      throw MedicalApiException('Khong the ket noi backend: $error');
    }
  }

  Future<Map<String, Object?>> _postJson(
    Uri uri,
    Map<String, Object?> payload, {
    String? bearerToken,
    bool authRequired = true,
  }) async {
    if (!isConfigured) {
      throw const MedicalApiException(
        'MEDCARE_API_BASE_URL chua duoc cau hinh hoac khong hop le.',
      );
    }

    final headers = _headers(bearerToken, authRequired: authRequired)
      ..['Content-Type'] = 'application/json';
    try {
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(_requestTimeout);
      return _decodeResponse(uri, response);
    } on MedicalApiException {
      rethrow;
    } catch (error) {
      throw MedicalApiException('Khong the ket noi backend: $error');
    }
  }

  Future<Map<String, Object?>> _patchJson(
    Uri uri,
    Map<String, Object?> payload, {
    String? bearerToken,
  }) async {
    if (!isConfigured) {
      throw const MedicalApiException(
        'MEDCARE_API_BASE_URL chua duoc cau hinh hoac khong hop le.',
      );
    }

    final headers = _headers(bearerToken)
      ..['Content-Type'] = 'application/json';
    try {
      final response = await http
          .patch(uri, headers: headers, body: jsonEncode(payload))
          .timeout(_requestTimeout);
      return _decodeResponse(uri, response);
    } on MedicalApiException {
      rethrow;
    } catch (error) {
      throw MedicalApiException('Khong the ket noi backend: $error');
    }
  }

  Future<void> _deleteJson(Uri uri, {String? bearerToken}) async {
    if (!isConfigured) {
      throw const MedicalApiException(
        'MEDCARE_API_BASE_URL chua duoc cau hinh hoac khong hop le.',
      );
    }
    final headers = _headers(bearerToken);
    try {
      final response = await http
          .delete(uri, headers: headers)
          .timeout(_requestTimeout);
      _decodeResponse(uri, response);
    } on MedicalApiException {
      rethrow;
    } catch (error) {
      throw MedicalApiException('Khong the ket noi backend: $error');
    }
  }

  Map<String, String> _headers(
    String? bearerToken, {
    bool authRequired = true,
  }) {
    final headers = <String, String>{'Accept': 'application/json'};
    final token = (bearerToken != null && bearerToken.trim().isNotEmpty)
        ? bearerToken.trim()
        : AppConfig.apiBearerToken.trim();
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else if (authRequired) {
      throw const MedicalApiException(
        'Chua co access token backend de goi API bao mat.',
      );
    }
    return headers;
  }

  Map<String, Object?> _decodeResponse(Uri uri, http.Response response) {
    final body = response.body;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MedicalApiException(
        'API ${uri.path} tra ve HTTP ${response.statusCode}: $body',
      );
    }
    if (body.trim().isEmpty) return <String, Object?>{};
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) {
      throw MedicalApiException('API ${uri.path} khong tra ve JSON object.');
    }
    return decoded;
  }

  Map<String, Object?> _mapField(
    Map<String, Object?> body,
    String key,
    String error,
  ) {
    final value = body[key];
    if (value is! Map) throw MedicalApiException(error);
    return value.map((k, v) => MapEntry(k.toString(), v));
  }

  List<Map<String, Object?>> _listField(Map<String, Object?> body, String key) {
    final value = body[key];
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
        .toList(growable: false);
  }

  Uri _apiUri(String path) {
    final base = _baseUri!;
    final basePath = base.path.endsWith('/') ? base.path : '${base.path}/';
    return base.replace(path: '$basePath$path');
  }
}

class MedicalApiAuthSession {
  const MedicalApiAuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  final MedicalApiUser user;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  factory MedicalApiAuthSession.fromJson(Map<String, Object?> json) {
    final userJson = json['user'];
    if (userJson is! Map<String, Object?>) {
      throw const MedicalApiException('API login thieu thong tin user.');
    }
    return MedicalApiAuthSession(
      user: MedicalApiUser.fromJson(userJson),
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: json['expiresIn'] as int? ?? 0,
    );
  }
}

class MedicalApiUser {
  const MedicalApiUser({
    required this.id,
    required this.identifier,
    required this.role,
    required this.displayName,
    this.patientId,
    this.phone,
  });

  final String id;
  final String identifier;
  final String role;
  final String displayName;
  final String? patientId;
  final String? phone;

  factory MedicalApiUser.fromJson(Map<String, Object?> json) => MedicalApiUser(
    id: json['id'] as String? ?? '',
    identifier: json['identifier'] as String? ?? '',
    role: json['role'] as String? ?? 'patient',
    displayName: json['displayName'] as String? ?? '',
    patientId: json['patientId'] as String?,
    phone: json['phone'] as String?,
  );
}

class MedicalApiException implements Exception {
  const MedicalApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
