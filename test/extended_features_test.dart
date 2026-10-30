import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bt2_2324801030077/models/medical_models.dart';
import 'package:bt2_2324801030077/pages/tro_ly_suc_khoe_ai_page.dart';
import 'package:bt2_2324801030077/pages/the_y_te_dien_tu_page.dart';
import 'package:bt2_2324801030077/pages/sos_cap_cuu_page.dart';
import 'package:bt2_2324801030077/pages/tin_tuc_suc_khoe_page.dart';
import 'package:bt2_2324801030077/pages/goi_kham_suc_khoe_page.dart';
import 'package:bt2_2324801030077/pages/ban_do_benh_vien_page.dart';
import 'package:bt2_2324801030077/pages/hang_doi_kham_page.dart';
import 'package:bt2_2324801030077/pages/nhac_lich_uong_thuoc_page.dart';
import 'package:bt2_2324801030077/pages/suc_khoe_tinh_than_page.dart';
import 'package:bt2_2324801030077/pages/tiem_chung_page.dart';
import 'package:bt2_2324801030077/pages/theo_doi_sinh_hieu_page.dart';
import 'package:bt2_2324801030077/state/app_settings_store.dart';
import 'package:bt2_2324801030077/state/medical_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MedicalStore Extended Features Unit Tests', () {
    test('Kiểm tra khởi tạo và thêm chỉ số sinh hiệu (Vitals)', () {
      final store = MedicalStore();
      expect(store.vitals.length, greaterThanOrEqualTo(3));

      final latest = store.vitals.first;
      expect(latest.systolic, 118);
      expect(latest.diastolic, 78);
      expect(latest.bpStatus, 'Tối ưu');
      expect(latest.bmi, closeTo(22.46, 0.1));
      expect(latest.bmiCategory, 'Bình thường (Chuẩn châu Á)');

      store.addVitalRecord(
        VitalSignRecord(
          timestamp: DateTime.now(),
          systolic: 135,
          diastolic: 88,
          heartRate: 85,
          bloodGlucose: 105.0,
          weightKg: 70.0,
          heightCm: 174.0,
        ),
      );

      expect(store.vitals.first.systolic, 135);
      expect(store.vitals.first.bpStatus, 'Tiền tăng huyết áp');
    });

    test('Kiểm tra lịch uống thuốc & tính tỷ lệ tuân thủ điều trị', () {
      final store = MedicalStore();
      expect(store.medicineSchedule, isEmpty);

      final initialRate = store.medicineAdherenceRate;
      expect(initialRate, 0.0);

      final prescribed = [
        const MedicineItem(
          name: 'Amlodipine Besylate',
          category: 'Thuốc hạ áp',
          dosage: '5mg',
          quantity: '30 viên',
          instruction: 'Uống 1 viên vào 8:00 sáng sau ăn',
        ),
      ];
      final appointment = store.book(
        doctor: store.activeDoctorUser,
        dateTime: DateTime(2026, 2, 12, 9),
        patientName: store.activeFamilyMember.name,
        reason: 'Khám tim mạch',
        useInsurance: true,
      );
      final appointmentFee = store.transactions.firstWhere(
        (tx) => tx.visitCode == '#${appointment.id}',
      );
      store.completeTransaction(appointmentFee.id);
      store.doctorExecuteFullConsultationSync(
        diagnosis: 'Tăng huyết áp nguyên phát độ 1',
        icd10Code: 'I10',
        icd10Name: 'Tăng huyết áp vô căn',
        symptoms: 'Đau đầu nhẹ',
        physicalExam: 'Huyết áp 135/85 mmHg',
        labNotes: 'Glucose 5.6 mmol/L',
        doctorAdvice: 'Theo dõi huyết áp tại nhà',
        followUpDate: '26/02/2026',
        prescribedMedicines: prescribed,
      );
      expect(store.medicineSchedule.length, 1);
      expect(store.medicineAdherenceRate, 0.0);
      store.toggleMedicineTaken(store.medicineSchedule.first.id);
      expect(store.medicineAdherenceRate, 1.0);
    });

    test('Kiểm tra hàng đợi khám & cập nhật tiến độ (Live Queue)', () {
      final store = MedicalStore();
      expect(store.queueInfo.currentNumber, 18);
      expect(store.queueInfo.patientNumber, 21);
      expect(store.queueInfo.waitCount, 3);

      store.refreshQueue();
      expect(store.queueInfo.currentNumber, 19);
      expect(store.queueInfo.waitCount, 2);
    });

    test('Kiểm tra dữ liệu Vắc-xin, Gói khám và Bài viết y khoa', () {
      final store = MedicalStore();
      expect(store.vaccineRecords.length, greaterThanOrEqualTo(4));
      expect(store.healthPackages.length, greaterThanOrEqualTo(3));
      expect(store.healthArticles.length, greaterThanOrEqualTo(3));
    });

    test('Kiểm tra giới hạn slot đặt khám và Admin điều chỉnh capacity', () {
      final store = MedicalStore();
      const docId = 'doc-test-99';
      const dateStr = '2026-09-20';
      const timeStr = '09:00';

      // Admin cấu hình slot này chỉ có đúng 2 chỗ
      store.setSlotCapacity(docId, dateStr, timeStr, 2);
      final slotInitial = store.getSlotInfo(docId, dateStr, timeStr);
      expect(slotInitial.capacity, 2);
      expect(slotInitial.booked, 0);
      expect(slotInitial.remaining, 2);
      expect(slotInitial.isFull, false);

      // Người 1 đặt thành công
      final ok1 = store.bookSlot(docId, dateStr, timeStr);
      expect(ok1, true);
      expect(store.getSlotInfo(docId, dateStr, timeStr).remaining, 1);
      expect(store.getSlotInfo(docId, dateStr, timeStr).isFull, false);

      // Người 2 đặt thành công -> slot đầy
      final ok2 = store.bookSlot(docId, dateStr, timeStr);
      expect(ok2, true);
      expect(store.getSlotInfo(docId, dateStr, timeStr).remaining, 0);
      expect(store.getSlotInfo(docId, dateStr, timeStr).isFull, true);

      // Người 3 đặt muộn -> BỊ CHẶN (hết chỗ)
      final ok3 = store.bookSlot(docId, dateStr, timeStr);
      expect(ok3, false);
      expect(store.getSlotInfo(docId, dateStr, timeStr).remaining, 0);

      // Hủy 1 chỗ -> giải phóng slot
      store.releaseSlot(docId, dateStr, timeStr);
      expect(store.getSlotInfo(docId, dateStr, timeStr).remaining, 1);
      expect(store.getSlotInfo(docId, dateStr, timeStr).isFull, false);

      // Người khác lại đặt được
      final ok4 = store.bookSlot(docId, dateStr, timeStr);
      expect(ok4, true);
    });

    test(
      'Trụ cột 1: Kiểm tra Quản lý Đa Hồ sơ Gia đình và chuyển đổi hồ sơ',
      () {
        final store = MedicalStore();
        expect(store.familyMembers.length, 1);
        expect(store.activeFamilyMember.name, 'Nguyễn Hoàng Vũ');

        // Thêm thành viên mới
        const newMember = FamilyMemberProfile(
          id: 'fam-new-99',
          name: 'Nguyễn Thị Hoa',
          relation: FamilyRelation.parent,
          dateOfBirth: '12/03/1962',
          gender: 'Nữ',
          insuranceNumber: 'HT3010999888',
          bloodType: 'A+',
        );
        store.addFamilyMember(newMember);
        expect(store.familyMembers.length, 2);

        // Chuyển sang thành viên mới
        store.switchFamilyProfile('fam-new-99');
        expect(store.activeFamilyMember.name, 'Nguyễn Thị Hoa');

        // Chuyển lại bản thân
        store.switchFamilyProfile('fam-01');
        expect(store.activeFamilyMember.name, 'Nguyễn Hoàng Vũ');
      },
    );

    test('Trụ cột 2 & 3: Khám từ xa Telemedicine và Giao thuốc tận nhà', () {
      final store = MedicalStore();
      final doctor = store.doctors.first;

      // Khám từ xa
      final session = store.startTelemedicine(doctor);
      expect(session.status, TelemedicineStatus.connected);
      expect(store.currentTelemedicine?.doctor.id, doctor.id);

      store.endTelemedicine(doctorNotes: 'Bệnh nhân ổn định');
      expect(store.currentTelemedicine?.status, TelemedicineStatus.ended);

      // Kiểm tra cảnh báo dị ứng thuốc
      store.switchFamilyProfile('fam-01'); // Dị ứng Penicillin
      final warning = store.checkPrescriptionAllergy([
        const MedicineItem(
          name: 'Amoxicillin 500mg',
          category: 'Kháng sinh',
          dosage: '1 viên x 2 lần/ngày',
          quantity: '14 viên',
          instruction: 'Uống sau ăn',
        ),
      ]);
      expect(warning, contains('Cảnh báo dị ứng nghiêm trọng'));

      expect(
        () => store.createPharmacyOrder(
          prescriptionId: 'DT-TEST-001',
          deliveryAddress: 'Số 10 Phố Huế, Hà Nội',
          pharmacyName: 'Nhà thuốc Long Châu',
          itemsCount: 3,
          medicineTotal: 250000,
        ),
        throwsA(isA<StateError>()),
      );

      final appointment = store.book(
        doctor: store.activeDoctorUser,
        dateTime: DateTime(2026, 2, 13, 9),
        patientName: store.activeFamilyMember.name,
        reason: 'Khám sau tư vấn từ xa',
        useInsurance: true,
      );
      final appointmentFee = store.transactions.firstWhere(
        (tx) => tx.visitCode == '#${appointment.id}',
      );
      store.completeTransaction(appointmentFee.id);
      store.doctorExecuteFullConsultationSync(
        diagnosis: 'Tư vấn sau khám từ xa',
        icd10Code: 'Z71.9',
        icd10Name: 'Tư vấn y tế không đặc hiệu',
        symptoms: 'Ổn định',
        physicalExam: 'Tổng trạng ổn',
        labNotes: 'Chưa chỉ định cận lâm sàng',
        doctorAdvice: 'Theo dõi triệu chứng tại nhà',
        followUpDate: '27/02/2026',
        prescribedMedicines: const [
          MedicineItem(
            name: 'Paracetamol 500mg',
            category: 'Giảm đau hạ sốt',
            dosage: '500mg',
            quantity: '10 viên',
            instruction: 'Uống khi sốt hoặc đau theo hướng dẫn bác sĩ',
          ),
        ],
      );

      // Đặt mua thuốc giao tận nhà sau khi có đơn thuốc thật
      final order = store.createPharmacyOrder(
        prescriptionId: store.medicalRecords.first.prescriptionCode,
        deliveryAddress: 'Số 10 Phố Huế, Hà Nội',
        pharmacyName: 'Nhà thuốc Long Châu',
        itemsCount: store.medicines.length,
        medicineTotal: 250000,
      );
      expect(order.status, PharmacyOrderStatus.shipping);
      expect(order.totalPayable, 275000);
      expect(store.pharmacyOrders.first.id, order.id);
    });

    test('Trụ cột 6: Phân hệ Bác sĩ gọi bệnh nhân và cập nhật KPI', () {
      final store = MedicalStore();
      final initialCurrent = store.queueInfo.currentNumber;
      final initialConsults = store.hospitalKpi.completedConsultations;

      // Bác sĩ gọi số kế tiếp
      store.doctorCallNextPatient('Phòng 204');
      expect(store.queueInfo.currentNumber, initialCurrent + 1);
      expect(store.hospitalKpi.completedConsultations, initialConsults + 1);
    });
  });

  group('Extended Pages Widget Tests', () {
    Widget buildTestApp(
      Widget page, {
      MedicalStore? store,
      AppSettingsStore? settings,
    }) {
      final s = store ?? MedicalStore();
      final set = settings ?? AppSettingsStore();
      return MedicalScope(
        store: s,
        child: AppSettingsScope(
          store: set,
          child: MaterialApp(home: page),
        ),
      );
    }

    testWidgets('AiHealthAssistantPage render đầy đủ giao diện và chat', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const AiHealthAssistantPage()));
      expect(find.text('MedCare AI Health'), findsOneWidget);
      expect(find.text('Trợ lý y tế thông minh 24/7'), findsOneWidget);
      expect(find.text('Đau quặn dạ dày, ợ chua'), findsOneWidget);
    });

    testWidgets('MedicationTrackerPage render tiến độ uống thuốc', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const MedicationTrackerPage()));
      expect(find.text('Nhắc lịch uống thuốc'), findsOneWidget);
      expect(find.text('Tuân thủ phác đồ hôm nay'), findsOneWidget);
      expect(find.text('Chưa có lịch uống thuốc'), findsOneWidget);
    });

    testWidgets('VitalsTrackerPage render các chỉ số sinh hiệu', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const VitalsTrackerPage()));
      expect(find.text('Chỉ số Sinh hiệu & Sức khỏe'), findsOneWidget);
      expect(find.text('Huyết áp'), findsOneWidget);
      expect(find.text('Nhịp tim'), findsOneWidget);
      expect(find.text('Đường huyết đói'), findsOneWidget);
      expect(find.text('Thể trạng BMI'), findsOneWidget);
    });

    testWidgets('LiveQueuePage render số thứ tự phòng khám', (tester) async {
      await tester.pumpWidget(buildTestApp(const LiveQueuePage()));
      expect(find.text('Theo dõi Hàng đợi Khám'), findsOneWidget);
      expect(find.text('Khoa Tiêu hóa & Gan Mật'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
    });

    testWidgets('VaccinationPage render các mũi tiêm', (tester) async {
      await tester.pumpWidget(buildTestApp(const VaccinationPage()));
      expect(find.text('Sổ Tiêm chủng Điện tử'), findsOneWidget);
      expect(find.text('Mũi tiêm của tôi'), findsOneWidget);
      expect(find.text('Danh mục Vắc-xin'), findsOneWidget);
      expect(find.text('Influvac Tetra (Hà Lan)'), findsOneWidget);
    });

    testWidgets('HealthPackagesPage render gói khám tầm soát', (tester) async {
      await tester.pumpWidget(buildTestApp(const HealthPackagesPage()));
      expect(find.text('Gói Khám Sức Khỏe & Tầm Soát'), findsOneWidget);
      expect(find.text('Tầm Soát Ung Thư Sớm Đường Tiêu Hóa'), findsOneWidget);
    });

    testWidgets('HospitalMapPage render lộ trình và các tòa nhà', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const HospitalMapPage()));
      expect(find.text('Sơ đồ & Chỉ đường Nội viện'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Tòa A'), 200);
      expect(find.text('Tòa A'), findsOneWidget);
    });

    testWidgets('DigitalCardPage render thẻ bệnh nhân và nút quét Kiosk', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const DigitalCardPage()));
      expect(find.text('Thẻ Y tế Điện tử'), findsOneWidget);
      expect(find.text('Quét Kiosk'), findsOneWidget);
    });

    testWidgets('EmergencySosPage render số hotline 1900 8899', (tester) async {
      await tester.pumpWidget(buildTestApp(const EmergencySosPage()));
      expect(find.text('Cấp cứu Khẩn cấp SOS'), findsOneWidget);
      expect(find.text('1900 8899'), findsOneWidget);
      expect(find.text('THẺ Y TẾ KHẨN CẤP (MEDICAL ID)'), findsOneWidget);
    });

    testWidgets('MentalHealthPage render bài tập thở Box Breathing', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const MentalHealthPage()));
      expect(find.text('Sức khỏe Tinh thần & Thư giãn'), findsOneWidget);
      expect(find.text('Bắt đầu thư giãn'), findsOneWidget);
    });

    testWidgets('HealthNewsPage render danh sách cẩm nang sức khỏe', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const HealthNewsPage()));
      expect(find.text('Cẩm nang Y khoa & Sức khỏe'), findsOneWidget);
      expect(
        find.text(
          'Chế độ ăn uống khoa học cho người viêm loét dạ dày có vi khuẩn Hp',
        ),
        findsOneWidget,
      );
    });
  });
}
