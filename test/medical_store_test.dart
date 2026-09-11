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
    expect(appointment.status, AppointmentStatus.confirmed);
    store.cancelAppointment(appointment.id);
    expect(
      store.appointments.firstWhere((a) => a.id == appointment.id).status,
      AppointmentStatus.cancelled,
    );
    expect(store.notifications, hasLength(initialNotifs + 2));
  });
}
