class PatientProfile {
  const PatientProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.dateOfBirth,
    required this.insuranceNumber,
    this.bloodType = 'O+',
    this.gender = 'Nam',
    this.address = 'Số 28, Phố Huế, Q. Hoàn Kiếm, Hà Nội',
    this.allergies = 'Penicillin, Phấn hoa',
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String dateOfBirth;
  final String insuranceNumber;
  final String bloodType;
  final String gender;
  final String address;
  final String allergies;

  PatientProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? allergies,
    String? insuranceNumber,
    String? bloodType,
    String? gender,
    String? dateOfBirth,
  }) =>
      PatientProfile(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        insuranceNumber: insuranceNumber ?? this.insuranceNumber,
        bloodType: bloodType ?? this.bloodType,
        gender: gender ?? this.gender,
        address: address ?? this.address,
        allergies: allergies ?? this.allergies,
      );
}

class DoctorProfile {
  const DoctorProfile({
    required this.id,
    required this.name,
    required this.specialty,
    required this.experience,
    required this.rating,
    required this.price,
    required this.location,
    required this.availability,
    this.education = 'Bác sĩ chuyên khoa đầu ngành',
    this.workingDays = 'Thứ 2 - Thứ 6 (08:00 - 17:00)',
    this.totalPatients = '2.500+',
    this.imageUrl,
  });

  final String id;
  final String name;
  final String specialty;
  final String experience;
  final double rating;
  final int price;
  final String location;
  final String availability;
  final String education;
  final String workingDays;
  final String totalPatients;
  final String? imageUrl;
}

enum UserRole { patient, doctor, admin }

enum ClinicalStepStatus { completed, inProgress, upcoming }

class ClinicalPathwayStep {
  const ClinicalPathwayStep({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.doctorInstruction,
    required this.status,
    this.actionText,
    this.actionRoute,
    this.completedTime,
    this.etaMinutes,
  });

  final int stepNumber;
  final String title;
  final String subtitle;
  final String location;
  final String doctorInstruction;
  final ClinicalStepStatus status;
  final String? actionText;
  final String? actionRoute;
  final String? completedTime;
  final int? etaMinutes;

  ClinicalPathwayStep copyWith({
    int? stepNumber,
    String? title,
    String? subtitle,
    String? location,
    String? doctorInstruction,
    ClinicalStepStatus? status,
    String? actionText,
    String? actionRoute,
    String? completedTime,
    int? etaMinutes,
  }) =>
      ClinicalPathwayStep(
        stepNumber: stepNumber ?? this.stepNumber,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        location: location ?? this.location,
        doctorInstruction: doctorInstruction ?? this.doctorInstruction,
        status: status ?? this.status,
        actionText: actionText ?? this.actionText,
        actionRoute: actionRoute ?? this.actionRoute,
        completedTime: completedTime ?? this.completedTime,
        etaMinutes: etaMinutes ?? this.etaMinutes,
      );
}

enum AppointmentStatus { confirmed, completed, cancelled }

class Appointment {
  const Appointment({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.location,
    required this.dateTime,
    required this.patientName,
    required this.reason,
    required this.insuranceApplied,
    required this.status,
    required this.fee,
    this.ticketNumber,
  });

  final String id;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String location;
  final DateTime dateTime;
  final String patientName;
  final String reason;
  final bool insuranceApplied;
  final AppointmentStatus status;
  final int fee;
  final String? ticketNumber;

  Appointment copyWith({AppointmentStatus? status}) => Appointment(
    id: id,
    doctorId: doctorId,
    doctorName: doctorName,
    specialty: specialty,
    location: location,
    dateTime: dateTime,
    patientName: patientName,
    reason: reason,
    insuranceApplied: insuranceApplied,
    status: status ?? this.status,
    fee: fee,
    ticketNumber: ticketNumber,
  );
}

class AppointmentDraft {
  const AppointmentDraft({
    required this.doctor,
    required this.dateTime,
    required this.patientName,
    required this.reason,
    required this.useInsurance,
  });

  final DoctorProfile doctor;
  final DateTime dateTime;
  final String patientName;
  final String reason;
  final bool useInsurance;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    title: title,
    body: body,
    createdAt: createdAt,
    read: read ?? this.read,
  );
}

