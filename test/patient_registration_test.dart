import 'package:flutter_test/flutter_test.dart';

import 'package:bt2_2324801030077/state/medical_store.dart';

void main() {
  test('patient registration creates a reusable local account', () async {
    final store = MedicalStore(enablePersistence: false);

    final result = await store.registerPatient(
      name: 'Tran Minh An',
      phone: '0912345678',
      email: 'minhan@example.com',
      password: 'abc123',
      confirmPassword: 'abc123',
    );

    expect(result.success, isTrue);
    expect(store.authenticated, isTrue);
    expect(store.profile.email, 'minhan@example.com');

    store.logout();
    final ok = await store.loginOnlineFirst(
      identifier: 'minhan@example.com',
      password: 'abc123',
    );

    expect(ok, isTrue);
    expect(store.authenticated, isTrue);

    final duplicate = await store.registerPatient(
      name: 'Tran Minh An',
      phone: '0987654321',
      email: 'minhan@example.com',
      password: 'abc123',
      confirmPassword: 'abc123',
    );

    expect(duplicate.success, isFalse);
  });
}
