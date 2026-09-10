import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/medical_models.dart';

class MedicalStore extends ChangeNotifier {
  MedicalStore() {
    _restore();
  }

  static const _storageKey = 'medcare.local-state.v1';
  bool _authenticated = false;
  bool _restored = false;
  bool get authenticated => _authenticated;
  bool get restored => _restored;

  PatientProfile _profile = const PatientProfile(
    id: 'MC-89241',
    name: 'Nguyễn Hoàng Vũ',
    phone: '0901 234 567',
    email: 'vu@example.com',
    dateOfBirth: '15/08/2002',
    insuranceNumber: 'DN4010123456789',
  );
  PatientProfile get profile => _profile;

  final List<DoctorProfile> doctors = const [
    DoctorProfile(
      id: 'doc-01',
      name: 'PGS.TS.BS Trần Minh Đức',
      specialty: 'Tim mạch',
      experience: 'Trưởng khoa Tim mạch • 22 năm kinh nghiệm',
      rating: 4.9,
      price: 450000,
      location: 'Phòng 402, Tòa A',
      availability: 'Đang có lịch hôm nay',
    ),
    DoctorProfile(
      id: 'doc-02',
      name: 'ThS.BS Lê Thu Trang',
      specialty: 'Nhi khoa',
      experience: 'Chuyên khoa Nhi • 14 năm kinh nghiệm',
      rating: 5.0,
      price: 350000,
      location: 'Phòng 202, Tòa A',
      availability: 'Còn 3 khung giờ',
    ),
    DoctorProfile(
      id: 'doc-03',
      name: 'BSCKII Hoàng Quốc Việt',
      specialty: 'Cơ xương khớp',
      experience: 'Chuyên khoa Xương Khớp • 18 năm kinh nghiệm',
      rating: 4.8,
      price: 400000,
      location: 'Phòng 205, Tòa C',
      availability: 'Lịch trống chiều nay',
    ),
    DoctorProfile(
      id: 'doc-04',
      name: 'TS.BS Đỗ Phương Linh',
      specialty: 'Da liễu',
      experience: 'Chuyên khoa Da liễu • 11 năm kinh nghiệm',
      rating: 4.9,
      price: 350000,
      location: 'Tầng 3, Khoa Da liễu',
      availability: 'Khám theo hẹn',
    ),
  ];