class MedicalRecord {
  const MedicalRecord({
    required this.id,
    required this.date,
    required this.department,
    required this.doctorName,
    required this.diagnosis,
    required this.symptoms,
    required this.treatmentPlan,
    required this.followUpDate,
    required this.prescriptionCode,
    required this.totalFee,
    required this.insuranceCovered,
    this.diagnosisCode = 'I10',
    this.icd10Name = 'Tăng huyết áp nguyên phát',
    this.differentialDiagnosis,
    this.physicalExamNotes = 'Tim đều T1, T2 rõ. Phổi thông khí tốt, không rale. Bụng mềm.',
    this.labSummary,
    this.xrayFindings,
    this.doctorInstructions = 'Uống thuốc đúng giờ, hạn chế ăn mặn, tái khám đúng hẹn.',
    this.digitalSignatureToken = 'EMR-SHA256-VN-MEDCARE-VALIDATED',
    this.riskLevel = 'Theo dõi định kỳ',
    this.prescribedMedicinesSummary,
  });

  final String id;
  final String date;
  final String department;
  final String doctorName;
  final String diagnosis;
  final String symptoms;
  final String treatmentPlan;
  final String followUpDate;
  final String prescriptionCode;
  final int totalFee;
  final int insuranceCovered;
  final String diagnosisCode;
  final String icd10Name;
  final String? differentialDiagnosis;
  final String physicalExamNotes;
  final String? labSummary;
  final String? xrayFindings;
  final String doctorInstructions;
  final String digitalSignatureToken;
  final String riskLevel;
  final String? prescribedMedicinesSummary;

  int get patientPaid => totalFee - insuranceCovered;
}

class LabTestItem {
  const LabTestItem({
    required this.name,
    required this.value,
    required this.unit,
    required this.normalRange,
    this.isAbnormal = false,
    this.note,
  });

  final String name;
  final String value;
  final String unit;
  final String normalRange;
  final bool isAbnormal;
  final String? note;
}

class MedicineItem {
  const MedicineItem({
    required this.name,
    required this.category,
    required this.dosage,
    required this.quantity,
    required this.instruction,
    this.warning,
  });

  final String name;
  final String category;
  final String dosage;
  final String quantity;
  final String instruction;
  final String? warning;
}

class VitalSignRecord {
  const VitalSignRecord({
    required this.timestamp,
    required this.systolic,
    required this.diastolic,
    required this.heartRate,
    required this.bloodGlucose,
    required this.weightKg,
    required this.heightCm,
    this.note,
  });

  final DateTime timestamp;
  final int systolic;
  final int diastolic;
  final int heartRate;
  final double bloodGlucose;
  final double weightKg;
  final double heightCm;
  final String? note;

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  String get bmiCategory {
    final value = bmi;
    if (value < 18.5) return 'Gầy / Thiếu cân';
    if (value < 23.0) return 'Bình thường (Chuẩn châu Á)';
    if (value < 25.0) return 'Tiền béo phì';
    return 'Béo phì';
  }

  String get bpStatus {
    if (systolic < 120 && diastolic < 80) return 'Tối ưu';
    if (systolic < 130 && diastolic < 85) return 'Bình thường';
    if (systolic < 140 || diastolic < 90) return 'Tiền tăng huyết áp';
    return 'Tăng huyết áp';
  }
}

class MedicineScheduleItem {
  const MedicineScheduleItem({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.timeSlot,
    required this.period,
    required this.instruction,
    this.isTaken = false,
    this.takenAt,
  });

  final String id;
  final String medicineName;
  final String dosage;
  final String timeSlot;
  final String period;
  final String instruction;
  final bool isTaken;
  final DateTime? takenAt;

  MedicineScheduleItem copyWith({
    bool? isTaken,
    DateTime? takenAt,
  }) => MedicineScheduleItem(
    id: id,
    medicineName: medicineName,
    dosage: dosage,
    timeSlot: timeSlot,
    period: period,
    instruction: instruction,
    isTaken: isTaken ?? this.isTaken,
    takenAt: takenAt ?? this.takenAt,
  );
}

