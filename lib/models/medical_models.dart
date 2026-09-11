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
