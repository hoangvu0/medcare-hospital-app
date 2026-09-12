import 'package:flutter_test/flutter_test.dart';
import 'package:bt2_2324801030077/data/medical_data.dart';
import 'package:bt2_2324801030077/models/medical_models.dart';
import 'package:bt2_2324801030077/state/medical_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hệ Thống Y Tế Nâng Cấp Toàn Diện - Unit Tests', () {
    late MedicalStore store;

    setUp(() {
      store = MedicalStore();
    });

    test('1. Kiểm tra mở rộng danh mục 20 Bác sĩ chuyên khoa đầu ngành', () {
      expect(store.doctors.length, equals(20));
      final gs = store.doctors.where((d) => d.name.startsWith('GS'));
      expect(gs.isNotEmpty, isTrue);
      expect(gs.first.name, contains('Nguyễn Chấn Hùng'));

      final pgs = store.doctors.where((d) => d.name.startsWith('PGS'));
      expect(pgs.length, greaterThanOrEqualTo(2));

      final specialties = MedicalData.specialties;
      expect(specialties, contains('Ung bướu & Xạ trị'));
      expect(specialties, contains('Hô hấp & Phổi'));
    });

    test('2. Kiểm tra Trợ lý AI Diễn giải Xét nghiệm (12 chỉ số chuẩn hóa)', () {
      final labs = store.labReports;
      expect(labs.length, equals(12));

      final hematology = labs.where((l) => l.category == LabCategory.hematology).toList();
      expect(hematology.length, equals(4)); // WBC, RBC, HGB, PLT

      final biochemistry = labs.where((l) => l.category == LabCategory.biochemistry).toList();
      expect(biochemistry.length, equals(8)); // GLU, HbA1c, ALT, AST, CREA, URIC, CHOL, TRIG

      final uric = labs.firstWhere((l) => l.code == 'URIC');
      expect(uric.riskLevel, equals(LabRiskLevel.critical));
      expect(uric.clinicalMeaning, contains('Gout'));

      final glu = labs.firstWhere((l) => l.code == 'GLU');
      expect(glu.dietaryAdvice, isNotEmpty);
    });

    test('3. Kiểm tra Bảo lãnh Viện phí Tư nhân Trực tiếp (Cashless Claim)', () {
      expect(store.insurancePolicies.length, greaterThanOrEqualTo(3));

      final claim = store.submitCashlessClaim(
        policyNumber: 'BV-AG-998241',
        providerName: 'Bảo Việt An Gia',
        totalBill: 1000000,
        coveredPercent: 100,
      );

      expect(claim.coveredAmount, equals(1000000));
      expect(claim.patientCoPay, equals(0));
      expect(claim.status, equals(CashlessClaimStatus.approved));
      expect(store.cashlessClaims.length, equals(1));

      // Kiểm tra có ghi nhận vào Audit Log
      final latestLog = store.securityAuditLogs.first;
      expect(latestLog.action, contains('Bảo lãnh viện phí'));
    });

    test('4. Kiểm tra Tự động nhắc Tái khám & Đánh giá Bác sĩ NPS', () {
      final initialReviewsCount = store.hospitalKpi.totalReviews;

      // Bác sĩ hoàn tất ca khám
      store.doctorFinishConsultation('GS.TS.BS Nguyễn Chấn Hùng', 'Ung bướu & Xạ trị');
      expect(store.followUpReminders.isNotEmpty, isTrue);
      expect(store.followUpReminders.first.doctorName, equals('GS.TS.BS Nguyễn Chấn Hùng'));

      // Bệnh nhân gửi đánh giá 5 sao
      final review = DoctorReview(
        id: 'rev-test-01',
        doctorId: 'doc-11',
        doctorName: 'GS.TS.BS Nguyễn Chấn Hùng',
        patientName: 'Nguyễn Hoàng Vũ',
        rating: 5.0,
        comment: 'Bác sĩ Hùng khám và tư vấn rất tận tình!',
        treatmentDepartment: 'Khoa Ung bướu',
        createdAt: DateTime.now(),
      );

      store.submitDoctorReview(review);
      expect(store.doctorReviews.length, greaterThanOrEqualTo(3));
      expect(store.hospitalKpi.totalReviews, equals(initialReviewsCount + 1));
      expect(store.hospitalKpi.npsSatisfactionScore, greaterThanOrEqualTo(90.0));
    });

    test('5. Kiểm tra Giám Sát An Ninh & Khóa Hệ Thống Khẩn Cấp (Lockdown)', () {
      expect(store.isEmergencyLockdown, isFalse);
      store.toggleEmergencyLockdown();
      expect(store.isEmergencyLockdown, isTrue);

      final latestLog = store.securityAuditLogs.first;
      expect(latestLog.action, contains('KHÓA HỆ THỐNG KHẨN CẤP'));
      expect(latestLog.severity, equals(SecuritySeverity.danger));

      store.toggleEmergencyLockdown();
      expect(store.isEmergencyLockdown, isFalse);
    });

    test('6. Kiểm tra Chế độ Người cao tuổi (Senior Mode Toggle)', () {
      expect(store.isSeniorMode, isFalse);
      store.toggleSeniorMode();
      expect(store.isSeniorMode, isTrue);
      store.toggleSeniorMode();
      expect(store.isSeniorMode, isFalse);
    });

    test('7. Kiểm tra Ví Viện Phí & Tự Động Hoàn Tiền Tạm Ứng (Auto-Refund)', () {
      final initialBalance = store.walletBalance;
      final initialDeposit = store.advanceDeposit;

      expect(initialDeposit, greaterThan(0));

      // Thực hiện hoàn tiền tự động 100%
      store.autoRefundAdvance();
      expect(store.advanceDeposit, equals(0));
      expect(store.walletBalance, equals(initialBalance + initialDeposit));
      expect(store.walletTransactions.first.title, contains('Tự động hoàn trả'));
    });

    test('8. Kiểm tra Gói thời gian khám bệnh (Appointment Passes)', () {
      final passes = store.appointmentPasses;
      expect(passes.length, equals(4));

      final vip = passes.firstWhere((p) => p.id == 'pass-vip');
      expect(vip.isPopular, isTrue);
      expect(vip.priceDelta, equals(150000));
      expect(vip.benefits, isNotEmpty);
    });

    test('9. Kiểm tra Đăng nhập tài khoản Bác sĩ & Chuyển đổi vai trò tương tác', () {
      // Đăng nhập bằng tài khoản Bác sĩ
      final ok = store.login(identifier: 'doctor@medcare.vn', password: '123456');
      expect(ok, isTrue);
      expect(store.isDoctorRole, isTrue);
      expect(store.currentUserRole, equals(UserRole.doctor));
      expect(store.activeDoctorUser.name, contains('Trần Minh Đức'));

      // Chuyển đổi sang Bệnh nhân
      store.switchRole(UserRole.patient);
      expect(store.isDoctorRole, isFalse);
      expect(store.currentUserRole, equals(UserRole.patient));
    });

    test('10. Kiểm tra Tương tác 2 chiều Bác sĩ gọi số, kê đơn và nhắc tái khám cho Bệnh nhân', () {
      // Bác sĩ gọi bệnh nhân vào phòng 402
      store.doctorCallNextPatient('Phòng 402');
      expect(store.queueInfo.room, equals('Phòng 402'));

      // Bác sĩ kê đơn thuốc
      store.doctorPrescribeMedication(
        patientName: 'Nguyễn Hoàng Vũ',
        diagnosis: 'Tăng huyết áp nguyên phát độ 1',
        medicines: ['Amlodipine 5mg', 'Atorvastatin 10mg'],
        advice: 'Ăn nhạt, đo huyết áp mỗi ngày',
      );
      expect(store.notifications.first.title, contains('đã kê đơn thuốc'));

      // Bác sĩ hoàn tất ca khám
      final initialReminders = store.followUpReminders.length;
      store.doctorFinishConsultation('PGS.TS.BS Trần Minh Đức', 'Tim mạch');
      expect(store.followUpReminders.length, equals(initialReminders + 1));
      expect(store.followUpReminders.first.doctorName, contains('Trần Minh Đức'));
    });

    test('11. Kiểm tra Quy trình & Lộ trình khám bệnh 6 bước chuẩn (Clinical Pathway Tracker)', () {
      final pathway = store.clinicalPathway;
      expect(pathway.length, equals(6));

      // Ban đầu: Bước 1, 2 xong, Bước 3 đang thực hiện
      expect(store.completedStepsCount, equals(2));
      expect(store.currentPathwayStep.stepNumber, equals(3));
      expect(store.currentPathwayStep.title, contains('Cận lâm sàng'));
      expect(store.currentPathwayStep.location, contains('Phòng 204'));

      // Hoàn thành Bước 3 (Xét nghiệm xong) -> Chuyển sang Bước 4 (Quay lại Bác sĩ kết luận)
      store.advancePathwayStep(3);
      expect(store.completedStepsCount, equals(3));
      expect(store.currentPathwayStep.stepNumber, equals(4));
      expect(store.currentPathwayStep.title, contains('Quay lại Bác sĩ'));

      // Đặt lại lộ trình
      store.resetPathway();
      expect(store.completedStepsCount, equals(2));
      expect(store.currentPathwayStep.stepNumber, equals(3));
    });

    test('12. Kiểm tra Phân quyền Đăng nhập Độc lập 3 vai trò (Bệnh nhân, Bác sĩ, Admin)', () {
      // 1. Đăng nhập Bệnh nhân
      final patientOk = store.login(identifier: 'vu@example.com', password: 'password123');
      expect(patientOk, isTrue);
      expect(store.currentUserRole, equals(UserRole.patient));
      expect(store.isDoctorRole, isFalse);
      expect(store.isAdminRole, isFalse);

      // 2. Đăng nhập Bác sĩ
      final doctorOk = store.login(identifier: 'doctor@medcare.vn', password: 'password123');
      expect(doctorOk, isTrue);
      expect(store.currentUserRole, equals(UserRole.doctor));
      expect(store.isDoctorRole, isTrue);
      expect(store.isAdminRole, isFalse);
      expect(store.activeDoctorUser.name, contains('Trần Minh Đức'));

      // 3. Đăng nhập Admin
      final adminOk = store.login(identifier: 'admin@medcare.vn', password: 'admin123password');
      expect(adminOk, isTrue);
      expect(store.currentUserRole, equals(UserRole.admin));
      expect(store.isAdminRole, isTrue);
      expect(store.isDoctorRole, isFalse);
    });

    test('13. 🔥 SIÊU TEST: Bác sĩ ký số EMR & Đồng bộ 100% dữ liệu sang tài khoản Bệnh nhân', () {
      // Chuẩn bị danh mục thuốc kê đơn từ Bác sĩ
      final prescribed = [
        const MedicineItem(
          name: 'Amlodipine Besylate',
          category: 'Thuốc hạ áp',
          dosage: '5mg',
          quantity: '30 viên',
          instruction: 'Uống 1 viên vào 8:00 sáng sau ăn',
          warning: 'Không dừng thuốc đột ngột',
        ),
        const MedicineItem(
          name: 'Rosuvastatin',
          category: 'Hạ lipid máu',
          dosage: '10mg',
          quantity: '30 viên',
          instruction: 'Uống 1 viên vào 20:00 tối trước ngủ',
        ),
      ];

      final initialRecordsCount = store.medicalRecords.length;
      final initialScheduleCount = store.medicineSchedule.length;

      // Bác sĩ thực thi buổi khám hoàn chỉnh và truyền dữ liệu
      store.doctorExecuteFullConsultationSync(
        diagnosis: 'Tăng huyết áp nguyên phát độ 1',
        icd10Code: 'I10',
        icd10Name: 'Tăng huyết áp vô căn (nguyên phát)',
        symptoms: 'Đau đầu chẩm, hồi hộp khi gắng sức',
        physicalExam: 'Tim đều T1 T2 rõ, huyết áp 135/85 mmHg, bụng mềm',
        labNotes: 'Glucose 5.6 mmol/L, Creatinine 82 µmol/L (eGFR 95)',
        doctorAdvice: 'Ăn nhạt dưới 5g muối/ngày, tập thể dục nhẹ, không hút thuốc',
        followUpDate: '26/02/2026',
        prescribedMedicines: prescribed,
        riskLevel: 'Theo dõi định kỳ tim mạch',
      );

      // 1. Kiểm tra Hồ sơ Bệnh án EMR của Bệnh nhân nhận được
      expect(store.medicalRecords.length, equals(initialRecordsCount + 1));
      final latestRecord = store.medicalRecords.first;
      expect(latestRecord.diagnosisCode, equals('I10'));
      expect(latestRecord.icd10Name, contains('Tăng huyết áp'));
      expect(latestRecord.physicalExamNotes, contains('135/85'));
      expect(latestRecord.doctorInstructions, contains('Ăn nhạt'));
      expect(latestRecord.digitalSignatureToken, contains('EMR-SHA256-VN-VALIDATED'));
      expect(latestRecord.prescribedMedicinesSummary, contains('Amlodipine Besylate'));

      // 2. Kiểm tra Danh mục thuốc và Lịch uống thuốc tự động của Bệnh nhân
      expect(store.medicineSchedule.length, equals(initialScheduleCount + 2));
      expect(store.medicineSchedule.first.medicineName, equals('Rosuvastatin'));
      expect(store.medicineSchedule[1].medicineName, equals('Amlodipine Besylate'));

      // 3. Kiểm tra Lộ trình khám bệnh Clinical Pathway tự động hoàn thành
      expect(store.clinicalPathway[2].status, equals(ClinicalStepStatus.completed)); // Bước 3 xong
      expect(store.clinicalPathway[3].status, equals(ClinicalStepStatus.completed)); // Bước 4 xong

      // 4. Kiểm tra Push Notification gửi tới ứng dụng Bệnh nhân
      expect(store.notifications.first.title, contains('ký số'));
      expect(store.notifications.first.body, contains('Trần Minh Đức'));

      // 5. Kiểm tra Nhật ký an ninh kiểm toán HIPAA EMR ghi nhận
      expect(store.securityAuditLogs.first.action, equals('EMR_FINAL_CONSULTATION_SYNC'));
    });

    test('14. Kiểm tra 32 Chức năng Lâm sàng chuyên sâu của Bác sĩ', () {
      // Sinh hiệu
      store.doctorRecordVitals(
        bpSys: 130,
        bpDia: 80,
        heartRate: 72,
        spo2: 99,
        temp: 36.6,
        weight: 68.0,
      );
      expect(store.vitals.first.systolic, equals(130));
      expect(store.vitals.first.heartRate, equals(72));

      // Cận lâm sàng CBC & Sinh hóa
      store.doctorOrderCBC();
      expect(store.labTests.first.name, contains('CBC'));

      store.doctorOrderBloodBiochemistry();
      expect(store.labTests.first.name, contains('Creatinine'));

      // Dược lâm sàng: Tương tác thuốc & Tính liều thận
      final interaction = store.doctorCheckDrugInteraction('Amlodipine', 'Atorvastatin');
      expect(interaction, contains('Không phát hiện tương tác đối kháng'));

      final isAllergic = store.doctorCheckAllergyRisk('Penicillin');
      expect(isAllergic, isTrue);

      final renalDose = store.doctorCalculateRenalDose(68.0, 95.0);
      expect(renalDose, contains('Chức năng thận bảo tồn'));

      // Ký số EMR
      final token = store.doctorDigitalSignEmr(signer: 'PGS.TS.BS Trần Minh Đức', certKey: 'TEST-KEY');
      expect(token, contains('EMR-SHA256'));

      // Y lệnh & Lời dặn
      store.doctorIssueHospitalizationOrder(false, 'Ngoại trú');
      store.doctorSendDirectAdvice('Đo huyết áp hàng ngày vào buổi sáng');
      expect(store.notifications.first.title, contains('Lời dặn dò'));
    });
  });
}
