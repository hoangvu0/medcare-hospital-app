import 'package:flutter/foundation.dart';

/// Runtime configuration. An explicit `--dart-define` always wins; otherwise
/// use the standard local-backend address for the current Flutter target.
abstract final class AppConfig {
  static String get apiBaseUrl {
    const configured = String.fromEnvironment('MEDCARE_API_BASE_URL');
    if (configured.trim().isNotEmpty) return configured.trim();
    // Chrome runs on the laptop; the Android emulator reaches the laptop via
    // the special host alias 10.0.2.2. A physical phone must still pass the
    // laptop LAN IP explicitly with --dart-define.
    return kIsWeb ? 'http://127.0.0.1:8080' : 'http://10.0.2.2:8080';
  }

  static const apiBearerToken = String.fromEnvironment(
    'MEDCARE_API_BEARER_TOKEN',
    defaultValue: '',
  );

  static const paymentBankCode = String.fromEnvironment(
    'MEDCARE_PAYMENT_BANK_CODE',
    defaultValue: 'TCB',
  );

  static const paymentBankAccount = String.fromEnvironment(
    'MEDCARE_PAYMENT_BANK_ACCOUNT',
    defaultValue: '0969261252',
  );

  static const paymentBankName = String.fromEnvironment(
    'MEDCARE_PAYMENT_BANK_NAME',
    defaultValue: 'NGUYEN HOANG VU',
  );

  static const paymentBankDisplayName = String.fromEnvironment(
    'MEDCARE_PAYMENT_BANK_DISPLAY_NAME',
    defaultValue: 'Techcombank',
  );

  static bool get hasApi => apiBaseUrl.isNotEmpty;

  static bool get hasApiToken => apiBearerToken.isNotEmpty;
}
