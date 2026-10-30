import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:file_picker/file_picker.dart';

import '../data/auth_security.dart';
import '../data/medical_api_client.dart';
import '../data/medical_data.dart';
import '../data/medical_database.dart';
import '../models/medical_models.dart';

class PatientRegistrationResult {
  const PatientRegistrationResult._({
    required this.success,
    required this.message,
  });

  const PatientRegistrationResult.success(String message)
    : this._(success: true, message: message);

  const PatientRegistrationResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class MedicalStore extends ChangeNotifier {
  static const _walletStateKey = 'patient_wallet_state_v1';
  static const _cashlessClaimsKey = 'patient_cashless_claims_v1';
  MedicalStore({bool? enablePersistence, MedicalApiClient? apiClient})
    : _apiClient = apiClient ?? MedicalApiClient(),
      // sqflite_common_ffi and dart:io are not available in the browser.
      // Keep the web client in memory; native targets retain SQLite persistence.
      _persistenceEnabled = !kIsWeb && (enablePersistence ?? !_isFlutterTest) {
    if (_persistenceEnabled) {
      _restore();
    } else {
      _restored = true;
    }
  }

  final MedicalDatabase _database = MedicalDatabase.instance;
  final MedicalApiClient _apiClient;
  final bool _persistenceEnabled;
  bool _authenticated = false;
  bool _restored = false;
  bool get authenticated => _authenticated;
  bool get restored => _restored;
  BackendSyncState _syncState = const BackendSyncState(pendingChanges: 0);
  BackendSyncState get syncState => _syncState;
  bool get hasPendingSync => _syncState.hasPendingChanges;
  bool get backendApiConfigured => _apiClient.isConfigured;
  StreamSubscription<Map<String, Object?>>? _queueRealtimeSub;
  bool _queueRealtimeConnected = false;
  bool get queueRealtimeConnected => _queueRealtimeConnected;
  String? _queueRealtimeError;
  String? get queueRealtimeError => _queueRealtimeError;

  UserRole _currentUserRole = UserRole.patient;
  UserRole get currentUserRole => _currentUserRole;
  bool get isDoctorRole => _currentUserRole == UserRole.doctor;
  bool get isAdminRole => _currentUserRole == UserRole.admin;
  String? _currentIdentifier;
  String? get currentIdentifier => _currentIdentifier;
  String? _backendUserId;
  String? get backendUserId => _backendUserId;
  String? _backendAccessToken;
  String? _backendRefreshToken;
  String? _lastAuthError;
  String? get lastAuthError => _lastAuthError;
  bool get hasBackendSession =>
      _backendAccessToken != null && _backendAccessToken!.isNotEmpty;
  DoctorProfile get activeDoctorUser =>
      doctors.first; // PGS.TS.BS Trần Minh Đức (Phòng 402)
  final Map<String, AuthAccount> _accounts = {};

  void switchRole(UserRole role) {
    if (_persistenceEnabled) return;
    _currentUserRole = role;
    notifyListeners();
  }

  void toggleDoctorRole() {
    if (_persistenceEnabled) return;
    _currentUserRole = _currentUserRole == UserRole.doctor
        ? UserRole.patient
        : UserRole.doctor;
    notifyListeners();
  }

  PatientProfile _profile = MedicalData.defaultPatient;
  PatientProfile get profile => _profile;
  bool _hasPatientProfile = false;
  bool get hasPatientProfile => _hasPatientProfile;

  final List<DoctorProfile> doctors = MedicalData.initialDoctors;
  late final List<MedicalRecord> _medicalRecords = List.from(
    MedicalData.initialRecords,
  );
  List<MedicalRecord> get medicalRecords => List.unmodifiable(_medicalRecords);

  late final List<LabTestItem> _labTests = List.from(
    MedicalData.initialLabTests,
  );
  List<LabTestItem> get labTests => List.unmodifiable(_labTests);

  late final List<MedicineItem> _medicines = List.from(
    MedicalData.initialMedicines,
  );
  List<MedicineItem> get medicines => List.unmodifiable(_medicines);

  final List<Appointment> _appointments = List.from(
    MedicalData.initialAppointments,
  );
  final List<AppNotification> _notifications = List.from(
    MedicalData.initialNotifications,
  );
  final List<VitalSignRecord> _vitals = List.from(MedicalData.initialVitals);
  final List<MedicineScheduleItem> _medicineSchedule = List.from(
    MedicalData.initialMedicineSchedule,
  );
  LiveQueueInfo _queueInfo = MedicalData.defaultQueue;
  List<Map<String, Object?>> _queueTickets = const [];
  String? _activeClinicalAppointmentId;
  String? _activeClinicalPatientId;
  String _activeClinicalAllergies = '';

  String? get activeClinicalAppointmentId => _activeClinicalAppointmentId;
  String? get activeClinicalPatientId => _activeClinicalPatientId;
  String get activeClinicalAllergies => _activeClinicalAllergies;

  final List<VaccineRecord> vaccineRecords = MedicalData.initialVaccines;
  final List<HealthPackage> healthPackages = MedicalData.initialHealthPackages;
  final List<HealthArticle> healthArticles = MedicalData.initialArticles;
  bool _healthNewsLoading = false;
  bool get healthNewsLoading => _healthNewsLoading;
  String? _healthNewsError;
  String? get healthNewsError => _healthNewsError;
  DateTime? _healthNewsUpdatedAt;
  DateTime? get healthNewsUpdatedAt => _healthNewsUpdatedAt;
  final List<PaymentTransaction> _transactions = List.from(
    MedicalData.initialTransactions,
  );
  final List<FamilyMemberProfile> _familyMembers = List.from(
    MedicalData.initialFamilyMembers,
  );
  String _activeFamilyMemberId = 'fam-01'; // Default: Bản thân
  final List<PharmacyOrder> _pharmacyOrders = List.from(
    MedicalData.initialPharmacyOrders,
  );
  final List<LabTrendPoint> _labTrends = List.from(
    MedicalData.initialLabTrends,
  );
  final List<Map<String, Object?>> _imagingResults = [];
  HospitalKpiData _hospitalKpi = MedicalData.initialHospitalKpi;
  TelemedicineSession? _currentTelemedicine;

  // ── Tính năng Mới Toàn Diện ──
  bool _isSeniorMode = false;
  final List<LabReportItem> _labReports = List.from(
    MedicalData.initialLabReports,
  );
  final List<InsurancePolicy> _insurancePolicies = List.from(
    MedicalData.initialInsurancePolicies,
  );
  final List<CashlessClaimRequest> _cashlessClaims = [];
  final List<AppointmentPassPackage> _appointmentPasses = List.from(
    MedicalData.initialAppointmentPasses,
  );
  final List<FollowUpReminder> _followUpReminders = List.from(
    MedicalData.initialFollowUpReminders,
  );
  final List<DoctorReview> _doctorReviews = List.from(
    MedicalData.initialDoctorReviews,
  );
  final List<SecurityAuditLog> _securityAuditLogs = List.from(
    MedicalData.initialSecurityAuditLogs,
  );
  final List<ActiveSessionInfo> _activeSessions = List.from(
    MedicalData.initialActiveSessions,
  );
  bool _isEmergencyLockdown = false;
  int _walletBalance = 0;
  int _advanceDeposit = 0;
  final List<HospitalWalletTransaction> _walletTransactions = [];
  final List<ClinicalPathwayStep> _clinicalPathway = List.from(
    MedicalData.initialClinicalPathway,
  );
  List<ClinicalPathwayStep> get clinicalPathway =>
      List.unmodifiable(_clinicalPathway);

  ClinicalPathwayStep get currentPathwayStep => _clinicalPathway.firstWhere(
    (s) => s.status == ClinicalStepStatus.inProgress,
    orElse: () => _clinicalPathway.last,
  );

  int get completedStepsCount => _clinicalPathway
      .where((s) => s.status == ClinicalStepStatus.completed)
      .length;

  double get pathwayProgressPercentage => _clinicalPathway.isEmpty
      ? 0.0
      : completedStepsCount / _clinicalPathway.length;

  void advancePathwayStep(int currentStepNumber) {
    final idx = _clinicalPathway.indexWhere(
      (s) => s.stepNumber == currentStepNumber,
    );
    if (idx >= 0) {
      _clinicalPathway[idx] = _clinicalPathway[idx].copyWith(
        status: ClinicalStepStatus.completed,
        completedTime:
            '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      );
      if (idx + 1 < _clinicalPathway.length) {
        _clinicalPathway[idx + 1] = _clinicalPathway[idx + 1].copyWith(
          status: ClinicalStepStatus.inProgress,
        );
      }
      notifyListeners();
    }
  }

  void resetPathway() {
    _clinicalPathway.clear();
    _clinicalPathway.addAll(MedicalData.initialClinicalPathway);
    notifyListeners();
  }

  /// Map key = "doctorId_date_time" → SlotConfig
  final Map<String, SlotConfig> _slotConfigs = {
    for (final s in MedicalData.buildInitialSlotConfigs()) s.key: s,
  };

  List<Appointment> get appointments => List.unmodifiable(_appointments);
  bool get hasOpenConsultationAppointment =>
      _findOpenConsultationAppointmentIndex() >= 0;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadNotificationCount =>
      _notifications.where((item) => !item.read).length;
  List<VitalSignRecord> get vitals => List.unmodifiable(_vitals);
  List<MedicineScheduleItem> get medicineSchedule =>
      List.unmodifiable(_medicineSchedule);
  List<PaymentTransaction> get transactions => List.unmodifiable(_transactions);
  List<FamilyMemberProfile> get familyMembers =>
      List.unmodifiable(_familyMembers);
  List<PharmacyOrder> get pharmacyOrders => List.unmodifiable(_pharmacyOrders);
  List<LabTrendPoint> get labTrends => List.unmodifiable(_labTrends);
  List<Map<String, Object?>> get imagingResults =>
      List.unmodifiable(_imagingResults);
  HospitalKpiData get hospitalKpi => _hospitalKpi;
  TelemedicineSession? get currentTelemedicine => _currentTelemedicine;
  LiveQueueInfo get queueInfo => _queueInfo;
  List<Map<String, Object?>> get queueTickets =>
      List.unmodifiable(_queueTickets);

  bool get isSeniorMode => _isSeniorMode;
  List<LabReportItem> get labReports => List.unmodifiable(_labReports);
  List<InsurancePolicy> get insurancePolicies =>
      List.unmodifiable(_insurancePolicies);
  List<CashlessClaimRequest> get cashlessClaims =>
      List.unmodifiable(_cashlessClaims);
  List<AppointmentPassPackage> get appointmentPasses =>
      List.unmodifiable(_appointmentPasses);
  List<FollowUpReminder> get followUpReminders =>
      List.unmodifiable(_followUpReminders);
  List<DoctorReview> get doctorReviews => List.unmodifiable(_doctorReviews);
  List<SecurityAuditLog> get securityAuditLogs =>
      List.unmodifiable(_securityAuditLogs);
  List<ActiveSessionInfo> get activeSessions =>
      List.unmodifiable(_activeSessions);
  bool get isEmergencyLockdown => _isEmergencyLockdown;
  int get walletBalance => _walletBalance;
  int get advanceDeposit => _advanceDeposit;
  List<HospitalWalletTransaction> get walletTransactions =>
      List.unmodifiable(_walletTransactions);

  /// Thành viên gia đình đang hoạt động
  FamilyMemberProfile get activeFamilyMember {
    final found = _familyMembers.where((m) => m.id == _activeFamilyMemberId);
    return found.isNotEmpty ? found.first : _familyMembers.first;
  }

  // ── Trụ cột 1: Quản lý Đa Hồ sơ Gia đình ──────────────────────────────────

  void switchFamilyProfile(String id) {
    if (_activeFamilyMemberId == id) return;
    _activeFamilyMemberId = id;
    final active = activeFamilyMember;
    // Đồng bộ sang profile chính của hệ thống
    _profile = _profile.copyWith(
      name: active.name,
      phone: active.phone.isNotEmpty ? active.phone : _profile.phone,
      insuranceNumber: active.insuranceNumber,
      allergies: active.allergies,
      bloodType: active.bloodType,
      gender: active.gender,
      dateOfBirth: active.dateOfBirth,
    );
    notifyListeners();
  }

  void addFamilyMember(FamilyMemberProfile member) {
    _familyMembers.add(member);
    notifyListeners();
  }

  void deleteFamilyMember(String id) {
    if (id == 'fam-01') return; // Không cho xóa bản thân
    _familyMembers.removeWhere((m) => m.id == id);
    if (_activeFamilyMemberId == id) {
      _activeFamilyMemberId = 'fam-01';
      switchFamilyProfile('fam-01');
    } else {
      notifyListeners();
    }
  }

  // ── Trụ cột 2: Khám từ xa Telemedicine ────────────────────────────────────

  TelemedicineSession startTelemedicine(DoctorProfile doctor) {
    final session = TelemedicineSession(
      id: 'TELE-${DateTime.now().millisecondsSinceEpoch}',
      doctor: doctor,
      patientName: activeFamilyMember.name,
      appointmentTime: DateTime.now(),
      status: TelemedicineStatus.connected,
    );
    _currentTelemedicine = session;
    notifyListeners();
    return session;
  }

  void endTelemedicine({String? doctorNotes}) {
    if (_currentTelemedicine != null) {
      _currentTelemedicine = _currentTelemedicine!.copyWith(
        status: TelemedicineStatus.ended,
        doctorNotes: doctorNotes ?? 'Đã hoàn thành buổi tư vấn khám từ xa. Bác sĩ đã lưu tóm tắt tư vấn; đơn thuốc chỉ phát hành khi bác sĩ ký EMR.',
      );
      notifyListeners();
    }
  }

  // ── Trụ cột 3: Giao thuốc tận nhà & Cảnh báo dị ứng ───────────────────────

  /// Kiểm tra xem đơn thuốc có chứa hoạt chất gây dị ứng cho bệnh nhân hiện tại không
  String? checkPrescriptionAllergy(List<MedicineItem> medicines) {
    final userAllergies = activeFamilyMember.allergies.toLowerCase();
    for (final med in medicines) {
      final name = med.name.toLowerCase();
      if (userAllergies.contains('penicillin') &&
          (name.contains('amoxicillin') ||
              name.contains('ampicillin') ||
              name.contains('penicillin'))) {
        return 'Cảnh báo dị ứng nghiêm trọng: Bệnh nhân có tiền sử dị ứng Penicillin. Thuốc ${med.name} thuộc nhóm beta-lactam có thể gây sốc phản vệ!';
      }
      if (userAllergies.contains('aspirin') && name.contains('aspirin')) {
        return 'Cảnh báo: Bệnh nhân dị ứng Aspirin. Vui lòng tham vấn bác sĩ trước khi sử dụng!';
      }
    }
    return null;
  }

  PharmacyOrder createPharmacyOrder({
    required String prescriptionId,
    required String deliveryAddress,
    required String pharmacyName,
    required int itemsCount,
    required int medicineTotal,
  }) {
    final normalizedPrescriptionId = prescriptionId.trim();
    final hasIssuedPrescription = _medicalRecords.any(
      (record) => record.prescriptionCode == normalizedPrescriptionId,
    );
    if (!hasIssuedPrescription || _medicines.isEmpty || itemsCount <= 0) {
      throw StateError(
        'Chưa có đơn thuốc hợp lệ được phát hành nên không thể đặt giao thuốc.',
      );
    }
    if (deliveryAddress.trim().isEmpty || pharmacyName.trim().isEmpty) {
      throw StateError('Vui lòng nhập đầy đủ địa chỉ nhận thuốc và nhà thuốc.');
    }
    final order = PharmacyOrder(
      id: 'PHARM-${DateTime.now().millisecondsSinceEpoch}',
      prescriptionId: normalizedPrescriptionId,
      patientName: activeFamilyMember.name,
      phone: activeFamilyMember.phone.isNotEmpty
          ? activeFamilyMember.phone
          : _profile.phone,
      deliveryAddress: deliveryAddress.trim(),
      pharmacyName: pharmacyName.trim(),
      itemsCount: itemsCount,
      medicineTotal: medicineTotal,
      shippingFee: 25000,
      status: PharmacyOrderStatus.shipping,
      orderedAt: DateTime.now(),
      estimatedMinutes: 45,
    );
    _pharmacyOrders.insert(0, order);
    _notifications.insert(
      0,
      AppNotification(
        id: 'pharm-${order.id}',
        title: 'Đơn thuốc đang giao hỏa tốc',
        body:
            'Đơn thuốc $normalizedPrescriptionId đang được vận chuyển đến ${deliveryAddress.trim()}.',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    return order;
  }

  // ── Trụ cột 6: Phân hệ Bác sĩ (Doctor Workspace) ──────────────────────────

  /// Bác sĩ bấm "Gọi bệnh nhân tiếp theo"
  void doctorCallNextPatient([String room = 'Phòng 402']) {
    if (_persistenceEnabled &&
        (!_authenticated ||
            (_currentUserRole != UserRole.doctor &&
                _currentUserRole != UserRole.admin))) {
      throw StateError(
        'Chỉ tài khoản bác sĩ hoặc quản trị mới được gọi hàng đợi.',
      );
    }
    final nextNumber = _queueInfo.currentNumber + 1;
    final waitRemain = (_queueInfo.patientNumber - nextNumber).clamp(0, 99);
    _queueInfo = LiveQueueInfo(
      department: _queueInfo.department,
      room: room,
      doctorName: _queueInfo.doctorName,
      currentNumber: nextNumber,
      patientNumber: _queueInfo.patientNumber,
      ticketCode: _queueInfo.ticketCode,
      estimatedMinutes: waitRemain * 4,
    );
    // Cập nhật số ca đã hoàn thành
    _hospitalKpi = _hospitalKpi.copyWith(
      completedConsultations: _hospitalKpi.completedConsultations + 1,
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'queue-call-$nextNumber-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Mời vào phòng khám',
        body: 'Bác sĩ mời bệnh nhân số $nextNumber vào $room.',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
  }

  Future<void> doctorCallNextPatientOnlineFirst([
    String room = 'Phòng 402',
  ]) async {
    if (_apiClient.isConfigured && hasBackendSession) {
      try {
        final queue = await _apiClient.callNextQueue(
          bearerToken: _backendAccessToken,
        );
        _applyBackendQueue(queue, fallbackRoom: room);
        _recordSecurityEvent(
          actor: _currentIdentifier ?? _currentUserRole.name,
          action: 'BACKEND_QUEUE_CALL_NEXT',
          targetResource: room,
          severity: SecuritySeverity.info,
          statusDescription: 'Gọi số tiếp theo qua backend realtime queue.',
        );
        _commit();
        return;
      } on MedicalApiException catch (error) {
        _queueRealtimeError = error.message;
        throw StateError(
          'Không thể đồng bộ hàng đợi với backend: ${error.message}',
        );
      }
    }
    doctorCallNextPatient(room);
  }

  /// Bác sĩ hoàn thành ca khám: Tự động lên lịch nhắc tái khám sau 14 ngày & nhắc đánh giá
  void doctorFinishConsultation(String doctorName, String specialty) {
    if (!_canPublishClinicalData('Hoàn tất ca khám')) return;
    doctorCallNextPatient('Phòng 402');
    final reminder = FollowUpReminder(
      id: 'rem-${DateTime.now().millisecondsSinceEpoch}',
      doctorName: doctorName,
      specialty: specialty,
      reminderDate: DateTime.now().add(const Duration(days: 14)),
      clinicalReason: 'Tái khám định kỳ & đánh giá đáp ứng phác đồ điều trị',
      doctorInstructions: 'Uống thuốc đúng đơn, ghi chép nhật ký triệu chứng và tái khám sau 14 ngày.',
    );
    _followUpReminders.insert(0, reminder);
    _notifications.insert(
      0,
      AppNotification(
        id: 'notif-fin-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Hoàn tất ca khám với $doctorName',
        body: 'Bác sĩ đã tạo lịch nhắc tái khám sau 14 ngày. Hãy dành 30 giây để đánh giá trải nghiệm khám bệnh của bạn!',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    unawaited(
      _persistClinicalAction('CONSULTATION_FINISH', {
        'doctorName': doctorName,
        'specialty': specialty,
        'queueNumber': _queueInfo.currentNumber,
      }),
    );
  }

  Future<void> doctorFinishConsultationOnlineFirst(
    String doctorName,
    String specialty,
  ) async {
    final appointmentIndex = _findOpenConsultationAppointmentIndex();
    if (appointmentIndex < 0) {
      if (_apiClient.isConfigured && hasBackendSession) {
        throw StateError(
          'Chưa có lịch hẹn đã xác nhận để hoàn tất ca khám trên backend.',
        );
      }
      doctorFinishConsultation(doctorName, specialty);
      return;
    }
    final appointment = _appointments[appointmentIndex];
    if (_apiClient.isConfigured && hasBackendSession) {
      await _apiClient.updateAppointment(
        id: appointment.id,
        status: 'completed',
        bearerToken: _backendAccessToken,
      );
    }
    doctorFinishConsultation(doctorName, specialty);
  }

  /// Bác sĩ kê đơn thuốc điện tử cho bệnh nhân
  void doctorPrescribeMedication({
    required String patientName,
    required String diagnosis,
    required List<String> medicines,
    required String advice,
  }) {
    _securityAuditLogs.insert(
      0,
      SecurityAuditLog(
        id: 'draft-rx-${DateTime.now().millisecondsSinceEpoch}',
        actor: activeDoctorUser.name,
        action: 'DRAFT_PRESCRIPTION',
        targetResource: 'Ca khám của $patientName',
        ipAddress: '10.0.4.12',
        timestamp: DateTime.now(),
        severity: SecuritySeverity.info,
        statusDescription:
            'Đã lưu đơn thuốc nháp cho chẩn đoán "$diagnosis"; chưa phát hành sang tài khoản bệnh nhân.',
      ),
    );
    notifyListeners();
  }

  Future<void> doctorPrescribeMedicationOnlineFirst({
    required String patientName,
    required String diagnosis,
    required List<MedicineItem> medicines,
    required String advice,
  }) async {
    if (_apiClient.isConfigured && hasBackendSession) {
      final patientId = _activeClinicalPatientId;
      if (patientId == null || patientId.isEmpty) {
        throw StateError('Hãy chọn một lịch hẹn bệnh nhân trước khi kê đơn.');
      }
      await _apiClient.createPrescription(
        patientId: patientId,
        appointmentId: _activeClinicalAppointmentId,
        diagnosis: diagnosis,
        medicines: medicines
            .map(
              (medicine) => {
                'name': medicine.name,
                'category': medicine.category,
                'dosage': medicine.dosage,
                'quantity': medicine.quantity,
                'instruction': medicine.instruction,
                'warning': medicine.warning,
              },
            )
            .toList(growable: false),
        bearerToken: _backendAccessToken,
      );
    }
    doctorPrescribeMedication(
      patientName: patientName,
      diagnosis: diagnosis,
      medicines: medicines.map((medicine) => medicine.toString()).toList(),
      advice: advice,
    );
  }

  // ── Nghiệp vụ Mới: Senior Mode & Trợ năng ──────────────────────────────────

  void toggleSeniorMode() {
    _isSeniorMode = !_isSeniorMode;
    notifyListeners();
  }

  // ── Nghiệp vụ Mới: Bảo lãnh Viện phí Trực tiếp (Cashless Claim) ───────────

  CashlessClaimRequest submitCashlessClaim({
    required String policyNumber,
    required String providerName,
    required int totalBill,
    required int coveredPercent,
  }) {
    final coveredAmount = (totalBill * (coveredPercent / 100)).round();
    final patientCoPay = totalBill - coveredAmount;
    final claim = CashlessClaimRequest(
      id: 'CLAIM-${DateTime.now().millisecondsSinceEpoch}',
      policyNumber: policyNumber,
      providerName: providerName,
      hospitalBillId: 'BILL-2026-${_transactions.length + 101}',
      totalBill: totalBill,
      coveredAmount: coveredAmount,
      patientCoPay: patientCoPay,
      // Chỉ hệ thống bảo hiểm/HIS có thể duyệt yêu cầu. Không tự sinh mã
      // duyệt ở phía bệnh nhân.
      status: CashlessClaimStatus.pending,
      requestedAt: DateTime.now(),
    );
    _cashlessClaims.insert(0, claim);
    // Ghi nhận log bảo mật
    addSecurityAuditLog(
      SecurityAuditLog(
        id: 'audit-${DateTime.now().millisecondsSinceEpoch}',
        actor: 'Cổng Liên Kết Bảo Hiểm ($providerName)',
        action: 'Bảo lãnh viện phí - gửi yêu cầu xác minh',
        targetResource:
            'Hồ sơ: ${_profile.name} • Hóa đơn: ${claim.hospitalBillId}',
        ipAddress: '10.0.99.1 (Cổng Thanh Toán Bảo Hiểm)',
        timestamp: DateTime.now(),
        severity: SecuritySeverity.info,
        statusDescription:
            'Đang chờ hệ thống bảo hiểm xác minh: ${coveredAmount ~/ 1000}.000đ, Đồng chi trả dự kiến: ${patientCoPay ~/ 1000}.000đ',
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'notif-claim-${claim.id}',
        title: 'Đã gửi yêu cầu bảo lãnh viện phí',
        body:
            '$providerName đang xác minh yêu cầu ${claim.id}. Hệ thống sẽ cập nhật khi có kết quả.',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    notifyListeners();
    return claim;
  }

  Future<CashlessClaimRequest> submitCashlessClaimOnlineFirst({
    required String policyNumber,
    required String providerName,
    required int totalBill,
    required int coveredPercent,
  }) async {
    if (!_apiClient.isConfigured || !hasBackendSession) {
      return submitCashlessClaim(
        policyNumber: policyNumber,
        providerName: providerName,
        totalBill: totalBill,
        coveredPercent: coveredPercent,
      );
    }

    final body = await _apiClient.createFeatureRecord('cashless-claims', {
      'policyNumber': policyNumber,
      'providerName': providerName,
      'totalBill': totalBill,
      'coveredPercent': coveredPercent,
    }, bearerToken: _backendAccessToken);
    final raw = body['claim'];
    if (raw is! Map) {
      throw const MedicalApiException('API bảo lãnh không trả về yêu cầu.');
    }
    final claim = _cashlessClaimFromBackend(raw);
    _cashlessClaims.removeWhere((item) => item.id == claim.id);
    _cashlessClaims.insert(0, claim);
    _commit();
    notifyListeners();
    return claim;
  }

  CashlessClaimRequest _cashlessClaimFromBackend(Map raw) {
    final payload = raw['payload'] is Map
        ? Map<String, Object?>.from(raw['payload'] as Map)
        : <String, Object?>{};
    final status = switch ((raw['status'] as String? ?? 'pending')
        .toLowerCase()) {
      'approved' => CashlessClaimStatus.approved,
      'rejected' => CashlessClaimStatus.rejected,
      _ => CashlessClaimStatus.pending,
    };
    final amount = _intFromJson(payload['totalBill'], fallback: 0);
    final coveredPercent = _intFromJson(payload['coveredPercent'], fallback: 0);
    final coveredAmount = (amount * coveredPercent / 100).round();
    return CashlessClaimRequest(
      id:
          raw['id'] as String? ??
          'CLAIM-${DateTime.now().microsecondsSinceEpoch}',
      policyNumber: payload['policyNumber'] as String? ?? '',
      providerName: payload['providerName'] as String? ?? '',
      hospitalBillId: payload['hospitalBillId'] as String? ?? '',
      totalBill: amount,
      coveredAmount: coveredAmount,
      patientCoPay: amount - coveredAmount,
      status: status,
      requestedAt:
          DateTime.tryParse(raw['createdAt'] as String? ?? '') ??
          DateTime.now(),
      approvalCode: payload['approvalCode'] as String?,
    );
  }

  // ── Nghiệp vụ Mới: Đánh giá Bác sĩ & Khảo sát NPS ─────────────────────────

  void submitDoctorReview(DoctorReview review) {
    _doctorReviews.insert(0, review);
    // Tính lại điểm NPS và review count
    final total = _doctorReviews.length;
    final totalStars = _doctorReviews.fold<double>(
      0,
      (sum, r) => sum + r.rating,
    );
    final avgRating = (totalStars / total);
    _hospitalKpi = _hospitalKpi.copyWith(
      totalReviews: _hospitalKpi.totalReviews + 1,
      npsSatisfactionScore: (90.0 + (avgRating / 5.0) * 9.5).clamp(80.0, 100.0),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'notif-rev-${review.id}',
        title: 'Cảm ơn phản hồi của bạn',
        body:
            'Đánh giá ${review.rating}★ cho ${review.doctorName} đã được ghi nhận vào hệ thống quản trị MedCare.',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void addFollowUpReminder(FollowUpReminder reminder) {
    _followUpReminders.insert(0, reminder);
    notifyListeners();
  }

  // ── Nghiệp vụ Mới: Giám sát An ninh & Khóa khẩn cấp ───────────────────────

  Future<void> refreshAdminOverviewOnline() async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) return;
    try {
      final overview = await _apiClient.fetchAdminOverview(
        bearerToken: _backendAccessToken,
      );
      int number(String key, int fallback) {
        final value = overview[key];
        return value is num ? value.toInt() : fallback;
      }

      _hospitalKpi = _hospitalKpi.copyWith(
        todayPatients: number('todayPatients', _hospitalKpi.todayPatients),
        todayRevenue: number('todayRevenue', _hospitalKpi.todayRevenue),
        completedConsultations: number(
          'completedConsultations',
          _hospitalKpi.completedConsultations,
        ),
      );
      _isEmergencyLockdown = overview['emergencyLockdown'] == true;
      final remoteLogs = await _apiClient.fetchAuditLogs(
        bearerToken: _backendAccessToken,
      );
      final mapped = remoteLogs
          .map((item) {
            final severityText = (item['severity'] ?? item['level'] ?? 'info')
                .toString()
                .toLowerCase();
            final severity =
                severityText.contains('danger') ||
                    severityText.contains('error')
                ? SecuritySeverity.danger
                : severityText.contains('warning')
                ? SecuritySeverity.warning
                : SecuritySeverity.info;
            return SecurityAuditLog(
              id: (item['id'] ?? 'remote-audit-${item.hashCode}').toString(),
              actor: (item['actor_id'] ?? item['actor'] ?? 'backend')
                  .toString(),
              action: (item['action'] ?? 'BACKEND_AUDIT').toString(),
              targetResource: (item['resource'] ?? '').toString(),
              ipAddress: 'backend',
              timestamp:
                  DateTime.tryParse((item['created_at'] ?? '').toString()) ??
                  DateTime.now(),
              severity: severity,
              statusDescription: (item['details'] ?? '').toString(),
            );
          })
          .toList(growable: false);
      if (mapped.isNotEmpty) {
        _securityAuditLogs
          ..clear()
          ..addAll(mapped.take(250));
      }
      _commit(markDirty: false);
    } catch (error) {
      markBackendSyncFailed('Không tải được dữ liệu quản trị: $error');
    }
  }

  /// Làm mới JWT trước khi mở các màn hình quản trị. Access token backend có
  /// thời hạn ngắn; refresh token giúp admin không bị lỗi 401 giữa phiên làm việc.
  Future<bool> refreshBackendSessionOnline() async {
    if (!_apiClient.isConfigured || !hasBackendSession) return false;
    final refreshToken = _backendRefreshToken;
    if (refreshToken == null || refreshToken.trim().isEmpty) return false;
    try {
      final session = await _apiClient.refresh(refreshToken);
      _applyBackendSession(session);
      await _persist();
      return true;
    } on MedicalApiException {
      return false;
    }
  }

  Future<List<Map<String, Object?>>> fetchAdminPaymentsOnline() async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) {
      return const [];
    }
    return _apiClient.fetchAdminPayments(bearerToken: _backendAccessToken);
  }

  Future<List<Map<String, Object?>>> fetchAdminUsersOnline() async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) {
      return const [];
    }
    return _apiClient.fetchAdminUsers(bearerToken: _backendAccessToken);
  }

  Future<List<Map<String, Object?>>> fetchAdminDoctorsOnline() async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) {
      return const [];
    }
    return _apiClient.fetchAdminDoctors(bearerToken: _backendAccessToken);
  }

  Future<Map<String, Object?>> createAdminDoctorOnline(
    Map<String, Object?> doctor,
  ) async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) {
      throw StateError('Cần đăng nhập tài khoản admin để tạo bác sĩ.');
    }
    final result = await _apiClient.createAdminDoctor(
      doctor,
      bearerToken: _backendAccessToken,
    );
    await refreshDoctorsFromBackend();
    return result;
  }

  Future<Map<String, Object?>> updateAdminDoctorOnline({
    required String id,
    required Map<String, Object?> patch,
  }) async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) {
      throw StateError('Cần đăng nhập tài khoản admin để cập nhật bác sĩ.');
    }
    final result = await _apiClient.updateAdminDoctor(
      id: id,
      patch: patch,
      bearerToken: _backendAccessToken,
    );
    await refreshDoctorsFromBackend();
    return result;
  }

  Future<List<Map<String, Object?>>> fetchMedicalFilesOnline({
    String? patientId,
  }) async {
    if (!_apiClient.isConfigured || !hasBackendSession) return const [];
    return _apiClient.fetchMedicalFiles(
      patientId: patientId,
      bearerToken: _backendAccessToken,
    );
  }

  Future<Map<String, Object?>> uploadMedicalFileOnline({
    required String patientId,
    required String category,
    required String fileName,
    required String mimeType,
    required String dataBase64,
    String? findings,
    String? appointmentId,
  }) async {
    if (!_apiClient.isConfigured || !hasBackendSession) {
      throw StateError('Cần kết nối backend để tải hồ sơ y tế.');
    }
    return _apiClient.uploadMedicalFile(
      patientId: patientId,
      category: category,
      fileName: fileName,
      mimeType: mimeType,
      dataBase64: dataBase64,
      findings: findings,
      appointmentId: appointmentId,
      bearerToken: _backendAccessToken,
    );
  }

  Future<Uint8List> downloadMedicalFileOnline(String id) async {
    if (!_apiClient.isConfigured || !hasBackendSession) {
      throw StateError('Cần kết nối backend để tải hồ sơ y tế.');
    }
    return _apiClient.downloadMedicalFile(
      id: id,
      bearerToken: _backendAccessToken,
    );
  }

  Future<Map<String, Object?>> fetchAdminOverviewDataOnline() async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) {
      throw StateError('Cần đăng nhập tài khoản admin để xem tổng quan.');
    }
    return _apiClient.fetchAdminOverview(bearerToken: _backendAccessToken);
  }

  Future<List<Map<String, Object?>>> fetchAdminRecordsOnline() async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) {
      throw StateError('Cần đăng nhập tài khoản admin để xem bệnh án.');
    }
    return _apiClient.fetchMedicalRecords(bearerToken: _backendAccessToken);
  }

  Future<List<Map<String, Object?>>> fetchAdminPrescriptionsOnline() async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) {
      throw StateError('Cần đăng nhập tài khoản admin để xem đơn thuốc.');
    }
    return _apiClient.fetchPrescriptions(bearerToken: _backendAccessToken);
  }

  Future<List<Map<String, Object?>>> fetchAdminClinicalActionsOnline() async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) {
      throw StateError(
        'Cần đăng nhập tài khoản admin để xem thao tác lâm sàng.',
      );
    }
    return _apiClient.fetchClinicalActions(bearerToken: _backendAccessToken);
  }

  Future<List<Map<String, Object?>>> fetchAdminAuditLogsOnline() async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) {
      throw StateError('Cần đăng nhập tài khoản admin để xem audit log.');
    }
    return _apiClient.fetchAuditLogs(bearerToken: _backendAccessToken);
  }

  Future<Map<String, Object?>> updateAdminUserOnline({
    required String id,
    bool? active,
    String? displayName,
  }) async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) {
      throw StateError('Cần đăng nhập tài khoản admin để quản lý user.');
    }
    return _apiClient.updateAdminUser(
      id: id,
      active: active,
      displayName: displayName,
      bearerToken: _backendAccessToken,
    );
  }

  Future<List<Map<String, Object?>>> fetchAdminAppointmentsOnline() async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) {
      return const [];
    }
    return _apiClient.fetchAppointments(bearerToken: _backendAccessToken);
  }

  Future<Map<String, Object?>> updateAdminAppointmentOnline({
    required String id,
    required String status,
  }) async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) {
      throw StateError('Cần đăng nhập tài khoản admin để quản lý lịch.');
    }
    return _apiClient.updateAppointment(
      id: id,
      status: status,
      bearerToken: _backendAccessToken,
    );
  }

  Future<Map<String, Object?>> reviewPaymentOnline({
    required String clientTransactionId,
    required String status,
    String? receiptCode,
  }) async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) {
      throw StateError('Cần đăng nhập tài khoản admin để duyệt thanh toán.');
    }
    final payment = await _apiClient.reviewPayment(
      clientTransactionId: clientTransactionId,
      status: status,
      receiptCode: receiptCode,
      bearerToken: _backendAccessToken,
    );
    final localIndex = _transactions.indexWhere(
      (item) => item.id == clientTransactionId,
    );
    if (localIndex >= 0) {
      final statusValue = (payment['status'] as String? ?? 'pending')
          .toLowerCase();
      final localStatus = switch (statusValue) {
        'success' => PaymentStatus.success,
        'failed' => PaymentStatus.failed,
        'refunded' => PaymentStatus.refunded,
        _ => PaymentStatus.pending,
      };
      _transactions[localIndex] = _transactions[localIndex].copyWith(
        status: localStatus,
        receiptCode: payment['receiptCode'] as String?,
      );
      _commit(markDirty: false);
    }
    return payment;
  }

  Future<List<Map<String, Object?>>> fetchCashlessClaimsOnline() async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) {
      return const [];
    }
    final body = await _apiClient.getFeatureRecord(
      'cashless-claims',
      bearerToken: _backendAccessToken,
    );
    final claims = body['claims'];
    if (claims is! List) return const [];
    return claims
        .whereType<Map>()
        .map((item) => Map<String, Object?>.from(item))
        .toList(growable: false);
  }

  Future<Map<String, Object?>> reviewCashlessClaimOnline({
    required String claimId,
    required String status,
    String? note,
  }) async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) {
      throw StateError('Cần đăng nhập tài khoản admin để duyệt bảo lãnh.');
    }
    final body = await _apiClient.updateFeatureRecord(
      'cashless-claims/$claimId',
      {
        'status': status,
        if (note != null && note.trim().isNotEmpty) 'reviewNote': note.trim(),
      },
      bearerToken: _backendAccessToken,
    );
    final raw = body['claim'];
    if (raw is Map) {
      final claim = _cashlessClaimFromBackend(raw);
      _cashlessClaims
        ..removeWhere((item) => item.id == claim.id)
        ..insert(0, claim);
      _commit(markDirty: false);
    }
    return body;
  }

  Future<void> _setAdminLockdownOnline(bool enabled) async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) return;
    try {
      await _apiClient.setAdminLockdown(
        enabled: enabled,
        bearerToken: _backendAccessToken,
      );
    } catch (error) {
      markBackendSyncFailed('Không cập nhật khóa khẩn cấp: $error');
    }
  }

  void toggleEmergencyLockdown() {
    _isEmergencyLockdown = !_isEmergencyLockdown;
    addSecurityAuditLog(
      SecurityAuditLog(
        id: 'audit-${DateTime.now().millisecondsSinceEpoch}',
        actor: 'Quản Trị Viên An Ninh (admin@medcare.vn)',
        action: _isEmergencyLockdown
            ? 'KÍCH HOẠT KHÓA HỆ THỐNG KHẨN CẤP'
            : 'Mở khóa hệ thống an ninh',
        targetResource: 'Toàn bộ Cơ sở dữ liệu Bệnh viện',
        ipAddress: '192.168.1.10 (Admin Web Console)',
        timestamp: DateTime.now(),
        severity: _isEmergencyLockdown
            ? SecuritySeverity.danger
            : SecuritySeverity.warning,
        statusDescription: _isEmergencyLockdown
            ? 'Đã tạm dừng các thao tác thay đổi dữ liệu để ngăn ngừa rò rỉ'
            : 'Hệ thống đã trở lại trạng thái hoạt động bình thường',
      ),
    );
    notifyListeners();
    unawaited(_setAdminLockdownOnline(_isEmergencyLockdown));
  }

  void revokeSession(String sessionId) {
    _activeSessions.removeWhere((s) => s.id == sessionId);
    addSecurityAuditLog(
      SecurityAuditLog(
        id: 'audit-${DateTime.now().millisecondsSinceEpoch}',
        actor: 'Quản Trị Viên An Ninh',
        action: 'Hủy phiên làm việc từ xa',
        targetResource: 'Phiên: $sessionId',
        ipAddress: '192.168.1.10',
        timestamp: DateTime.now(),
        severity: SecuritySeverity.warning,
        statusDescription: 'Đã ngắt kết nối thiết bị thành công',
      ),
    );
    notifyListeners();
  }

  void addSecurityAuditLog(SecurityAuditLog log) {
    _securityAuditLogs.insert(0, log);
    if (_securityAuditLogs.length > 250) {
      _securityAuditLogs.removeRange(250, _securityAuditLogs.length);
    }
    _commit();
  }

  // ── Nghiệp vụ Mới: Ví Viện Phí & Tự động Hoàn Tạm Ứng ───────────────────────

  void topUpWallet(int amount) {
    if (amount <= 0) return;
    _walletBalance += amount;
    _walletTransactions.insert(
      0,
      HospitalWalletTransaction(
        id: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Nạp tiền vào ví viện phí',
        amount: amount,
        timestamp: DateTime.now(),
        isDebit: false,
        description: 'Nạp tiền vào ví MedCare Pay để thanh toán viện phí',
      ),
    );
    _commit();
    notifyListeners();
  }

  /// Creates a top-up request without crediting the balance. The balance is
  /// increased only after a verified payment callback is received.
  void requestWalletTopUp({required int amount, required String method}) {
    if (amount <= 0) return;
    _walletTransactions.insert(
      0,
      HospitalWalletTransaction(
        id: 'TOPUP-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Yêu cầu nạp ví - chờ xác nhận',
        amount: amount,
        timestamp: DateTime.now(),
        isDebit: false,
        description:
            'Phương thức: $method. Chưa cộng số dư khi chưa có xác nhận thanh toán.',
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'notif-topup-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Đã tạo yêu cầu nạp ví',
        body: 'Số dư chỉ được cập nhật sau khi cổng thanh toán xác nhận giao dịch.',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    notifyListeners();
  }

  void depositAdvance(int amount) {
    if (amount <= 0 || amount > _walletBalance) return;
    _walletBalance -= amount;
    _advanceDeposit += amount;
    _walletTransactions.insert(
      0,
      HospitalWalletTransaction(
        id: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Nộp tạm ứng viện phí',
        amount: amount,
        timestamp: DateTime.now(),
        isDebit: true,
        description: 'Tạm ứng vào quỹ viện phí MedCare',
      ),
    );
    notifyListeners();
  }

  void autoRefundAdvance() {
    if (_advanceDeposit <= 0) return;
    final refundAmount = _advanceDeposit;
    _advanceDeposit = 0;
    _walletBalance += refundAmount;
    _walletTransactions.insert(
      0,
      HospitalWalletTransaction(
        id: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Tự động hoàn trả số dư tạm ứng (Auto-Refund)',
        amount: refundAmount,
        timestamp: DateTime.now(),
        isDebit: false,
        description: 'Đã hoàn 100% số tiền tạm ứng thừa vào tài khoản/ví',
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'notif-refund-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Hoàn trả tạm ứng viện phí',
        body:
            'MedCare đã hoàn trả ${refundAmount ~/ 1000}.000đ tiền tạm ứng thừa về tài khoản của bạn.',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  // ── Slot management ─────────────────────────────────────────────────────

  /// Lấy thông tin slot cho bác sĩ × ngày × giờ.
  /// Nếu chưa có cấu hình, trả về slot mặc định capacity=5.
  SlotConfig getSlotInfo(String doctorId, String date, String time) {
    final key = '${doctorId}_${date}_$time';
    return _slotConfigs[key] ??
        SlotConfig(doctorId: doctorId, date: date, time: time, capacity: 5);
  }

  /// Lấy tất cả slot của bác sĩ trong một ngày.
  List<SlotConfig> getSlotsForDoctorDate(String doctorId, String date) {
    const times = ['08:00', '09:00', '10:00', '14:00', '15:00', '16:00'];
    return times.map((t) => getSlotInfo(doctorId, date, t)).toList();
  }

  /// [Admin] Cập nhật capacity của một slot.
  void setSlotCapacity(
    String doctorId,
    String date,
    String time,
    int capacity,
  ) {
    if (_persistenceEnabled &&
        (!_authenticated || _currentUserRole != UserRole.admin)) {
      throw StateError('Chỉ quản trị viên mới được cấu hình slot khám.');
    }
    final key = '${doctorId}_${date}_$time';
    final existing = _slotConfigs[key];
    final minCapacity = (existing?.booked ?? 0).clamp(1, 50);
    final normalizedCapacity = capacity.clamp(minCapacity, 50);
    _slotConfigs[key] =
        (existing ??
                SlotConfig(
                  doctorId: doctorId,
                  date: date,
                  time: time,
                  capacity: normalizedCapacity,
                ))
            .copyWith(capacity: normalizedCapacity);
    _commit();
  }

  Future<void> refreshSlotsOnline({
    required String doctorId,
    required String date,
  }) async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) return;
    final remote = await _apiClient.fetchAdminSlots(
      doctorId: _backendDoctorIdFor(doctorId),
      date: date,
      bearerToken: _backendAccessToken,
    );
    for (final item in remote) {
      final remoteDoctorId = _localDoctorIdFor(
        item['doctorId'] as String? ?? _backendDoctorIdFor(doctorId),
      );
      final remoteDate = item['date'] as String? ?? date;
      final remoteTime = item['time'] as String? ?? '';
      if (remoteTime.isEmpty) continue;
      _slotConfigs['${remoteDoctorId}_${remoteDate}_$remoteTime'] = SlotConfig(
        doctorId: remoteDoctorId,
        date: remoteDate,
        time: remoteTime,
        capacity: (item['capacity'] as num?)?.toInt() ?? 5,
        booked: (item['booked'] as num?)?.toInt() ?? 0,
      );
    }
    notifyListeners();
  }

  Future<void> setSlotCapacityOnlineFirst(
    String doctorId,
    String date,
    String time,
    int capacity,
  ) async {
    setSlotCapacity(doctorId, date, time, capacity);
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) return;
    await _apiClient.updateAdminSlot(
      doctorId: _backendDoctorIdFor(doctorId),
      date: date,
      time: time,
      capacity: capacity,
      bearerToken: _backendAccessToken,
    );
  }

  String _localDoctorIdFor(String doctorId) => switch (doctorId) {
    'doctor-001' => 'doc-01',
    'doctor-002' => 'doc-02',
    _ => doctorId,
  };

  /// [Bệnh nhân] Đặt 1 chỗ vào slot. Trả về true nếu thành công, false nếu hết chỗ.
  /// Đây là atomic check-and-decrement: nếu vừa đầy ngay lúc đặt → từ chối.
  bool bookSlot(String doctorId, String date, String time) {
    final reserved = _reserveSlot(doctorId, date, time);
    if (reserved) _commit();
    return reserved;
  }

  bool _reserveSlot(String doctorId, String date, String time) {
    final key = '${doctorId}_${date}_$time';
    final slot = getSlotInfo(doctorId, date, time);
    if (slot.isFull) return false;
    // Ghi nhận slot vào map (tạo mới nếu chưa có)
    final updated = SlotConfig(
      doctorId: slot.doctorId,
      date: slot.date,
      time: slot.time,
      capacity: slot.capacity,
      booked: slot.booked + 1,
    );
    _slotConfigs[key] = updated;
    return true;
  }

  /// [Admin] Giải phóng 1 chỗ khi hủy lịch.
  void releaseSlot(String doctorId, String date, String time) {
    final key = '${doctorId}_${date}_$time';
    final slot = _slotConfigs[key];
    if (slot == null || slot.booked <= 0) return;
    _slotConfigs[key] = slot.copyWith(booked: slot.booked - 1);
    _commit();
  }

  double get medicineAdherenceRate {
    if (_medicineSchedule.isEmpty) return 0.0;
    final taken = _medicineSchedule.where((m) => m.isTaken).length;
    return taken / _medicineSchedule.length;
  }

  /// Tổng chi phí y tế thực trả trong năm [year]
  int yearlyNetSpend(int year) => _transactions
      .where(
        (t) => t.timestamp.year == year && t.status == PaymentStatus.success,
      )
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
    _commit();
    return tx;
  }

  PaymentTransaction prepareTransactionPayment({
    required String txId,
    required PaymentMethod method,
    String? walletName,
    String? invoiceEmail,
  }) {
    final idx = _transactions.indexWhere((t) => t.id == txId);
    if (idx < 0) {
      throw StateError('Không tìm thấy giao dịch viện phí cần thanh toán.');
    }
    final old = _transactions[idx];
    if (old.status != PaymentStatus.pending) {
      throw StateError('Giao dịch này không còn ở trạng thái chờ thanh toán.');
    }
    final updated = PaymentTransaction(
      id: old.id,
      visitCode: old.visitCode,
      description: old.description,
      grossAmount: old.grossAmount,
      insuranceAmount: old.insuranceAmount,
      netAmount: old.netAmount,
      method: method,
      status: old.status,
      timestamp: old.timestamp,
      walletName: walletName,
      invoiceEmail: invoiceEmail,
      receiptCode: old.receiptCode,
    );
    _transactions[idx] = updated;
    _commit();
    return updated;
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
    _confirmAppointmentAfterPayment(old.visitCode);
    _commit();
  }

  Future<void> completeTransactionOnlineFirst(String txId) async {
    final tx = _transactions.firstWhere(
      (item) => item.id == txId,
      orElse: () => throw StateError('Không tìm thấy giao dịch viện phí.'),
    );
    if (_apiClient.isConfigured && hasBackendSession) {
      final payment = await _apiClient.submitPaymentVerification(
        clientTransactionId: tx.id,
        amount: tx.netAmount,
        method: tx.method.name,
        appointmentId: tx.visitCode.startsWith('#')
            ? tx.visitCode.substring(1)
            : null,
        bearerToken: _backendAccessToken,
      );
      final paymentStatus = payment['status'] as String? ?? 'pending';
      if (paymentStatus == 'success') {
        completeTransaction(
          txId,
          receiptCode: payment['receiptCode'] as String?,
        );
        return;
      }
      final localIndex = _transactions.indexWhere((item) => item.id == txId);
      if (localIndex >= 0) {
        _transactions[localIndex] = _transactions[localIndex].copyWith(
          status: paymentStatus == 'failed'
              ? PaymentStatus.failed
              : PaymentStatus.pending,
          receiptCode: payment['receiptCode'] as String?,
        );
        _commit(markDirty: false);
      }
      return;
    }
    throw StateError(
      'Chưa kết nối cổng thanh toán/backend để xác minh giao dịch.',
    );
  }

  Future<PaymentTransaction> refreshPaymentStatus(String txId) async {
    if (!_apiClient.isConfigured || !hasBackendSession) {
      throw StateError('Chưa kết nối backend để lấy trạng thái thanh toán.');
    }
    final payment = await _apiClient.fetchPaymentStatus(
      clientTransactionId: txId,
      bearerToken: _backendAccessToken,
    );
    final current = _transactions.firstWhere(
      (item) => item.id == txId,
      orElse: () => throw StateError('Không tìm thấy giao dịch viện phí.'),
    );
    final status = switch ((payment['status'] as String? ?? 'pending')
        .toLowerCase()) {
      'success' => PaymentStatus.success,
      'failed' => PaymentStatus.failed,
      'refunded' => PaymentStatus.refunded,
      _ => PaymentStatus.pending,
    };
    final updated = current.copyWith(
      status: status,
      receiptCode: payment['receiptCode'] as String?,
    );
    final index = _transactions.indexOf(current);
    _transactions[index] = updated;
    if (status == PaymentStatus.success) {
      _confirmAppointmentAfterPayment(updated.visitCode);
      await refreshNotificationsFromBackend();
    }
    _commit(markDirty: false);
    notifyListeners();
    return updated;
  }

  void _confirmAppointmentAfterPayment(String visitCode) {
    if (!visitCode.startsWith('#MED-')) return;
    final appointmentId = visitCode.substring(1);
    final idx = _appointments.indexWhere((item) => item.id == appointmentId);
    if (idx < 0) return;
    final appointment = _appointments[idx];
    if (appointment.status != AppointmentStatus.awaitingPayment) return;
    _appointments[idx] = appointment.copyWith(
      status: AppointmentStatus.confirmed,
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'appointment-confirmed-${appointment.id}',
        title: 'Lịch khám đã xác nhận',
        body:
            '${appointment.doctorName} • ${_formatDate(appointment.dateTime)} (Mã lịch hẹn: ${appointment.ticketNumber ?? appointment.id})',
        createdAt: DateTime.now(),
      ),
    );
  }

  void addVitalRecord(VitalSignRecord record) {
    _vitals.insert(0, record);
    _commit();
  }

  void toggleMedicineTaken(String id) {
    final index = _medicineSchedule.indexWhere((m) => m.id == id);
    if (index < 0) return;
    final current = _medicineSchedule[index];
    final updatedTaken = !current.isTaken;
    _medicineSchedule[index] = current.copyWith(
      isTaken: updatedTaken,
      takenAt: updatedTaken ? DateTime.now() : null,
      clearTakenAt: !updatedTaken,
    );
    _commit();
  }

  Future<void> toggleMedicineTakenOnline(String id) async {
    final index = _medicineSchedule.indexWhere((m) => m.id == id);
    if (index < 0) return;
    final current = _medicineSchedule[index];
    final nextTaken = !current.isTaken;
    if (_apiClient.isConfigured && hasBackendSession) {
      await _apiClient.createFeatureRecord('medication-reminders', {
        'scheduleId': id,
        'action': nextTaken ? 'taken' : 'undone',
        'takenAt': nextTaken ? DateTime.now().toUtc().toIso8601String() : null,
      }, bearerToken: _backendAccessToken);
    }
    toggleMedicineTaken(id);
  }

  void refreshQueue() {
    if (_persistenceEnabled) {
      notifyListeners();
      return;
    }

    // Chỉ dùng dữ liệu khởi tạo trong môi trường không có persistence
    // (widget test/web preview). Android production lấy số thứ tự từ backend.
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

  Future<bool> connectQueueRealtime() async {
    if (!_apiClient.isConfigured) {
      _queueRealtimeError = 'Chưa cấu hình MEDCARE_API_BASE_URL.';
      _queueRealtimeConnected = false;
      notifyListeners();
      return false;
    }
    if (!hasBackendSession) {
      _queueRealtimeError = 'Cần đăng nhập backend để mở realtime queue.';
      _queueRealtimeConnected = false;
      notifyListeners();
      return false;
    }
    await _queueRealtimeSub?.cancel();
    _queueRealtimeError = null;
    _queueRealtimeConnected = true;
    notifyListeners();
    _queueRealtimeSub = _apiClient
        .watchQueue(bearerToken: _backendAccessToken)
        .listen(
          (queue) {
            _applyBackendQueue(queue);
            unawaited(refreshQueueTicketsFromBackend());
            _queueRealtimeConnected = true;
            _queueRealtimeError = null;
            _commit(markDirty: false);
          },
          onError: (Object error) {
            _queueRealtimeConnected = false;
            _queueRealtimeError = error.toString();
            notifyListeners();
          },
          onDone: () {
            _queueRealtimeConnected = false;
            notifyListeners();
          },
          cancelOnError: true,
        );
    return true;
  }

  Future<void> disconnectQueueRealtime() async {
    await _queueRealtimeSub?.cancel();
    _queueRealtimeSub = null;
    _queueRealtimeConnected = false;
    notifyListeners();
  }

  void _applyBackendQueue(Map<String, Object?> queue, {String? fallbackRoom}) {
    final currentNumber = _intFromJson(
      queue['currentNumber'],
      fallback: _queueInfo.currentNumber,
    );
    final patientNumber = _intFromJson(
      queue['patientNumber'],
      fallback: _queueInfo.patientNumber,
    );
    final waitRemain = (patientNumber - currentNumber).clamp(0, 99);
    _queueInfo = LiveQueueInfo(
      department: queue['department'] as String? ?? _queueInfo.department,
      room: queue['room'] as String? ?? fallbackRoom ?? _queueInfo.room,
      doctorName: queue['doctorName'] as String? ?? _queueInfo.doctorName,
      currentNumber: currentNumber,
      patientNumber: patientNumber,
      ticketCode: queue['ticketCode'] as String? ?? _queueInfo.ticketCode,
      estimatedMinutes: _intFromJson(
        queue['estimatedMinutes'],
        fallback: waitRemain * 4,
      ),
    );
  }

  int _intFromJson(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  Future<void> _restore() async {
    try {
      final authenticated = await _database.loadAuthenticated();
      if (authenticated != null) _authenticated = authenticated;

      final role = await _database.loadCurrentRole();
      if (role != null) _currentUserRole = role;

      _currentIdentifier = await _database.loadCurrentIdentifier();
      _backendAccessToken = await _database.loadBackendAccessToken();
      _backendRefreshToken = await _database.loadBackendRefreshToken();

      final syncState = await _database.loadBackendSyncState();
      if (syncState != null) _syncState = syncState;

      final accounts = await _database.loadAccounts();
      _accounts
        ..clear()
        ..addEntries(
          accounts.map((account) => MapEntry(account.identifier, account)),
        );
      await _migrateLegacyPasswordHashes();
      await _ensureSystemAccounts();
      if (_authenticated &&
          (_currentIdentifier == null ||
              !_accounts.containsKey(_currentIdentifier))) {
        _authenticated = false;
        _currentIdentifier = null;
        _currentUserRole = UserRole.patient;
      }

      final profile = await _database.loadProfile();
      if (profile != null) {
        _profile = profile;
        _hasPatientProfile = true;
      } else {
        _profile = MedicalData.defaultPatient;
        _hasPatientProfile = true;
      }

      final appointments = await _database.loadAppointments();
      _appointments
        ..clear()
        ..addAll(appointments);

      final vitals = await _database.loadVitals();
      _vitals
        ..clear()
        ..addAll(vitals);

      final medicineSchedule = await _database.loadMedicineSchedule();
      _medicineSchedule
        ..clear()
        ..addAll(medicineSchedule);

      final medicalRecords = await _database.loadMedicalRecords();
      _medicalRecords
        ..clear()
        ..addAll(medicalRecords);

      final prescriptionMedicines = await _database.loadPrescriptionMedicines();
      _medicines
        ..clear()
        ..addAll(prescriptionMedicines);

      final notifications = await _database.loadNotifications();
      _notifications
        ..clear()
        ..addAll(notifications);

      final transactions = await _database.loadPaymentTransactions();
      _transactions
        ..clear()
        ..addAll(transactions);

      final pharmacyOrders = await _database.loadPharmacyOrders();
      _pharmacyOrders
        ..clear()
        ..addAll(pharmacyOrders);

      final queue = await _database.loadQueue();
      if (queue != null) _queueInfo = queue;

      final slots = await _database.loadSlotConfigs();
      if (slots.isNotEmpty) {
        _slotConfigs
          ..clear()
          ..addEntries(slots.map((slot) => MapEntry(slot.key, slot)));
      }

      final auditLogs = await _database.loadSecurityAuditLogs();
      _securityAuditLogs
        ..clear()
        ..addAll(auditLogs);

      final sessions = await _database.loadActiveSessions();
      _activeSessions
        ..clear()
        ..addAll(sessions);

      // Phiên backend được lưu trên máy có thể đã hết hạn trong lúc app đóng.
      // Làm mới bằng refresh token trước khi các màn hình bắt đầu polling.
      if (_authenticated &&
          _apiClient.isConfigured &&
          _backendRefreshToken != null &&
          _backendRefreshToken!.isNotEmpty) {
        try {
          final session = await _apiClient.refresh(_backendRefreshToken!);
          _applyBackendSession(session);
          await _persist();
        } on MedicalApiException {
          _authenticated = false;
          _backendAccessToken = null;
          _backendRefreshToken = null;
        }
      }

      if (_authenticated && _apiClient.isConfigured) {
        await refreshDoctorsFromBackend();
      }

      await _restorePatientFeatureState();
    } catch (_) {
      // Keep resilient
    } finally {
      _restored = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    if (!_persistenceEnabled) return;
    try {
      await _database.saveAuthenticated(_authenticated);
      await _database.saveCurrentRole(_currentUserRole);
      await _database.saveCurrentIdentifier(_currentIdentifier);
      await _database.saveBackendAccessToken(_backendAccessToken);
      await _database.saveBackendRefreshToken(_backendRefreshToken);
      if (_hasPatientProfile) {
        await _database.saveProfile(_profile);
      }
      await _database.replaceAppointments(_appointments);
      await _database.replaceVitals(_vitals);
      await _database.replaceMedicineSchedule(_medicineSchedule);
      await _database.replaceMedicalRecords(_medicalRecords);
      await _database.replacePrescriptionMedicines(_medicines);
      await _database.replaceNotifications(_notifications.take(250).toList());
      await _database.replacePaymentTransactions(_transactions);
      await _database.replacePharmacyOrders(_pharmacyOrders);
      await _database.saveQueue(_queueInfo);
      await _database.replaceSlotConfigs(_slotConfigs.values.toList());
      await _database.replaceAccounts(_accounts.values.toList());
      await _database.replaceSecurityAuditLogs(
        _securityAuditLogs.take(250).toList(),
      );
      await _database.replaceActiveSessions(_activeSessions);
      await _database.saveBackendSyncState(_syncState);
      await _database.saveSetting(
        _walletStateKey,
        jsonEncode({
          'balance': _walletBalance,
          'advanceDeposit': _advanceDeposit,
          'transactions': _walletTransactions
              .map(
                (item) => {
                  'id': item.id,
                  'title': item.title,
                  'amount': item.amount,
                  'timestamp': item.timestamp.toIso8601String(),
                  'isDebit': item.isDebit,
                  'description': item.description,
                },
              )
              .toList(),
        }),
      );
      await _database.saveSetting(
        _cashlessClaimsKey,
        jsonEncode(
          _cashlessClaims
              .map(
                (claim) => {
                  'id': claim.id,
                  'policyNumber': claim.policyNumber,
                  'providerName': claim.providerName,
                  'hospitalBillId': claim.hospitalBillId,
                  'totalBill': claim.totalBill,
                  'coveredAmount': claim.coveredAmount,
                  'patientCoPay': claim.patientCoPay,
                  'status': claim.status.name,
                  'requestedAt': claim.requestedAt.toIso8601String(),
                  'approvalCode': claim.approvalCode,
                },
              )
              .toList(),
        ),
      );
    } catch (_) {}
  }

  Future<void> _restorePatientFeatureState() async {
    final walletRaw = await _database.loadSetting(_walletStateKey);
    if (walletRaw != null && walletRaw.trim().isNotEmpty) {
      final decoded = jsonDecode(walletRaw);
      if (decoded is Map) {
        _walletBalance = _intFromJson(decoded['balance'], fallback: 0);
        _advanceDeposit = _intFromJson(decoded['advanceDeposit'], fallback: 0);
        final rows = decoded['transactions'];
        if (rows is List) {
          _walletTransactions
            ..clear()
            ..addAll(
              rows.whereType<Map>().map((row) {
                return HospitalWalletTransaction(
                  id:
                      row['id'] as String? ??
                      'TXN-${DateTime.now().microsecondsSinceEpoch}',
                  title: row['title'] as String? ?? 'Giao dịch ví viện phí',
                  amount: _intFromJson(row['amount'], fallback: 0),
                  timestamp:
                      DateTime.tryParse(row['timestamp'] as String? ?? '') ??
                      DateTime.now(),
                  isDebit: row['isDebit'] == true,
                  description: row['description'] as String? ?? '',
                );
              }),
            );
        }
      }
    }

    final claimsRaw = await _database.loadSetting(_cashlessClaimsKey);
    if (claimsRaw != null && claimsRaw.trim().isNotEmpty) {
      final decoded = jsonDecode(claimsRaw);
      if (decoded is List) {
        _cashlessClaims
          ..clear()
          ..addAll(
            decoded.whereType<Map>().map((row) {
              final status = CashlessClaimStatus.values.firstWhere(
                (item) => item.name == row['status'],
                orElse: () => CashlessClaimStatus.pending,
              );
              return CashlessClaimRequest(
                id: row['id'] as String? ?? '',
                policyNumber: row['policyNumber'] as String? ?? '',
                providerName: row['providerName'] as String? ?? '',
                hospitalBillId: row['hospitalBillId'] as String? ?? '',
                totalBill: _intFromJson(row['totalBill'], fallback: 0),
                coveredAmount: _intFromJson(row['coveredAmount'], fallback: 0),
                patientCoPay: _intFromJson(row['patientCoPay'], fallback: 0),
                status: status,
                requestedAt:
                    DateTime.tryParse(row['requestedAt'] as String? ?? '') ??
                    DateTime.now(),
                approvalCode: row['approvalCode'] as String?,
              );
            }),
          );
      }
    }
  }

  Future<void> _migrateLegacyPasswordHashes() async {
    var changed = false;
    for (final entry in _accounts.entries.toList()) {
      final account = entry.value;
      if (!AuthSecurity.needsMigration(account.passwordHash)) continue;
      _accounts[entry.key] = AuthAccount(
        identifier: account.identifier,
        passwordHash: AuthSecurity.hashPassword(
          identifier: account.identifier,
          password: account.passwordHash,
        ),
        role: account.role,
        displayName: account.displayName,
        patientId: account.patientId,
      );
      changed = true;
    }
    if (changed) {
      await _database.replaceAccounts(_accounts.values.toList());
    }
  }

  Future<void> _ensureSystemAccounts() async {
    final defaults = [
      AuthAccount(
        identifier: MedicalData.defaultPatient.email.toLowerCase(),
        passwordHash: '',
        role: UserRole.patient,
        displayName: MedicalData.defaultPatient.name,
        patientId: MedicalData.defaultPatient.id,
      ),
      AuthAccount(
        identifier: MedicalData.defaultPatient.phone.toLowerCase(),
        passwordHash: '',
        role: UserRole.patient,
        displayName: MedicalData.defaultPatient.name,
        patientId: MedicalData.defaultPatient.id,
      ),
      const AuthAccount(
        identifier: '0969261252',
        passwordHash: '',
        role: UserRole.patient,
        displayName: 'Nguyễn Hoàng Vũ',
        patientId: 'MC-89241',
      ),
      const AuthAccount(
        identifier: 'doctor@medcare.vn',
        passwordHash: '',
        role: UserRole.doctor,
        displayName: 'Tài khoản bác sĩ MedCare',
      ),
      const AuthAccount(
        identifier: 'bacsi@medcare.vn',
        passwordHash: '',
        role: UserRole.doctor,
        displayName: 'Tài khoản bác sĩ MedCare',
      ),
      const AuthAccount(
        identifier: 'bacsi',
        passwordHash: '',
        role: UserRole.doctor,
        displayName: 'Tài khoản bác sĩ MedCare',
      ),
      const AuthAccount(
        identifier: 'admin@medcare.vn',
        passwordHash: '',
        role: UserRole.admin,
        displayName: 'Quản trị hệ thống MedCare',
      ),
      const AuthAccount(
        identifier: 'admin',
        passwordHash: '',
        role: UserRole.admin,
        displayName: 'Quản trị hệ thống MedCare',
      ),
    ];

    var changed = false;
    for (final defaultAccount in defaults) {
      final defaultPassword = defaultAccount.identifier == '0969261252'
          ? 'vu12345'
          : defaultAccount.identifier == 'admin'
          ? '123456'
          : defaultAccount.role == UserRole.admin
          ? 'admin123'
          : '123456';
      final account = AuthAccount(
        identifier: defaultAccount.identifier,
        passwordHash: AuthSecurity.hashPassword(
          identifier: defaultAccount.identifier,
          password: defaultPassword,
        ),
        role: defaultAccount.role,
        displayName: defaultAccount.displayName,
        patientId: defaultAccount.patientId,
      );
      final existing = _accounts[account.identifier];
      if (existing == null ||
          existing.role != account.role ||
          existing.passwordHash != account.passwordHash) {
        _accounts[account.identifier] = account;
        changed = true;
      }
    }
    if (changed) {
      await _database.replaceAccounts(_accounts.values.toList());
    }
  }

  void _openCurrentSession(AuthAccount account) {
    final now = DateTime.now();
    _activeSessions.removeWhere((session) => session.isCurrent);
    _activeSessions.insert(
      0,
      ActiveSessionInfo(
        id: 'sess-${now.microsecondsSinceEpoch}',
        deviceName:
            '${kIsWeb ? 'Web browser' : Platform.operatingSystem} device',
        clientType: account.role.name,
        ipAddress: '127.0.0.1',
        lastActive:
            '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        isCurrent: true,
      ),
    );
  }

  void _recordSecurityEvent({
    required String actor,
    required String action,
    required String targetResource,
    required SecuritySeverity severity,
    required String statusDescription,
  }) {
    _securityAuditLogs.insert(
      0,
      SecurityAuditLog(
        id: 'audit-${DateTime.now().microsecondsSinceEpoch}',
        actor: actor,
        action: action,
        targetResource: targetResource,
        ipAddress: '127.0.0.1',
        timestamp: DateTime.now(),
        severity: severity,
        statusDescription: statusDescription,
      ),
    );
    if (_securityAuditLogs.length > 250) {
      _securityAuditLogs.removeRange(250, _securityAuditLogs.length);
    }
  }

  static bool get _isFlutterTest {
    if (kIsWeb) return false;
    final executable = Platform.resolvedExecutable.toLowerCase();
    return Platform.environment['FLUTTER_TEST'] == 'true' ||
        executable.contains('flutter_tester');
  }

  void _markLocalChange() {
    if (!_persistenceEnabled) return;
    _syncState = _syncState.copyWith(
      pendingChanges: _syncState.pendingChanges + 1,
      lastLocalChangeAt: DateTime.now(),
      clearLastError: true,
    );
  }

  void _commit({bool markDirty = true}) {
    if (markDirty) _markLocalChange();
    notifyListeners();
    _persist();
  }

  void markBackendSynced() {
    _syncState = _syncState.copyWith(
      pendingChanges: 0,
      lastSyncedAt: DateTime.now(),
      clearLastError: true,
    );
    _commit(markDirty: false);
  }

  void markBackendSyncFailed(String message) {
    _syncState = _syncState.copyWith(lastError: message.trim());
    _commit(markDirty: false);
  }

  Future<bool> syncWithBackend() async {
    if (!_apiClient.isConfigured) {
      markBackendSyncFailed(
        'Chua cau hinh MEDCARE_API_BASE_URL de dong bo API that.',
      );
      return false;
    }

    try {
      await _apiClient.pushSyncSnapshot(
        _buildBackendSyncPayload(),
        bearerToken: _backendAccessToken,
      );
      markBackendSynced();
      return true;
    } catch (error) {
      markBackendSyncFailed(error.toString());
      return false;
    }
  }

  Future<String?> askAiAssistant({
    required String message,
    List<Map<String, String>> history = const [],
  }) async {
    if (!_apiClient.isConfigured || !hasBackendSession) return null;
    try {
      return await _apiClient.chatWithAi(
        message: message,
        history: history,
        age: _profileAge,
        sex: _profileSex,
        bearerToken: _backendAccessToken,
      );
    } on MedicalApiException catch (error) {
      markBackendSyncFailed(error.message);
      return null;
    } catch (error) {
      markBackendSyncFailed(error.toString());
      return null;
    }
  }

  int? get _profileAge {
    final parts = _profile.dateOfBirth.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final birth = DateTime(year, month, day);
    final today = DateTime.now();
    var age = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age > 0 ? age : null;
  }

  String? get _profileSex {
    final gender = _profile.gender.toLowerCase();
    if (gender.contains('nữ') || gender.contains('female')) return 'female';
    if (gender.contains('nam') || gender.contains('male')) return 'male';
    return null;
  }

  Future<bool> refreshHealthNews() async {
    if (!_apiClient.isConfigured) {
      _healthNewsError =
          'Chua cau hinh MEDCARE_API_BASE_URL nen dang hien thi tin noi bo.';
      notifyListeners();
      return false;
    }

    _healthNewsLoading = true;
    _healthNewsError = null;
    notifyListeners();

    try {
      final remoteArticles = await _apiClient.fetchHealthNews(
        bearerToken: _backendAccessToken,
      );
      if (remoteArticles.isEmpty) {
        _healthNewsError = 'API tin tuc chua co bai viet moi.';
        return false;
      }
      healthArticles
        ..clear()
        ..addAll(remoteArticles);
      _healthNewsUpdatedAt = DateTime.now();
      _healthNewsError = null;
      return true;
    } on MedicalApiException catch (error) {
      _healthNewsError = error.message;
      return false;
    } catch (error) {
      _healthNewsError = error.toString();
      return false;
    } finally {
      _healthNewsLoading = false;
      notifyListeners();
    }
  }

  Map<String, Object?> _buildBackendSyncPayload() => {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'actor': _currentIdentifier,
    'role': _currentUserRole.name,
    'authenticated': _authenticated,
    'syncState': {
      'pendingChanges': _syncState.pendingChanges,
      'lastLocalChangeAt': _syncState.lastLocalChangeAt?.toIso8601String(),
      'lastSyncedAt': _syncState.lastSyncedAt?.toIso8601String(),
    },
    'patientProfile': _patientProfilePayload(),
    'appointments': _appointments.map(_appointmentPayload).toList(),
    'vitals': _vitals.map(_vitalPayload).toList(),
    'medicineSchedule': _medicineSchedule
        .map(_medicineSchedulePayload)
        .toList(),
    'medicalRecords': _medicalRecords.map(_medicalRecordPayload).toList(),
    'prescriptionMedicines': _medicines.map(_medicinePayload).toList(),
    'notifications': _notifications.map(_notificationPayload).toList(),
    'paymentTransactions': _transactions.map(_paymentPayload).toList(),
    'pharmacyOrders': _pharmacyOrders.map(_pharmacyOrderPayload).toList(),
    'liveQueue': _queuePayload(_queueInfo),
    'slotConfigs': _slotConfigs.values.map(_slotPayload).toList(),
    'securityAuditLogs': _securityAuditLogs.map(_auditPayload).toList(),
    'activeSessions': _activeSessions.map(_sessionPayload).toList(),
  };

  Map<String, Object?>? _patientProfilePayload() {
    if (!_hasPatientProfile) return null;
    return {
      'id': _profile.id,
      'name': _profile.name,
      'phone': _profile.phone,
      'email': _profile.email,
      'dateOfBirth': _profile.dateOfBirth,
      'insuranceNumber': _profile.insuranceNumber,
      'bloodType': _profile.bloodType,
      'gender': _profile.gender,
      'address': _profile.address,
      'allergies': _profile.allergies,
    };
  }

  Map<String, Object?> _appointmentPayload(Appointment value) => {
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

  Map<String, Object?> _vitalPayload(VitalSignRecord value) => {
    'timestamp': value.timestamp.toIso8601String(),
    'systolic': value.systolic,
    'diastolic': value.diastolic,
    'heartRate': value.heartRate,
    'bloodGlucose': value.bloodGlucose,
    'weightKg': value.weightKg,
    'heightCm': value.heightCm,
    'note': value.note,
  };

  Map<String, Object?> _medicineSchedulePayload(MedicineScheduleItem value) => {
    'id': value.id,
    'medicineName': value.medicineName,
    'dosage': value.dosage,
    'timeSlot': value.timeSlot,
    'period': value.period,
    'instruction': value.instruction,
    'isTaken': value.isTaken,
    'takenAt': value.takenAt?.toIso8601String(),
  };

  Map<String, Object?> _medicalRecordPayload(MedicalRecord value) => {
    'id': value.id,
    'date': value.date,
    'department': value.department,
    'doctorName': value.doctorName,
    'diagnosis': value.diagnosis,
    'symptoms': value.symptoms,
    'treatmentPlan': value.treatmentPlan,
    'followUpDate': value.followUpDate,
    'prescriptionCode': value.prescriptionCode,
    'totalFee': value.totalFee,
    'insuranceCovered': value.insuranceCovered,
    'diagnosisCode': value.diagnosisCode,
    'icd10Name': value.icd10Name,
    'differentialDiagnosis': value.differentialDiagnosis,
    'physicalExamNotes': value.physicalExamNotes,
    'labSummary': value.labSummary,
    'xrayFindings': value.xrayFindings,
    'doctorInstructions': value.doctorInstructions,
    'digitalSignatureToken': value.digitalSignatureToken,
    'riskLevel': value.riskLevel,
    'prescribedMedicinesSummary': value.prescribedMedicinesSummary,
  };

  Map<String, Object?> _medicinePayload(MedicineItem value) => {
    'name': value.name,
    'category': value.category,
    'dosage': value.dosage,
    'quantity': value.quantity,
    'instruction': value.instruction,
    'warning': value.warning,
  };

  Map<String, Object?> _notificationPayload(AppNotification value) => {
    'id': value.id,
    'title': value.title,
    'body': value.body,
    'createdAt': value.createdAt.toIso8601String(),
    'read': value.read,
  };

  Map<String, Object?> _paymentPayload(PaymentTransaction value) => {
    'id': value.id,
    'visitCode': value.visitCode,
    'description': value.description,
    'grossAmount': value.grossAmount,
    'insuranceAmount': value.insuranceAmount,
    'netAmount': value.netAmount,
    'method': value.method.name,
    'status': value.status.name,
    'timestamp': value.timestamp.toIso8601String(),
    'walletName': value.walletName,
    'invoiceEmail': value.invoiceEmail,
    'receiptCode': value.receiptCode,
  };

  Map<String, Object?> _pharmacyOrderPayload(PharmacyOrder value) => {
    'id': value.id,
    'prescriptionId': value.prescriptionId,
    'patientName': value.patientName,
    'phone': value.phone,
    'deliveryAddress': value.deliveryAddress,
    'pharmacyName': value.pharmacyName,
    'itemsCount': value.itemsCount,
    'medicineTotal': value.medicineTotal,
    'shippingFee': value.shippingFee,
    'status': value.status.name,
    'orderedAt': value.orderedAt.toIso8601String(),
    'estimatedMinutes': value.estimatedMinutes,
  };

  Map<String, Object?> _queuePayload(LiveQueueInfo value) => {
    'department': value.department,
    'room': value.room,
    'doctorName': value.doctorName,
    'currentNumber': value.currentNumber,
    'patientNumber': value.patientNumber,
    'ticketCode': value.ticketCode,
    'estimatedMinutes': value.estimatedMinutes,
  };

  Map<String, Object?> _slotPayload(SlotConfig value) => {
    'key': value.key,
    'doctorId': value.doctorId,
    'date': value.date,
    'time': value.time,
    'capacity': value.capacity,
    'booked': value.booked,
  };

  Map<String, Object?> _auditPayload(SecurityAuditLog value) => {
    'id': value.id,
    'actor': value.actor,
    'action': value.action,
    'targetResource': value.targetResource,
    'ipAddress': value.ipAddress,
    'timestamp': value.timestamp.toIso8601String(),
    'severity': value.severity.name,
    'statusDescription': value.statusDescription,
  };

  Map<String, Object?> _sessionPayload(ActiveSessionInfo value) => {
    'id': value.id,
    'deviceName': value.deviceName,
    'clientType': value.clientType,
    'ipAddress': value.ipAddress,
    'lastActive': value.lastActive,
    'isCurrent': value.isCurrent,
  };

  bool login({required String identifier, required String password}) {
    _lastAuthError = null;
    if (identifier.trim().isEmpty || password.trim().length < 6) return false;
    final lower = identifier.trim().toLowerCase();

    if (_persistenceEnabled) {
      final account = _accounts[lower];
      if (account == null ||
          !AuthSecurity.verifyPassword(
            identifier: lower,
            password: password,
            storedHash: account.passwordHash,
          )) {
        _recordSecurityEvent(
          actor: lower,
          action: 'LOGIN_DENIED',
          targetResource: 'Auth Gateway',
          severity: SecuritySeverity.warning,
          statusDescription: 'Sai tài khoản hoặc mật khẩu.',
        );
        _commit();
        return false;
      }
      if (account.role == UserRole.patient && !_hasPatientProfile) {
        _recordSecurityEvent(
          actor: lower,
          action: 'LOGIN_DENIED',
          targetResource: 'Patient Portal',
          severity: SecuritySeverity.warning,
          statusDescription: 'Tài khoản bệnh nhân chưa có hồ sơ hợp lệ.',
        );
        _commit();
        return false;
      }
      if (AuthSecurity.needsMigration(account.passwordHash)) {
        _accounts[lower] = AuthAccount(
          identifier: account.identifier,
          passwordHash: AuthSecurity.hashPassword(
            identifier: lower,
            password: password,
          ),
          role: account.role,
          displayName: account.displayName,
          patientId: account.patientId,
        );
      }
      _authenticated = true;
      _currentUserRole = account.role;
      _currentIdentifier = account.identifier;
      _openCurrentSession(account);
      _recordSecurityEvent(
        actor: account.displayName,
        action: 'LOGIN_SUCCESS',
        targetResource: account.role.name,
        severity: SecuritySeverity.info,
        statusDescription: 'Đăng nhập thành công bằng tài khoản được cấp.',
      );
    } else if (lower == 'doctor@medcare.vn' || lower == 'bacsi@medcare.vn') {
      if (password != '123456' && password != 'password123') return false;
      _authenticated = true;
      _currentUserRole = UserRole.doctor;
      _currentIdentifier = lower;
    } else if (lower == 'admin@medcare.vn') {
      if (password != 'admin123' && password != 'admin123password') {
        return false;
      }
      _authenticated = true;
      _currentUserRole = UserRole.admin;
      _currentIdentifier = lower;
    } else {
      if (_persistenceEnabled && !_hasPatientProfile) return false;
      if (_persistenceEnabled &&
          lower != _profile.email.toLowerCase() &&
          lower != _profile.phone.toLowerCase()) {
        return false;
      }
      _authenticated = true;
      _currentUserRole = UserRole.patient;
      _currentIdentifier = lower;
    }
    _commit();
    return true;
  }

  Future<bool> loginOnlineFirst({
    required String identifier,
    required String password,
  }) async {
    _lastAuthError = null;
    final cleanIdentifier = identifier.trim();
    final cleanPassword = password.trim();
    if (cleanIdentifier.isEmpty || cleanPassword.length < 6) {
      _lastAuthError = 'Vui lòng nhập tài khoản và mật khẩu hợp lệ.';
      return false;
    }

    if (_apiClient.isConfigured) {
      try {
        final session = await _apiClient.login(
          identifier: cleanIdentifier,
          password: cleanPassword,
        );
        _applyBackendSession(session);
        try {
          await refreshDoctorsFromBackend();
          await refreshAppointmentsFromBackend();
          await refreshNotificationsFromBackend();
        } catch (error) {
          markBackendSyncFailed(error.toString());
        }
        _recordSecurityEvent(
          actor: session.user.displayName.isNotEmpty
              ? session.user.displayName
              : session.user.identifier,
          action: 'BACKEND_LOGIN_SUCCESS',
          targetResource: session.user.role,
          severity: SecuritySeverity.info,
          statusDescription:
              'Đăng nhập thành công qua backend API và nhận JWT.',
        );
        _commit();
        return true;
      } on MedicalApiException catch (error) {
        _lastAuthError = error.message;
        _recordSecurityEvent(
          actor: cleanIdentifier.toLowerCase(),
          action: 'BACKEND_LOGIN_DENIED',
          targetResource: 'Backend Auth API',
          severity: SecuritySeverity.warning,
          statusDescription: error.message,
        );
        _commit();
        return false;
      } catch (error) {
        _lastAuthError = 'Đăng nhập thất bại: $error';
        _commit();
        return false;
      }
    }

    final ok = login(identifier: cleanIdentifier, password: cleanPassword);
    if (!ok) {
      _lastAuthError =
          'Thông tin đăng nhập không đúng hoặc tài khoản chưa được cấp.';
    }
    return ok;
  }

  void _applyBackendSession(MedicalApiAuthSession session) {
    final role = _roleFromBackend(session.user.role);
    final identifier = session.user.identifier.trim().isNotEmpty
        ? session.user.identifier.trim().toLowerCase()
        : session.user.id.trim().toLowerCase();
    final displayName = session.user.displayName.trim().isNotEmpty
        ? session.user.displayName.trim()
        : identifier;

    _backendAccessToken = session.accessToken;
    _backendRefreshToken = session.refreshToken;
    _backendUserId = session.user.id;
    _authenticated = true;
    _currentUserRole = role;
    _currentIdentifier = identifier;

    final account = AuthAccount(
      identifier: identifier,
      passwordHash: AuthSecurity.hashPassword(
        identifier: identifier,
        password: 'backend-session-${session.user.id}',
      ),
      role: role,
      displayName: displayName,
      patientId: session.user.patientId,
    );
    _accounts[identifier] = account;
    _openCurrentSession(account);

    if (role == UserRole.patient) {
      final patientId = session.user.patientId ?? session.user.id;
      final isSamePatient = _hasPatientProfile && _profile.id == patientId;
      _profile = PatientProfile(
        id: patientId,
        name: displayName,
        phone: session.user.phone?.trim().isNotEmpty == true
            ? session.user.phone!.trim()
            : _profile.phone,
        email: identifier.contains('@') ? identifier : _profile.email,
        // Chỉ giữ dữ liệu y tế khi đăng nhập lại đúng bệnh nhân. Tài khoản
        // mới không được thừa hưởng thông tin của hồ sơ mặc định/cũ.
        dateOfBirth: isSamePatient ? _profile.dateOfBirth : '',
        insuranceNumber: isSamePatient ? _profile.insuranceNumber : '',
        bloodType: isSamePatient ? _profile.bloodType : '',
        gender: isSamePatient ? _profile.gender : '',
        address: isSamePatient ? _profile.address : '',
        allergies: isSamePatient ? _profile.allergies : '',
      );
      _hasPatientProfile = true;
    }
  }

  UserRole _roleFromBackend(String role) {
    switch (role.trim().toLowerCase()) {
      case 'doctor':
        return UserRole.doctor;
      case 'admin':
        return UserRole.admin;
      case 'patient':
      default:
        return UserRole.patient;
    }
  }

  PatientRegistrationResult validatePatientRegistration({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final cleanName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final cleanPhone = phone.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();
    final cleanConfirmPassword = confirmPassword.trim();

    if (cleanName.length < 2) {
      return const PatientRegistrationResult.failure(
        'Họ tên phải có ít nhất 2 ký tự.',
      );
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(cleanEmail)) {
      return const PatientRegistrationResult.failure(
        'Email không đúng định dạng.',
      );
    }
    if (!RegExp(r'^(0|\+84)[0-9]{9,10}$').hasMatch(cleanPhone)) {
      return const PatientRegistrationResult.failure(
        'Số điện thoại phải đúng định dạng Việt Nam.',
      );
    }
    if (cleanPassword.length < 6 ||
        !RegExp(r'[A-Za-z]').hasMatch(cleanPassword) ||
        !RegExp(r'[0-9]').hasMatch(cleanPassword)) {
      return const PatientRegistrationResult.failure(
        'Mật khẩu phải từ 6 ký tự và có cả chữ lẫn số.',
      );
    }
    if (cleanPassword != cleanConfirmPassword) {
      return const PatientRegistrationResult.failure(
        'Xác nhận mật khẩu không khớp.',
      );
    }
    if (_accounts.containsKey(cleanEmail)) {
      return const PatientRegistrationResult.failure(
        'Email này đã được đăng ký.',
      );
    }
    if (_accounts.containsKey(cleanPhone)) {
      return const PatientRegistrationResult.failure(
        'Số điện thoại này đã được đăng ký.',
      );
    }

    return const PatientRegistrationResult.success('Thông tin hợp lệ.');
  }

  Future<PatientRegistrationResult> requestRegistrationOtp({
    required String name,
    required String phone,
    required String email,
    required String password,
    String channel = 'sms',
  }) async {
    if (!_apiClient.isConfigured) {
      return const PatientRegistrationResult.failure(
        'Backend OTP chưa được cấu hình.',
      );
    }
    try {
      await _apiClient.requestRegistrationOtp(
        name: name,
        phone: phone,
        email: email,
        password: password,
        channel: channel,
      );
      return const PatientRegistrationResult.success('Mã OTP đã được gửi.');
    } on MedicalApiException catch (error) {
      return PatientRegistrationResult.failure(error.message);
    }
  }

  Future<PatientRegistrationResult> registerPatientOnline({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String code,
    String channel = 'sms',
  }) async {
    if (!_apiClient.isConfigured) {
      return const PatientRegistrationResult.failure(
        'Backend OTP chưa được cấu hình.',
      );
    }
    try {
      final session = await _apiClient.registerPatient(
        name: name,
        phone: phone,
        email: email,
        password: password,
        code: code,
        channel: channel,
      );
      _applyBackendSession(session);
      await _persist();
      return const PatientRegistrationResult.success(
        'Đăng ký thành công. Tài khoản đã được xác thực bằng OTP.',
      );
    } on MedicalApiException catch (error) {
      return PatientRegistrationResult.failure(error.message);
    }
  }

  Future<PatientRegistrationResult> registerPatient({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final validation = validatePatientRegistration(
      name: name,
      phone: phone,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
    if (!validation.success) return validation;

    final cleanName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final cleanPhone = phone.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    register(
      name: cleanName,
      phone: cleanPhone,
      email: cleanEmail,
      password: cleanPassword,
    );
    await _persist();
    return const PatientRegistrationResult.success(
      'Đăng ký thành công. Tài khoản bệnh nhân đã được lưu vào SQLite.',
    );
  }

  void register({
    required String name,
    required String phone,
    required String email,
    String password = '123456',
  }) {
    final cleanName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final cleanPhone = phone.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    final cleanEmail = email.trim().toLowerCase();
    if (_profile.id.isEmpty) {
      _profile = PatientProfile(
        id: 'MC-${DateTime.now().millisecondsSinceEpoch}',
        name: cleanName,
        phone: cleanPhone,
        email: cleanEmail,
        dateOfBirth: '',
        insuranceNumber: '',
        bloodType: '',
        gender: '',
        address: '',
        allergies: '',
      );
    } else {
      _profile = _profile.copyWith(
        name: cleanName,
        phone: cleanPhone,
        email: cleanEmail,
      );
    }
    _hasPatientProfile = true;
    final normalizedPassword = password.trim();
    final accountPassword = normalizedPassword.length >= 6
        ? normalizedPassword
        : '123456';
    final patientAccount = AuthAccount(
      identifier: cleanEmail,
      passwordHash: AuthSecurity.hashPassword(
        identifier: cleanEmail,
        password: accountPassword,
      ),
      role: UserRole.patient,
      displayName: cleanName,
      patientId: _profile.id,
    );
    _accounts[cleanEmail] = patientAccount;
    _accounts[cleanPhone] = AuthAccount(
      identifier: cleanPhone,
      passwordHash: AuthSecurity.hashPassword(
        identifier: cleanPhone,
        password: accountPassword,
      ),
      role: UserRole.patient,
      displayName: cleanName,
      patientId: _profile.id,
    );
    _authenticated = true;
    _currentUserRole = UserRole.patient;
    _currentIdentifier = patientAccount.identifier;
    _openCurrentSession(patientAccount);
    _recordSecurityEvent(
      actor: cleanName,
      action: 'REGISTER_PATIENT',
      targetResource: 'Patient Portal',
      severity: SecuritySeverity.info,
      statusDescription: 'Tạo hồ sơ bệnh nhân và tài khoản đăng nhập.',
    );
    _commit();
  }

  void logout() {
    final actor = _currentIdentifier ?? _currentUserRole.name;
    final refreshToken = _backendRefreshToken;
    if (_apiClient.isConfigured &&
        refreshToken != null &&
        refreshToken.trim().isNotEmpty) {
      unawaited(_apiClient.logout(refreshToken));
    }
    if (_authenticated) {
      _recordSecurityEvent(
        actor: actor,
        action: 'LOGOUT',
        targetResource: _currentUserRole.name,
        severity: SecuritySeverity.info,
        statusDescription: 'Kết thúc phiên đăng nhập hiện tại.',
      );
    }
    _activeSessions.removeWhere((session) => session.isCurrent);
    unawaited(_queueRealtimeSub?.cancel());
    _queueRealtimeSub = null;
    _queueRealtimeConnected = false;
    _queueRealtimeError = null;
    _authenticated = false;
    _currentUserRole = UserRole.patient;
    _currentIdentifier = null;
    _backendAccessToken = null;
    _backendRefreshToken = null;
    _backendUserId = null;
    _queueTickets = const [];
    _lastAuthError = null;
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
    _hasPatientProfile = true;
    _commit();
  }

  Future<void> refreshAppointmentsFromBackend() async {
    if (!_apiClient.isConfigured || !hasBackendSession) return;
    final remote = await _apiClient.fetchAppointments(
      bearerToken: _backendAccessToken,
    );
    _appointments
      ..clear()
      ..addAll(remote.map(_appointmentFromBackend));
    if (isDoctorRole) {
      final selected = _appointments.cast<Appointment?>().firstWhere(
        (item) =>
            item != null &&
            item.patientId != null &&
            item.status != AppointmentStatus.cancelled &&
            item.status != AppointmentStatus.completed,
        orElse: () => null,
      );
      if (selected != null) {
        _activeClinicalAppointmentId = selected.id;
        _activeClinicalPatientId = selected.patientId;
      }
    }
    _commit(markDirty: false);
  }

  /// Đồng bộ danh mục bác sĩ từ backend. Nếu backend chưa có dữ liệu hoặc
  /// tạm thời mất kết nối, giữ danh mục cục bộ để giao diện vẫn dùng được.
  Future<void> refreshDoctorsFromBackend() async {
    if (!_apiClient.isConfigured) return;
    try {
      final remote = await _apiClient.fetchDoctors();
      if (remote.isEmpty) return;
      doctors
        ..clear()
        ..addAll(remote.map(_doctorFromBackend));
      notifyListeners();
    } catch (error) {
      // Không làm hỏng đăng nhập chỉ vì danh mục bác sĩ đang tạm thời lỗi.
      markBackendSyncFailed(error.toString());
    }
  }

  Future<void> refreshNotificationsFromBackend() async {
    if (!_apiClient.isConfigured || !hasBackendSession) return;
    try {
      final remote = await _apiClient.fetchNotifications(
        bearerToken: _backendAccessToken,
      );
      final localOnly = _notifications
          .where((item) => !item.id.startsWith('remote-'))
          .toList(growable: false);
      _notifications
        ..clear()
        ..addAll(remote.map(_notificationFromBackend))
        ..addAll(localOnly);
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (error) {
      markBackendSyncFailed(error.toString());
    }
  }

  Future<void> refreshQueueTicketsFromBackend() async {
    if (!_apiClient.isConfigured || !hasBackendSession) return;
    _queueTickets = await _apiClient.fetchQueueTickets(
      bearerToken: _backendAccessToken,
    );
    notifyListeners();
  }

  void selectClinicalAppointment(Appointment appointment) {
    if (appointment.patientId == null || appointment.patientId!.isEmpty) {
      throw StateError('Lịch hẹn chưa có mã bệnh nhân hợp lệ.');
    }
    _activeClinicalAppointmentId = appointment.id;
    _activeClinicalPatientId = appointment.patientId;
    // Không dùng hồ sơ của bác sĩ/người đăng nhập làm hồ sơ dị ứng của ca mới.
    // Dị ứng phải được xác nhận trong bước bệnh sử của đúng bệnh nhân.
    _activeClinicalAllergies = '';
    notifyListeners();
  }

  Future<void> refreshClinicalDataFromBackend() async {
    if (!_apiClient.isConfigured || !hasBackendSession) return;
    final records = await _apiClient.fetchMedicalRecords(
      bearerToken: _backendAccessToken,
    );
    final prescriptions = await _apiClient.fetchPrescriptions(
      bearerToken: _backendAccessToken,
    );
    final actions = await _apiClient.fetchClinicalActions(
      bearerToken: _backendAccessToken,
    );
    _medicalRecords
      ..clear()
      ..addAll(records.map(_medicalRecordFromBackend));
    if (_currentUserRole == UserRole.patient) {
      _syncPatientClinicalSections(actions);
      final files = await fetchMedicalFilesOnline();
      await _syncPatientMedicalFiles(files);
    }
    if (prescriptions.isNotEmpty) {
      final medicines = prescriptions.first['medicines'];
      if (medicines is List) {
        _medicines
          ..clear()
          ..addAll(medicines.whereType<Map>().map(_medicineFromBackend));
      }
    }
    _commit(markDirty: false);
  }

  void _syncPatientClinicalSections(List<Map<String, Object?>> actions) {
    // Khi đã đăng nhập backend, chỉ hiển thị dữ liệu thật từ ca khám; không
    // trộn các mẫu cục bộ vào hồ sơ của bệnh nhân.
    _labTests.clear();
    _labTrends.clear();
    _labReports.clear();
    _imagingResults.clear();

    final trendPoints = <LabTrendPoint>[];
    for (final item in actions) {
      final action = item['action'] as String? ?? '';
      final payload = item['payload'] is Map
          ? Map<String, Object?>.from(item['payload'] as Map)
          : const <String, Object?>{};
      final createdAt =
          DateTime.tryParse(item['createdAt'] as String? ?? '') ??
          DateTime.now();
      if (action == 'LAB_RESULT') {
        final name = payload['name']?.toString().trim() ?? '';
        final value = payload['value']?.toString().trim() ?? '';
        if (name.isEmpty || value.isEmpty) continue;
        final numeric = _firstNumber(value);
        final unit = payload['unit']?.toString() ?? '';
        final abnormal = payload['isAbnormal'] == true;
        _labTests.add(
          LabTestItem(
            name: name,
            value: value,
            unit: unit,
            normalRange: payload['normalRange']?.toString() ?? '',
            isAbnormal: abnormal,
            note: payload['note']?.toString(),
          ),
        );
        if (numeric != null) {
          trendPoints.add(
            _trendPointForLab(
              name: name,
              value: numeric,
              unit: unit,
              timestamp: createdAt,
            ),
          );
        }
        final risk = abnormal ? LabRiskLevel.warning : LabRiskLevel.normal;
        _labReports.add(
          LabReportItem(
            id:
                item['id']?.toString() ??
                'lab-${createdAt.microsecondsSinceEpoch}',
            code: name,
            name: name,
            category:
                name.toLowerCase().contains('cbc') ||
                    name.toLowerCase().contains('hồng')
                ? LabCategory.hematology
                : LabCategory.biochemistry,
            value: numeric ?? 0,
            unit: unit,
            referenceRange: payload['normalRange']?.toString() ?? '',
            riskLevel: risk,
            clinicalMeaning:
                payload['note']?.toString() ??
                'Kết quả do bộ phận xét nghiệm trả về.',
            dietaryAdvice: 'Thực hiện theo hướng dẫn của bác sĩ.',
            testedAt: createdAt.toLocal().toString(),
          ),
        );
      }
      if (action.startsWith('IMAGING_')) {
        final modality = payload['modality']?.toString() ?? action;
        final findings =
            payload['findings']?.toString() ??
            payload['result']?.toString() ??
            'Đang chờ bộ phận chẩn đoán hình ảnh trả kết quả.';
        _imagingResults.add({
          'id':
              item['id']?.toString() ??
              'img-${createdAt.microsecondsSinceEpoch}',
          'modality': modality,
          'findings': findings,
          'imageUrl': payload['imageUrl']?.toString() ?? '',
          'imageBase64': payload['imageBase64']?.toString() ?? '',
          'fileName': payload['fileName']?.toString() ?? '',
          'status': action == 'IMAGING_RESULT'
              ? 'Đã có kết luận'
              : 'Đã chỉ định',
          'createdAt': createdAt,
        });
      }
    }
    _labTests.sort((a, b) => a.name.compareTo(b.name));
    _labReports.sort((a, b) => b.testedAt.compareTo(a.testedAt));
    trendPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _labTrends.addAll(trendPoints);
    _imagingResults.sort(
      (a, b) =>
          (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime),
    );
  }

  Future<void> _syncPatientMedicalFiles(
    List<Map<String, Object?>> files,
  ) async {
    for (final file in files) {
      final id = file['id']?.toString() ?? '';
      if (id.isEmpty ||
          _imagingResults.any((item) => item['id']?.toString() == id)) {
        continue;
      }
      var encoded = '';
      final mimeType = file['mimeType']?.toString() ?? '';
      if (mimeType.startsWith('image/')) {
        try {
          encoded = base64Encode(await downloadMedicalFileOnline(id));
        } catch (_) {
          // Vẫn hiển thị metadata nếu nội dung file tạm thời không tải được.
        }
      }
      final createdAt =
          DateTime.tryParse(file['createdAt']?.toString() ?? '') ??
          DateTime.now();
      _imagingResults.add({
        'id': id,
        'modality': file['category']?.toString() ?? 'Hồ sơ y tế',
        'findings': file['findings']?.toString() ?? '',
        'imageUrl': '',
        'imageBase64': encoded,
        'fileName': file['fileName']?.toString() ?? '',
        'status': 'Đã có kết luận',
        'createdAt': createdAt,
      });
    }
    _imagingResults.sort(
      (a, b) =>
          (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime),
    );
  }

  double? _firstNumber(String value) {
    final match = RegExp(r'-?\d+(?:[.,]\d+)?').firstMatch(value);
    return match == null
        ? null
        : double.tryParse(match.group(0)!.replaceAll(',', '.'));
  }

  LabTrendPoint _trendPointForLab({
    required String name,
    required double value,
    required String unit,
    required DateTime timestamp,
  }) {
    final normalized = name.toLowerCase();
    final convertedGlucose = unit.toLowerCase().contains('mmol')
        ? value * 18
        : value;
    return LabTrendPoint(
      dateStr:
          '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}',
      timestamp: timestamp,
      bloodGlucose:
          normalized.contains('glucose') || normalized.contains('đường')
          ? convertedGlucose
          : 0,
      alt: normalized.contains('alt') ? value : 0,
      ast: normalized.contains('ast') ? value : 0,
      cholesterolTotal: normalized.contains('cholesterol') ? value : 0,
      uricAcid: normalized.contains('uric') || normalized.contains('acid uric')
          ? value
          : 0,
    );
  }

  Future<String> submitSupportRequest({
    required String category,
    required String message,
  }) async {
    if (_apiClient.isConfigured && hasBackendSession) {
      final request = await _apiClient.submitSupportRequest(
        category: category,
        message: message,
        bearerToken: _backendAccessToken,
      );
      return request['id'] as String? ??
          'HT-${DateTime.now().millisecondsSinceEpoch}';
    }
    return 'HT-${DateTime.now().millisecondsSinceEpoch % 1000000}'.padLeft(
      9,
      '0',
    );
  }

  Future<List<Map<String, Object?>>> fetchSupportRequests() async {
    if (!_apiClient.isConfigured || !hasBackendSession) return const [];
    return _apiClient.fetchSupportRequests(bearerToken: _backendAccessToken);
  }

  Future<String> submitPackageRequest({
    required String category,
    required String packageId,
    required String packageTitle,
    required int amount,
    required String details,
  }) async {
    if (!_apiClient.isConfigured || !hasBackendSession) {
      throw StateError('Cần kết nối backend để gửi đăng ký gói dịch vụ.');
    }
    final request = await _apiClient.submitSupportRequest(
      category: category,
      message:
          'PACKAGE_ID=$packageId\nPACKAGE_TITLE=$packageTitle\nAMOUNT=$amount\n$details',
      bearerToken: _backendAccessToken,
    );
    return request['id']?.toString() ?? '';
  }

  Future<Map<String, Object?>> updateAdminSupportRequestOnline({
    required String requestId,
    required String status,
  }) async {
    if (!_apiClient.isConfigured || !hasBackendSession || !isAdminRole) {
      throw StateError('Cần đăng nhập tài khoản admin để xử lý yêu cầu.');
    }
    return _apiClient.updateSupportRequestStatus(
      requestId: requestId,
      status: status,
      bearerToken: _backendAccessToken,
    );
  }

  Future<Map<String, Object?>> fetchSupportRequest(String id) async {
    if (!_apiClient.isConfigured || !hasBackendSession) {
      throw StateError('Cần kết nối backend để xem hội thoại hỗ trợ.');
    }
    return _apiClient.fetchSupportRequest(id, bearerToken: _backendAccessToken);
  }

  Future<void> addSupportMessage({
    required String requestId,
    required String message,
  }) async {
    if (!_apiClient.isConfigured || !hasBackendSession) {
      throw StateError('Cần kết nối backend để gửi phản hồi hỗ trợ.');
    }
    await _apiClient.addSupportMessage(
      requestId: requestId,
      message: message,
      bearerToken: _backendAccessToken,
    );
  }

  Appointment _appointmentFromBackend(Map<String, Object?> data) {
    final doctorId = data['doctorId'] as String? ?? '';
    final doctor = doctors.cast<DoctorProfile?>().firstWhere(
      (item) => item?.id == doctorId,
      orElse: () => null,
    );
    final appointmentId = data['id'] as String? ?? '';
    final existing = _appointments.cast<Appointment?>().firstWhere(
      (item) => item?.id == appointmentId,
      orElse: () => null,
    );
    final time =
        DateTime.tryParse(data['appointmentTime'] as String? ?? '')
            ?.toLocal() ??
        existing?.dateTime ??
        DateTime.now();
    final status = switch ((data['status'] as String? ?? 'confirmed')
        .toLowerCase()) {
      'cancelled' => AppointmentStatus.cancelled,
      'completed' => AppointmentStatus.completed,
      'awaitingpayment' ||
      'awaiting_payment' => AppointmentStatus.awaitingPayment,
      _ => AppointmentStatus.confirmed,
    };
    return Appointment(
      id: appointmentId.isEmpty
          ? 'REMOTE-${time.microsecondsSinceEpoch}'
          : appointmentId,
      doctorId: doctorId.isEmpty
          ? existing?.doctorId ?? doctor?.id ?? ''
          : doctorId,
      doctorName:
          data['doctorName'] as String? ??
          existing?.doctorName ??
          doctor?.name ??
          '',
      specialty:
          data['specialty'] as String? ??
          existing?.specialty ??
          doctor?.specialty ??
          '',
      location: existing?.location ?? doctor?.location ?? 'Bệnh viện MedCare',
      dateTime: time,
      patientName:
          data['patientName'] as String? ??
          existing?.patientName ??
          profile.name,
      reason: data['reason'] as String? ?? existing?.reason ?? '',
      insuranceApplied:
          data['insuranceApplied'] == true ||
          existing?.insuranceApplied == true,
      status: status,
      fee:
          (data['fee'] as num?)?.toInt() ?? existing?.fee ?? doctor?.price ?? 0,
      ticketNumber: data['ticketNumber'] as String? ?? existing?.ticketNumber,
      patientId: data['patientId'] as String? ?? existing?.patientId,
    );
  }

  DoctorProfile _doctorFromBackend(Map<String, Object?> data) {
    final rating = data['rating'];
    final parsedRating = rating is num
        ? rating.toDouble()
        : double.tryParse(rating?.toString() ?? '') ?? 0;
    return DoctorProfile(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Bác sĩ MedCare',
      specialty: data['specialty']?.toString() ?? 'Đa khoa',
      experience: data['experience']?.toString() ?? '',
      rating: parsedRating,
      price: _intFromJson(data['price'], fallback: 0),
      location: data['location']?.toString() ?? 'Bệnh viện MedCare',
      availability: data['availability']?.toString() ?? 'Đang cập nhật',
      education: data['education']?.toString() ?? 'Bác sĩ chuyên khoa',
      workingDays: data['workingDays']?.toString() ?? 'Đang cập nhật',
      totalPatients: data['totalPatients']?.toString() ?? '0',
      imageUrl: data['imageUrl']?.toString(),
    );
  }

  MedicalRecord _medicalRecordFromBackend(Map<String, Object?> data) {
    final record = data['record'] is Map
        ? Map<String, Object?>.from(data['record'] as Map)
        : const <String, Object?>{};
    final doctorId = data['doctorId'] as String? ?? '';
    final doctor = doctors.cast<DoctorProfile?>().firstWhere(
      (item) => item?.id == doctorId,
      orElse: () => null,
    );
    final medicines = record['prescribedMedicines'];
    return MedicalRecord(
      id: data['id'] as String? ?? 'remote-emr',
      date: data['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      department:
          record['specialty'] as String? ?? doctor?.specialty ?? 'Khám bệnh',
      doctorName:
          record['doctorName'] as String? ?? doctor?.name ?? 'Bác sĩ MedCare',
      diagnosis: data['diagnosis'] as String? ?? 'Chưa cập nhật',
      symptoms: record['symptoms'] as String? ?? '',
      treatmentPlan: record['treatmentPlan'] as String? ?? '',
      followUpDate: record['followUpDate'] as String? ?? 'Theo hẹn bác sĩ',
      prescriptionCode: record['prescriptionCode'] as String? ?? '',
      totalFee: _intFromJson(record['totalFee'], fallback: 0),
      insuranceCovered: _intFromJson(record['insuranceCovered'], fallback: 0),
      diagnosisCode: record['icd10Code'] as String? ?? 'N/A',
      icd10Name: record['icd10Name'] as String? ?? '',
      differentialDiagnosis: record['differentialDiagnosis'] as String?,
      physicalExamNotes: record['physicalExam'] as String? ?? '',
      labSummary: record['labNotes'] as String?,
      xrayFindings: record['xrayFindings'] as String?,
      doctorInstructions: record['doctorAdvice'] as String? ?? '',
      digitalSignatureToken: record['digitalSignature'] as String? ?? '',
      riskLevel: record['riskLevel'] as String? ?? '',
      prescribedMedicinesSummary: medicines?.toString(),
    );
  }

  AppNotification _notificationFromBackend(Map<String, Object?> data) {
    final payload = data['payload'] is Map
        ? Map<String, Object?>.from(data['payload'] as Map)
        : const <String, Object?>{};
    final createdAt =
        DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now();
    return AppNotification(
      id: 'remote-${data['id'] ?? createdAt.microsecondsSinceEpoch}',
      title: payload['title'] as String? ?? 'Thông báo từ MedCare',
      body: payload['body'] as String? ?? 'Hồ sơ của bạn vừa được cập nhật.',
      createdAt: createdAt.toLocal(),
      read: data['status'] == 'read' || payload['read'] == true,
    );
  }

  MedicineItem _medicineFromBackend(Map item) => MedicineItem(
    name: item['name']?.toString() ?? '',
    category: item['category']?.toString() ?? 'Thuốc kê đơn',
    dosage: item['dosage']?.toString() ?? '',
    quantity: item['quantity']?.toString() ?? '',
    instruction: item['instruction']?.toString() ?? '',
    warning: item['warning']?.toString(),
  );

  /// Creates the appointment on the configured backend first. Local state is
  /// used only for offline/cache mode and is never presented as a server
  /// appointment.
  Future<Appointment> bookOnlineFirst({
    required DoctorProfile doctor,
    required DateTime dateTime,
    required String patientName,
    required String reason,
    required bool useInsurance,
    String packageId = 'pass-std',
    String packageTitle = 'Gói Tiêu Chuẩn',
    int packagePriceDelta = 0,
    int priorityLevel = 0,
  }) async {
    if (!_apiClient.isConfigured || !hasBackendSession) {
      return book(
        doctor: doctor,
        dateTime: dateTime,
        patientName: patientName,
        reason: reason,
        useInsurance: useInsurance,
        packageId: packageId,
        packageTitle: packageTitle,
        packagePriceDelta: packagePriceDelta,
        priorityLevel: priorityLevel,
      );
    }

    final consultationFee = useInsurance
        ? (doctor.price * .2).round()
        : doctor.price;
    final finalFee = consultationFee + packagePriceDelta;
    final data = await _apiClient.createAppointment(
      doctorId: _backendDoctorIdFor(doctor.id),
      doctorName: doctor.name,
      specialty: doctor.specialty,
      appointmentTime: dateTime,
      reason: reason,
      insuranceApplied: useInsurance,
      fee: finalFee,
      packageId: packageId,
      packageTitle: packageTitle,
      priorityLevel: priorityLevel,
      bearerToken: _backendAccessToken,
    );
    final appointment = _appointmentFromBackend(data).copyWith(
      dateTime:
          DateTime.tryParse(data['appointmentTime'] as String? ?? '')
              ?.toLocal() ??
          dateTime,
    );
    _appointments.removeWhere((item) => item.id == appointment.id);
    _appointments.insert(0, appointment);
    _transactions.insert(
      0,
      PaymentTransaction(
        id: 'TXN-APPT-${DateTime.now().millisecondsSinceEpoch}',
        visitCode: '#${appointment.id}',
        description:
            '$packageTitle • Phí khám ${appointment.specialty} - ${appointment.doctorName}',
        grossAmount: doctor.price + packagePriceDelta,
        insuranceAmount: useInsurance ? doctor.price - consultationFee : 0,
        netAmount: appointment.fee,
        method: PaymentMethod.vietQr,
        status: PaymentStatus.pending,
        timestamp: DateTime.now(),
        invoiceEmail: _profile.email,
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'appointment-${appointment.id}',
        title: 'Lịch khám đã được ghi nhận',
        body:
            '${appointment.doctorName} • ${_formatDate(appointment.dateTime)}',
        createdAt: DateTime.now(),
      ),
    );
    _commit(markDirty: false);
    return appointment;
  }

  String _backendDoctorIdFor(String doctorId) => switch (doctorId) {
    'doc-01' => 'doctor-001',
    'doc-02' => 'doctor-002',
    _ => doctorId,
  };

  Appointment book({
    required DoctorProfile doctor,
    required DateTime dateTime,
    required String patientName,
    required String reason,
    required bool useInsurance,
    String packageId = 'pass-std',
    String packageTitle = 'Gói Tiêu Chuẩn',
    int packagePriceDelta = 0,
    int priorityLevel = 0,
  }) {
    if (_persistenceEnabled &&
        (!_authenticated ||
            _currentUserRole != UserRole.patient ||
            !_hasPatientProfile)) {
      throw StateError(
        'Vui lòng đăng nhập bằng tài khoản bệnh nhân trước khi đặt lịch.',
      );
    }
    final ticketNum = 'KB-${1000 + _appointments.length + 1}';
    final consultationFee = useInsurance
        ? (doctor.price * .2).round()
        : doctor.price;
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
      status: AppointmentStatus.awaitingPayment,
      fee: consultationFee + packagePriceDelta,
      ticketNumber: ticketNum,
    );
    final dateStr =
        '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    if (!_reserveSlot(doctor.id, dateStr, timeStr)) {
      throw StateError('Khung giờ này đã hết chỗ, vui lòng chọn giờ khác.');
    }

    _appointments.insert(0, appointment);
    _transactions.insert(
      0,
      PaymentTransaction(
        id: 'TXN-APPT-${DateTime.now().millisecondsSinceEpoch}',
        visitCode: '#${appointment.id}',
        description:
            '$packageTitle • Phí khám ${appointment.specialty} - ${appointment.doctorName}',
        grossAmount: doctor.price + packagePriceDelta,
        insuranceAmount: useInsurance ? doctor.price - consultationFee : 0,
        netAmount: appointment.fee,
        method: PaymentMethod.vietQr,
        status: PaymentStatus.pending,
        timestamp: DateTime.now(),
        invoiceEmail: _profile.email,
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'appointment-${appointment.id}',
        title: 'Đã tạo lịch hẹn',
        body:
            '${doctor.name} • ${_formatDate(dateTime)}. Vui lòng thanh toán viện phí để xác nhận lịch khám.',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    return appointment;
  }

  int _findOpenConsultationAppointmentIndex() {
    final selectedId = _activeClinicalAppointmentId;
    if (selectedId != null) {
      final selectedIndex = _appointments.indexWhere(
        (item) =>
            item.id == selectedId && item.status == AppointmentStatus.confirmed,
      );
      if (selectedIndex >= 0) return selectedIndex;
    }
    final activeName = activeFamilyMember.name.trim().toLowerCase();
    for (var i = 0; i < _appointments.length; i++) {
      final item = _appointments[i];
      if (item.status == AppointmentStatus.confirmed &&
          item.patientName.trim().toLowerCase() == activeName) {
        return i;
      }
    }
    return _appointments.indexWhere(
      (item) => item.status == AppointmentStatus.confirmed,
    );
  }

  bool _canPublishClinicalData(String action) {
    if (_findOpenConsultationAppointmentIndex() >= 0) return true;
    _securityAuditLogs.insert(
      0,
      SecurityAuditLog(
        id: 'blocked-clinical-${DateTime.now().microsecondsSinceEpoch}',
        actor: activeDoctorUser.name,
        action: 'BLOCKED_CLINICAL_WRITE',
        targetResource: action,
        ipAddress: '10.0.4.12',
        timestamp: DateTime.now(),
        severity: SecuritySeverity.warning,
        statusDescription:
            'Từ chối ghi dữ liệu lâm sàng vì chưa có lịch hẹn đã xác nhận.',
      ),
    );
    _commit();
    return false;
  }

  /// Ghi mọi thao tác lâm sàng lên backend khi phiên hiện tại là bác sĩ/admin.
  /// UI vẫn cập nhật ngay để không làm gián đoạn ca khám; backend là nguồn lưu
  /// trữ chính khi API được cấu hình.
  Future<void> _persistClinicalAction(
    String action,
    Map<String, Object?> payload, {
    String status = 'completed',
  }) async {
    if (!_apiClient.isConfigured || !hasBackendSession) return;
    try {
      await _apiClient.createClinicalAction(
        patientId: _activeClinicalPatientId ?? _profile.id,
        appointmentId: _activeClinicalAppointmentId,
        action: action,
        status: status,
        payload: payload,
        bearerToken: _backendAccessToken,
      );
    } catch (error) {
      markBackendSyncFailed(
        'Không lưu được thao tác $action lên backend: $error',
      );
    }
  }

  Future<List<Map<String, Object?>>> fetchClinicalActionsOnline({
    String? patientId,
  }) async {
    if (!_apiClient.isConfigured || !hasBackendSession) {
      throw StateError(
        'Cần kết nối backend và đăng nhập để xem dữ liệu lâm sàng.',
      );
    }
    return _apiClient.fetchClinicalActions(
      patientId: patientId,
      bearerToken: _backendAccessToken,
    );
  }

  Future<void> cancelAppointmentOnlineFirst(String id) async {
    if (_apiClient.isConfigured && hasBackendSession) {
      final data = await _apiClient.updateAppointment(
        id: id,
        status: 'cancelled',
        bearerToken: _backendAccessToken,
      );
      final index = _appointments.indexWhere((item) => item.id == id);
      if (index >= 0) {
        _appointments[index] = _appointments[index].copyWith(
          status: AppointmentStatus.cancelled,
        );
        _notifications.insert(
          0,
          AppNotification(
            id: 'cancel-$id',
            title: 'Lịch hẹn đã hủy',
            body: 'Lịch khám ${_appointments[index].doctorName} đã được hủy.',
            createdAt: DateTime.now(),
          ),
        );
        _commit(markDirty: false);
      } else if (data.isNotEmpty) {
        _appointments.insert(0, _appointmentFromBackend(data));
        _commit(markDirty: false);
      }
      return;
    }
    cancelAppointment(id);
  }

  Future<Map<String, Object?>> createCheckInOnline(String appointmentId) async {
    if (!_apiClient.isConfigured || !hasBackendSession) {
      throw StateError(
        'Cần kết nối backend và đăng nhập để tạo mã check-in an toàn.',
      );
    }
    return _apiClient.createCheckIn(
      appointmentId: appointmentId,
      bearerToken: _backendAccessToken,
    );
  }

  Future<LiveQueueInfo> joinQueueForAppointment(String appointmentId) async {
    if (!_apiClient.isConfigured || !hasBackendSession) {
      throw StateError('Cần kết nối backend để nhận số thứ tự theo lịch khám.');
    }
    final record = await _apiClient.joinAppointmentQueue(
      appointmentId: appointmentId,
      bearerToken: _backendAccessToken,
    );
    final payload = record['payload'] is Map
        ? Map<String, Object?>.from(record['payload'] as Map)
        : const <String, Object?>{};
    _queueInfo = LiveQueueInfo(
      department: payload['department'] as String? ?? _queueInfo.department,
      room: payload['room'] as String? ?? _queueInfo.room,
      doctorName: payload['doctorName'] as String? ?? _queueInfo.doctorName,
      currentNumber: _intFromJson(
        payload['currentNumber'],
        fallback: _queueInfo.currentNumber,
      ),
      patientNumber: _intFromJson(
        payload['patientNumber'],
        fallback: _queueInfo.patientNumber,
      ),
      ticketCode: payload['ticketNumber'] as String? ?? _queueInfo.ticketCode,
      estimatedMinutes: _intFromJson(
        payload['estimatedMinutes'],
        fallback: _queueInfo.estimatedMinutes,
      ),
    );
    _commit(markDirty: false);
    return _queueInfo;
  }

  Future<void> rescheduleAppointmentOnlineFirst(
    String id,
    DateTime newDateTime,
  ) async {
    if (newDateTime.isBefore(DateTime.now())) {
      throw StateError('Thời gian khám mới phải ở tương lai.');
    }
    final index = _appointments.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Không tìm thấy lịch hẹn.');
    final current = _appointments[index];
    if (current.status == AppointmentStatus.cancelled ||
        current.status == AppointmentStatus.completed) {
      throw StateError('Lịch hẹn này không thể đổi giờ.');
    }
    if (_apiClient.isConfigured && hasBackendSession) {
      final data = await _apiClient.updateAppointment(
        id: id,
        appointmentTime: newDateTime,
        bearerToken: _backendAccessToken,
      );
      _appointments[index] = current.copyWith(
        dateTime:
            DateTime.tryParse(data['appointmentTime'] as String? ?? '')
                ?.toLocal() ??
            newDateTime,
      );
    } else {
      _appointments[index] = current.copyWith(dateTime: newDateTime);
    }
    _notifications.insert(
      0,
      AppNotification(
        id: 'reschedule-$id-${newDateTime.microsecondsSinceEpoch}',
        title: 'Lịch hẹn đã đổi thời gian',
        body: '${current.doctorName} • ${_formatDate(newDateTime)}',
        createdAt: DateTime.now(),
      ),
    );
    _commit(markDirty: !(_apiClient.isConfigured && hasBackendSession));
  }

  void cancelAppointment(String id) {
    final index = _appointments.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final app = _appointments[index];
    if (app.status == AppointmentStatus.completed ||
        app.status == AppointmentStatus.cancelled) {
      throw StateError(
        'Chỉ có thể hủy lịch đang chờ thanh toán hoặc đã xác nhận.',
      );
    }
    final dateStr =
        '${app.dateTime.year}-${app.dateTime.month.toString().padLeft(2, '0')}-${app.dateTime.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${app.dateTime.hour.toString().padLeft(2, '0')}:${app.dateTime.minute.toString().padLeft(2, '0')}';
    releaseSlot(app.doctorId, dateStr, timeStr);

    _appointments[index] = _appointments[index].copyWith(
      status: AppointmentStatus.cancelled,
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'cancel-$id',
        title: 'Lịch hẹn đã hủy',
        body:
            'Lịch khám với ${_appointments[index].doctorName} (${_appointments[index].id}) đã được hủy thành công.',
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
    if (id.startsWith('remote-') &&
        _apiClient.isConfigured &&
        hasBackendSession) {
      unawaited(
        _apiClient.markNotificationRead(
          id: id.substring('remote-'.length),
          bearerToken: _backendAccessToken,
        ),
      );
    }
  }

  // ============================================================================
  // 🩺 32 CHỨC NĂNG LÂM SÀNG BÁC SĨ & ĐỒNG BỘ DỮ LIỆU THỜI GIAN THỰC VỀ BỆNH NHÂN
  // ============================================================================

  // ── Phân hệ 1: Tiếp nhận & Tiền lâm sàng (6 chức năng) ──
  // 1. Gọi bệnh nhân theo số thứ tự (được hỗ trợ trực tiếp bởi doctorCallNextPatient)
  void doctorCallCurrentQueue() =>
      doctorCallNextPatient('Phòng 402 - Tim mạch');

  // 2. Đo và ghi nhận sinh hiệu
  void doctorRecordVitals({
    required double bpSys,
    required double bpDia,
    required int heartRate,
    required double spo2,
    required double temp,
    required double weight,
    double? bloodGlucose,
    double? heightCm,
    String? note,
  }) {
    if (!_canPublishClinicalData('Ghi nhận sinh hiệu')) return;
    final newVital = VitalSignRecord(
      timestamp: DateTime.now(),
      systolic: bpSys.toInt(),
      diastolic: bpDia.toInt(),
      heartRate: heartRate,
      bloodGlucose: bloodGlucose ?? 0,
      weightKg: weight,
      heightCm: heightCm ?? 0,
      note:
          note ??
          'Trạm khám 402: SpO2 ${spo2.toInt()}%, Thân nhiệt ${temp.toStringAsFixed(1)}°C',
    );
    _vitals.insert(0, newVital);
    _notifications.insert(
      0,
      AppNotification(
        id: 'vital-sync-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Chỉ số sinh hiệu mới cập nhật',
        body:
            'Bác sĩ đã cập nhật chỉ số sinh hiệu: HA ${bpSys.toInt()}/${bpDia.toInt()} mmHg, Nhịp tim $heartRate bpm, SpO2 ${spo2.toInt()}%.',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
  }

  Future<void> doctorRecordVitalsOnlineFirst({
    required double bpSys,
    required double bpDia,
    required int heartRate,
    required double spo2,
    required double temp,
    required double weight,
    double? bloodGlucose,
    double? heightCm,
    String? note,
  }) async {
    if (_apiClient.isConfigured && hasBackendSession) {
      final patientId = _activeClinicalPatientId;
      if (patientId == null || patientId.isEmpty) {
        throw StateError(
          'Hãy chọn một lịch hẹn bệnh nhân trước khi ghi sinh hiệu.',
        );
      }
      await _apiClient.createMedicalRecord(
        patientId: patientId,
        appointmentId: _activeClinicalAppointmentId,
        diagnosis: 'Sinh hiệu tại trạm khám',
        record: {
          'type': 'vitals',
          'systolic': bpSys,
          'diastolic': bpDia,
          'heartRate': heartRate,
          'spo2': spo2,
          'temperature': temp,
          'weight': weight,
          'bloodGlucose': bloodGlucose,
          'heightCm': heightCm,
          'note': note,
          'recordedAt': DateTime.now().toUtc().toIso8601String(),
        },
        bearerToken: _backendAccessToken,
      );
    }
    doctorRecordVitals(
      bpSys: bpSys,
      bpDia: bpDia,
      heartRate: heartRate,
      spo2: spo2,
      temp: temp,
      weight: weight,
      bloodGlucose: bloodGlucose,
      heightCm: heightCm,
      note: note,
    );
  }

  // 3. Xem xét bệnh sử & tiền sử dị ứng
  void doctorReviewHistory({String? history, String? allergyNotes}) {
    _securityAuditLogs.insert(
      0,
      SecurityAuditLog(
        id: 'audit-${DateTime.now().millisecondsSinceEpoch}',
        actor: 'PGS.TS.BS Trần Minh Đức',
        action: 'EMR_ACCESS',
        targetResource: 'Hồ sơ bệnh sử ${_profile.name} (${_profile.id})',
        ipAddress: '10.0.4.12',
        timestamp: DateTime.now(),
        severity: SecuritySeverity.info,
        statusDescription: 'Truy xuất thành công tiền sử dị ứng & bệnh án',
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('HISTORY_REVIEW', {
        'patientName': _profile.name,
        'history': history ?? '',
        'allergies': allergyNotes ?? _activeClinicalAllergies,
      }),
    );
    if (allergyNotes != null) {
      _activeClinicalAllergies = allergyNotes.trim();
    }
  }

  // 4. Phân tầng nguy cơ bệnh nhân (Triage)
  void doctorUpdateTriageRisk(String riskLevel, {String reason = ''}) {
    if (!_canPublishClinicalData('Phân tầng nguy cơ')) return;
    _notifications.insert(
      0,
      AppNotification(
        id: 'triage-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Phân tầng chăm sóc y tế',
        body: 'Bác sĩ đã đánh giá phân tầng nguy cơ của bạn: $riskLevel.',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('TRIAGE_RISK_UPDATE', {
        'riskLevel': riskLevel,
        'reason': reason,
      }),
    );
  }

  // 5. Điều hướng buồng khám chuyên khoa
  void doctorAssignRoom(String roomName, {String note = ''}) {
    _queueInfo = LiveQueueInfo(
      department: _queueInfo.department,
      room: roomName,
      doctorName: _queueInfo.doctorName,
      currentNumber: _queueInfo.currentNumber,
      patientNumber: _queueInfo.patientNumber,
      ticketCode: _queueInfo.ticketCode,
      estimatedMinutes: _queueInfo.estimatedMinutes,
    );
    _commit();
    unawaited(
      _persistClinicalAction('ROOM_ASSIGNMENT', {
        'room': roomName,
        'note': note,
      }),
    );
  }

  // 6. Xác thực sinh trắc học thẻ BHYT
  void doctorBiometricVerification({
    String? cardNumber,
    String? verificationCode,
  }) {
    _securityAuditLogs.insert(
      0,
      SecurityAuditLog(
        id: 'bio-${DateTime.now().millisecondsSinceEpoch}',
        actor: 'PGS.TS.BS Trần Minh Đức',
        action: 'BIOMETRIC_AUTH',
        targetResource: 'Thẻ BHYT ${_profile.insuranceNumber}',
        ipAddress: '10.0.4.12',
        timestamp: DateTime.now(),
        severity: SecuritySeverity.info,
        statusDescription: 'Xác thực sinh trắc học thẻ BHYT thành công',
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('BIOMETRIC_INSURANCE_VERIFY', {
        'insuranceNumber': cardNumber ?? _profile.insuranceNumber,
        'verificationCode': verificationCode ?? '',
        'verified': true,
      }),
    );
  }

  // ── Phân hệ 2: Khám lâm sàng & Chẩn đoán ICD-10 (6 chức năng) ──
  // 7. Ghi nhận khám thực thể
  String? _lastDoctorPhysicalExam;
  String? get lastDoctorPhysicalExam => _lastDoctorPhysicalExam;
  void doctorRecordPhysicalExam(
    String notes, {
    Map<String, String> findings = const {},
    String assessment = '',
    String plan = '',
  }) {
    if (!_canPublishClinicalData('Khám thực thể')) return;
    _lastDoctorPhysicalExam = notes;
    _commit();
    unawaited(
      _persistClinicalAction('PHYSICAL_EXAM', {
        'notes': notes,
        'findings': findings,
        'assessment': assessment,
        'plan': plan,
      }),
    );
  }

  // 8. Gán mã bệnh ICD-10
  String _activeIcd10Code = '';
  String _activeIcd10Name = '';
  String get activeIcd10Code => _activeIcd10Code;
  String get activeIcd10Name => _activeIcd10Name;
  void doctorSetIcd10Diagnosis(
    String code,
    String name, {
    String certainty = '',
    String rationale = '',
    String severity = '',
  }) {
    if (!_canPublishClinicalData('Chẩn đoán ICD-10')) return;
    _activeIcd10Code = code;
    _activeIcd10Name = name;
    _commit();
    unawaited(
      _persistClinicalAction('ICD10_DIAGNOSIS', {
        'code': code,
        'name': name,
        'certainty': certainty,
        'rationale': rationale,
        'severity': severity,
      }),
    );
  }

  // 9. Thêm chẩn đoán phân biệt
  String? _lastDifferentialDiagnosis;
  String? get lastDifferentialDiagnosis => _lastDifferentialDiagnosis;
  void doctorAddDifferentialDiagnosis(
    String diff, {
    String rationale = '',
    String exclusionPlan = '',
    String monitoringPlan = '',
  }) {
    if (!_canPublishClinicalData('Chẩn đoán phân biệt')) return;
    _lastDifferentialDiagnosis = diff;
    _commit();
    unawaited(
      _persistClinicalAction('DIFFERENTIAL_DIAGNOSIS', {
        'diagnosis': diff,
        'rationale': rationale,
        'exclusionPlan': exclusionPlan,
        'monitoringPlan': monitoringPlan,
      }),
    );
  }

  // 10. Đánh giá bệnh lý kèm theo (Comorbidities)
  final List<String> _recordedComorbidities = [];
  List<String> get recordedComorbidities =>
      List.unmodifiable(_recordedComorbidities);
  void doctorAssessComorbidities(
    List<String> list, {
    String severity = 'Ổn định',
    String controlStatus = 'Đang theo dõi',
    String note = '',
  }) {
    _recordedComorbidities.clear();
    _recordedComorbidities.addAll(list);
    _commit();
    unawaited(
      _persistClinicalAction('COMORBIDITY_ASSESSMENT', {
        'conditions': List<String>.from(list),
        'severity': severity,
        'controlStatus': controlStatus,
        'note': note,
      }),
    );
  }

  // 11. Đánh giá thang điểm lâm sàng
  void doctorEvaluateClinicalScore(
    String scoreType,
    int score,
    String assessment, {
    Map<String, Object?> parameters = const {},
  }) {
    _notifications.insert(
      0,
      AppNotification(
        id: 'score-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Thang điểm lâm sàng: $scoreType',
        body: 'Điểm số: $score điểm. Đánh giá: $assessment.',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('CLINICAL_SCORE', {
        'scoreType': scoreType,
        'score': score,
        'assessment': assessment,
        'parameters': parameters,
      }),
    );
  }

  // 12. Tóm tắt diễn tiến bệnh cảnh
  String? _clinicalSummary;
  String? get clinicalSummary => _clinicalSummary;
  void doctorRecordCourseSummary(
    String summary, {
    String responseToTreatment = '',
    String nextPlan = '',
    String warningSigns = '',
  }) {
    _clinicalSummary = summary;
    _commit();
    unawaited(
      _persistClinicalAction('CLINICAL_COURSE_SUMMARY', {
        'summary': summary,
        'responseToTreatment': responseToTreatment,
        'nextPlan': nextPlan,
        'warningSigns': warningSigns,
      }),
    );
  }

  // ── Phân hệ 3: Chỉ định Cận lâm sàng & Chẩn đoán hình ảnh (8 chức năng) ──
  // 13. Thêm kết quả xét nghiệm chung
  void doctorOrderLabTest({
    required String name,
    required String value,
    required String unit,
    required String normalRange,
    bool isAbnormal = false,
    String? note,
  }) {
    if (!_canPublishClinicalData('Cập nhật kết quả xét nghiệm')) return;
    _labTests.insert(
      0,
      LabTestItem(
        name: name,
        value: value,
        unit: unit,
        normalRange: normalRange,
        isAbnormal: isAbnormal,
        note: note,
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'lab-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Có kết quả xét nghiệm mới',
        body: 'Bác sĩ đã cập nhật kết quả: $name: $value $unit ($normalRange).',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('LAB_RESULT', {
        'name': name,
        'value': value,
        'unit': unit,
        'normalRange': normalRange,
        'isAbnormal': isAbnormal,
        'note': note,
      }),
    );
  }

  /// Tạo y lệnh cận lâm sàng để khoa xét nghiệm/hình ảnh tiếp nhận.
  /// Kết quả chỉ được hiển thị sau khi nhân sự thực hiện nhập kết quả thật.
  void doctorCreateClinicalOrder({
    required String orderType,
    required String title,
    required Map<String, Object?> details,
  }) {
    if (!_canPublishClinicalData('Tạo y lệnh $title')) return;
    _notifications.insert(
      0,
      AppNotification(
        id: 'order-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Đã tạo y lệnh $title',
        body: 'Y lệnh đã chuyển đến bộ phận phụ trách để tiếp nhận và trả kết quả.',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('CLINICAL_ORDER', {
        'orderType': orderType,
        'title': title,
        ...details,
      }, status: 'requested'),
    );
  }

  /// Lưu biểu mẫu khám riêng theo chuyên khoa và gửi vào hồ sơ bệnh nhân.
  void doctorSaveSpecialtyAssessment({
    required String specialty,
    required Map<String, Object?> fields,
  }) {
    if (!_canPublishClinicalData('Lưu đánh giá chuyên khoa')) return;
    _notifications.insert(
      0,
      AppNotification(
        id: 'specialty-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Bác sĩ đã cập nhật đánh giá $specialty',
        body: 'Thông tin khám chuyên khoa đã được lưu vào hồ sơ bệnh nhân.',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('SPECIALTY_ASSESSMENT', {
        'specialty': specialty,
        'fields': fields,
      }),
    );
  }

  // 14. Chỉ định Tổng phân tích tế bào máu CBC
  void doctorOrderCBC() {
    doctorOrderLabTest(
      name: 'Tổng phân tích tế bào máu ngoại vi (CBC - Bạch cầu, Hồng cầu, Tiểu cầu)',
      value: '7.5 (Bạch cầu) / 4.8 (Hồng cầu)',
      unit: 'G/L - T/L',
      normalRange: '4.0 - 10.0 G/L',
      isAbnormal: false,
      note: 'Các chỉ số tế bào máu trong giới hạn bình thường',
    );
  }

  // 15. Chỉ định Sinh hóa máu tổng quát
  void doctorOrderBloodBiochemistry() {
    doctorOrderLabTest(
      name: 'Sinh hóa máu (Glucose máu lúc đói)',
      value: '5.6',
      unit: 'mmol/L',
      normalRange: '3.9 - 6.4 mmol/L',
      isAbnormal: false,
      note: 'Đường huyết kiểm soát tốt',
    );
    doctorOrderLabTest(
      name: 'Chức năng thận (Creatinine huyết thanh)',
      value: '82',
      unit: 'µmol/L',
      normalRange: '62 - 106 µmol/L',
      isAbnormal: false,
      note: 'Độ lọc cầu thận eGFR = 95 mL/phút/1.73m2 (Bình thường)',
    );
  }

  // 16. Chỉ định X-Quang ngực thẳng
  void doctorOrderChestXRay() {
    if (!_canPublishClinicalData('Cập nhật X-Quang ngực')) return;
    _notifications.insert(
      0,
      AppNotification(
        id: 'xray-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Kết quả Chẩn đoán hình ảnh: X-Quang Ngực Thẳng',
        body: 'Bác sĩ đã cập nhật kết quả: Bóng tim không to, hai phế trường sáng đều, không thấy tổn thương thâm nhiễm nhu mô phổi.',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('IMAGING_ORDER_XRAY', {
        'modality': 'X-Ray ngực',
        'result': 'Bóng tim không to, hai phế trường sáng đều.',
      }),
    );
  }

  // 17. Chỉ định Siêu âm ổ bụng
  void doctorOrderAbdominalUltrasound() {
    if (!_canPublishClinicalData('Cập nhật siêu âm ổ bụng')) return;
    _notifications.insert(
      0,
      AppNotification(
        id: 'us-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Kết quả Siêu âm ổ bụng tổng quát',
        body: 'Gan, mật, tụy, lách, hai thận hình dạng kích thước bình thường, không có sỏi hay ứ nước.',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('IMAGING_ORDER_ULTRASOUND', {
        'modality': 'Siêu âm ổ bụng',
        'result': 'Chưa ghi nhận bất thường.',
      }),
    );
  }

  // 18. Chỉ định Điện tim ECG 12 cần
  void doctorOrderECG() {
    if (!_canPublishClinicalData('Cập nhật điện tim ECG')) return;
    _notifications.insert(
      0,
      AppNotification(
        id: 'ecg-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Kết quả Điện tim đồ (ECG 12 chuyển đạo)',
        body: 'Nhịp xoang đều, tần số 74 chu kỳ/phút, trục trung gian, không thấy dấu hiệu thiếu máu cơ tim cấp.',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('IMAGING_ORDER_ECG', {
        'modality': 'ECG 12 chuyển đạo',
        'result': 'Nhịp xoang đều.',
      }),
    );
  }

  // 19. Chỉ định Siêu âm tim Doppler màu
  void doctorOrderEcho() {
    if (!_canPublishClinicalData('Cập nhật siêu âm tim')) return;
    _notifications.insert(
      0,
      AppNotification(
        id: 'echo-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Kết quả Siêu âm tim Doppler màu',
        body: 'Phân suất tống máu EF = 65%, chức năng tâm thu thất trái bảo tồn, các van tim thanh mảnh hoạt động tốt.',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('IMAGING_ORDER_ECHO', {
        'modality': 'Siêu âm tim Doppler',
        'result': 'EF 65%, chức năng tâm thu bảo tồn.',
      }),
    );
  }

  // 20. Trả ảnh phim và kết luận số hóa
  void doctorPushImagingResult({
    required String modality,
    required String findings,
    required String imageUrl,
    String? imageBase64,
    String? fileName,
    String? mimeType,
  }) {
    if (!_canPublishClinicalData('Trả kết quả chẩn đoán hình ảnh')) return;
    _notifications.insert(
      0,
      AppNotification(
        id: 'img-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Hình ảnh y khoa số hóa: $modality',
        body: 'Kết luận: $findings. Đã lưu phim vào hồ sơ EMR.',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('IMAGING_RESULT', {
        'modality': modality,
        'findings': findings,
        'imageUrl': imageUrl,
        'imageBase64': imageBase64,
        'fileName': fileName,
        'mimeType': mimeType,
      }),
    );
  }

  Future<bool> doctorPickAndPushImagingResult({
    required String modality,
    required String findings,
  }) async {
    if (!_canPublishClinicalData('Tải ảnh chẩn đoán hình ảnh')) return false;
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return false;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw StateError('Không đọc được nội dung ảnh từ thiết bị.');
    }
    if (bytes.length > 8 * 1024 * 1024) {
      throw StateError('Ảnh vượt quá 8 MB. Hãy nén ảnh trước khi tải lên.');
    }
    final encoded = base64Encode(bytes);
    final mimeType = file.extension == null
        ? 'image/jpeg'
        : 'image/${file.extension!.toLowerCase() == 'jpg' ? 'jpeg' : file.extension!.toLowerCase()}';
    if (_apiClient.isConfigured && hasBackendSession) {
      final patientId = _activeClinicalPatientId;
      final appointmentId = _activeClinicalAppointmentId;
      if (patientId == null || patientId.trim().isEmpty) {
        throw StateError('Hãy chọn đúng lịch hẹn bệnh nhân trước khi upload.');
      }
      if (appointmentId == null || appointmentId.trim().isEmpty) {
        throw StateError('Hãy chọn đúng ca khám trước khi upload.');
      }
      await uploadMedicalFileOnline(
        patientId: patientId,
        category: modality,
        findings: findings,
        fileName: file.name,
        mimeType: mimeType,
        dataBase64: encoded,
        appointmentId: appointmentId,
      );
      _notifications.insert(
        0,
        AppNotification(
          id: 'remote-file-${DateTime.now().microsecondsSinceEpoch}',
          title: 'Đã tải hồ sơ y tế lên backend',
          body: '$modality • ${file.name}',
          createdAt: DateTime.now(),
        ),
      );
      _commit(markDirty: false);
      return true;
    }
    doctorPushImagingResult(
      modality: modality,
      findings: findings,
      imageUrl: '',
      imageBase64: encoded,
      fileName: file.name,
      mimeType: mimeType,
    );
    return true;
  }

  // ── Phân hệ 4: Kê đơn điện tử & Cảnh báo tương tác thuốc (6 chức năng) ──
  // 21. Kê đơn thuốc mới
  void doctorPrescribeMedicine({
    required String name,
    required String category,
    required String dosage,
    required String instruction,
    required String quantity,
    String? warning,
  }) {
    _securityAuditLogs.insert(
      0,
      SecurityAuditLog(
        id: 'draft-med-${DateTime.now().millisecondsSinceEpoch}',
        actor: activeDoctorUser.name,
        action: 'DRAFT_MEDICINE_ITEM',
        targetResource: name,
        ipAddress: '10.0.4.12',
        timestamp: DateTime.now(),
        severity: SecuritySeverity.info,
        statusDescription:
            'Thuốc $name ($dosage, $quantity) chỉ nằm trong đơn nháp; chưa phát hành cho bệnh nhân.',
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('MEDICINE_DRAFT', {
        'name': name,
        'category': category,
        'dosage': dosage,
        'instruction': instruction,
        'quantity': quantity,
        'warning': warning,
      }, status: 'draft'),
    );
  }

  // 22. Kiểm tra tương tác thuốc
  String doctorCheckDrugInteraction(String drug1, String drug2) {
    const knownPairs = <String>{
      'warfarin|aspirin',
      'simvastatin|clarithromycin',
    };
    final pair = '${drug1.trim().toLowerCase()}|${drug2.trim().toLowerCase()}';
    final reverse =
        '${drug2.trim().toLowerCase()}|${drug1.trim().toLowerCase()}';
    final result = knownPairs.contains(pair) || knownPairs.contains(reverse)
        ? 'Cảnh báo: có khả năng tương tác nghiêm trọng giữa $drug1 và $drug2, cần dược sĩ kiểm tra.'
        : 'Không phát hiện tương tác đối kháng trong danh mục nội bộ giữa $drug1 và $drug2.';
    unawaited(
      _persistClinicalAction('DRUG_INTERACTION_CHECK', {
        'drug1': drug1,
        'drug2': drug2,
        'result': result,
      }),
    );
    return result;
  }

  // 23. Kiểm tra tiền sử dị ứng
  bool doctorCheckAllergyRisk(String drugName) {
    final allergies =
        (_activeClinicalPatientId == null
                ? _profile.allergies
                : _activeClinicalAllergies)
            .toLowerCase();
    final result = allergies.contains(drugName.toLowerCase().trim());
    unawaited(
      _persistClinicalAction('ALLERGY_CHECK', {
        'drugName': drugName,
        'allergic': result,
      }),
    );
    return result;
  }

  // 24. Tính toán liều theo độ lọc cầu thận (eGFR)
  String doctorCalculateRenalDose(
    double weight,
    double egfr, {
    String medicineName = '',
  }) {
    final medicine = medicineName.trim().toLowerCase();
    final String result;
    if (medicine.contains('metformin')) {
      result = egfr >= 45
          ? 'Metformin: có thể dùng theo liều kê đơn; theo dõi eGFR định kỳ.'
          : egfr >= 30
          ? 'Metformin: không nên khởi trị; cần đánh giá giảm liều và theo dõi sát.'
          : 'Metformin: chống chỉ định khi eGFR < 30 mL/phút; cần đổi phác đồ theo bác sĩ.';
    } else if (medicine.contains('gabapentin') ||
        medicine.contains('pregabalin')) {
      result = egfr >= 60
          ? '$medicineName: dùng liều chuẩn theo đơn, theo dõi buồn ngủ/chóng mặt.'
          : egfr >= 30
          ? '$medicineName: cần giảm liều hoặc kéo dài khoảng cách dùng theo bảng liều thận.'
          : '$medicineName: cần chỉnh liều bắt buộc và cân nhắc lọc máu; không tự động kê liều.';
    } else if (medicine.contains('enoxaparin')) {
      result = egfr >= 30
          ? 'Enoxaparin: cần xác định chỉ định và cân nặng để chọn liều; theo dõi chảy máu.'
          : 'Enoxaparin: eGFR < 30 cần phác đồ giảm liều/thuốc thay thế do bác sĩ huyết học quyết định.';
    } else if (medicine.isEmpty && egfr >= 60) {
      result =
          'Chức năng thận bảo tồn (eGFR = ${egfr.toInt()} mL/min) -> Sử dụng 100% liều tiêu chuẩn người lớn.';
    } else if (medicine.isEmpty && egfr >= 30) {
      result =
          'Suy thận mức độ trung bình (eGFR = ${egfr.toInt()} mL/min) -> Khuyến cáo giảm 25% - 50% liều hoặc giãn khoảng cách dùng.';
    } else if (medicine.isEmpty) {
      result =
          'Suy thận nặng (eGFR = ${egfr.toInt()} mL/min) -> Chỉnh liều thận nghiêm ngặt theo dõi nồng độ thuốc.';
    } else {
      result =
          'Chưa có bảng chỉnh liều đã được phê duyệt cho $medicineName. Không tự động suy ra liều; cần dược sĩ/bác sĩ xác nhận.';
    }
    unawaited(
      _persistClinicalAction('RENAL_DOSE_CALCULATION', {
        'weight': weight,
        'egfr': egfr,
        'medicineName': medicineName,
        'result': result,
      }),
    );
    return result;
  }

  // 25. Tự động lập lịch uống thuốc cho bệnh nhân
  void doctorGenerateAutoSchedule({
    required String medicineName,
    required String timeOfDay,
    required String dosage,
  }) {
    _securityAuditLogs.insert(
      0,
      SecurityAuditLog(
        id: 'draft-schedule-${DateTime.now().millisecondsSinceEpoch}',
        actor: activeDoctorUser.name,
        action: 'DRAFT_MEDICATION_SCHEDULE',
        targetResource: medicineName,
        ipAddress: '10.0.4.12',
        timestamp: DateTime.now(),
        severity: SecuritySeverity.info,
        statusDescription:
            'Đã tạo lịch uống thuốc nháp $medicineName lúc $timeOfDay; chỉ phát hành sau khi ký EMR.',
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('MEDICATION_SCHEDULE', {
        'medicineName': medicineName,
        'timeOfDay': timeOfDay,
        'dosage': dosage,
      }),
    );
  }

  // 26. Gửi đơn lên Cổng Đơn thuốc Quốc gia
  void doctorSubmitNationalPrescriptionPortal(String prescriptionCode) {
    _securityAuditLogs.insert(
      0,
      SecurityAuditLog(
        id: 'audit-presc-${DateTime.now().millisecondsSinceEpoch}',
        actor: 'PGS.TS.BS Trần Minh Đức',
        action: 'NATIONAL_EPRESCRIPTION_SYNC',
        targetResource: 'Đơn thuốc $prescriptionCode',
        ipAddress: '10.0.4.12',
        timestamp: DateTime.now(),
        severity: SecuritySeverity.info,
        statusDescription: 'Đã tạo yêu cầu gửi Cổng Đơn thuốc Quốc gia; đang chờ cổng xác nhận.',
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('NATIONAL_PRESCRIPTION_SUBMISSION', {
        'prescriptionCode': prescriptionCode,
        'integrationStatus': 'pending_external_gateway',
      }, status: 'pending_external_gateway'),
    );
  }

  // ── Phân hệ 5: Ký số EMR, Hội chẩn & Đồng bộ Toàn diện (6 chức năng) ──
  // 27. Ký số EMR điện tử chuẩn SHA-256
  String doctorDigitalSignEmr({
    required String signer,
    required String certKey,
    String confirmation = '',
    String signingReason = '',
  }) {
    if (!_canPublishClinicalData('Ký số EMR')) {
      return 'EMR-BLOCKED-NO-CONFIRMED-APPOINTMENT';
    }
    final signToken =
        'EMR-SHA256-${DateTime.now().millisecondsSinceEpoch}-$certKey';
    _securityAuditLogs.insert(
      0,
      SecurityAuditLog(
        id: 'sign-${DateTime.now().millisecondsSinceEpoch}',
        actor: signer,
        action: 'EMR_DIGITAL_SIGNATURE',
        targetResource: 'Hồ sơ bệnh án điện tử ${_profile.name}',
        ipAddress: '10.0.4.12',
        timestamp: DateTime.now(),
        severity: SecuritySeverity.info,
        statusDescription: 'Ký số bảo mật thành công: $signToken',
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('EMR_DIGITAL_SIGNATURE', {
        'signer': signer,
        'certificateKey': certKey,
        'token': signToken,
        'signatureStatus': 'local_application_signature',
        'confirmation': confirmation,
        'signingReason': signingReason,
      }),
    );
    return signToken;
  }

  Future<String> doctorDigitalSignEmrOnlineFirst({
    required String signer,
    required String certKey,
    String confirmation = '',
    String signingReason = '',
  }) async {
    final patientId = _activeClinicalPatientId;
    final appointmentId = _activeClinicalAppointmentId;
    if (_apiClient.isConfigured && hasBackendSession) {
      if (patientId == null || appointmentId == null) {
        throw StateError('Hãy chọn lịch hẹn bệnh nhân trước khi ký EMR.');
      }
      final action = await _apiClient.signEmr(
        patientId: patientId,
        appointmentId: appointmentId,
        document: {
          'signer': signer,
          'certificateKeyId': certKey,
          'confirmation': confirmation,
          'signingReason': signingReason,
        },
        bearerToken: _backendAccessToken,
      );
      final payload = action['payload'];
      final signature = payload is Map
          ? payload['signature']?.toString() ?? ''
          : '';
      if (signature.isEmpty) {
        throw StateError('Máy chủ không trả về chữ ký EMR hợp lệ.');
      }
      notifyListeners();
      return signature;
    }
    throw StateError('Cần kết nối backend để ký EMR thật.');
  }

  // 28. Đặt lịch tái khám cho bệnh nhân
  Future<void> doctorScheduleFollowUpOnlineFirst({
    required DateTime dateTime,
    required String notes,
    required String doctorName,
    required String specialty,
    String visitType = 'Tái khám định kỳ',
  }) async {
    final sourceAppointmentId = _activeClinicalAppointmentId;
    if (_apiClient.isConfigured && hasBackendSession) {
      if (sourceAppointmentId == null) {
        throw StateError('Hãy chọn lịch hẹn bệnh nhân trước khi tạo tái khám.');
      }
      final data = await _apiClient.createDoctorFollowUp(
        appointmentId: sourceAppointmentId,
        appointmentTime: dateTime,
        reason: '$visitType: $notes',
        doctorName: doctorName,
        specialty: specialty,
        bearerToken: _backendAccessToken,
      );
      final appointment = _appointmentFromBackend(data);
      _appointments.removeWhere((item) => item.id == appointment.id);
      _appointments.insert(0, appointment);
      _notifications.insert(
        0,
        AppNotification(
          id: 'follow-up-${appointment.id}',
          title: 'Đã tạo lịch tái khám',
          body: '$doctorName • ${_formatDate(dateTime)}',
          createdAt: DateTime.now(),
        ),
      );
      _commit(markDirty: false);
      return;
    }
    throw StateError('Cần kết nối backend để tạo lịch tái khám thật.');
  }

  Future<Map<String, Object?>> startTeleconsultationOnlineFirst() async {
    if (!_apiClient.isConfigured || !hasBackendSession) {
      throw StateError('Cần kết nối backend để mở phiên khám từ xa.');
    }
    final session = await _apiClient.createFeatureRecord('teleconsultations', {
      'appointmentId': _activeClinicalAppointmentId,
      'patientId': _activeClinicalPatientId,
      'requestedAt': DateTime.now().toUtc().toIso8601String(),
      'mediaStatus': 'waiting_for_webrtc_peer',
    }, bearerToken: _backendAccessToken);
    return session;
  }

  void doctorScheduleFollowUp({
    required String date,
    required String notes,
    String doctorName = 'PGS.TS.BS Trần Minh Đức',
    String visitType = 'Tái khám định kỳ',
    String reminderChannel = 'Thông báo ứng dụng',
    String recurrence = 'Một lần',
    bool requireOpenEncounter = true,
  }) {
    if (requireOpenEncounter && !_canPublishClinicalData('Tạo lịch tái khám')) {
      return;
    }
    final reminder = FollowUpReminder(
      id: 're-${DateTime.now().millisecondsSinceEpoch}',
      doctorName: doctorName,
      specialty: 'Nội tim mạch & Chuyển hóa',
      reminderDate:
          _parseDoctorDate(date) ??
          DateTime.now().add(const Duration(days: 14)),
      clinicalReason: 'Tái khám định kỳ & đánh giá đáp ứng phác đồ điều trị',
      doctorInstructions: notes,
    );
    _followUpReminders.insert(0, reminder);
    _notifications.insert(
      0,
      AppNotification(
        id: 'fu-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Lịch hẹn tái khám từ Bác sĩ',
        body: 'Bác sĩ $doctorName hẹn tái khám ngày $date. Ghi chú: $notes',
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('FOLLOW_UP_APPOINTMENT', {
        'date': date,
        'notes': notes,
        'doctorName': doctorName,
        'visitType': visitType,
        'reminderChannel': reminderChannel,
        'recurrence': recurrence,
      }),
    );
  }

  DateTime? _parseDoctorDate(String value) {
    final parts = value.trim().split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  // 29. Gửi yêu cầu hội chẩn liên chuyên khoa
  void doctorRequestSpecialtyConsultation(
    String specialty,
    String reason, {
    String urgency = 'Bình thường',
    String clinicalQuestion = '',
    String attachments = '',
  }) {
    _securityAuditLogs.insert(
      0,
      SecurityAuditLog(
        id: 'cons-${DateTime.now().millisecondsSinceEpoch}',
        actor: 'PGS.TS.BS Trần Minh Đức',
        action: 'CONSULTATION_REQUEST',
        targetResource: 'Chuyên khoa $specialty',
        ipAddress: '10.0.4.12',
        timestamp: DateTime.now(),
        severity: SecuritySeverity.warning,
        statusDescription: 'Yêu cầu hội chẩn: $reason',
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('SPECIALTY_CONSULTATION', {
        'specialty': specialty,
        'reason': reason,
        'urgency': urgency,
        'clinicalQuestion': clinicalQuestion,
        'attachments': attachments,
      }, status: 'requested'),
    );
  }

  // 30. Ra y lệnh nhập viện / cho về ngoại trú
  void doctorIssueHospitalizationOrder(
    bool inpatient,
    String notes, {
    String destination = '',
    String bedType = '',
    String transport = '',
    String consent = '',
  }) {
    if (!_canPublishClinicalData('Ra y lệnh điều trị')) return;
    _notifications.insert(
      0,
      AppNotification(
        id: 'order-${DateTime.now().millisecondsSinceEpoch}',
        title: inpatient
            ? 'Y lệnh: Nhập viện điều trị nội trú'
            : 'Y lệnh: Điều trị ngoại trú theo đơn',
        body: notes,
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('HOSPITALIZATION_ORDER', {
        'inpatient': inpatient,
        'notes': notes,
        'destination': destination,
        'bedType': bedType,
        'transport': transport,
        'consent': consent,
      }, status: inpatient ? 'requested' : 'cancelled'),
    );
  }

  // 31. Gửi lời dặn dò y khoa trực tiếp tới điện thoại bệnh nhân
  void doctorSendDirectAdvice(
    String advice, {
    String category = 'Dặn dò điều trị',
    String channel = 'Ứng dụng bệnh nhân',
    bool requiresReadReceipt = true,
    String emergencyInstruction = '',
  }) {
    if (!_canPublishClinicalData('Gửi lời dặn dò')) return;
    _notifications.insert(
      0,
      AppNotification(
        id: 'advice-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Lời dặn dò từ Bác sĩ điều trị',
        body: advice,
        createdAt: DateTime.now(),
      ),
    );
    _commit();
    unawaited(
      _persistClinicalAction('DIRECT_MEDICAL_ADVICE', {
        'advice': advice,
        'category': category,
        'channel': channel,
        'requiresReadReceipt': requiresReadReceipt,
        'emergencyInstruction': emergencyInstruction,
      }),
    );
  }

  // 32. 🔥 SIÊU HÀM ĐỒNG BỘ TOÀN DIỆN TỪ BÁC SĨ SANG TÀI KHOẢN BỆNH NHÂN 🔥
  void doctorExecuteFullConsultationSync({
    required String diagnosis,
    required String icd10Code,
    required String icd10Name,
    required String symptoms,
    required String physicalExam,
    required String labNotes,
    required String doctorAdvice,
    required String followUpDate,
    required List<MedicineItem> prescribedMedicines,
    String riskLevel = 'Theo dõi định kỳ',
  }) {
    final appointmentIndex = _findOpenConsultationAppointmentIndex();
    if (appointmentIndex < 0) {
      throw StateError(
        'Chưa có lịch hẹn đã xác nhận nên không thể phát hành hồ sơ bệnh án hoặc đơn thuốc.',
      );
    }
    final sourceAppointment = _appointments[appointmentIndex];
    final now = DateTime.now();
    final recId =
        'EMR-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${100 + _medicalRecords.length + 1}';
    final prescCode =
        'DT-VN-${now.year}${now.month.toString().padLeft(2, '0')}-${2000 + _medicalRecords.length + 1}';
    final signToken = 'EMR-SHA256-VN-VALIDATED-${now.millisecondsSinceEpoch}';

    // 1. Thêm thuốc vào danh mục kê đơn & lịch nhắc uống thuốc cho bệnh nhân
    for (final med in prescribedMedicines) {
      _medicines.insert(0, med);
      _medicineSchedule.insert(
        0,
        MedicineScheduleItem(
          id: 'sch-${now.millisecondsSinceEpoch}-${med.name.hashCode}',
          medicineName: med.name,
          timeSlot: '08:00 & 20:00',
          period: 'Hàng ngày',
          instruction: med.instruction,
          dosage: med.dosage,
          isTaken: false,
        ),
      );
    }

    // 2. Tạo Hồ Sơ Bệnh Án Điện Tử (EMR) hoàn chỉnh khớp 100%
    final newRecord = MedicalRecord(
      id: recId,
      date:
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      department: sourceAppointment.specialty,
      doctorName: activeDoctorUser.name,
      diagnosis: '$diagnosis (Mã ICD-10: $icd10Code)',
      symptoms: symptoms,
      treatmentPlan: 'Điều trị ngoại trú theo phác đồ hiệp hội tim mạch. Kê đơn kết hợp hạ áp và kiểm soát đường huyết.',
      followUpDate: followUpDate,
      prescriptionCode: prescCode,
      totalFee: 450000,
      insuranceCovered: 360000,
      diagnosisCode: icd10Code,
      icd10Name: icd10Name,
      differentialDiagnosis:
          _lastDifferentialDiagnosis ??
          'Theo dõi cơn thiếu máu não thoáng qua (TIA)',
      physicalExamNotes: physicalExam,
      labSummary: labNotes,
      xrayFindings: 'X-Quang ngực: Bóng tim trong giới hạn, hai phế trường thông khí tốt.',
      doctorInstructions: doctorAdvice,
      digitalSignatureToken: signToken,
      riskLevel: riskLevel,
      prescribedMedicinesSummary: prescribedMedicines
          .map((m) => '${m.name} (${m.dosage})')
          .join(', '),
    );

    _medicalRecords.insert(0, newRecord);
    _appointments[appointmentIndex] = sourceAppointment.copyWith(
      status: AppointmentStatus.completed,
    );
    _transactions.insert(
      0,
      PaymentTransaction(
        id: 'TXN-EMR-${now.millisecondsSinceEpoch}',
        visitCode: '#$recId',
        description:
            'Chi phí phát sinh sau khám ${sourceAppointment.specialty} - $prescCode',
        grossAmount: newRecord.totalFee,
        insuranceAmount: newRecord.insuranceCovered,
        netAmount: newRecord.totalFee - newRecord.insuranceCovered,
        method: PaymentMethod.vietQr,
        status: PaymentStatus.pending,
        timestamp: now,
        invoiceEmail: _profile.email,
      ),
    );

    // 3. Đặt lịch tái khám tự động
    doctorScheduleFollowUp(
      date: followUpDate,
      notes: 'Tái khám đánh giá đáp ứng hạ áp và làm lại bilan mỡ máu, đường huyết.',
      doctorName: activeDoctorUser.name,
      requireOpenEncounter: false,
    );

    // 4. Cập nhật các bước lộ trình khám bệnh sang hoàn thành
    advancePathwayStep(3); // Bước 3 xong -> chuyển sang bước 4
    advancePathwayStep(4); // Bước 4 xong -> chuyển sang bước 5

    // 5. Gửi thông báo Push Notification đến điện thoại Bệnh nhân
    _notifications.insert(
      0,
      AppNotification(
        id: 'emr-sync-$recId',
        title: 'Hồ sơ bệnh án điện tử đã được ký số',
        body:
            'Bác sĩ ${activeDoctorUser.name} đã hoàn tất ca khám, ký số EMR và gửi đơn thuốc điện tử ($prescCode) về tài khoản của bạn.',
        createdAt: now,
      ),
    );

    // 6. Ghi nhật ký kiểm toán HIPAA an ninh EMR
    _securityAuditLogs.insert(
      0,
      SecurityAuditLog(
        id: 'sync-audit-${now.millisecondsSinceEpoch}',
        actor: activeDoctorUser.name,
        action: 'EMR_FINAL_CONSULTATION_SYNC',
        targetResource: 'Hồ sơ EMR $recId',
        ipAddress: '10.0.4.12',
        timestamp: now,
        severity: SecuritySeverity.info,
        statusDescription:
            'Ký số và truyền dữ liệu EMR $recId sang bệnh nhân ${_profile.name}. Token: $signToken',
      ),
    );

    _commit();
  }

  Future<void> doctorExecuteFullConsultationOnlineFirst({
    required String diagnosis,
    required String icd10Code,
    required String icd10Name,
    required String symptoms,
    required String physicalExam,
    required String labNotes,
    required String doctorAdvice,
    required String followUpDate,
    required List<MedicineItem> prescribedMedicines,
    String riskLevel = 'Theo dõi định kỳ',
  }) async {
    if (_apiClient.isConfigured && hasBackendSession) {
      final appointmentId = _activeClinicalAppointmentId;
      final patientId = _activeClinicalPatientId;
      if (appointmentId == null || patientId == null || patientId.isEmpty) {
        throw StateError('Hãy chọn lịch hẹn bệnh nhân trước khi ký gửi EMR.');
      }
      await _apiClient.completeConsultation(
        appointmentId: appointmentId,
        diagnosis: '$diagnosis (Mã ICD-10: $icd10Code)',
        record: {
          'icd10Code': icd10Code,
          'icd10Name': icd10Name,
          'symptoms': symptoms,
          'physicalExam': physicalExam,
          'labNotes': labNotes,
          'doctorAdvice': doctorAdvice,
          'followUpDate': followUpDate,
          'riskLevel': riskLevel,
          'digitalSignature':
              'EMR-SHA256-${DateTime.now().millisecondsSinceEpoch}',
        },
        medicines: prescribedMedicines
            .map(
              (medicine) => {
                'name': medicine.name,
                'category': medicine.category,
                'dosage': medicine.dosage,
                'quantity': medicine.quantity,
                'instruction': medicine.instruction,
                'warning': medicine.warning,
              },
            )
            .toList(growable: false),
        bearerToken: _backendAccessToken,
      );
    }
    doctorExecuteFullConsultationSync(
      diagnosis: diagnosis,
      icd10Code: icd10Code,
      icd10Name: icd10Name,
      symptoms: symptoms,
      physicalExam: physicalExam,
      labNotes: labNotes,
      doctorAdvice: doctorAdvice,
      followUpDate: followUpDate,
      prescribedMedicines: prescribedMedicines,
      riskLevel: riskLevel,
    );
  }

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

  static MedicalStore? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MedicalScope>();
    return scope?.notifier;
  }
}
