import 'package:flutter_test/flutter_test.dart';
import 'package:bt2_2324801030077/data/auth_security.dart';

void main() {
  group('AuthSecurity', () {
    test('hashes password instead of storing plain text', () {
      final hash = AuthSecurity.hashPassword(
        identifier: 'doctor@medcare.vn',
        password: '123456',
      );

      expect(hash, isNot('123456'));
      expect(hash.startsWith('sha256:'), isTrue);
      expect(
        AuthSecurity.verifyPassword(
          identifier: 'doctor@medcare.vn',
          password: '123456',
          storedHash: hash,
        ),
        isTrue,
      );
      expect(
        AuthSecurity.verifyPassword(
          identifier: 'doctor@medcare.vn',
          password: 'wrong-password',
          storedHash: hash,
        ),
        isFalse,
      );
    });

    test('keeps legacy plain-text verification for migration only', () {
      expect(
        AuthSecurity.verifyPassword(
          identifier: 'patient@example.com',
          password: '123456',
          storedHash: '123456',
        ),
        isTrue,
      );
      expect(AuthSecurity.needsMigration('123456'), isTrue);
    });
  });
}
