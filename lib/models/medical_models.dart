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
  }) =>
      PatientProfile(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        dateOfBirth: dateOfBirth,
        insuranceNumber: insuranceNumber,
        bloodType: bloodType,
        gender: gender,
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
