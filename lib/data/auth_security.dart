import 'dart:convert';

import 'package:crypto/crypto.dart';

class AuthSecurity {
  AuthSecurity._();

  static const _algorithm = 'sha256';

  static String hashPassword({
    required String identifier,
    required String password,
  }) {
    final normalizedIdentifier = identifier.trim().toLowerCase();
    final salt = base64Url
        .encode(utf8.encode('medcare:$normalizedIdentifier:v1'))
        .replaceAll('=', '');
    final digest = sha256
        .convert(utf8.encode('$salt:$normalizedIdentifier:$password'))
        .toString();
    return '$_algorithm:$salt:$digest';
  }

  static bool verifyPassword({
    required String identifier,
    required String password,
    required String storedHash,
  }) {
    if (!storedHash.startsWith('$_algorithm:')) {
      return storedHash == password;
    }
    final parts = storedHash.split(':');
    if (parts.length != 3) return false;
    final normalizedIdentifier = identifier.trim().toLowerCase();
    final digest = sha256
        .convert(utf8.encode('${parts[1]}:$normalizedIdentifier:$password'))
        .toString();
    return digest == parts[2];
  }

  static bool needsMigration(String storedHash) =>
      !storedHash.startsWith('$_algorithm:');
}
