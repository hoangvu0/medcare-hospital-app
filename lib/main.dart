import 'package:flutter/material.dart';

import 'pages/admin_slot_page.dart';
import 'pages/ai_health_assistant_page.dart';
import 'pages/appointment_page.dart';
import 'pages/additional_pages.dart';
import 'pages/family_profiles_page.dart';
import 'pages/telemedicine_page.dart';
import 'pages/diagnostics_page.dart';
import 'pages/digital_card_page.dart';
import 'pages/doctor_detail_page.dart';
import 'pages/doctors_page.dart';
import 'pages/e_prescription_page.dart';
import 'pages/emergency_sos_page.dart';
import 'pages/health_news_page.dart';
import 'pages/health_packages_page.dart';
import 'pages/home_page.dart';
import 'pages/hospital_map_page.dart';
import 'pages/live_queue_page.dart';
import 'pages/medication_tracker_page.dart';
import 'pages/mental_health_page.dart';
import 'pages/patient_records_page.dart';
import 'pages/payment_page.dart';
import 'pages/simple_pages.dart';
import 'pages/vaccination_page.dart';
import 'pages/vitals_tracker_page.dart';
import 'routes/app_routes.dart';
import 'state/app_settings_store.dart';
import 'state/medical_store.dart';
import 'widgets/app_lock_screen.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
                scaffoldBackgroundColor: isHighContrast ? Colors.white : const Color(0xFFF8FAFC),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF0D6EFD),
                  brightness: Brightness.light,
                ),
                inputDecorationTheme: const InputDecorationTheme(
                  border: OutlineInputBorder(),
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                scaffoldBackgroundColor: isHighContrast ? Colors.black : const Color(0xFF0F172A),
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
                AppRoutes.home: (context) => const HomePage(),
                AppRoutes.appointments: (context) => const AppointmentPage(),
                AppRoutes.doctors: (context) => const DoctorsPage(),
                AppRoutes.doctorDetail: (context) => const DoctorDetailPage(),
                AppRoutes.records: (context) => const PatientRecordsPage(),
                AppRoutes.prescription: (context) => const EPrescriptionPage(),
                AppRoutes.payment: (context) => const PaymentPage(),
                AppRoutes.specialty: (context) {
                  final specialty =
                      ModalRoute.of(context)?.settings.arguments as String? ??
                      'Chuyên khoa';
                  return SpecialtyPage(specialty: specialty);
                },
                AppRoutes.splash: (context) => const SplashPage(),
                AppRoutes.intro: (context) => const IntroPage(),
                AppRoutes.login: (context) => const LoginPage(),
                AppRoutes.register: (context) => const RegisterPage(),
                AppRoutes.forgotPassword: (context) => const ForgotPasswordPage(),
                AppRoutes.otp: (context) => const OtpPage(),
                AppRoutes.search: (context) => const SearchPage(),
                AppRoutes.specialtyList: (context) => const SpecialtyListPage(),
                AppRoutes.specialtyDetail: (context) => SpecialtyDetailPage(
                  specialty:
                      ModalRoute.of(context)?.settings.arguments as String? ??
                      'Chuyên khoa',
                ),
                AppRoutes.confirmAppointment: (context) =>
                    const ConfirmAppointmentPage(),
                AppRoutes.bookingSuccess: (context) => const BookingSuccessPage(),
                AppRoutes.myAppointments: (context) => const MyAppointmentsPage(),
                AppRoutes.appointmentDetail: (context) =>
                    const AppointmentDetailPage(),
                AppRoutes.cancelAppointment: (context) =>
                    const CancelAppointmentPage(),
                AppRoutes.visitHistory: (context) => const VisitHistoryPage(),
                AppRoutes.doctorRating: (context) => const DoctorRatingPage(),
                AppRoutes.profile: (context) => const PatientProfilePage(),
                AppRoutes.labResults: (context) => const LabResultsPage(),
                AppRoutes.labDetail: (context) => const LabResultDetailPage(),
                AppRoutes.prescriptionDetail: (context) =>
                    const PrescriptionDetailPage(),
                AppRoutes.notifications: (context) => const NotificationsPage(),
                AppRoutes.settings: (context) => const SettingsPage(),
                AppRoutes.diagnostics: (context) => const DiagnosticsPage(),
                AppRoutes.aiAssistant: (context) => const AiHealthAssistantPage(),
                AppRoutes.medicationTracker: (context) => const MedicationTrackerPage(),
                AppRoutes.vitalsTracker: (context) => const VitalsTrackerPage(),
                AppRoutes.liveQueue: (context) => const LiveQueuePage(),
                AppRoutes.vaccination: (context) => const VaccinationPage(),
                AppRoutes.healthPackages: (context) => const HealthPackagesPage(),
                AppRoutes.hospitalMap: (context) => const HospitalMapPage(),
                AppRoutes.digitalCard: (context) => const DigitalCardPage(),
                AppRoutes.emergencySos: (context) => const EmergencySosPage(),
                AppRoutes.mentalHealth: (context) => const MentalHealthPage(),
                AppRoutes.healthNews: (context) => const HealthNewsPage(),
                AppRoutes.adminSlots: (context) => const AdminSlotPage(),
                AppRoutes.familyProfiles: (context) => const FamilyProfilesPage(),
                AppRoutes.telemedicine: (context) => const TelemedicinePage(),
              },

            );
          },
        ),
      ),
    );
  }
}
