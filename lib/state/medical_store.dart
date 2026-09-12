import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/medical_data.dart';
import '../models/medical_models.dart';

class MedicalStore extends ChangeNotifier {
  MedicalStore() {
    _restore();
  }

  static const _storageKey = 'medcare.local-state.v2';
  bool _authenticated = false;
  bool _restored = false;
  bool get authenticated => _authenticated;
  bool get restored => _restored;

  PatientProfile _profile = MedicalData.defaultPatient;
  PatientProfile get profile => _profile;

  final List<DoctorProfile> doctors = MedicalData.initialDoctors;
  final List<MedicalRecord> medicalRecords = MedicalData.initialRecords;
  final List<LabTestItem> labTests = MedicalData.initialLabTests;
  final List<MedicineItem> medicines = MedicalData.initialMedicines;

  final List<Appointment> _appointments = List.from(MedicalData.initialAppointments);
  final List<AppNotification> _notifications = List.from(MedicalData.initialNotifications);
  final List<VitalSignRecord> _vitals = List.from(MedicalData.initialVitals);
  final List<MedicineScheduleItem> _medicineSchedule = List.from(MedicalData.initialMedicineSchedule);
  LiveQueueInfo _queueInfo = MedicalData.defaultQueue;

  final List<VaccineRecord> vaccineRecords = MedicalData.initialVaccines;
  final List<HealthPackage> healthPackages = MedicalData.initialHealthPackages;
  final List<HealthArticle> healthArticles = MedicalData.initialArticles;
  final List<PaymentTransaction> _transactions = List.from(MedicalData.initialTransactions);

  List<Appointment> get appointments => List.unmodifiable(_appointments);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<VitalSignRecord> get vitals => List.unmodifiable(_vitals);
  List<MedicineScheduleItem> get medicineSchedule => List.unmodifiable(_medicineSchedule);
  List<PaymentTransaction> get transactions => List.unmodifiable(_transactions);
  LiveQueueInfo get queueInfo => _queueInfo;

  double get medicineAdherenceRate {
    if (_medicineSchedule.isEmpty) return 1.0;
    final taken = _medicineSchedule.where((m) => m.isTaken).length;
    return taken / _medicineSchedule.length;
  }

  /// Tổng chi phí y tế thực trả trong năm [year]
  int yearlyNetSpend(int year) => _transactions
      .where((t) =>
          t.timestamp.year == year && t.status == PaymentStatus.success)
      .fold(0, (sum, t) => sum + t.netAmount);

  /// Thêm giao dịch mới (trạng thái pending) và trả về id
  PaymentTransaction addTransaction({
    required String visitCode,
    required String description,
    required int grossAmount,
    required int insuranceAmount,
    required int netAmount,
    required PaymentMethod method,
    String? walletName,
    String? invoiceEmail,
  }) {
    final tx = PaymentTransaction(
      id: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      visitCode: visitCode,
      description: description,
      grossAmount: grossAmount,
      insuranceAmount: insuranceAmount,
      netAmount: netAmount,
      method: method,
      status: PaymentStatus.pending,
      timestamp: DateTime.now(),
      walletName: walletName,
      invoiceEmail: invoiceEmail,
    );
    _transactions.insert(0, tx);
    notifyListeners();
    return tx;
  }

  /// Cập nhật trạng thái giao dịch thành công
  void completeTransaction(String txId, {String? receiptCode}) {
    final idx = _transactions.indexWhere((t) => t.id == txId);
    if (idx < 0) return;
    final old = _transactions[idx];
    _transactions[idx] = PaymentTransaction(
      id: old.id,
      visitCode: old.visitCode,
      description: old.description,
      grossAmount: old.grossAmount,
      insuranceAmount: old.insuranceAmount,
      netAmount: old.netAmount,
      method: old.method,
      status: PaymentStatus.success,
      timestamp: old.timestamp,
      walletName: old.walletName,
      invoiceEmail: old.invoiceEmail,
      receiptCode: receiptCode ?? 'RC-${DateTime.now().millisecondsSinceEpoch}',
    );
    notifyListeners();
  }

  void addVitalRecord(VitalSignRecord record) {
    _vitals.insert(0, record);
    notifyListeners();
  }

  void toggleMedicineTaken(String id) {
    final index = _medicineSchedule.indexWhere((m) => m.id == id);
    if (index < 0) return;
    final current = _medicineSchedule[index];
    final updatedTaken = !current.isTaken;
    _medicineSchedule[index] = current.copyWith(
      isTaken: updatedTaken,
      takenAt: updatedTaken ? DateTime.now() : null,
    );
    notifyListeners();
  }