  final List<Appointment> _appointments = [];
  final List<AppNotification> _notifications = [];
  List<Appointment> get appointments => List.unmodifiable(_appointments);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) _decodeState(raw);
    } catch (_) {
      // The application stays usable when local storage is unavailable.
    } finally {
      _restored = true;
      notifyListeners();
    }
  }

  void _decodeState(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _authenticated = data['authenticated'] as bool? ?? false;
    final profile = data['profile'] as Map<String, dynamic>?;
    if (profile != null) _profile = _profileFromJson(profile);
    final appointments = data['appointments'] as List<dynamic>? ?? [];
    _appointments
      ..clear()
      ..addAll(
        appointments.whereType<Map<String, dynamic>>().map(
          _appointmentFromJson,
        ),
      );
    final notifications = data['notifications'] as List<dynamic>? ?? [];
    _notifications
      ..clear()
      ..addAll(
        notifications.whereType<Map<String, dynamic>>().map(
          _notificationFromJson,
        ),
      );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'authenticated': _authenticated,
      'profile': _profileToJson(_profile),
      'appointments': _appointments.map(_appointmentToJson).toList(),
      'notifications': _notifications.map(_notificationToJson).toList(),
    };
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  void _commit() {
    notifyListeners();
    _persist();
  }

  bool login({required String identifier, required String password}) {
    if (identifier.trim().isEmpty || password.trim().length < 6) return false;
    _authenticated = true;
    _commit();
    return true;
  }

  void register({
    required String name,
    required String phone,
    required String email,
  }) {
    _profile = _profile.copyWith(name: name, phone: phone, email: email);
    _authenticated = true;
    _commit();
  }

  void logout() {
    _authenticated = false;
    _commit();
  }

  void updateProfile({
    required String name,
    required String phone,
    required String email,
  }) {
    _profile = _profile.copyWith(name: name, phone: phone, email: email);
    _commit();
  }

  Appointment book({
    required DoctorProfile doctor,
    required DateTime dateTime,
    required String patientName,
    required String reason,
    required bool useInsurance,
  }) {
    final appointment = Appointment(
      id: 'MED-${1000 + _appointments.length}',
      doctorId: doctor.id,
      doctorName: doctor.name,
      specialty: doctor.specialty,
      location: doctor.location,
      dateTime: dateTime,
      patientName: patientName,
      reason: reason,
      insuranceApplied: useInsurance,
      status: AppointmentStatus.confirmed,
      fee: useInsurance ? (doctor.price * .2).round() : doctor.price,
    );
    _appointments.insert(0, appointment);
    _notifications.insert(
      0,
      AppNotification(
        id: 'appointment-${appointment.id}',
        title: 'Đặt lịch thành công',
        body: '${doctor.name} • ${_formatDate(dateTime)}',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    return appointment;
  }

  void cancelAppointment(String id) {
    final index = _appointments.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _appointments[index] = _appointments[index].copyWith(
      status: AppointmentStatus.cancelled,
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'cancel-$id',
        title: 'Lịch hẹn đã hủy',
        body: 'Lịch ${_appointments[index].id} đã được hủy.',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
  }

  void markNotificationRead(String id) {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _notifications[index] = _notifications[index].copyWith(read: true);
    _commit();
  }

  static Map<String, dynamic> _profileToJson(PatientProfile value) => {
    'id': value.id,
    'name': value.name,
    'phone': value.phone,
    'email': value.email,
    'dateOfBirth': value.dateOfBirth,
    'insuranceNumber': value.insuranceNumber,
  };
  static PatientProfile _profileFromJson(Map<String, dynamic> value) =>
      PatientProfile(
        id: value['id'] as String? ?? 'MC-89241',
        name: value['name'] as String? ?? '',
        phone: value['phone'] as String? ?? '',
        email: value['email'] as String? ?? '',
        dateOfBirth: value['dateOfBirth'] as String? ?? '',
        insuranceNumber: value['insuranceNumber'] as String? ?? '',
      );
  static Map<String, dynamic> _appointmentToJson(Appointment value) => {
    'id': value.id,
    'doctorId': value.doctorId,
    'doctorName': value.doctorName,
    'specialty': value.specialty,
    'location': value.location,
    'dateTime': value.dateTime.toIso8601String(),
    'patientName': value.patientName,
    'reason': value.reason,
    'insuranceApplied': value.insuranceApplied,
    'status': value.status.name,
    'fee': value.fee,
  };
  static Appointment _appointmentFromJson(Map<String, dynamic> value) =>
      Appointment(
        id: value['id'] as String,
        doctorId: value['doctorId'] as String,
        doctorName: value['doctorName'] as String,
        specialty: value['specialty'] as String,
        location: value['location'] as String,
        dateTime: DateTime.parse(value['dateTime'] as String),
        patientName: value['patientName'] as String,
        reason: value['reason'] as String,
        insuranceApplied: value['insuranceApplied'] as bool? ?? false,
        status: AppointmentStatus.values.byName(
          value['status'] as String? ?? 'confirmed',
        ),
        fee: value['fee'] as int? ?? 0,
      );
  static Map<String, dynamic> _notificationToJson(AppNotification value) => {
    'id': value.id,
    'title': value.title,
    'body': value.body,
    'createdAt': value.createdAt.toIso8601String(),
    'read': value.read,
  };
  static AppNotification _notificationFromJson(Map<String, dynamic> value) =>
      AppNotification(
        id: value['id'] as String,
        title: value['title'] as String,
        body: value['body'] as String,
        createdAt: DateTime.parse(value['createdAt'] as String),
        read: value['read'] as bool? ?? false,
      );
  static String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class MedicalScope extends InheritedNotifier<MedicalStore> {
  const MedicalScope({
    super.key,
    required MedicalStore store,
    required super.child,
  }) : super(notifier: store);
  static MedicalStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MedicalScope>();
    assert(scope != null, 'MedicalScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