class LiveQueueInfo {
  const LiveQueueInfo({
    required this.department,
    required this.room,
    required this.doctorName,
    required this.currentNumber,
    required this.patientNumber,
    required this.ticketCode,
    required this.estimatedMinutes,
  });

  final String department;
  final String room;
  final String doctorName;
  final int currentNumber;
  final int patientNumber;
  final String ticketCode;
  final int estimatedMinutes;

  int get waitCount => (patientNumber - currentNumber).clamp(0, 999);
}

class VaccineRecord {
  const VaccineRecord({
    required this.id,
    required this.vaccineName,
    required this.diseaseTarget,
    required this.doseNumber,
    required this.dateAdministered,
    required this.batchNumber,
    required this.facility,
    this.nextDoseDate,
    this.status = 'Đã hoàn thành',
  });

  final String id;
  final String vaccineName;
  final String diseaseTarget;
  final String doseNumber;
  final String dateAdministered;
  final String batchNumber;
  final String facility;
  final String? nextDoseDate;
  final String status;
}

class HealthPackage {
  const HealthPackage({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.originalPrice,
    this.isPopular = false,
    required this.targetGroup,
    required this.benefits,
    required this.items,
  });

  final String id;
  final String title;
  final String subtitle;
  final int price;
  final int originalPrice;
  final bool isPopular;
  final String targetGroup;
  final List<String> benefits;
  final List<String> items;
}

class HealthArticle {
  const HealthArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.author,
    required this.readTime,
    required this.summary,
    required this.content,
    required this.date,
  });

  final String id;
  final String title;
  final String category;
  final String author;
  final String readTime;
  final String summary;
  final String content;
  final String date;
}

// ── Thanh toán viện phí ─────────────────────────────────────────────────────

enum PaymentMethod { vietQr, momo, zalopay, vnpay, bankCard, kiosk }

enum PaymentStatus { pending, success, failed, refunded }

class PaymentTransaction {
  const PaymentTransaction({
    required this.id,
    required this.visitCode,
    required this.description,
    required this.grossAmount,
    required this.insuranceAmount,
    required this.netAmount,
    required this.method,
    required this.status,
    required this.timestamp,
    this.walletName,
    this.invoiceEmail,
    this.receiptCode,
  });

  final String id;
  final String visitCode;
  final String description;
  final int grossAmount;
  final int insuranceAmount;
  final int netAmount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime timestamp;
  final String? walletName;
  final String? invoiceEmail;
  final String? receiptCode;

  String get methodLabel => switch (method) {
        PaymentMethod.vietQr => 'VietQR / Napas247',
        PaymentMethod.momo => 'Ví MoMo',
        PaymentMethod.zalopay => 'Ví ZaloPay',
        PaymentMethod.vnpay => 'Ví VNPay',
        PaymentMethod.bankCard => 'Thẻ ngân hàng',
        PaymentMethod.kiosk => 'Kiosk quầy thu',
      };

  String get statusLabel => switch (status) {
        PaymentStatus.pending => 'Chờ thanh toán',
        PaymentStatus.success => 'Thành công',
        PaymentStatus.failed => 'Thất bại',
        PaymentStatus.refunded => 'Đã hoàn tiền',
      };
}

// ── Quản lý slot đặt khám (Admin) ──────────────────────────────────────────

/// Cấu hình slot đặt khám cho một bác sĩ tại một khung giờ cụ thể.
class SlotConfig {
  SlotConfig({
    required this.doctorId,
    required this.date,   // "2026-09-15"
    required this.time,   // "09:00"
    required this.capacity,
    this.booked = 0,
  });

  final String doctorId;
  final String date;
  final String time;
  final int capacity;
  int booked;

  int get remaining => (capacity - booked).clamp(0, capacity);
  bool get isFull => remaining <= 0;

  /// Key dùng để tra cứu trong Map
  String get key => '${doctorId}_${date}_$time';

  SlotConfig copyWith({int? capacity, int? booked}) => SlotConfig(
        doctorId: doctorId,
        date: date,
        time: time,
        capacity: capacity ?? this.capacity,
        booked: booked ?? this.booked,
      );
}

// ── Trụ cột 1: Đa Hồ sơ Gia đình (Family Profiles) ─────────────────────────

