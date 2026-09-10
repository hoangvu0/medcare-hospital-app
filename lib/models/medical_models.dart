class PatientProfile {
  const PatientProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.dateOfBirth,
    required this.insuranceNumber,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String dateOfBirth;
  final String insuranceNumber;

  PatientProfile copyWith({String? name, String? phone, String? email}) =>
      PatientProfile(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        dateOfBirth: dateOfBirth,
        insuranceNumber: insuranceNumber,
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
