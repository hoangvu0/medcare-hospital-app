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
  });
}
