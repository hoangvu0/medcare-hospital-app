import '../models/medical_models.dart';

/// Kho dữ liệu y tế thực tế chuẩn lâm sàng của MedCare Hospital.
/// Đồng bộ 100% cho bệnh nhân Nguyễn Hoàng Vũ, danh sách 10 bác sĩ chuyên khoa đầu ngành,
/// bệnh án điện tử, kết quả xét nghiệm sinh hóa máu và đơn thuốc điều trị.
abstract final class MedicalData {
  /// Thông tin hồ sơ bệnh nhân chính thức
  static const PatientProfile defaultPatient = PatientProfile(
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

  /// Danh sách 10 Bác sĩ Chuyên khoa Đầu ngành
  static const List<DoctorProfile> initialDoctors = [
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
      experience: 'Chuyên gia Da liễu & Thẩm mỹ • 11 năm kinh nghiệm',
      education: 'Tiến sĩ Da liễu - Bệnh viện Da liễu Trung ương',
      workingDays: 'Thứ 2 đến Thứ 6 (08:00 - 16:30)',
      totalPatients: '3.100+',
      rating: 4.9,
      price: 350000,
      location: 'Tầng 3, Nhà B - Khoa Da liễu',
      availability: 'Khám theo hẹn',
    ),
    DoctorProfile(
      id: 'doc-05',
      name: 'PGS.TS.BS Nguyễn Văn An',
      specialty: 'Tiêu hóa',
      experience: 'Chuyên gia Tiêu hóa & Gan mật • 20 năm kinh nghiệm',
      education: 'Phó Giáo sư Y khoa - Trưởng đơn vị Nội soi Can thiệp',
      workingDays: 'Thứ 2, 3, 5, 7 (08:00 - 16:00)',
      totalPatients: '4.500+',
      rating: 4.9,
      price: 500000,
      location: 'Phòng 305, Tòa B - Khoa Tiêu hóa',
      availability: 'Đang có lịch hôm nay',
    ),
    DoctorProfile(
      id: 'doc-06',
      name: 'TS.BS Phạm Đức Thắng',
      specialty: 'Tai Mũi Họng',
      experience: 'Phẫu thuật viên Tai Mũi Họng • 15 năm kinh nghiệm',
      education: 'Tiến sĩ Y khoa - BV Tai Mũi Họng Trung ương',
      workingDays: 'Thứ 2 đến Thứ 6 (08:00 - 17:00)',
      totalPatients: '2.700+',
      rating: 4.8,
      price: 350000,
      location: 'Phòng 104, Tòa A',
      availability: 'Còn 5 khung giờ',
    ),
    DoctorProfile(
      id: 'doc-07',
      name: 'BSCKII Vũ Thị Bích Ngọc',
      specialty: 'Mắt',
      experience: 'Chuyên gia Khúc xạ & Phaco • 16 năm kinh nghiệm',
      education: 'Bác sĩ Chuyên khoa II - Bệnh viện Mắt Trung ương',
      workingDays: 'Thứ 3, 5, 7 (08:00 - 16:30)',
      totalPatients: '3.400+',
      rating: 4.9,
      price: 400000,
      location: 'Phòng 208, Tòa B',
      availability: 'Lịch trống sáng nay',
    ),
    DoctorProfile(
      id: 'doc-08',
      name: 'TS.BS Đặng Minh Tuấn',
      specialty: 'Thần kinh',
      experience: 'Nội thần kinh & Đột quỵ • 19 năm kinh nghiệm',
      education: 'Tiến sĩ Y học Thần kinh - Bệnh viện Bạch Mai',
      workingDays: 'Thứ 2, 4, 6 (08:30 - 17:00)',
      totalPatients: '2.600+',
      rating: 4.9,
      price: 450000,
      location: 'Phòng 405, Tòa A',
      availability: 'Đang tiếp nhận',
    ),
    DoctorProfile(
      id: 'doc-09',
      name: 'ThS.BSCKII Ngô Kim Oanh',
      specialty: 'Sản phụ khoa',
      experience: 'Trưởng khoa Sản Phụ • 21 năm kinh nghiệm',
      education: 'Thạc sĩ - Bác sĩ Chuyên khoa II Phụ sản',
      workingDays: 'Thứ 2 đến Thứ 7 (07:30 - 16:30)',
      totalPatients: '5.100+',
      rating: 5.0,
      price: 400000,
      location: 'Phòng 102, Tòa C',
      availability: 'Khám theo hẹn',
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
    DoctorProfile(
      id: 'doc-11',
      name: 'GS.TS.BS Nguyễn Chấn Hùng',
      specialty: 'Ung bướu & Xạ trị',
      experience: 'Chuyên gia Cấp cao Ung bướu • 35 năm kinh nghiệm',
      education: 'Giáo sư Y học, Tiến sĩ - Chủ tịch Hội Ung thư Việt Nam',
      workingDays: 'Thứ 3, 5 (08:30 - 16:00)',
      totalPatients: '6.800+',
      rating: 5.0,
      price: 600000,
      location: 'Phòng 501, Tòa A - Trung tâm Ung bướu',
      availability: 'Đặt trước 2 ngày',
    ),
    DoctorProfile(
      id: 'doc-12',
      name: 'PGS.TS.BS Phan Thu Phương',
      specialty: 'Hô hấp & Phổi',
      experience: 'Giám đốc Trung tâm Hô hấp • 24 năm kinh nghiệm',
      education: 'Phó Giáo sư, Tiến sĩ Y khoa - Bệnh viện Bạch Mai',
      workingDays: 'Thứ 2, 4, 6 (08:00 - 16:30)',
      totalPatients: '4.900+',
      rating: 4.9,
      price: 500000,
      location: 'Phòng 408, Tòa A',
      availability: 'Đang có lịch hôm nay',
    ),
    DoctorProfile(
      id: 'doc-13',
      name: 'BSCKII Nguyễn Thị Mai Hoa',
      specialty: 'Tim mạch',
      experience: 'Chuyên gia Can thiệp Tim mạch • 19 năm kinh nghiệm',
      education: 'Bác sĩ Chuyên khoa II - Viện Tim mạch TP.HCM',
      workingDays: 'Thứ 2 đến Thứ 6 (08:00 - 17:00)',
      totalPatients: '3.600+',
      rating: 4.9,
      price: 450000,
      location: 'Phòng 401, Tòa A',
      availability: 'Còn 4 khung giờ',
    ),
    DoctorProfile(
      id: 'doc-14',
      name: 'TS.BS Vũ Đình Thắng',
      specialty: 'Nhi khoa',
      experience: 'Hồi sức Cấp cứu Nhi & Sơ sinh • 16 năm kinh nghiệm',
      education: 'Tiến sĩ Nhi khoa - Đại học Y Dược',
      workingDays: 'Thứ 2 đến Thứ 7 (07:30 - 16:30)',
      totalPatients: '3.900+',
      rating: 4.8,
      price: 350000,
      location: 'Phòng 203, Tòa A',
      availability: 'Đang có lịch hôm nay',
    ),
    DoctorProfile(
      id: 'doc-15',
      name: 'BSCKII Phạm Hoài Nam',
      specialty: 'Tiêu hóa',
      experience: 'Chuyên gia Gan Mật & Tụy • 21 năm kinh nghiệm',
      education: 'Bác sĩ Chuyên khoa II - BV Chợ Rẫy',
      workingDays: 'Thứ 3, 5, 7 (08:00 - 17:00)',
      totalPatients: '4.100+',
      rating: 4.9,
      price: 450000,
      location: 'Phòng 306, Tòa B',
      availability: 'Còn 2 khung giờ',
    ),
    DoctorProfile(
      id: 'doc-16',
      name: 'ThS.BS Đặng Xuân Thành',
      specialty: 'Cơ xương khớp',
      experience: 'Phẫu thuật Cột sống & Nội soi khớp • 13 năm kinh nghiệm',
      education: 'Thạc sĩ Chấn thương Chỉnh hình - BV Việt Đức',
      workingDays: 'Thứ 2, 4, 6 (08:00 - 16:30)',
      totalPatients: '2.400+',
      rating: 4.8,
      price: 350000,
      location: 'Phòng 206, Tòa C',
      availability: 'Khám theo hẹn',
    ),
    DoctorProfile(
      id: 'doc-17',
      name: 'ThS.BS Nguyễn Khánh Vy',
      specialty: 'Da liễu',
      experience: 'Laser Thẩm mỹ da & Dị ứng • 12 năm kinh nghiệm',
      education: 'Thạc sĩ Da liễu Lâm sàng - BV Da liễu',
      workingDays: 'Thứ 2 đến Thứ 6 (08:30 - 17:30)',
      totalPatients: '3.000+',
      rating: 4.9,
      price: 350000,
      location: 'Tầng 3, Nhà B',
      availability: 'Đang có lịch hôm nay',
    ),
    DoctorProfile(
      id: 'doc-18',
      name: 'TS.BS Hoàng Trọng Hải',
      specialty: 'Mắt',
      experience: 'Phẫu thuật Lasik & Thủy tinh thể • 18 năm kinh nghiệm',
      education: 'Tiến sĩ Nhãn khoa - Đại học Y Hà Nội',
      workingDays: 'Thứ 2, 3, 5, 7 (08:00 - 16:00)',
      totalPatients: '3.700+',
      rating: 4.9,
      price: 400000,
      location: 'Phòng 209, Tòa B',
      availability: 'Lịch trống chiều nay',
    ),
    DoctorProfile(
      id: 'doc-19',
      name: 'BSCKII Trần Thu Hà',
      specialty: 'Tai Mũi Họng',
      experience: 'Nội soi Vi phẫu Tai Mũi Họng • 15 năm kinh nghiệm',
      education: 'Bác sĩ Chuyên khoa II - BV Tai Mũi Họng',
      workingDays: 'Thứ 2 đến Thứ 6 (08:00 - 17:00)',
      totalPatients: '2.800+',
      rating: 4.8,
      price: 350000,
      location: 'Phòng 105, Tòa A',
      availability: 'Còn 3 khung giờ',
    ),
    DoctorProfile(
      id: 'doc-20',
      name: 'PGS.TS.BS Lê Thị Cúc',
      specialty: 'Sản phụ khoa',
      experience: 'Chuyên gia Hiếm muộn & Sản khoa • 26 năm kinh nghiệm',
      education: 'Phó Giáo sư Sản phụ khoa - BV Phụ sản Trung ương',
      workingDays: 'Thứ 2, 4, 6 (08:00 - 16:00)',
      totalPatients: '5.600+',
      rating: 5.0,
      price: 550000,
      location: 'Phòng 103, Tòa C',
      availability: 'Đặt trước 1 ngày',
    ),
  ];

  /// Danh mục các chuyên khoa chính (13 chuyên khoa bao phủ toàn diện)
  static const List<String> specialties = [
    'Tất cả',
    'Tiêu hóa',
    'Tim mạch',
    'Nhi khoa',
    'Cơ xương khớp',
    'Da liễu',
    'Mắt',
    'Tai Mũi Họng',
    'Thần kinh',
    'Sản phụ khoa',
    'Răng Hàm Mặt',
    'Ung bướu & Xạ trị',
    'Hô hấp & Phổi',
  ];

  /// Hồ sơ bệnh án điện tử (3 đợt khám thực tế)
  static const List<MedicalRecord> initialRecords = [
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

  /// Kết quả xét nghiệm sinh hóa máu chuẩn tham chiếu y khoa
  static const List<LabTestItem> initialLabTests = [
    LabTestItem(name: 'Đường huyết lúc đói (Glucose)', value: '5.1', unit: 'mmol/L', normalRange: '3.9 - 6.4'),
    LabTestItem(name: 'Chức năng thận (Ure)', value: '4.8', unit: 'mmol/L', normalRange: '2.5 - 7.5'),
    LabTestItem(name: 'Chức năng thận (Creatinine)', value: '82', unit: 'µmol/L', normalRange: '62 - 106'),
    LabTestItem(name: 'Men gan (AST / SGOT)', value: '24', unit: 'U/L', normalRange: '< 40'),
    LabTestItem(name: 'Men gan (ALT / SGPT)', value: '28', unit: 'U/L', normalRange: '< 41'),
    LabTestItem(name: 'Mỡ máu (Cholesterol toàn phần)', value: '4.6', unit: 'mmol/L', normalRange: '< 5.2'),
    LabTestItem(name: 'Mỡ máu (Triglycerid)', value: '1.4', unit: 'mmol/L', normalRange: '< 1.7'),
    LabTestItem(name: 'Vi khuẩn HP (Clotest qua nội soi)', value: 'Dương tính (+)', unit: 'Kết quả', normalRange: 'Âm tính (-)', isAbnormal: true, note: 'Chỉ định phác đồ diệt trừ Hp'),
  ];

  /// Đơn thuốc điện tử điều trị Hp thực tế
  static const List<MedicineItem> initialMedicines = [
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

  /// Lịch hẹn khám mặc định ban đầu
  static List<Appointment> get initialAppointments => [
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

  /// Thông báo hệ thống ban đầu
  static List<AppNotification> get initialNotifications => [
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

  /// Danh sách chỉ số sinh hiệu thực tế của bệnh nhân Nguyễn Hoàng Vũ
  static List<VitalSignRecord> get initialVitals => [
    VitalSignRecord(
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      systolic: 118,
      diastolic: 78,
      heartRate: 74,
      bloodGlucose: 94.5,
      weightKg: 68.0,
      heightCm: 174.0,
      note: 'Đo sau ăn sáng 2 giờ, thể trạng ổn định.',
    ),
    VitalSignRecord(
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      systolic: 122,
      diastolic: 80,
      heartRate: 78,
      bloodGlucose: 98.0,
      weightKg: 68.2,
      heightCm: 174.0,
      note: 'Đo tại phòng khám sàng lọc Tòa B.',
    ),
    VitalSignRecord(
      timestamp: DateTime.now().subtract(const Duration(days: 7)),
      systolic: 125,
      diastolic: 82,
      heartRate: 82,
      bloodGlucose: 102.0,
      weightKg: 68.5,
      heightCm: 174.0,
      note: 'Hơi mệt do đau dạ dày thượng vị.',
    ),
  ];

  /// Lịch uống thuốc hôm nay theo đơn tiệt trừ Hp
  static List<MedicineScheduleItem> get initialMedicineSchedule => [
    const MedicineScheduleItem(
      id: 'sch-01',
      medicineName: 'Nexium 40mg (Esomeprazole)',
      dosage: '1 viên',
      timeSlot: '06:30',
      period: 'Sáng',
      instruction: 'Uống trước ăn sáng 30 phút, nuốt nguyên viên.',
      isTaken: true,
    ),
    const MedicineScheduleItem(
      id: 'sch-02',
      medicineName: 'Amoxicillin 500mg',
      dosage: '2 viên',
      timeSlot: '07:30',
      period: 'Sáng',
      instruction: 'Uống ngay sau ăn sáng, uống cùng nhiều nước.',
      isTaken: true,
    ),
    const MedicineScheduleItem(
      id: 'sch-03',
      medicineName: 'Clarithromycin 500mg',
      dosage: '1 viên',
      timeSlot: '07:30',
      period: 'Sáng',
      instruction: 'Uống sau ăn sáng cùng Amoxicillin.',
      isTaken: true,
    ),
    const MedicineScheduleItem(
      id: 'sch-04',
      medicineName: 'Nexium 40mg (Esomeprazole)',
      dosage: '1 viên',
      timeSlot: '18:30',
      period: 'Tối',
      instruction: 'Uống trước ăn tối 30 phút.',
      isTaken: false,
    ),
    const MedicineScheduleItem(
      id: 'sch-05',
      medicineName: 'Amoxicillin 500mg',
      dosage: '2 viên',
      timeSlot: '19:30',
      period: 'Tối',
      instruction: 'Uống sau ăn tối, uống đủ 2 viên.',
      isTaken: false,
    ),
    const MedicineScheduleItem(
      id: 'sch-06',
      medicineName: 'Clarithromycin 500mg',
      dosage: '1 viên',
      timeSlot: '19:30',
      period: 'Tối',
      instruction: 'Uống sau ăn tối, tránh rượu bia hoàn toàn.',
      isTaken: false,
    ),
    const MedicineScheduleItem(
      id: 'sch-07',
      medicineName: 'Phosphalugel (Gel nhôm)',
      dosage: '1 gói 20g',
      timeSlot: '21:30',
      period: 'Tối',
      instruction: 'Uống khi đau hoặc trước khi đi ngủ 30 phút.',
      isTaken: false,
    ),
  ];

  /// Thông tin hàng đợi khám trực tiếp mô phỏng phòng khám
  static const LiveQueueInfo defaultQueue = LiveQueueInfo(
    department: 'Khoa Tiêu hóa & Gan Mật',
    room: 'Phòng 305 (Tầng 3 - Tòa B)',
    doctorName: 'PGS.TS.BS Nguyễn Văn An',
    currentNumber: 18,
    patientNumber: 21,
    ticketCode: 'KB-0824',
    estimatedMinutes: 12,
  );

  /// Sổ tiêm chủng vắc-xin của bệnh nhân
  static const List<VaccineRecord> initialVaccines = [
    VaccineRecord(
      id: 'vac-01',
      vaccineName: 'Influvac Tetra (Hà Lan)',
      diseaseTarget: 'Cúm mùa 4 chủng (A/H1N1, A/H3N2, B)',
      doseNumber: 'Mũi 1/1 (Hàng năm)',
      dateAdministered: '15/10/2025',
      batchNumber: 'INF-2025-98A',
      facility: 'Trung tâm Tiêm chủng MedCare Hospital',
      nextDoseDate: '15/10/2026',
      status: 'Đã hoàn thành',
    ),
    VaccineRecord(
      id: 'vac-02',
      vaccineName: 'Engerix-B 20mcg (Bỉ)',
      diseaseTarget: 'Viêm gan siêu vi B',
      doseNumber: 'Mũi 3/3 (Hoàn thành phác đồ)',
      dateAdministered: '20/04/2024',
      batchNumber: 'ENG-8821B',
      facility: 'Trung tâm Tiêm chủng MedCare Hospital',
      status: 'Đã hoàn thành',
    ),
    VaccineRecord(
      id: 'vac-03',
      vaccineName: 'Comirnaty Pfizer-BioNTech',
      diseaseTarget: 'Covid-19',
      doseNumber: 'Mũi 3 (Mũi nhắc lại)',
      dateAdministered: '12/03/2023',
      batchNumber: 'PFI-91204',
      facility: 'Điểm tiêm chủng BV Bạch Mai',
      status: 'Đã hoàn thành',
    ),
    VaccineRecord(
      id: 'vac-04',
      vaccineName: 'VAT (Việt Nam)',
      diseaseTarget: 'Uốn ván hấp phụ',
      doseNumber: 'Mũi nhắc lại 10 năm',
      dateAdministered: '05/06/2022',
      batchNumber: 'VAT-4410',
      facility: 'Trung tâm Tiêm chủng MedCare Hospital',
      status: 'Đã hoàn thành',
    ),
  ];

  /// Danh mục các gói khám sức khỏe tổng quát
  static const List<HealthPackage> initialHealthPackages = [
    HealthPackage(
      id: 'pkg-01',
      title: 'Tầm Soát Ung Thư Sớm Đường Tiêu Hóa',
      subtitle: 'Nội soi dạ dày - đại tràng không đau & Test vi khuẩn Hp',
      price: 2850000,
      originalPrice: 3500000,
      isPopular: true,
      targetGroup: 'Người hay đau dạ dày, ợ chua, tiền sử gia đình có polyp',
      benefits: [
        'Nội soi tiền mê không đau, êm ái, tỉnh ngay sau 15 phút',
        'Máy nội soi Olympus EVIS X1 phóng đại 100 lần phát hiện tổn thương vi thể',
        'Bao gồm test nhanh Clo-test tìm vi khuẩn Helicobacter Pylori',
        'Bác sĩ chuyên khoa tiêu hóa tư vấn kết quả và kê đơn trực tiếp',
      ],
      items: [
        'Khám chuyên khoa tiêu hóa với PGS.TS',
        'Nội soi thực quản - dạ dày - tá tràng gây mê',
        'Nội soi toàn bộ đại trực tràng',
        'Test vi khuẩn Hp qua mảnh sinh thiết',
        'Xét nghiệm công thức máu & đông máu cơ bản',
      ],
    ),
    HealthPackage(
      id: 'pkg-02',
      title: 'Khám Sức Khỏe Tổng Quát Định Kỳ VIP',
      subtitle: 'Đánh giá toàn diện 36 chỉ số sinh hóa & Chẩn đoán hình ảnh',
      price: 3950000,
      originalPrice: 4800000,
      isPopular: false,
      targetGroup: 'Nam/Nữ từ 20-65 tuổi muốn kiểm tra thể trạng toàn thân',
      benefits: [
        'Kiểm tra chức năng gan, thận, tim mạch, mỡ máu, đường huyết',
        'Chụp X-quang tim phổi kỹ thuật số & Siêu âm ổ bụng tổng quát màu',
        'Đo điện tim đồ ECG 12 chuyển đạo',
        'Bác sĩ Trưởng khoa kết luận tổng quan và định hướng lối sống',
      ],
      items: [
        'Khám Nội tổng quát, Mắt, Tai mũi họng, Răng hàm mặt',
        'Tổng phân tích tế bào máu 24 thông số',
        'Đường huyết đói & HbA1c đánh giá tiểu đường',
        'Men gan AST, ALT, GGT & Chức năng thận Ure, Creatinine',
        'Bộ mỡ máu Lipid (Cholesterol, Triglyceride, HDL, LDL)',
        'Chụp X-quang ngực thẳng & Siêu âm Doppler ổ bụng',
      ],
    ),
    HealthPackage(
      id: 'pkg-03',
      title: 'Tầm Soát Tim Mạch & Phòng Ngừa Đột Quỵ',
      subtitle: 'Siêu âm tim màu 4D & Đo xơ vữa động mạch cảnh',
      price: 2400000,
      originalPrice: 3000000,
      isPopular: false,
      targetGroup: 'Người có huyết áp dao động, đau ngực, tim đập nhanh hoặc trên 40 tuổi',
      benefits: [
        'Khám chuyên sâu với chuyên gia Viện Tim mạch Quốc gia',
        'Phát hiện sớm nguy cơ nhồi máu cơ tim và xơ vữa mạch máu não',
        'Đo điện tim gắng sức và phân tích rối loạn nhịp tim',
      ],
      items: [
        'Khám Nội Tim mạch cùng PGS.TS Trần Minh Đức',
        'Điện tâm đồ ECG 12 cần',
        'Siêu âm tim Doppler màu 4D công nghệ cao',
        'Siêu âm mạch máu hệ động mạch cảnh đoạn ngoài sọ',
        'Định lượng Troponin-T và Hs-CRP đánh giá viêm mạch vành',
      ],
    ),
  ];

  /// Cẩm nang y khoa & Bài viết chuyên gia
  static const List<HealthArticle> initialArticles = [
    HealthArticle(
      id: 'art-01',
      title: 'Chế độ ăn uống khoa học cho người viêm loét dạ dày có vi khuẩn Hp',
      category: 'Tiêu hóa',
      author: 'PGS.TS.BS Nguyễn Văn An',
      readTime: '4 phút đọc',
      summary: 'Các nguyên tắc vàng trong dinh dưỡng giúp bảo vệ niêm mạc dạ dày và tăng hiệu quả tiệt trừ vi khuẩn Hp.',
      content:
          'Khi đang điều trị vi khuẩn Helicobacter Pylori (Hp), chế độ ăn uống đóng vai trò then chốt quyết định 30% tỷ lệ khỏi bệnh. Bệnh nhân cần:\n\n1. Chia nhỏ bữa ăn thành 4-5 bữa nhẹ trong ngày để dạ dày không bao giờ quá đói hoặc quá no.\n2. Tránh tuyệt đối đồ uống có cồn, bia rượu, cà phê đặc và trà đặc vì chúng kích thích tăng tiết acid chlohydric.\n3. Hạn chế đồ chiên xào nhiều dầu mỡ, đồ muối chua lên men (dưa cà muối).\n4. Bổ sung các loại rau họ cải như bông cải xanh (chứa sulforaphane diệt khuẩn Hp tự nhiên), nghệ vàng và sữa chua men sống sau bữa ăn 1 tiếng.',
      date: '10/02/2026',
    ),
    HealthArticle(
      id: 'art-02',
      title: 'Phân biệt cơn đau thắt ngực do tim và đau tức ngực do trào ngược dạ dày',
      category: 'Tim mạch',
      author: 'PGS.TS.BS Trần Minh Đức',
      readTime: '5 phút đọc',
      summary: 'Rất nhiều bệnh nhân nhầm lẫn giữa trào ngược thực quản dạ dày (GERD) và cơn thiếu máu cơ tim cấp.',
      content:
          'Đau ngực là triệu chứng thường gặp khiến người bệnh rất lo lắng. Để phân biệt:\n\n• Đau do Tim mạch: Thường có cảm giác đè nặng, bóp nghẹt như có đá đè lên vùng ngực trái hoặc sau xương ức, có thể lan lên cằm, vai trái hoặc cánh tay trái. Cơn đau tăng khi gắng sức hoặc xúc động, kéo dài từ 5-15 phút.\n\n• Đau do Trào ngược dạ dày: Thường có cảm giác nóng rát (ợ nóng - heartburn) lan từ vùng thượng vị lên cổ họng, thường xuất hiện sau khi ăn no, khi cúi người hoặc nằm xuống, kèm theo ợ chua, đắng miệng.\n\nKhi có biểu hiện đau tức ngực kèm khó thở, vã mồ hôi lạnh, hãy gọi ngay cấp cứu 1900 8899 để được hỗ trợ kịp thời.',
      date: '08/02/2026',
    ),
    HealthArticle(
      id: 'art-03',
      title: 'Những lưu ý sống còn trước khi tiến hành Nội soi dạ dày gây mê',
      category: 'Cận lâm sàng',
      author: 'BSCKII Hoàng Quốc Việt',
      readTime: '3 phút đọc',
      summary: 'Chuẩn bị đúng cách giúp cuộc nội soi diễn ra an toàn, không đau và hình ảnh niêm mạc rõ nét nhất.',
      content:
          'Để chuẩn bị cho buổi nội soi dạ dày êm ái không đau:\n\n1. Nhịn ăn ít nhất 6-8 tiếng trước giờ nội soi để dạ dày sạch hoàn toàn.\n2. Nhịn uống nước ít nhất 2 tiếng trước khi vào phòng soi để tránh trào ngược dịch vào đường thở khi gây mê.\n3. Thông báo cho bác sĩ tiền sử dị ứng thuốc, bệnh lý tim mạch, hen suyễn hoặc nếu đang uống thuốc chống đông máu.\n4. Cần có người nhà đi cùng để hỗ trợ đưa về sau khi hết thuốc mê.',
      date: '02/02/2026',
    ),
  ];

  /// Lịch sử giao dịch thanh toán viện phí mẫu
  static List<PaymentTransaction> get initialTransactions => [
    PaymentTransaction(
      id: 'TXN-20260312-001',
      visitCode: '#HS-2026-0891',
      description: 'Khám Tiêu hóa + Nội soi + XN máu',
      grossAmount: 1650000,
      insuranceAmount: 1320000,
      netAmount: 330000,
      method: PaymentMethod.vietQr,
      status: PaymentStatus.pending,
      timestamp: DateTime(2026, 3, 12, 9, 30),
      invoiceEmail: 'vu@example.com',
      receiptCode: null,
    ),
    PaymentTransaction(
      id: 'TXN-20260205-002',
      visitCode: '#HS-2026-0612',
      description: 'Khám Tim mạch định kỳ + ECG 12 chuyển đạo',
      grossAmount: 980000,
      insuranceAmount: 784000,
      netAmount: 196000,
      method: PaymentMethod.momo,
      status: PaymentStatus.success,
      timestamp: DateTime(2026, 2, 5, 14, 15),
      walletName: 'MoMo',
      invoiceEmail: 'vu@example.com',
      receiptCode: 'RC-M-20260205-9921',
    ),
    PaymentTransaction(
      id: 'TXN-20260118-003',
      visitCode: '#HS-2026-0341',
      description: 'Khám Thần kinh + MRI não 1.5T',
      grossAmount: 3200000,
      insuranceAmount: 2560000,
      netAmount: 640000,
      method: PaymentMethod.bankCard,
      status: PaymentStatus.success,
      timestamp: DateTime(2026, 1, 18, 10, 45),
      invoiceEmail: 'vu@example.com',
      receiptCode: 'RC-B-20260118-4477',
    ),
    PaymentTransaction(
      id: 'TXN-20251210-004',
      visitCode: '#HS-2025-2814',
      description: 'Xét nghiệm tổng quát cuối năm (15 chỉ số)',
      grossAmount: 750000,
      insuranceAmount: 600000,
      netAmount: 150000,
      method: PaymentMethod.zalopay,
      status: PaymentStatus.refunded,
      timestamp: DateTime(2025, 12, 10, 8, 0),
      walletName: 'ZaloPay',
      invoiceEmail: 'vu@example.com',
      receiptCode: 'RC-Z-20251210-3308',
    ),
  ];

  /// Danh sách các time slot cấu hình mặc định (Admin có thể chỉnh sửa)
  /// Mặc định: 10 bác sĩ × 6 khung giờ × 7 ngày tới
  static List<SlotConfig> buildInitialSlotConfigs() {
    const doctorIds = [
      'doc-01', 'doc-02', 'doc-03', 'doc-04', 'doc-05',
      'doc-06', 'doc-07', 'doc-08', 'doc-09', 'doc-10',
    ];
    const times = ['08:00', '09:00', '10:00', '14:00', '15:00', '16:00'];
    // Capacity mặc định theo khung giờ (sáng đông hơn chiều)
    const defaultCapacity = {
      '08:00': 8,
      '09:00': 10,
      '10:00': 8,
      '14:00': 6,
      '15:00': 6,
      '16:00': 4,
    };

    final slots = <SlotConfig>[];
    final today = DateTime.now();
    for (var d = 1; d <= 7; d++) {
      final day = today.add(Duration(days: d));
      final dateStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      for (final docId in doctorIds) {
        for (final time in times) {
          // Giả lập một số slot đã có người đặt sẵn
          final cap = defaultCapacity[time] ?? 5;
          final booked = switch ('${docId}_$time') {
            'doc-01_09:00' when d == 1 => 9,  // gần đầy
            'doc-01_10:00' when d == 1 => 8,  // đầy
            'doc-02_08:00' when d == 1 => 8,  // đầy
            'doc-03_09:00' when d == 2 => 5,  // đầy
            _ => (d == 1 && time == '09:00') ? 2 : 0,
          };
          slots.add(SlotConfig(
            doctorId: docId,
            date: dateStr,
            time: time,
            capacity: cap,
            booked: booked.clamp(0, cap),
          ));
        }
      }
    }
    return slots;
  }

  /// Danh sách Thành viên Gia đình mẫu
  static List<FamilyMemberProfile> get initialFamilyMembers => [
    const FamilyMemberProfile(
      id: 'fam-01',
      name: 'Nguyễn Hoàng Vũ',
      relation: FamilyRelation.self,
      dateOfBirth: '15/08/2002',
      gender: 'Nam',
      insuranceNumber: 'DN4010123456789',
      bloodType: 'O+',
      allergies: 'Penicillin, Phấn hoa',
      phone: '0901 234 567',
      avatarEmoji: '👨‍💼',
      medicalNotes: 'Tiền sử đau dạ dày do vi khuẩn Hp (đang điều trị)',
    ),
    const FamilyMemberProfile(
      id: 'fam-02',
      name: 'Bé Nguyễn Bảo An',
      relation: FamilyRelation.child,
      dateOfBirth: '10/05/2022',
      gender: 'Nam',
      insuranceNumber: 'TE4010987654321',
      bloodType: 'O+',
      allergies: 'Hải sản (tôm, cua)',
      phone: '0901 234 567',
      avatarEmoji: '👦',
      medicalNotes: '4 tuổi • Đã hoàn thành mũi tiêm 6 trong 1',
    ),
    const FamilyMemberProfile(
      id: 'fam-03',
      name: 'Bác Nguyễn Văn Hùng',
      relation: FamilyRelation.parent,
      dateOfBirth: '20/11/1958',
      gender: 'Nam',
      insuranceNumber: 'HT3010555666777',
      bloodType: 'B+',
      allergies: 'Aspirin',
      phone: '0912 345 678',
      avatarEmoji: '👴',
      medicalNotes: '68 tuổi • Tăng huyết áp độ 2, Đái tháo đường Type 2',
    ),
    const FamilyMemberProfile(
      id: 'fam-04',
      name: 'Trần Thị Mai Anh',
      relation: FamilyRelation.spouse,
      dateOfBirth: '24/09/2003',
      gender: 'Nữ',
      insuranceNumber: 'DN4010888999000',
      bloodType: 'A+',
      allergies: 'Không có',
      phone: '0933 456 789',
      avatarEmoji: '👩‍💼',
      medicalNotes: 'Sức khỏe tốt • Tầm soát phụ khoa định kỳ hàng năm',
    ),
  ];

  /// Dữ liệu xu hướng xét nghiệm cận lâm sàng qua 5 lần khám
  static List<LabTrendPoint> get initialLabTrends => [
    LabTrendPoint(
      dateStr: 'T8/2025',
      timestamp: DateTime(2025, 8, 15),
      bloodGlucose: 118.0, // Tiền đái tháo đường
      alt: 48.0,           // Men gan tăng nhẹ
      ast: 42.0,
      cholesterolTotal: 5.8, // Hơi cao
      uricAcid: 410.0,
    ),
    LabTrendPoint(
      dateStr: 'T10/2025',
      timestamp: DateTime(2025, 10, 20),
      bloodGlucose: 108.0,
      alt: 42.0,
      ast: 38.0,
      cholesterolTotal: 5.4,
      uricAcid: 385.0,
    ),
    LabTrendPoint(
      dateStr: 'T12/2025',
      timestamp: DateTime(2025, 12, 10),
      bloodGlucose: 102.0,
      alt: 36.0,
      ast: 32.0,
      cholesterolTotal: 5.0, // Về chuẩn
      uricAcid: 360.0,
    ),
    LabTrendPoint(
      dateStr: 'T1/2026',
      timestamp: DateTime(2026, 1, 18),
      bloodGlucose: 98.0,
      alt: 31.0,
      ast: 28.0,
      cholesterolTotal: 4.8,
      uricAcid: 340.0,
    ),
    LabTrendPoint(
      dateStr: 'T3/2026',
      timestamp: DateTime(2026, 3, 12),
      bloodGlucose: 94.0,  // Tối ưu chuẩn ADA
      alt: 28.0,           // Bình thường
      ast: 26.0,
      cholesterolTotal: 4.6, // Chuẩn
      uricAcid: 320.0,
    ),
  ];

  /// Đơn thuốc giao tận nhà mẫu
  static List<PharmacyOrder> get initialPharmacyOrders => [
    PharmacyOrder(
      id: 'PHARM-20260312-01',
      prescriptionId: 'DT-2026-0891',
      patientName: 'Nguyễn Hoàng Vũ',
      phone: '0901 234 567',
      deliveryAddress: 'Số 28, Phố Huế, Q. Hoàn Kiếm, Hà Nội',
      pharmacyName: 'Nhà thuốc Bệnh viện MedCare & FPT Long Châu',
      itemsCount: 4,
      medicineTotal: 345000,
      shippingFee: 25000,
      status: PharmacyOrderStatus.shipping,
      orderedAt: DateTime.now().subtract(const Duration(minutes: 25)),
      estimatedMinutes: 20,
    ),
  ];

  /// Chỉ số KPI Bệnh viện hôm nay (Admin & Doctor Dashboard)
  static HospitalKpiData get initialHospitalKpi => const HospitalKpiData(
    todayPatients: 342,
    todayRevenue: 184500000, // 184.5 triệu
    avgWaitMinutes: 14,
    occupancyRatePercent: 88,
    totalDoctorsOnDuty: 20,
    completedConsultations: 215,
    npsSatisfactionScore: 96.8,
    totalReviews: 142,
  );

  /// 12 Chỉ số xét nghiệm huyết học & sinh hóa mẫu (AI Lab Explainer)
  static List<LabReportItem> get initialLabReports => [
    const LabReportItem(
      id: 'lab-01',
      code: 'WBC',
      name: 'Số lượng Bạch cầu (White Blood Cells)',
      category: LabCategory.hematology,
      value: 10.8,
      unit: 'G/L',
      referenceRange: '4.0 - 10.0 G/L',
      riskLevel: LabRiskLevel.warning,
      clinicalMeaning: 'Bạch cầu tăng nhẹ, thường phản ánh cơ thể đang có phản ứng viêm hoặc nhiễm khuẩn nhẹ (như viêm họng, vết xước).',
      dietaryAdvice: 'Uống nhiều nước, bổ sung thực phẩm giàu vitamin C (cam, bưởi, ổi) để tăng cường đề kháng.',
      testedAt: '12/03/2026',
    ),
    const LabReportItem(
      id: 'lab-02',
      code: 'RBC',
      name: 'Số lượng Hồng cầu (Red Blood Cells)',
      category: LabCategory.hematology,
      value: 4.65,
      unit: 'T/L',
      referenceRange: '4.0 - 5.8 T/L',
      riskLevel: LabRiskLevel.normal,
      clinicalMeaning: 'Hồng cầu trong giới hạn bình thường, khả năng vận chuyển oxy nuôi cơ thể hoạt động tốt.',
      dietaryAdvice: 'Duy trì chế độ ăn đủ chất sắt từ thịt nạc, trứng và các loại hạt ngũ cốc.',
      testedAt: '12/03/2026',
    ),
    const LabReportItem(
      id: 'lab-03',
      code: 'HGB',
      name: 'Huyết sắc tố (Hemoglobin)',
      category: LabCategory.hematology,
      value: 148.0,
      unit: 'g/L',
      referenceRange: '130 - 175 g/L',
      riskLevel: LabRiskLevel.normal,
      clinicalMeaning: 'Chỉ số Hemoglobin tối ưu, không có dấu hiệu thiếu máu hay xuất huyết tiềm ẩn.',
      dietaryAdvice: 'Tiếp tục duy trì khẩu phần ăn uống cân đối, tập thể thao đều đặn.',
      testedAt: '12/03/2026',
    ),
    const LabReportItem(
      id: 'lab-04',
      code: 'PLT',
      name: 'Số lượng Tiểu cầu (Platelets)',
      category: LabCategory.hematology,
      value: 245.0,
      unit: 'G/L',
      referenceRange: '150 - 450 G/L',
      riskLevel: LabRiskLevel.normal,
      clinicalMeaning: 'Tiểu cầu ổn định, chức năng đông máu và cầm máu diễn ra bình thường.',
      dietaryAdvice: 'Không cần kiêng cữ đặc biệt.',
      testedAt: '12/03/2026',
    ),
    const LabReportItem(
      id: 'lab-05',
      code: 'GLU',
      name: 'Đường huyết đói (Fasting Blood Glucose)',
      category: LabCategory.biochemistry,
      value: 112.0,
      unit: 'mg/dL',
      referenceRange: '70 - 99 mg/dL',
      riskLevel: LabRiskLevel.warning,
      clinicalMeaning: 'Đường huyết lúc đói tăng nhẹ trên ngưỡng 100 mg/dL, cảnh báo giai đoạn Tiền Đái tháo đường.',
      dietaryAdvice: 'Cắt giảm nước ngọt, trà sữa, bánh kẹo; thay cơm trắng bằng gạo lứt hoặc khoai lang, tập đi bộ 30 phút/ngày.',
      testedAt: '12/03/2026',
    ),
    const LabReportItem(
      id: 'lab-06',
      code: 'HbA1c',
      name: 'Đường hóa huyết sắc tố (HbA1c)',
      category: LabCategory.biochemistry,
      value: 6.2,
      unit: '%',
      referenceRange: '4.0 - 5.6 %',
      riskLevel: LabRiskLevel.warning,
      clinicalMeaning: 'Phản ánh mức đường huyết trung bình trong 3 tháng qua đang ở ngưỡng nguy cơ (5.7% - 6.4%).',
      dietaryAdvice: 'Ăn nhiều chất xơ rau củ trước bữa ăn chính để làm chậm hấp thu đường.',
      testedAt: '12/03/2026',
    ),
    const LabReportItem(
      id: 'lab-07',
      code: 'ALT',
      name: 'Men gan Alanine Aminotransferase (ALT / SGPT)',
      category: LabCategory.biochemistry,
      value: 48.0,
      unit: 'U/L',
      referenceRange: '< 40 U/L',
      riskLevel: LabRiskLevel.warning,
      clinicalMeaning: 'Men gan tăng nhẹ báo hiệu tế bào gan đang bị kích ứng hoặc tích tụ mỡ nhẹ.',
      dietaryAdvice: 'Hạn chế bia rượu tuyệt đối trong 2 tuần, không thức khuya sau 23h, uống trà atiso mát gan.',
      testedAt: '12/03/2026',
    ),
    const LabReportItem(
      id: 'lab-08',
      code: 'AST',
      name: 'Men gan Aspartate Aminotransferase (AST / SGOT)',
      category: LabCategory.biochemistry,
      value: 34.0,
      unit: 'U/L',
      referenceRange: '< 40 U/L',
      riskLevel: LabRiskLevel.normal,
      clinicalMeaning: 'Men gan AST nằm trong giới hạn cho phép, cơ tim và gan không có tổn thương cấp.',
      dietaryAdvice: 'Duy trì lối sống lành mạnh.',
      testedAt: '12/03/2026',
    ),
    const LabReportItem(
      id: 'lab-09',
      code: 'CREA',
      name: 'Định lượng Creatinine huyết thanh',
      category: LabCategory.biochemistry,
      value: 82.0,
      unit: 'umol/L',
      referenceRange: '62 - 106 umol/L',
      riskLevel: LabRiskLevel.normal,
      clinicalMeaning: 'Chức năng lọc cầu thận bình thường, thận bài tiết tốt các chất cặn bã.',
      dietaryAdvice: 'Uống đủ 1.5 - 2 lít nước lọc mỗi ngày, không nhịn tiểu.',
      testedAt: '12/03/2026',
    ),
    const LabReportItem(
      id: 'lab-10',
      code: 'URIC',
      name: 'Axit Uric máu (Nguy cơ bệnh Gout)',
      category: LabCategory.biochemistry,
      value: 445.0,
      unit: 'umol/L',
      referenceRange: '200 - 420 umol/L',
      riskLevel: LabRiskLevel.critical,
      clinicalMeaning: 'Axit uric vượt ngưỡng chuẩn, có nguy cơ kết tủa tinh thể urat tại các khớp ngón chân gây sưng đau Gout.',
      dietaryAdvice: 'Kiêng phủ tạng động vật, thịt bò, tôm cua, nước hầm xương; uống nhiều nước kiềm ion.',
      testedAt: '12/03/2026',
    ),
    const LabReportItem(
      id: 'lab-11',
      code: 'CHOL',
      name: 'Cholesterol toàn phần (Total Cholesterol)',
      category: LabCategory.biochemistry,
      value: 5.6,
      unit: 'mmol/L',
      referenceRange: '< 5.2 mmol/L',
      riskLevel: LabRiskLevel.warning,
      clinicalMeaning: 'Mỡ máu tăng nhẹ trên giới hạn khuyến cáo, cần theo dõi đề phòng xơ vữa động mạch.',
      dietaryAdvice: 'Hạn chế mỡ động vật, bơ, đồ chiên rán; tăng cường ăn cá biển béo (cá hồi, cá trích).',
      testedAt: '12/03/2026',
    ),
    const LabReportItem(
      id: 'lab-12',
      code: 'TRIG',
      name: 'Triglycerides máu',
      category: LabCategory.biochemistry,
      value: 2.3,
      unit: 'mmol/L',
      referenceRange: '< 1.7 mmol/L',
      riskLevel: LabRiskLevel.warning,
      clinicalMeaning: 'Chỉ số Triglyceride tăng phản ánh chế độ ăn dư thừa calo và tinh bột gần đây.',
      dietaryAdvice: 'Giảm đồ uống có cồn và đường tinh luyện, tích cực vận động thể chất để đốt năng lượng.',
      testedAt: '12/03/2026',
    ),
  ];

  /// Danh sách chính sách bảo hiểm liên kết (Bảo lãnh viện phí Cashless)
  static List<InsurancePolicy> get initialInsurancePolicies => [
    const InsurancePolicy(
      id: 'pol-bhyt',
      providerName: 'Bảo Hiểm Y Tế Quốc Gia (BHYT)',
      policyNumber: 'DN4010123456789',
      cardHolderName: 'Nguyễn Hoàng Vũ',
      outpatientLimit: 50000000,
      inpatientLimit: 150000000,
      usedAmount: 1850000,
      expireDate: '31/12/2026',
      coveragePercent: 80,
      logoEmoji: '🇻🇳',
    ),
    const InsurancePolicy(
      id: 'pol-baoviet',
      providerName: 'Bảo Việt An Gia (Bảo Việt Tokio Marine)',
      policyNumber: 'BV-AG-998241',
      cardHolderName: 'Nguyễn Hoàng Vũ',
      outpatientLimit: 20000000,
      inpatientLimit: 80000000,
      usedAmount: 4200000,
      expireDate: '15/10/2026',
      coveragePercent: 100,
      logoEmoji: '🛡️',
    ),
    const InsurancePolicy(
      id: 'pol-pvicare',
      providerName: 'PVI Care Toàn Diện',
      policyNumber: 'PVI-CARE-77123',
      cardHolderName: 'Nguyễn Hoàng Vũ',
      outpatientLimit: 15000000,
      inpatientLimit: 60000000,
      usedAmount: 0,
      expireDate: '01/08/2026',
      coveragePercent: 100,
      logoEmoji: '🏢',
    ),
  ];

  /// Các gói thời gian khám của bệnh nhân (Appointment Passes)
  static List<AppointmentPassPackage> get initialAppointmentPasses => [
    const AppointmentPassPackage(
      id: 'pass-std',
      title: 'Gói Tiêu Chuẩn',
      subtitle: 'Khám giờ hành chính (08:00 - 17:00)',
      priceDelta: 0,
      badge: 'TIÊU CHUẨN',
      benefits: [
        'Khám trực tiếp với Bác sĩ chuyên khoa',
        'Xếp hàng lấy số thứ tự theo thời gian đặt',
        'Hỗ trợ thanh toán bảo lãnh BHYT cơ bản',
      ],
    ),
    const AppointmentPassPackage(
      id: 'pass-vip',
      title: 'Gói VIP Ưu Tiên Nhanh',
      subtitle: 'Vào khám ngay, không cần chờ đợi',
      priceDelta: 150000,
      badge: '★ KHUYÊN DÙNG ★',
      isPopular: true,
      benefits: [
        'Ưu tiên vào khám ngay trong vòng 5 phút',
        'Phòng chờ VIP thương gia máy lạnh, trà bánh nước miễn phí',
        'Bác sĩ Trưởng khoa / Giáo sư trực tiếp thăm khám',
        'Miễn phí đo huyết áp & đường huyết mao mạch tại chỗ',
      ],
    ),
    const AppointmentPassPackage(
      id: 'pass-afterhours',
      title: 'Gói Khám Ngoài Giờ & Cuối Tuần',
      subtitle: 'Khám tối 17:30 - 20:30 & Thứ 7/CN',
      priceDelta: 80000,
      badge: 'NGOÀI GIỜ',
      benefits: [
        'Linh hoạt cho người bận rộn đi làm cả ngày',
        'Không gian thông thoáng, xét nghiệm nhanh không chen lấn',
        'Bác sĩ chuyên khoa trực tiếp khám và kê đơn điện tử',
      ],
    ),
    const AppointmentPassPackage(
      id: 'pass-combo',
      title: 'Gói Combo Tầm Soát Toàn Diện',
      subtitle: 'Khám chuyên khoa + Combo xét nghiệm máu',
      priceDelta: 420000,
      badge: 'TIẾT KIỆM 30%',
      benefits: [
        'Khám lâm sàng chuyên khoa tim mạch / tiêu hóa',
        'Bộ 10 chỉ số xét nghiệm huyết học & sinh hóa máu',
        'Chụp X-quang tim phổi thẳng kỹ thuật số',
        'Siêu âm ổ bụng tổng quát & tư vấn dinh dưỡng',
      ],
    ),
  ];

  /// Lịch nhắc tái khám tự động (Auto Follow-up Reminders)
  static List<FollowUpReminder> get initialFollowUpReminders => [
    FollowUpReminder(
      id: 'rem-01',
      doctorName: 'PGS.TS.BS Trần Minh Đức',
      specialty: 'Tim mạch',
      reminderDate: DateTime.now().add(const Duration(days: 14)),
      clinicalReason: 'Tái khám định kỳ tăng huyết áp & đánh giá hiệu quả thuốc Amlodipine',
      doctorInstructions: 'Uống thuốc đúng giờ, đo huyết áp mỗi sáng ghi vào nhật ký sinh hiệu, mang theo đơn thuốc cũ.',
    ),
  ];

  /// Đánh giá bác sĩ sau khám mẫu (Doctor Reviews)
  static List<DoctorReview> get initialDoctorReviews => [
    DoctorReview(
      id: 'rev-01',
      doctorId: 'doc-01',
      doctorName: 'PGS.TS.BS Trần Minh Đức',
      patientName: 'Nguyễn Hoàng Vũ',
      rating: 5.0,
      comment: 'Bác sĩ Đức giải thích rất tận tâm, phân tích kỹ từng chỉ số điện tâm đồ và điều chỉnh liều thuốc rất phù hợp.',
      treatmentDepartment: 'Khoa Tim mạch',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    DoctorReview(
      id: 'rev-02',
      doctorId: 'doc-05',
      doctorName: 'PGS.TS.BS Nguyễn Văn An',
      patientName: 'Trần Văn Cường',
      rating: 5.0,
      comment: 'Bác sĩ nội soi dạ dày rất nhẹ nhàng, không bị đau hay khó chịu. Rất khuyên mọi người đến khám.',
      treatmentDepartment: 'Khoa Tiêu hóa',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  /// Nhật ký Giám sát Bảo mật (Audit Logs) thời gian thực chuẩn HIPAA & Nghị định 13
  static List<SecurityAuditLog> get initialSecurityAuditLogs => [
    SecurityAuditLog(
      id: 'audit-101',
      actor: 'Admin Hệ Thống (admin@medcare.vn)',
      action: 'Cập nhật hạn mức capacity slot',
      targetResource: 'Slot Khoa Tim mạch 08:00 - 09:00',
      ipAddress: '192.168.1.10 (Mạng Nội viện)',
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      severity: SecuritySeverity.info,
      statusDescription: 'Thành công - Điều chỉnh tăng capacity lên 12 bệnh nhân',
    ),
    SecurityAuditLog(
      id: 'audit-102',
      actor: 'BS. Trần Minh Đức (doc-01)',
      action: 'Truy cập Bệnh án Điện tử (EMR Access)',
      targetResource: 'Bệnh nhân: Nguyễn Hoàng Vũ (MC-89241)',
      ipAddress: '10.0.4.15 (Tablet Bác sĩ)',
      timestamp: DateTime.now().subtract(const Duration(minutes: 22)),
      severity: SecuritySeverity.info,
      statusDescription: 'Thành công - Xem kết quả xét nghiệm sinh hóa máu',
    ),
    SecurityAuditLog(
      id: 'audit-103',
      actor: 'Bệnh nhân: Nguyễn Hoàng Vũ',
      action: 'Xác thực Đăng nhập sinh trắc học',
      targetResource: 'MedCare Mobile App',
      ipAddress: '14.162.88.21 (Viettel 5G)',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      severity: SecuritySeverity.info,
      statusDescription: 'Thành công - Token phiên làm việc mã hóa 256-bit',
    ),
    SecurityAuditLog(
      id: 'audit-104',
      actor: 'Tường lửa WAF Bệnh viện',
      action: 'Ngăn chặn quét lỗ hổng trái phép',
      targetResource: 'Cổng API Cận lâm sàng',
      ipAddress: '185.220.101.5 (IP Ngoại biên)',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      severity: SecuritySeverity.danger,
      statusDescription: 'Đã chặn tự động - Phát hiện mẫu dò quét SQL Injection',
    ),
    SecurityAuditLog(
      id: 'audit-105',
      actor: 'Dược sĩ Nhà thuốc MedCare',
      action: 'Kiểm tra tương tác dị ứng thuốc',
      targetResource: 'Đơn thuốc: DT-2026-0891',
      ipAddress: '192.168.1.52 (Quầy Dược Nhà A)',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      severity: SecuritySeverity.warning,
      statusDescription: 'Cảnh báo - Tự động đối chiếu dị ứng Penicillin thành công',
    ),
  ];

  /// Danh sách thiết bị và phiên đang đăng nhập (Active Sessions)
  static List<ActiveSessionInfo> get initialActiveSessions => [
    const ActiveSessionInfo(
      id: 'sess-01',
      deviceName: 'Chrome 122 on Windows 11',
      clientType: 'Cổng Quản Trị Admin Web',
      ipAddress: '192.168.1.10',
      lastActive: 'Vừa xong',
      isCurrent: true,
    ),
    const ActiveSessionInfo(
      id: 'sess-02',
      deviceName: 'iPad Pro 11" (Phòng khám 402)',
      clientType: 'Tablet Bác sĩ Trực tiếp',
      ipAddress: '10.0.4.15',
      lastActive: '5 phút trước',
      isCurrent: false,
    ),
    const ActiveSessionInfo(
      id: 'sess-03',
      deviceName: 'iPhone 15 Pro Max',
      clientType: 'Ứng dụng Bệnh nhân Mobile',
      ipAddress: '14.162.88.21',
      lastActive: '12 phút trước',
      isCurrent: false,
    ),
  ];

  /// Lịch sử giao dịch ví viện phí MedCare Pay
  static List<HospitalWalletTransaction> get initialWalletTransactions => [
    HospitalWalletTransaction(
      id: 'TXN-001',
      title: 'Tạm ứng viện phí khám ban đầu',
      amount: 1000000,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isDebit: true,
      description: 'Nộp tạm ứng ban đầu theo chỉ định buồng khám',
    ),
    HospitalWalletTransaction(
      id: 'TXN-002',
      title: 'Trừ chi phí xét nghiệm sinh hóa 10 chỉ số',
      amount: 250000,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isDebit: true,
      description: 'Trừ trực tiếp từ tiền tạm ứng',
    ),
    HospitalWalletTransaction(
      id: 'TXN-003',
      title: 'Tự động hoàn trả tiền tạm ứng dư (Auto-Refund)',
      amount: 750000,
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      isDebit: false,
      description: 'Hoàn trả tức thì 100% số dư tạm ứng về tài khoản ngân hàng',
    ),
  ];
}



