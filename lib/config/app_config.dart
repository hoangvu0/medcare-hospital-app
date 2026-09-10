/// Runtime configuration placeholder. Inject values with `--dart-define` in CI.
abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'MEDCARE_API_BASE_URL',
    defaultValue: '',
  );

  static bool get hasApi => apiBaseUrl.isNotEmpty;
}
