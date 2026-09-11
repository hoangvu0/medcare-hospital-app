import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bt2_2324801030077/pages/diagnostics_page.dart';
import 'package:bt2_2324801030077/state/app_settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppSettingsStore Tests (Yêu cầu Phi Chức Năng)', () {
    test('Khởi tạo mặc định các thiết lập phi chức năng', () {
      final store = AppSettingsStore();
      expect(store.themeMode, ThemeMode.light);
      expect(store.locale, 'vi');
      expect(store.isLargeText, false);
      expect(store.isHighContrast, false);
      expect(store.isMaskingSensitiveData, true);
      expect(store.isAppLocked, false);
      expect(store.isOfflineSimulated, false);
    });

    test('Chuyển đổi Dark Mode và Ngôn ngữ (i18n)', () {
      final store = AppSettingsStore();
      store.setThemeMode(ThemeMode.dark);
      expect(store.themeMode, ThemeMode.dark);

      store.setLocale('en');
      expect(store.locale, 'en');
      expect(store.tr('home'), 'Home');
      expect(store.tr('emergency_title'), 'EMERGENCY 24/7');

      store.setLocale('vi');
      expect(store.tr('home'), 'Trang chủ');
      expect(store.tr('emergency_title'), 'CẤP CỨU 24/7');
    });

    test('Trợ năng Chế độ chữ lớn & Tương phản cao', () {
      final store = AppSettingsStore();
      store.setLargeText(true);
      expect(store.isLargeText, true);

      store.setHighContrast(true);
      expect(store.isHighContrast, true);
    });

    test('Bảo mật: Che dữ liệu nhạy cảm (Data Masking)', () {
      final store = AppSettingsStore();
      final maskedPhone = store.maskText('0901234567', visiblePrefix: 3, visibleSuffix: 3);
      expect(maskedPhone, '090****567');

      final maskedInsurance = store.maskText('DN4010123456789', visiblePrefix: 4, visibleSuffix: 3);
      expect(maskedInsurance, 'DN40********789');

      store.setMaskingSensitiveData(false);
      expect(store.maskText('0901234567'), '0901234567');
    });

    test('Bảo mật: Khóa ứng dụng bằng mã PIN', () {
      final store = AppSettingsStore();
      store.setPinCode('1234');
      expect(store.pinCode, '1234');

      store.lockApp();
      expect(store.isAppLocked, true);

      final failed = store.unlockWithPin('9999');
      expect(failed, false);
      expect(store.isAppLocked, true);

      final success = store.unlockWithPin('1234');
      expect(success, true);
      expect(store.isAppLocked, false);
    });

    test('Bộ nhớ & Dọn dẹp cache (Clear Cache)', () async {
      final store = AppSettingsStore();
      expect(store.simulatedCacheBytes, greaterThan(0));

      await store.clearCache();
      expect(store.simulatedCacheBytes, 0);
    });

    test('Kiểm thử giả lập Ngoại tuyến (Offline Mode)', () {
      final store = AppSettingsStore();
      expect(store.isOfflineSimulated, false);

      store.toggleOfflineSimulation();
      expect(store.isOfflineSimulated, true);
    });
  });

  group('DiagnosticsPage Widget Test', () {
    testWidgets('Hiển thị đầy đủ thông tin chẩn đoán hệ thống và nút dọn cache', (tester) async {
      final settingsStore = AppSettingsStore();

      await tester.pumpWidget(
        AppSettingsScope(
          store: settingsStore,
          child: const MaterialApp(
            home: DiagnosticsPage(),
          ),
        ),
      );

      expect(find.text('Chẩn đoán Hệ thống & Bộ nhớ'), findsOneWidget);
      expect(find.text('Chỉ số Hiệu năng (Performance Metrics)'), findsOneWidget);
      expect(find.text('Quản lý Bộ nhớ & Cache (Storage)'), findsOneWidget);
      expect(find.text('Dọn dẹp bộ nhớ đệm (Clear Cache)'), findsOneWidget);

      await tester.tap(find.text('Dọn dẹp bộ nhớ đệm (Clear Cache)'));
      await tester.pump();
      expect(settingsStore.simulatedCacheBytes, 0);
    });
  });
}

