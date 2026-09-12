import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bt2_2324801030077/models/medical_models.dart';
import 'package:bt2_2324801030077/pages/ai_health_assistant_page.dart';
import 'package:bt2_2324801030077/pages/digital_card_page.dart';
import 'package:bt2_2324801030077/pages/emergency_sos_page.dart';
import 'package:bt2_2324801030077/pages/health_news_page.dart';
import 'package:bt2_2324801030077/pages/health_packages_page.dart';
import 'package:bt2_2324801030077/pages/hospital_map_page.dart';
import 'package:bt2_2324801030077/pages/live_queue_page.dart';
import 'package:bt2_2324801030077/pages/medication_tracker_page.dart';
import 'package:bt2_2324801030077/pages/mental_health_page.dart';
import 'package:bt2_2324801030077/pages/vaccination_page.dart';
import 'package:bt2_2324801030077/pages/vitals_tracker_page.dart';
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
      expect(store.medicineSchedule.length, 7);

      final initialRate = store.medicineAdherenceRate;
      expect(initialRate, closeTo(3 / 7, 0.01));

      store.toggleMedicineTaken('sch-04');
      expect(store.medicineAdherenceRate, closeTo(4 / 7, 0.01));

      store.toggleMedicineTaken('sch-04');
      expect(store.medicineAdherenceRate, closeTo(3 / 7, 0.01));
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
  });

  group('Extended Pages Widget Tests', () {
    Widget buildTestApp(Widget page, {MedicalStore? store, AppSettingsStore? settings}) {
      final s = store ?? MedicalStore();
      final set = settings ?? AppSettingsStore();
      return MedicalScope(
        store: s,
        child: AppSettingsScope(
          store: set,
          child: MaterialApp(
            home: page,
          ),
        ),
      );
    }

    testWidgets('AiHealthAssistantPage render đầy đủ giao diện và chat', (tester) async {
      await tester.pumpWidget(buildTestApp(const AiHealthAssistantPage()));
      expect(find.text('MedCare AI Health'), findsOneWidget);
      expect(find.text('Trợ lý y tế thông minh 24/7'), findsOneWidget);
      expect(find.text('Đau quặn dạ dày, ợ chua'), findsOneWidget);
    });

    testWidgets('MedicationTrackerPage render tiến độ uống thuốc', (tester) async {
      await tester.pumpWidget(buildTestApp(const MedicationTrackerPage()));
      expect(find.text('Nhắc lịch Uống thuốc'), findsOneWidget);
      expect(find.text('Tuân thủ phác đồ hôm nay'), findsOneWidget);
      expect(find.text('Buổi Sáng'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Buổi Tối'), findsOneWidget);
    });


    testWidgets('VitalsTrackerPage render các chỉ số sinh hiệu', (tester) async {
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

    testWidgets('HospitalMapPage render lộ trình và các tòa nhà', (tester) async {
      await tester.pumpWidget(buildTestApp(const HospitalMapPage()));
      expect(find.text('Sơ đồ & Chỉ đường Nội viện'), findsOneWidget);
      expect(find.text('Tòa A'), findsOneWidget);
    });

    testWidgets('DigitalCardPage render thẻ bệnh nhân và nút quét Kiosk', (tester) async {
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

    testWidgets('MentalHealthPage render bài tập thở Box Breathing', (tester) async {
      await tester.pumpWidget(buildTestApp(const MentalHealthPage()));
      expect(find.text('Sức khỏe Tinh thần & Thư giãn'), findsOneWidget);
      expect(find.text('Bắt đầu thư giãn'), findsOneWidget);
    });

    testWidgets('HealthNewsPage render danh sách cẩm nang sức khỏe', (tester) async {
      await tester.pumpWidget(buildTestApp(const HealthNewsPage()));
      expect(find.text('Cẩm nang Y khoa & Sức khỏe'), findsOneWidget);
      expect(find.text('Chế độ ăn uống khoa học cho người viêm loét dạ dày có vi khuẩn Hp'), findsOneWidget);
    });
  });
}
