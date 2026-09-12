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
  final List<FamilyMemberProfile> _familyMembers = List.from(MedicalData.initialFamilyMembers);
  String _activeFamilyMemberId = 'fam-01'; // Default: Bản thân
  final List<PharmacyOrder> _pharmacyOrders = List.from(MedicalData.initialPharmacyOrders);
  final List<LabTrendPoint> _labTrends = List.from(MedicalData.initialLabTrends);
  HospitalKpiData _hospitalKpi = MedicalData.initialHospitalKpi;
  TelemedicineSession? _currentTelemedicine;

  // ── Tính năng Mới Toàn Diện ──
  bool _isSeniorMode = false;
  final List<LabReportItem> _labReports = List.from(MedicalData.initialLabReports);
  final List<InsurancePolicy> _insurancePolicies = List.from(MedicalData.initialInsurancePolicies);
  final List<CashlessClaimRequest> _cashlessClaims = [];
  final List<AppointmentPassPackage> _appointmentPasses = List.from(MedicalData.initialAppointmentPasses);
  final List<FollowUpReminder> _followUpReminders = List.from(MedicalData.initialFollowUpReminders);
  final List<DoctorReview> _doctorReviews = List.from(MedicalData.initialDoctorReviews);
  final List<SecurityAuditLog> _securityAuditLogs = List.from(MedicalData.initialSecurityAuditLogs);
  final List<ActiveSessionInfo> _activeSessions = List.from(MedicalData.initialActiveSessions);
  bool _isEmergencyLockdown = false;
  int _walletBalance = 2500000;
  int _advanceDeposit = 1000000;
  final List<HospitalWalletTransaction> _walletTransactions = List.from(MedicalData.initialWalletTransactions);

  /// Map key = "doctorId_date_time" → SlotConfig
  final Map<String, SlotConfig> _slotConfigs = {
    for (final s in MedicalData.buildInitialSlotConfigs()) s.key: s
  };

  List<Appointment> get appointments => List.unmodifiable(_appointments);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<VitalSignRecord> get vitals => List.unmodifiable(_vitals);
  List<MedicineScheduleItem> get medicineSchedule => List.unmodifiable(_medicineSchedule);
  List<PaymentTransaction> get transactions => List.unmodifiable(_transactions);
  List<FamilyMemberProfile> get familyMembers => List.unmodifiable(_familyMembers);
  List<PharmacyOrder> get pharmacyOrders => List.unmodifiable(_pharmacyOrders);
  List<LabTrendPoint> get labTrends => List.unmodifiable(_labTrends);
  HospitalKpiData get hospitalKpi => _hospitalKpi;
  TelemedicineSession? get currentTelemedicine => _currentTelemedicine;
  LiveQueueInfo get queueInfo => _queueInfo;

  bool get isSeniorMode => _isSeniorMode;
  List<LabReportItem> get labReports => List.unmodifiable(_labReports);
  List<InsurancePolicy> get insurancePolicies => List.unmodifiable(_insurancePolicies);
  List<CashlessClaimRequest> get cashlessClaims => List.unmodifiable(_cashlessClaims);
  List<AppointmentPassPackage> get appointmentPasses => List.unmodifiable(_appointmentPasses);
  List<FollowUpReminder> get followUpReminders => List.unmodifiable(_followUpReminders);
  List<DoctorReview> get doctorReviews => List.unmodifiable(_doctorReviews);
  List<SecurityAuditLog> get securityAuditLogs => List.unmodifiable(_securityAuditLogs);
  List<ActiveSessionInfo> get activeSessions => List.unmodifiable(_activeSessions);
  bool get isEmergencyLockdown => _isEmergencyLockdown;
  int get walletBalance => _walletBalance;
  int get advanceDeposit => _advanceDeposit;
  List<HospitalWalletTransaction> get walletTransactions => List.unmodifiable(_walletTransactions);

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
        doctorNotes: doctorNotes ?? 'Đã hoàn thành buổi tư vấn khám từ xa. Đơn thuốc điện tử đã được cập nhật.',
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
      if (userAllergies.contains('penicillin') && (name.contains('amoxicillin') || name.contains('ampicillin') || name.contains('penicillin'))) {
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
    final order = PharmacyOrder(
      id: 'PHARM-${DateTime.now().millisecondsSinceEpoch}',
      prescriptionId: prescriptionId,
      patientName: activeFamilyMember.name,
      phone: activeFamilyMember.phone.isNotEmpty ? activeFamilyMember.phone : _profile.phone,
      deliveryAddress: deliveryAddress,
      pharmacyName: pharmacyName,
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
        body: 'Đơn thuốc $prescriptionId đang được vận chuyển đến $deliveryAddress.',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return order;
  }

  // ── Trụ cột 6: Phân hệ Bác sĩ (Doctor Workspace) ──────────────────────────

  /// Bác sĩ bấm "Gọi bệnh nhân tiếp theo"
  void doctorCallNextPatient(String room) {
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
    notifyListeners();
  }

  /// Bác sĩ hoàn thành ca khám: Tự động lên lịch nhắc tái khám sau 14 ngày & nhắc đánh giá
  void doctorFinishConsultation(String doctorName, String specialty) {
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
      status: CashlessClaimStatus.approved,
      requestedAt: DateTime.now(),
      approvalCode: 'AUTH-${100000 + (DateTime.now().millisecond * 89)}',
    );
    _cashlessClaims.insert(0, claim);
    // Ghi nhận log bảo mật
    addSecurityAuditLog(
      SecurityAuditLog(
        id: 'audit-${DateTime.now().millisecondsSinceEpoch}',
        actor: 'Cổng Liên Kết Bảo Hiểm ($providerName)',
        action: 'Bảo lãnh viện phí trực tiếp thành công',
        targetResource: 'Hồ sơ: ${_profile.name} • Hóa đơn: ${claim.hospitalBillId}',
        ipAddress: '10.0.99.1 (Cổng Thanh Toán Bảo Hiểm)',
        timestamp: DateTime.now(),
        severity: SecuritySeverity.info,
        statusDescription: 'Đã duyệt bảo lãnh: ${coveredAmount ~/ 1000}.000đ, Đồng chi trả: ${patientCoPay ~/ 1000}.000đ',
      ),
    );
    _notifications.insert(
      0,
      AppNotification(
        id: 'notif-claim-${claim.id}',
        title: 'Bảo lãnh viện phí thành công!',
        body: '$providerName đã chi trả ${coveredAmount ~/ 1000}.000đ. Bạn chỉ cần đồng chi trả ${patientCoPay ~/ 1000}.000đ.',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return claim;
  }

  // ── Nghiệp vụ Mới: Đánh giá Bác sĩ & Khảo sát NPS ─────────────────────────

  void submitDoctorReview(DoctorReview review) {
    _doctorReviews.insert(0, review);
    // Tính lại điểm NPS và review count
    final total = _doctorReviews.length;
    final totalStars = _doctorReviews.fold<double>(0, (sum, r) => sum + r.rating);
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
        body: 'Đánh giá ${review.rating}★ cho ${review.doctorName} đã được ghi nhận vào hệ thống quản trị MedCare.',
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

  void toggleEmergencyLockdown() {
    _isEmergencyLockdown = !_isEmergencyLockdown;
    addSecurityAuditLog(
      SecurityAuditLog(
        id: 'audit-${DateTime.now().millisecondsSinceEpoch}',
        actor: 'Quản Trị Viên An Ninh (admin@medcare.vn)',
        action: _isEmergencyLockdown ? 'KÍCH HOẠT KHÓA HỆ THỐNG KHẨN CẤP' : 'Mở khóa hệ thống an ninh',
        targetResource: 'Toàn bộ Cơ sở dữ liệu Bệnh viện',
        ipAddress: '192.168.1.10 (Admin Web Console)',
        timestamp: DateTime.now(),
        severity: _isEmergencyLockdown ? SecuritySeverity.danger : SecuritySeverity.warning,
        statusDescription: _isEmergencyLockdown
            ? 'Đã tạm dừng các thao tác thay đổi dữ liệu để ngăn ngừa rò rỉ'
            : 'Hệ thống đã trở lại trạng thái hoạt động bình thường',
      ),
    );
    notifyListeners();
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
    notifyListeners();
  }

  // ── Nghiệp vụ Mới: Ví Viện Phí & Tự động Hoàn Tạm Ứng ───────────────────────

  void depositAdvance(int amount) {
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
        body: 'MedCare đã hoàn trả ${refundAmount ~/ 1000}.000đ tiền tạm ứng thừa về tài khoản của bạn.',
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
  void setSlotCapacity(String doctorId, String date, String time, int capacity) {
    final key = '${doctorId}_${date}_$time';
    final existing = _slotConfigs[key];
    _slotConfigs[key] = (existing ?? SlotConfig(doctorId: doctorId, date: date, time: time, capacity: capacity))
        .copyWith(capacity: capacity.clamp(1, 50));
    notifyListeners();
  }

  /// [Bệnh nhân] Đặt 1 chỗ vào slot. Trả về true nếu thành công, false nếu hết chỗ.
  /// Đây là atomic check-and-decrement: nếu vừa đầy ngay lúc đặt → từ chối.
  bool bookSlot(String doctorId, String date, String time) {
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
    notifyListeners();
    return true;
  }

  /// [Admin] Giải phóng 1 chỗ khi hủy lịch.
  void releaseSlot(String doctorId, String date, String time) {
    final key = '${doctorId}_${date}_$time';
    final slot = _slotConfigs[key];
    if (slot == null || slot.booked <= 0) return;
    _slotConfigs[key] = slot.copyWith(booked: slot.booked - 1);
    notifyListeners();
  }

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
    final dateStr =
        '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    bookSlot(doctor.id, dateStr, timeStr);

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
    final app = _appointments[index];
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
