import 'package:flutter/material.dart';

import 'pages/quan_tri_slot_kham_page.dart';
import 'pages/admin_approval_page.dart';
import 'pages/admin_control_page.dart';
import 'pages/tro_ly_suc_khoe_ai_page.dart';
import 'pages/dat_lich_kham_page.dart';
import 'pages/man_hinh_bo_sung.dart';
import 'pages/ho_so_gia_dinh_page.dart';
import 'pages/kham_tu_xa_page.dart';
import 'pages/giai_thich_xet_nghiem_page.dart';
import 'pages/bao_lanh_vien_phi_page.dart';
import 'pages/ban_lam_viec_bac_si_page.dart';
import 'pages/tien_do_kham_page.dart';
import 'pages/chan_doan_he_thong_page.dart';
import 'pages/the_y_te_dien_tu_page.dart';
import 'pages/chi_tiet_bac_si_page.dart';
import 'pages/danh_sach_bac_si_page.dart';
import 'pages/don_thuoc_dien_tu_page.dart';
import 'pages/sos_cap_cuu_page.dart';
import 'pages/tin_tuc_suc_khoe_page.dart';
import 'pages/goi_kham_suc_khoe_page.dart';
import 'pages/trang_chu_page.dart';
import 'pages/ban_do_benh_vien_page.dart';
import 'pages/hang_doi_kham_page.dart';
import 'pages/nhac_lich_uong_thuoc_page.dart';
import 'pages/suc_khoe_tinh_than_page.dart';
import 'pages/ho_so_benh_an_page.dart';
import 'pages/thanh_toan_vien_phi_page.dart';
import 'pages/nap_vi_page.dart';
import 'pages/man_hinh_don_gian.dart';
import 'pages/tiem_chung_page.dart';
import 'pages/theo_doi_sinh_hieu_page.dart';
import 'routes/app_routes.dart';
import 'models/medical_models.dart';
import 'state/app_settings_store.dart';
import 'state/medical_store.dart';
import 'services/local_notification_service.dart';
import 'widgets/app_lock_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.instance.initialize();
  runApp(const HospitalApp());
}

class HospitalApp extends StatefulWidget {
  const HospitalApp({super.key});

  @override
  State<HospitalApp> createState() => _HospitalAppState();
}

class _HospitalAppState extends State<HospitalApp> {
  final _store = MedicalStore();
  final _settings = AppSettingsStore();