enum FamilyRelation { self, child, parent, spouse }

class FamilyMemberProfile {
  const FamilyMemberProfile({
    required this.id,
    required this.name,
    required this.relation,
    required this.dateOfBirth,
    required this.gender,
    required this.insuranceNumber,
    required this.bloodType,
    this.allergies = 'Không có',
    this.phone = '',
    this.avatarEmoji = '👤',
    this.medicalNotes = '',
  });

  final String id;
  final String name;
  final FamilyRelation relation;
  final String dateOfBirth;
  final String gender;
  final String insuranceNumber;
  final String bloodType;
  final String allergies;
  final String phone;
  final String avatarEmoji;
  final String medicalNotes;

  String get relationLabel => switch (relation) {
        FamilyRelation.self => 'Bản thân',
        FamilyRelation.child => 'Con cái',
        FamilyRelation.parent => 'Bố / Mẹ',
        FamilyRelation.spouse => 'Vợ / Chồng',
      };

  FamilyMemberProfile copyWith({
    String? name,
    FamilyRelation? relation,
    String? dateOfBirth,
    String? gender,
    String? insuranceNumber,
    String? bloodType,
    String? allergies,
    String? phone,
    String? avatarEmoji,
    String? medicalNotes,
  }) =>
      FamilyMemberProfile(
        id: id,
        name: name ?? this.name,
        relation: relation ?? this.relation,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        insuranceNumber: insuranceNumber ?? this.insuranceNumber,
        bloodType: bloodType ?? this.bloodType,
        allergies: allergies ?? this.allergies,
        phone: phone ?? this.phone,
        avatarEmoji: avatarEmoji ?? this.avatarEmoji,
        medicalNotes: medicalNotes ?? this.medicalNotes,
      );
}

// ── Trụ cột 2: Khám từ xa Telemedicine ──────────────────────────────────────

enum TelemedicineStatus { waiting, connected, ended }

class TelemedicineSession {
  const TelemedicineSession({
    required this.id,
    required this.doctor,
    required this.patientName,
    required this.appointmentTime,
    this.status = TelemedicineStatus.waiting,
    this.durationSeconds = 0,
    this.doctorNotes = '',
  });

  final String id;
  final DoctorProfile doctor;
  final String patientName;
  final DateTime appointmentTime;
  final TelemedicineStatus status;
  final int durationSeconds;
  final String doctorNotes;

  TelemedicineSession copyWith({
    TelemedicineStatus? status,
    int? durationSeconds,
    String? doctorNotes,
  }) =>
      TelemedicineSession(
        id: id,
        doctor: doctor,
        patientName: patientName,
        appointmentTime: appointmentTime,
        status: status ?? this.status,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        doctorNotes: doctorNotes ?? this.doctorNotes,
      );
}

// ── Trụ cột 3: Giao thuốc tận nhà (Pharmacy Delivery) ──────────────────────

enum PharmacyOrderStatus { packing, shipping, delivered, cancelled }

class PharmacyOrder {
  const PharmacyOrder({
    required this.id,
    required this.prescriptionId,
    required this.patientName,
    required this.phone,
    required this.deliveryAddress,
    required this.pharmacyName,
    required this.itemsCount,
    required this.medicineTotal,
    required this.shippingFee,
    required this.status,
    required this.orderedAt,
    this.estimatedMinutes = 45,
  });

  final String id;
  final String prescriptionId;
  final String patientName;
  final String phone;
  final String deliveryAddress;
  final String pharmacyName;
  final int itemsCount;
  final int medicineTotal;
  final int shippingFee;
  final PharmacyOrderStatus status;
  final DateTime orderedAt;
  final int estimatedMinutes;

  int get totalPayable => medicineTotal + shippingFee;

  String get statusLabel => switch (status) {
        PharmacyOrderStatus.packing => 'Đang đóng gói thuốc',
        PharmacyOrderStatus.shipping => 'Đang giao hỏa tốc 2h',
        PharmacyOrderStatus.delivered => 'Đã giao thành công',
        PharmacyOrderStatus.cancelled => 'Đã hủy',
      };
}

