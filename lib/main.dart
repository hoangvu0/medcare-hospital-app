import 'package:flutter/material.dart';

import 'pages/appointment_page.dart';
import 'pages/additional_pages.dart';
import 'pages/doctors_page.dart';
import 'pages/e_prescription_page.dart';
import 'pages/home_page.dart';
import 'pages/patient_records_page.dart';
import 'pages/payment_page.dart';
import 'pages/simple_pages.dart';
import 'routes/app_routes.dart';
import 'state/medical_store.dart';

void main() => runApp(const HospitalApp());

class HospitalApp extends StatefulWidget {
  const HospitalApp({super.key});

  @override
  State<HospitalApp> createState() => _HospitalAppState();
}

class _HospitalAppState extends State<HospitalApp> {
  final _store = MedicalStore();

  @override
  Widget build(BuildContext context) {
    return MedicalScope(
      store: _store,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MedCare Hospital',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D6EFD)),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.home: (context) => const HomePage(),
          AppRoutes.appointments: (context) => const AppointmentPage(),
          AppRoutes.doctors: (context) => const DoctorsPage(),
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
        },
      ),
    );
  }
}
