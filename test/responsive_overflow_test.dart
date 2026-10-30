import 'package:bt2_2324801030077/pages/the_y_te_dien_tu_page.dart';
import 'package:bt2_2324801030077/pages/tro_ly_suc_khoe_ai_page.dart';
import 'package:bt2_2324801030077/pages/dat_lich_kham_page.dart';
import 'package:bt2_2324801030077/pages/tien_do_kham_page.dart';
import 'package:bt2_2324801030077/pages/chan_doan_he_thong_page.dart';
import 'package:bt2_2324801030077/pages/chi_tiet_bac_si_page.dart';
import 'package:bt2_2324801030077/pages/danh_sach_bac_si_page.dart';
import 'package:bt2_2324801030077/pages/don_thuoc_dien_tu_page.dart';
import 'package:bt2_2324801030077/pages/sos_cap_cuu_page.dart';
import 'package:bt2_2324801030077/pages/ho_so_gia_dinh_page.dart';
import 'package:bt2_2324801030077/pages/tin_tuc_suc_khoe_page.dart';
import 'package:bt2_2324801030077/pages/goi_kham_suc_khoe_page.dart';
import 'package:bt2_2324801030077/pages/ban_do_benh_vien_page.dart';
import 'package:bt2_2324801030077/pages/bao_lanh_vien_phi_page.dart';
import 'package:bt2_2324801030077/pages/giai_thich_xet_nghiem_page.dart';
import 'package:bt2_2324801030077/pages/hang_doi_kham_page.dart';
import 'package:bt2_2324801030077/pages/nhac_lich_uong_thuoc_page.dart';
import 'package:bt2_2324801030077/pages/suc_khoe_tinh_than_page.dart';
import 'package:bt2_2324801030077/pages/ho_so_benh_an_page.dart';
import 'package:bt2_2324801030077/pages/thanh_toan_vien_phi_page.dart';
import 'package:bt2_2324801030077/pages/kham_tu_xa_page.dart';
import 'package:bt2_2324801030077/pages/tiem_chung_page.dart';
import 'package:bt2_2324801030077/pages/theo_doi_sinh_hieu_page.dart';
import 'package:bt2_2324801030077/state/app_settings_store.dart';
import 'package:bt2_2324801030077/state/medical_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp(Widget page) {
    return MedicalScope(
      store: MedicalStore(enablePersistence: false),
      child: AppSettingsScope(
        store: AppSettingsStore(),
        child: MaterialApp(home: page),
      ),
    );
  }

  Future<void> pumpNarrow(
    WidgetTester tester,
    String pageName,
    Widget page,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestApp(page));
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull, reason: pageName);
  }

  testWidgets('key patient pages render on narrow phones without overflow', (
    tester,
  ) async {
    final pages = <String, Widget>{
      'FamilyProfilesPage': const FamilyProfilesPage(),
      'VitalsTrackerPage': const VitalsTrackerPage(),
      'MedicationTrackerPage': const MedicationTrackerPage(),
      'LiveQueuePage': const LiveQueuePage(),
      'DigitalCardPage': const DigitalCardPage(),
      'EmergencySosPage': const EmergencySosPage(),
      'EPrescriptionPage': const EPrescriptionPage(),
      'PaymentPage': const PaymentPage(),
      'AiHealthAssistantPage': const AiHealthAssistantPage(),
      'AppointmentPage': const AppointmentPage(),
      'ClinicalPathwayPage': const ClinicalPathwayPage(),
      'DiagnosticsPage': const DiagnosticsPage(),
      'DoctorsPage': const DoctorsPage(),
      'DoctorDetailPage': const DoctorDetailPage(),
      'HealthNewsPage': const HealthNewsPage(),
      'HealthPackagesPage': const HealthPackagesPage(),
      'HospitalMapPage': const HospitalMapPage(),
      'InsuranceGuaranteePage': const InsuranceGuaranteePage(),
      'LabExplainerPage': const LabExplainerPage(),
      'MentalHealthPage': const MentalHealthPage(),
      'PatientRecordsPage': const PatientRecordsPage(),
      'TelemedicinePage': const TelemedicinePage(),
      'VaccinationPage': const VaccinationPage(),
    };

    for (final entry in pages.entries) {
      await pumpNarrow(tester, entry.key, entry.value);
    }
  });
}