// ── Trụ cột 4: Xu hướng Xét nghiệm (Lab Trends) ─────────────────────────────

class LabTrendPoint {
  const LabTrendPoint({
    required this.dateStr,
    required this.timestamp,
    required this.bloodGlucose,     // mg/dL (chuẩn 70-99)
    required this.alt,              // U/L (men gan ALT chuẩn < 40)
    required this.ast,              // U/L (men gan AST chuẩn < 40)
    required this.cholesterolTotal, // mmol/L (chuẩn < 5.2)
    required this.uricAcid,         // umol/L (chuẩn 200-420)
  });

  final String dateStr;
  final DateTime timestamp;
  final double bloodGlucose;
  final double alt;
  final double ast;
  final double cholesterolTotal;
  final double uricAcid;
}

// ── Trụ cột 6: Thống kê KPI Viện phí & Bác sĩ ───────────────────────────────

class HospitalKpiData {
  const HospitalKpiData({
    required this.todayPatients,
    required this.todayRevenue,
    required this.avgWaitMinutes,
    required this.occupancyRatePercent,
    required this.totalDoctorsOnDuty,
    required this.completedConsultations,
    this.npsSatisfactionScore = 96.8,
    this.totalReviews = 142,
  });

  final int todayPatients;
  final int todayRevenue;
  final int avgWaitMinutes;
  final int occupancyRatePercent;
  final int totalDoctorsOnDuty;
  final int completedConsultations;
  final double npsSatisfactionScore;
  final int totalReviews;

  HospitalKpiData copyWith({
    int? todayPatients,
    int? todayRevenue,
    int? avgWaitMinutes,
    int? occupancyRatePercent,
    int? totalDoctorsOnDuty,
    int? completedConsultations,
    double? npsSatisfactionScore,
    int? totalReviews,
  }) =>
      HospitalKpiData(
        todayPatients: todayPatients ?? this.todayPatients,
        todayRevenue: todayRevenue ?? this.todayRevenue,
        avgWaitMinutes: avgWaitMinutes ?? this.avgWaitMinutes,
        occupancyRatePercent: occupancyRatePercent ?? this.occupancyRatePercent,
        totalDoctorsOnDuty: totalDoctorsOnDuty ?? this.totalDoctorsOnDuty,
        completedConsultations: completedConsultations ?? this.completedConsultations,
        npsSatisfactionScore: npsSatisfactionScore ?? this.npsSatisfactionScore,
        totalReviews: totalReviews ?? this.totalReviews,
      );
}

// ── Nâng cấp: Trợ lý AI Diễn giải Xét nghiệm (Lab Explainer) ────────────────

enum LabRiskLevel { normal, warning, critical }
enum LabCategory { hematology, biochemistry }

class LabReportItem {
  const LabReportItem({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.value,
    required this.unit,
    required this.referenceRange,
    required this.riskLevel,
    required this.clinicalMeaning,
    required this.dietaryAdvice,
    required this.testedAt,
  });

  final String id;
  final String code;
  final String name;
  final LabCategory category;
  final double value;
  final String unit;
  final String referenceRange;
  final LabRiskLevel riskLevel;
  final String clinicalMeaning;
  final String dietaryAdvice;
  final String testedAt;

  String get categoryLabel => category == LabCategory.hematology ? 'Huyết học' : 'Sinh hóa máu';

  String get riskLabel => switch (riskLevel) {
        LabRiskLevel.normal => 'Bình thường',
        LabRiskLevel.warning => 'Cảnh báo nhẹ',
        LabRiskLevel.critical => 'Vượt ngưỡng',
      };
}

// ── Nâng cấp: Cổng Bảo Hiểm & Bảo Lãnh Viện Phí Tư Nhân (Direct Billing) ───

enum CashlessClaimStatus { pending, approved, rejected }

class InsurancePolicy {
  const InsurancePolicy({
    required this.id,
    required this.providerName,
    required this.policyNumber,
    required this.cardHolderName,
    required this.outpatientLimit,
    required this.inpatientLimit,
    required this.usedAmount,
    required this.expireDate,
    required this.coveragePercent,
    this.logoEmoji = '🛡️',
  });