  @override
  Widget build(BuildContext context) {
    return MedicalScope(
      store: _store,
      child: AppSettingsScope(
        store: _settings,
        child: AnimatedBuilder(
          animation: _settings,
          builder: (context, _) {
            final isHighContrast = _settings.isHighContrast;
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'MedCare Hospital',
              themeMode: _settings.themeMode,
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                scaffoldBackgroundColor: isHighContrast
                    ? Colors.white
                    : const Color(0xFFFAF8FF),
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF0057CD),
                  onPrimary: Colors.white,
                  primaryContainer: Color(0xFF0D6EFD),
                  onPrimaryContainer: Colors.white,
                  secondary: Color(0xFF006591),
                  onSecondary: Colors.white,
                  tertiary: Color(0xFF006C49),
                  onTertiary: Colors.white,
                  surface: Color(0xFFFAF8FF),
                  onSurface: Color(0xFF131B2E),
                  surfaceContainerHighest: Color(0xFFDAE2FD),
                  outline: Color(0xFF727787),
                ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFFFAF8FF),
                  foregroundColor: Color(0xFF131B2E),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                ),
                cardTheme: CardThemeData(
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: .8),
                  ),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF0057CD),
                      width: 1.5,
                    ),
                  ),
                ),
                navigationBarTheme: const NavigationBarThemeData(
                  backgroundColor: Colors.white,
                  indicatorColor: Color(0xFFDAE2FF),
                  elevation: 2,
                  labelTextStyle: WidgetStatePropertyAll(
                    TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                scaffoldBackgroundColor: isHighContrast
                    ? Colors.black
                    : const Color(0xFF0F172A),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF0D6EFD),
                  brightness: Brightness.dark,
                ),
                inputDecorationTheme: const InputDecorationTheme(
                  border: OutlineInputBorder(),
                ),
              ),
              builder: (context, child) {
                final textScaler = _settings.isLargeText
                    ? const TextScaler.linear(1.25)
                    : MediaQuery.textScalerOf(context);

                Widget content = MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                  child: child ?? const SizedBox.shrink(),
                );

                if (_settings.isAppLocked) {
                  content = Stack(
                    children: [
                      content,
                      const Positioned.fill(child: AppLockScreen()),
                    ],
                  );
                }

                return content;
              },
              initialRoute: AppRoutes.splash,
              routes: {
                AppRoutes.home: (context) => _patientPage(const HomePage()),
                AppRoutes.appointments: (context) =>
                    _patientPage(const AppointmentPage()),
                AppRoutes.doctors: (context) => const DoctorsPage(),
                AppRoutes.doctorDetail: (context) => const DoctorDetailPage(),
                AppRoutes.records: (context) =>
                    _patientPage(const PatientRecordsPage()),
                AppRoutes.prescription: (context) =>
                    _patientPage(const EPrescriptionPage()),
                AppRoutes.payment: (context) =>
                    _patientPage(const PaymentPage()),
                AppRoutes.walletTopUp: (context) =>
                    _patientPage(const WalletTopUpPage()),
                AppRoutes.specialty: (context) {
                  final specialty =
                      ModalRoute.of(context)?.settings.arguments as String? ??
                      'Chuyên khoa';
                  return SpecialtyPage(specialty: specialty);
                },
                AppRoutes.splash: (context) => const SplashPage(),
                AppRoutes.login: (context) => const LoginPage(),
                AppRoutes.register: (context) => const RegisterPage(),
                AppRoutes.forgotPassword: (context) =>
                    const ForgotPasswordPage(),
                AppRoutes.otp: (context) => const OtpPage(),
                AppRoutes.search: (context) => const SearchPage(),
                AppRoutes.specialtyList: (context) => const SpecialtyListPage(),
                AppRoutes.specialtyDetail: (context) => SpecialtyDetailPage(
                  specialty:
                      ModalRoute.of(context)?.settings.arguments as String? ??
                      'Chuyên khoa',
                ),
                AppRoutes.confirmAppointment: (context) =>
                    _patientPage(const ConfirmAppointmentPage()),
                AppRoutes.bookingSuccess: (context) =>
                    _patientPage(const BookingSuccessPage()),
                AppRoutes.myAppointments: (context) =>
                    _patientPage(const MyAppointmentsPage()),
                AppRoutes.appointmentDetail: (context) =>
                    _patientPage(const AppointmentDetailPage()),
                AppRoutes.cancelAppointment: (context) =>
                    _patientPage(const CancelAppointmentPage()),
                AppRoutes.visitHistory: (context) =>
                    _patientPage(const VisitHistoryPage()),
                AppRoutes.doctorRating: (context) =>
                    _patientPage(const DoctorRatingPage()),
                AppRoutes.profile: (context) =>
                    _patientPage(const PatientProfilePage()),
                AppRoutes.labResults: (context) =>
                    _patientPage(const LabResultsPage()),
                AppRoutes.labDetail: (context) =>
                    _patientPage(const LabResultDetailPage()),
                AppRoutes.prescriptionDetail: (context) =>
                    _patientPage(const PrescriptionDetailPage()),
                AppRoutes.notifications: (context) =>
                    _patientPage(const NotificationsPage()),
                AppRoutes.settings: (context) => const SettingsPage(),
                AppRoutes.diagnostics: (context) => const DiagnosticsPage(),
                AppRoutes.aiAssistant: (context) =>
                    _patientPage(const AiHealthAssistantPage()),
                AppRoutes.medicationTracker: (context) =>
                    _patientPage(const MedicationTrackerPage()),
                AppRoutes.vitalsTracker: (context) =>
                    _patientPage(const VitalsTrackerPage()),
                AppRoutes.liveQueue: (context) =>
                    _patientPage(const LiveQueuePage()),
                AppRoutes.vaccination: (context) =>
                    _patientPage(const VaccinationPage()),
                AppRoutes.healthPackages: (context) =>
                    const HealthPackagesPage(),
                AppRoutes.hospitalMap: (context) => const HospitalMapPage(),
                AppRoutes.digitalCard: (context) =>
                    _patientPage(const DigitalCardPage()),
                AppRoutes.emergencySos: (context) => const EmergencySosPage(),
                AppRoutes.mentalHealth: (context) => const MentalHealthPage(),
                AppRoutes.healthNews: (context) => const HealthNewsPage(),
                AppRoutes.adminSlots: (context) =>
                    _adminPage(const AdminSlotPage()),
                AppRoutes.adminApprovals: (context) =>
                    _adminPage(const AdminApprovalPage()),
                AppRoutes.adminControl: (context) =>
                    _adminPage(const AdminControlPage()),
                AppRoutes.familyProfiles: (context) =>
                    _patientPage(const FamilyProfilesPage()),
                AppRoutes.telemedicine: (context) =>
                    _patientPage(const TelemedicinePage()),
                AppRoutes.labExplainer: (context) =>
                    _patientPage(const LabExplainerPage()),
                AppRoutes.insuranceGuarantee: (context) =>
                    _patientPage(const InsuranceGuaranteePage()),
                AppRoutes.doctorPortal: (context) =>
                    _doctorPage(const DoctorPortalPage()),
                AppRoutes.clinicalPathway: (context) =>
                    _patientPage(const ClinicalPathwayPage()),
                AppRoutes.support: (context) =>
                    _patientPage(const SupportPage()),
              },
            );
          },
        ),
      ),
    );
  }
}

Widget _patientPage(Widget child) =>
    _RoleGate(allowedRoles: const {UserRole.patient}, child: child);

Widget _doctorPage(Widget child) =>
    _RoleGate(allowedRoles: const {UserRole.doctor}, child: child);

Widget _adminPage(Widget child) =>
    _RoleGate(allowedRoles: const {UserRole.admin}, child: child);

class _RoleGate extends StatelessWidget {
  const _RoleGate({required this.allowedRoles, required this.child});

  final Set<UserRole> allowedRoles;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    if (store.authenticated && allowedRoles.contains(store.currentUserRole)) {
      return child;
    }
    final destination = store.authenticated
        ? AppRoutes.landingForRole(store.currentUserRole)
        : AppRoutes.login;
    final actionLabel = store.authenticated
        ? 'Mở khu vực đúng quyền'
        : 'Đăng nhập';

    return Scaffold(
      appBar: AppBar(title: const Text('Không có quyền truy cập')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Tài khoản hiện tại không có quyền mở khu vực này.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng đăng nhập bằng tài khoản được cấp đúng vai trò.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  destination,
                  (_) => false,
                ),
                icon: Icon(
                  store.authenticated
                      ? Icons.work_outline_rounded
                      : Icons.login_rounded,
                ),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
