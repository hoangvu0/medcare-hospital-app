import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  PatientProfile _profile = const PatientProfile(
    id: 'MC-89241',
    name: 'Nguyễn Hoàng Vũ',
    phone: '0901 234 567',
    email: 'vu@example.com',
    dateOfBirth: '15/08/2002',
    insuranceNumber: 'DN4010123456789',
    bloodType: 'O+',
    gender: 'Nam',
    address: 'Số 28, Phố Huế, Q. Hoàn Kiếm, Hà Nội',
    allergies: 'Penicillin, Phấn hoa',
  );
  PatientProfile get profile => _profile;

  final List<DoctorProfile> doctors = const [
    DoctorProfile(
      id: 'doc-01',
      name: 'PGS.TS.BS Trần Minh Đức',
      specialty: 'Tim mạch',
      experience: 'Trưởng khoa Tim mạch • 22 năm kinh nghiệm',
      education: 'Phó Giáo sư, Tiến sĩ Y khoa - Viện Tim mạch Quốc gia',
      workingDays: 'Thứ 2, 4, 6 (08:00 - 16:30)',
      totalPatients: '3.800+',
      rating: 4.9,
      price: 450000,
      location: 'Phòng 402, Tòa A',
      availability: 'Đang có lịch hôm nay',
    ),
    DoctorProfile(
      id: 'doc-02',
      name: 'ThS.BS Lê Thu Trang',
      specialty: 'Nhi khoa',
      experience: 'Phó khoa Nhi • 14 năm kinh nghiệm',
      education: 'Thạc sĩ Nhi khoa - Bệnh viện Nhi Trung ương',
      workingDays: 'Thứ 2 đến Thứ 7 (07:30 - 17:00)',
      totalPatients: '4.200+',
      rating: 5.0,
      price: 350000,
      location: 'Phòng 202, Tòa A',
      availability: 'Còn 3 khung giờ',
    ),
    DoctorProfile(
      id: 'doc-03',
      name: 'BSCKII Hoàng Quốc Việt',
      specialty: 'Cơ xương khớp',
      experience: 'Trưởng khoa Xương Khớp • 18 năm kinh nghiệm',
      education: 'Bác sĩ Chuyên khoa II - BV Chấn thương Chỉnh hình',
      workingDays: 'Thứ 3, 5, 7 (08:00 - 17:00)',
      totalPatients: '2.900+',
      rating: 4.8,
      price: 400000,
      location: 'Phòng 205, Tòa C',
      availability: 'Lịch trống chiều nay',
    ),
    DoctorProfile(
      id: 'doc-04',
      name: 'TS.BS Đỗ Phương Linh',
      specialty: 'Da liễu',
      experience: 'Chuyên gia Da liễu & Thẩm mỹ • 12 năm kinh nghiệm',
      education: 'Tiến sĩ Da liễu - Bệnh viện Da liễu Trung ương',
      workingDays: 'Thứ 2, 3, 5, 6 (08:30 - 16:30)',
      totalPatients: '3.100+',
      rating: 4.9,
      price: 350000,
      location: 'Tầng 3, Khoa Da liễu',
      availability: 'Khám theo hẹn',
    ),
    DoctorProfile(
      id: 'doc-05',
      name: 'PGS.TS.BS Nguyễn Văn An',
      specialty: 'Tiêu hóa',
      experience: 'Chủ nhiệm khoa Tiêu hóa - Gan mật • 25 năm kinh nghiệm',
      education: 'Phó Giáo sư, Tiến sĩ - Chuyên gia Nội soi Tiêu hóa BV Bạch Mai',
      workingDays: 'Thứ 2 đến Thứ 6 (08:00 - 16:00)',
      totalPatients: '5.600+',
      rating: 5.0,
      price: 500000,
      location: 'Phòng 305, Tòa B',
      availability: 'Đang có lịch hôm nay',
    ),
    DoctorProfile(
      id: 'doc-06',
      name: 'BSCKII Vũ Thị Mai',
      specialty: 'Mắt',
      experience: 'Khoa Nhãn khoa Kỹ thuật cao • 16 năm kinh nghiệm',
      education: 'Bác sĩ Chuyên khoa II - BV Mắt Trung ương',
      workingDays: 'Thứ 2, 4, 6, CN (08:00 - 17:00)',
      totalPatients: '2.400+',
      rating: 4.9,
      price: 380000,
      location: 'Phòng 108, Tòa B',
      availability: 'Lịch trống sáng mai',
    ),
    DoctorProfile(
      id: 'doc-07',
      name: 'TS.BS Phạm Đức Thắng',
      specialty: 'Tai Mũi Họng',
      experience: 'Phẫu thuật Tai Mũi Họng • 15 năm kinh nghiệm',
      education: 'Tiến sĩ Y khoa - BV Tai Mũi Họng Trung ương',
      workingDays: 'Thứ 3 đến Thứ 7 (08:00 - 17:00)',
      totalPatients: '3.500+',
      rating: 4.8,
      price: 360000,
      location: 'Phòng 204, Tòa B',
      availability: 'Còn 5 khung giờ',
    ),
    DoctorProfile(
      id: 'doc-08',
      name: 'ThS.BS Đặng Minh Châu',
      specialty: 'Thần kinh',
      experience: 'Nội thần kinh & Đột quỵ • 13 năm kinh nghiệm',
      education: 'Thạc sĩ Thần kinh - Đại học Y Hà Nội',
      workingDays: 'Thứ 2, 3, 5 (08:00 - 16:30)',
      totalPatients: '1.900+',
      rating: 4.9,
      price: 420000,
      location: 'Phòng 501, Tòa A',
      availability: 'Lịch trống chiều nay',
    ),
    DoctorProfile(
      id: 'doc-09',
      name: 'BSCKI Trương Quỳnh Anh',
      specialty: 'Sản phụ khoa',
      experience: 'Chăm sóc tiền sản & Phụ khoa • 11 năm kinh nghiệm',
      education: 'Bác sĩ Chuyên khoa I - BV Phụ sản Trung ương',
      workingDays: 'Thứ 2 đến Thứ 6 (08:00 - 17:00)',
      totalPatients: '2.700+',
      rating: 4.9,
      price: 380000,
      location: 'Phòng 302, Tòa C',
      availability: 'Đang có lịch hôm nay',
    ),
    DoctorProfile(
      id: 'doc-10',
      name: 'BSCKII Bùi Thanh Tùng',
      specialty: 'Răng Hàm Mặt',
      experience: 'Phục hình răng & Chỉnh nha • 17 năm kinh nghiệm',
      education: 'Bác sĩ Chuyên khoa II - Viện Răng Hàm Mặt Quốc gia',
      workingDays: 'Thứ 2 đến Thứ 7 (08:30 - 18:00)',
      totalPatients: '3.200+',
      rating: 4.8,
      price: 350000,
      location: 'Tầng 2, Tòa C',
      availability: 'Khám theo hẹn',
    ),
  ];

  final List<MedicalRecord> medicalRecords = const [
    MedicalRecord(
      id: 'HS-2026-0891',
      date: '10/02/2026',
      department: 'Khoa Tiêu hóa - Gan mật',
      doctorName: 'PGS.TS.BS Nguyễn Văn An',
      diagnosis: 'K29.0 - Viêm loét dạ dày tá tràng sung huyết, nhiễm vi khuẩn HP (+)',
      symptoms: 'Đau rát vùng thượng vị, ợ chua, buồn nôn, khó tiêu sau ăn kéo dài 2 tuần.',
      treatmentPlan: 'Phác đồ 4 thuốc tiệt trừ Helicobacter Pylori trong 14 ngày. Nội soi kiểm tra sau 4 tuần.',
      followUpDate: '10/03/2026',
      prescriptionCode: 'DT-2026-89241',
      totalFee: 1650000,
      insuranceCovered: 1320000,
    ),
    MedicalRecord(
      id: 'HS-2025-1104',
      date: '15/11/2025',
      department: 'Khoa Tai Mũi Họng',
      doctorName: 'TS.BS Phạm Đức Thắng',
      diagnosis: 'J02.9 - Viêm họng cấp thể mủ, viêm amidan hốc mủ đợt cấp',
      symptoms: 'Đau rát họng khi nuốt, sốt 38.5°C, có giả mạc mủ nhẹ trên amidan.',
      treatmentPlan: 'Kháng sinh phổ rộng đường uống 7 ngày, kháng viêm giảm phù nề, súc họng sát khuẩn.',
      followUpDate: '22/11/2025',
      prescriptionCode: 'DT-2025-44120',
      totalFee: 550000,
      insuranceCovered: 440000,
    ),
    MedicalRecord(
      id: 'HS-2025-0520',
      date: '20/05/2025',
      department: 'Khoa Khám sức khỏe Tổng quát',
      doctorName: 'PGS.TS.BS Trần Minh Đức',
      diagnosis: 'Z00.0 - Khám sức khỏe định kỳ, huyết áp và tim mạch bình thường',
      symptoms: 'Khám định kỳ hàng năm. Không có triệu chứng bất thường.',
      treatmentPlan: 'Duy trì chế độ ăn ít muối, tăng cường rau xanh và tập thể dục 30 phút/ngày.',
      followUpDate: '20/05/2026',
      prescriptionCode: 'DT-2025-09112',
      totalFee: 1200000,
      insuranceCovered: 960000,
    ),
  ];

  final List<LabTestItem> labTests = const [
    LabTestItem(name: 'Đường huyết lúc đói (Glucose)', value: '5.1', unit: 'mmol/L', normalRange: '3.9 - 6.4'),
    LabTestItem(name: 'Chức năng thận (Ure)', value: '4.8', unit: 'mmol/L', normalRange: '2.5 - 7.5'),
    LabTestItem(name: 'Chức năng thận (Creatinine)', value: '82', unit: 'µmol/L', normalRange: '62 - 106'),
    LabTestItem(name: 'Men gan (AST / SGOT)', value: '24', unit: 'U/L', normalRange: '< 40'),
    LabTestItem(name: 'Men gan (ALT / SGPT)', value: '28', unit: 'U/L', normalRange: '< 41'),
    LabTestItem(name: 'Mỡ máu (Cholesterol toàn phần)', value: '4.6', unit: 'mmol/L', normalRange: '< 5.2'),
    LabTestItem(name: 'Mỡ máu (Triglycerid)', value: '1.4', unit: 'mmol/L', normalRange: '< 1.7'),
    LabTestItem(name: 'Vi khuẩn HP (Clotest qua nội soi)', value: 'Dương tính (+)', unit: 'Kết quả', normalRange: 'Âm tính (-)', isAbnormal: true, note: 'Chỉ định phác đồ diệt trừ Hp'),
  ];

  final List<MedicineItem> medicines = const [
    MedicineItem(
      name: 'Nexium 40mg (Esomeprazole)',
      category: 'Ức chế tiết acid dạ dày (PPI)',
      dosage: '40mg',
      quantity: '28 viên',
      instruction: 'Uống 1 viên trước ăn sáng 30 phút. Uống nguyên viên, không nhai.',
    ),
    MedicineItem(
      name: 'Clarithromycin 500mg',
      category: 'Kháng sinh diệt khuẩn Hp',
      dosage: '500mg',
      quantity: '28 viên',
      instruction: 'Uống 1 viên sáng, 1 viên tối sau bữa ăn. Dùng đủ 14 ngày.',
      warning: 'Không dùng cùng rượu bia hoặc thức uống có cồn.',
    ),
    MedicineItem(
      name: 'Amoxicillin 500mg',
      category: 'Kháng sinh nhóm Penicillin',
      dosage: '500mg',
      quantity: '56 viên',
      instruction: 'Uống 2 viên sáng, 2 viên tối sau bữa ăn.',
      warning: 'Uống nhiều nước trong ngày.',
    ),
    MedicineItem(
      name: 'Phosphalugel (Gel nhôm phosphat)',
      category: 'Bảo vệ niêm mạc dạ dày',
      dosage: 'Gói 20g',
      quantity: '30 gói',
      instruction: 'Uống 1 gói khi đau rát thượng vị hoặc sau ăn 2 giờ.',
    ),
  ];

  final List<Appointment> _appointments = [
    Appointment(
      id: 'MED-1001',
      doctorId: 'doc-05',
      doctorName: 'PGS.TS.BS Nguyễn Văn An',
      specialty: 'Tiêu hóa',
      location: 'Phòng 305, Tòa B - Khoa Tiêu hóa',
      dateTime: DateTime.now().add(const Duration(days: 2, hours: 3)),
      patientName: 'Nguyễn Hoàng Vũ',
      reason: 'Tái khám dạ dày & đánh giá phác đồ Hp',
      insuranceApplied: true,
      status: AppointmentStatus.confirmed,
      fee: 100000,
      ticketNumber: 'KB-0824',
    ),
    Appointment(
      id: 'MED-1000',
      doctorId: 'doc-01',
      doctorName: 'PGS.TS.BS Trần Minh Đức',
      specialty: 'Tim mạch',
      location: 'Phòng 402, Tòa A',
      dateTime: DateTime(2026, 2, 10, 9, 30),
      patientName: 'Nguyễn Hoàng Vũ',
      reason: 'Khám định kỳ & đo điện tim ECG',
      insuranceApplied: true,
      status: AppointmentStatus.completed,
      fee: 90000,
      ticketNumber: 'KB-0112',
    ),
  ];

  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'notif-01',
      title: 'Lịch hẹn sắp tới',
      body: 'Bạn có lịch tái khám Tiêu hóa với PGS.TS Nguyễn Văn An vào 09:00 ngày tới.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'notif-02',
      title: 'Đã có kết quả xét nghiệm máu',
      body: 'Kết quả xét nghiệm sinh hóa ngày 10/02/2026 đã được cập nhật vào hồ sơ bệnh án.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  List<Appointment> get appointments => List.unmodifiable(_appointments);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

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