  final String id;
  final String providerName;
  final String policyNumber;
  final String cardHolderName;
  final int outpatientLimit;
  final int inpatientLimit;
  final int usedAmount;
  final String expireDate;
  final int coveragePercent;
  final String logoEmoji;

  int get remainingOutpatient => outpatientLimit - usedAmount;
}

class CashlessClaimRequest {
  const CashlessClaimRequest({
    required this.id,
    required this.policyNumber,
    required this.providerName,
    required this.hospitalBillId,
    required this.totalBill,
    required this.coveredAmount,
    required this.patientCoPay,
    required this.status,
    required this.requestedAt,
    this.approvalCode,
  });

  final String id;
  final String policyNumber;
  final String providerName;
  final String hospitalBillId;
  final int totalBill;
  final int coveredAmount;
  final int patientCoPay;
  final CashlessClaimStatus status;
  final DateTime requestedAt;
  final String? approvalCode;
}

// ── Nâng cấp: Tự động nhắc Tái khám & Đánh giá Bác sĩ ───────────────────────

class FollowUpReminder {
  const FollowUpReminder({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.reminderDate,
    required this.clinicalReason,
    required this.doctorInstructions,
    this.isCompleted = false,
  });

  final String id;
  final String doctorName;
  final String specialty;
  final DateTime reminderDate;
  final String clinicalReason;
  final String doctorInstructions;
  final bool isCompleted;

  FollowUpReminder copyWith({bool? isCompleted}) => FollowUpReminder(
        id: id,
        doctorName: doctorName,
        specialty: specialty,
        reminderDate: reminderDate,
        clinicalReason: clinicalReason,
        doctorInstructions: doctorInstructions,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}

class DoctorReview {
  const DoctorReview({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.patientName,
    required this.rating,
    required this.comment,
    required this.treatmentDepartment,
    required this.createdAt,
    this.attitudeRating = 5,
    this.expertiseRating = 5,
    this.waitingTimeRating = 5,
  });

  final String id;
  final String doctorId;
  final String doctorName;
  final String patientName;
  final double rating;
  final String comment;
  final String treatmentDepartment;
  final DateTime createdAt;
  final int attitudeRating;
  final int expertiseRating;
  final int waitingTimeRating;
}

// ── Nâng cấp: Giám Sát Bảo Mật & Nhật Ký Truy Vết (Security & Audit) ────────

enum SecuritySeverity { info, warning, danger }

class SecurityAuditLog {
  const SecurityAuditLog({
    required this.id,
    required this.actor,
    required this.action,
    required this.targetResource,
    required this.ipAddress,
    required this.timestamp,
    required this.severity,
    required this.statusDescription,
  });

  final String id;
  final String actor;
  final String action;
  final String targetResource;
  final String ipAddress;
  final DateTime timestamp;
  final SecuritySeverity severity;
  final String statusDescription;

  String get severityLabel => switch (severity) {
        SecuritySeverity.info => 'Hợp lệ',
        SecuritySeverity.warning => 'Chú ý',
        SecuritySeverity.danger => 'Cảnh báo',
      };
}

class ActiveSessionInfo {
  const ActiveSessionInfo({
    required this.id,
    required this.deviceName,
    required this.clientType,
    required this.ipAddress,
    required this.lastActive,
    required this.isCurrent,
  });

  final String id;
  final String deviceName;
  final String clientType;
  final String ipAddress;
  final String lastActive;
  final bool isCurrent;
}

// ── Nâng cấp: Gói Đăng Ký Thời Gian Khám Bệnh (Appointment Pass) ────────────

class AppointmentPassPackage {
  const AppointmentPassPackage({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priceDelta,
    required this.badge,
    required this.benefits,
    this.isPopular = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final int priceDelta;
  final String badge;
  final List<String> benefits;
  final bool isPopular;
}

// ── Nâng cấp: Ví Viện Phí & Tạm Ứng Tự Động Hoàn Tiền ───────────────────────

class HospitalWalletTransaction {
  const HospitalWalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.timestamp,
    required this.isDebit,
    required this.description,
  });

  final String id;
  final String title;
  final int amount;
  final DateTime timestamp;
  final bool isDebit; // true: trừ tiền, false: cộng tiền / hoàn tiền
  final String description;
}