  void refreshQueue() {
    // Tự động mô phỏng bước tiến của hàng đợi
    final nextCur = (_queueInfo.currentNumber < _queueInfo.patientNumber)
        ? _queueInfo.currentNumber + 1
        : _queueInfo.currentNumber;
    final remain = (_queueInfo.patientNumber - nextCur).clamp(0, 99);
    _queueInfo = LiveQueueInfo(
      department: _queueInfo.department,
      room: _queueInfo.room,
      doctorName: _queueInfo.doctorName,
      currentNumber: nextCur,
      patientNumber: _queueInfo.patientNumber,
      ticketCode: _queueInfo.ticketCode,
      estimatedMinutes: remain * 4,
    );
    notifyListeners();
  }


  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) _decodeState(raw);
    } catch (_) {
      // Keep resilient
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
    final appointments = data['appointments'] as List<dynamic>?;
    if (appointments != null && appointments.isNotEmpty) {
      _appointments
        ..clear()
        ..addAll(
          appointments.whereType<Map<String, dynamic>>().map(
            _appointmentFromJson,
          ),
        );
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, dynamic>{
        'authenticated': _authenticated,
        'profile': _profileToJson(_profile),
        'appointments': _appointments.map(_appointmentToJson).toList(),
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (_) {}
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
    String? address,
    String? allergies,
  }) {
    _profile = _profile.copyWith(
      name: name,
      phone: phone,
      email: email,
      address: address,
      allergies: allergies,
    );
    _commit();
  }

  Appointment book({
    required DoctorProfile doctor,
    required DateTime dateTime,
    required String patientName,
    required String reason,
    required bool useInsurance,
  }) {
    final ticketNum = 'KB-${1000 + _appointments.length + 1}';
    final appointment = Appointment(
      id: 'MED-${1000 + _appointments.length + 1}',
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
      ticketNumber: ticketNum,
    );
    _appointments.insert(0, appointment);
    _notifications.insert(
      0,
      AppNotification(
        id: 'appointment-${appointment.id}',
        title: 'Đặt lịch thành công',
        body: '${doctor.name} • ${_formatDate(dateTime)} (Số phiếu: $ticketNum)',
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
        body: 'Lịch khám với ${_appointments[index].doctorName} (${_appointments[index].id}) đã được hủy thành công.',
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
    'bloodType': value.bloodType,
    'gender': value.gender,
    'address': value.address,
    'allergies': value.allergies,
  };

  static PatientProfile _profileFromJson(Map<String, dynamic> json) =>
      PatientProfile(
        id: json['id'] as String? ?? 'MC-89241',
        name: json['name'] as String? ?? 'Nguyễn Hoàng Vũ',
        phone: json['phone'] as String? ?? '0901 234 567',
        email: json['email'] as String? ?? 'vu@example.com',
        dateOfBirth: json['dateOfBirth'] as String? ?? '15/08/2002',
        insuranceNumber:
            json['insuranceNumber'] as String? ?? 'DN4010123456789',
        bloodType: json['bloodType'] as String? ?? 'O+',
        gender: json['gender'] as String? ?? 'Nam',
        address: json['address'] as String? ?? 'Số 28, Phố Huế, Q. Hoàn Kiếm, Hà Nội',
        allergies: json['allergies'] as String? ?? 'Penicillin, Phấn hoa',
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
    'ticketNumber': value.ticketNumber,
  };

  static Appointment _appointmentFromJson(Map<String, dynamic> json) =>
      Appointment(
        id: json['id'] as String,
        doctorId: json['doctorId'] as String,
        doctorName: json['doctorName'] as String,
        specialty: json['specialty'] as String,
        location: json['location'] as String,
        dateTime: DateTime.parse(json['dateTime'] as String),
        patientName: json['patientName'] as String,
        reason: json['reason'] as String,
        insuranceApplied: json['insuranceApplied'] as bool? ?? false,
        status: AppointmentStatus.values.byName(
          json['status'] as String? ?? 'confirmed',
        ),
        fee: json['fee'] as int? ?? 0,
        ticketNumber: json['ticketNumber'] as String?,
      );

  String _formatDate(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ngày ${dt.day}/${dt.month}/${dt.year}';
}

class MedicalScope extends InheritedNotifier<MedicalStore> {
  const MedicalScope({
    super.key,
    required MedicalStore store,
    required super.child,
  }) : super(notifier: store);

  static MedicalStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MedicalScope>();
    assert(scope != null, 'No MedicalScope found in context');
    return scope!.notifier!;
  }
}
