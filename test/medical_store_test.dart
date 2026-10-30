import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bt2_2324801030077/models/medical_models.dart';
import 'package:bt2_2324801030077/state/medical_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('đặt rồi hủy lịch cập nhật state và thông báo', () {
    final store = MedicalStore();
    final initialCount = store.appointments.length;
    final initialNotifs = store.notifications.length;
    final appointment = store.book(
      doctor: store.doctors.first,
      dateTime: DateTime(2026, 10, 1, 9),
      patientName: store.profile.name,
      reason: 'Khám định kỳ',
      useInsurance: false,
    );

    expect(store.appointments, hasLength(initialCount + 1));
    expect(store.notifications, hasLength(initialNotifs + 1));
    expect(appointment.status, AppointmentStatus.awaitingPayment);
    final appointmentFee = store.transactions.firstWhere(
      (tx) => tx.visitCode == '#${appointment.id}',
    );
    store.completeTransaction(appointmentFee.id);
    expect(
      store.appointments.firstWhere((a) => a.id == appointment.id).status,
      AppointmentStatus.confirmed,
    );
    store.cancelAppointment(appointment.id);
    expect(
      store.appointments.firstWhere((a) => a.id == appointment.id).status,
      AppointmentStatus.cancelled,
    );
    expect(store.notifications, hasLength(initialNotifs + 3));
  });

  test('chưa thanh toán lịch hẹn thì bác sĩ không được phát hành EMR', () {
    final store = MedicalStore();
    store.book(
      doctor: store.activeDoctorUser,
      dateTime: DateTime(2026, 10, 2, 9),
      patientName: store.activeFamilyMember.name,
      reason: 'Khám tim mạch',
      useInsurance: true,
    );

    expect(
      () => store.doctorExecuteFullConsultationSync(
        diagnosis: 'Theo dõi tăng huyết áp',
        icd10Code: 'I10',
        icd10Name: 'Tăng huyết áp vô căn',
        symptoms: 'Đau đầu nhẹ',
        physicalExam: 'Huyết áp 130/80 mmHg',
        labNotes: 'Chưa chỉ định cận lâm sàng',
        doctorAdvice: 'Theo dõi tại nhà',
        followUpDate: '09/10/2026',
        prescribedMedicines: const [],
      ),
      throwsA(isA<StateError>()),
    );
    expect(store.medicalRecords, isEmpty);
    expect(store.medicines, isEmpty);
  });

  test(
    'chưa có lịch xác nhận thì dữ liệu lâm sàng không ghi sang bệnh nhân',
    () {
      final store = MedicalStore();
      final initialVitals = store.vitals.length;
      final initialLabs = store.labTests.length;

      store.doctorRecordVitals(
        bpSys: 130,
        bpDia: 80,
        heartRate: 72,
        spo2: 98,
        temp: 36.7,
        weight: 70,
      );
      store.doctorOrderCBC();

      expect(store.vitals.length, initialVitals);
      expect(store.labTests.length, initialLabs);
      expect(store.securityAuditLogs.first.action, 'BLOCKED_CLINICAL_WRITE');
    },
  );

  test('không được hủy lịch đã hoàn tất khám', () {
    final store = MedicalStore();
    final appointment = store.book(
      doctor: store.activeDoctorUser,
      dateTime: DateTime(2026, 10, 3, 9),
      patientName: store.activeFamilyMember.name,
      reason: 'Khám tim mạch',
      useInsurance: true,
    );
    final appointmentFee = store.transactions.firstWhere(
      (tx) => tx.visitCode == '#${appointment.id}',
    );
    store.completeTransaction(appointmentFee.id);
    store.doctorExecuteFullConsultationSync(
      diagnosis: 'Theo dõi tăng huyết áp',
      icd10Code: 'I10',
      icd10Name: 'Tăng huyết áp vô căn',
      symptoms: 'Đau đầu nhẹ',
      physicalExam: 'Huyết áp 130/80 mmHg',
      labNotes: 'Chưa chỉ định cận lâm sàng',
      doctorAdvice: 'Theo dõi tại nhà',
      followUpDate: '10/10/2026',
      prescribedMedicines: const [
        MedicineItem(
          name: 'Amlodipine 5mg',
          category: 'Hạ áp',
          dosage: '5mg',
          quantity: '30 viên',
          instruction: 'Uống 1 viên buổi sáng',
        ),
      ],
    );

    expect(
      () => store.cancelAppointment(appointment.id),
      throwsA(isA<StateError>()),
    );
  });
}
