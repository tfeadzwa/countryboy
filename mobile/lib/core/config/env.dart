/// Runtime configuration. Override via `--dart-define=API_BASE_URL=...`.
class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  static const appName = 'CountryBoy Conductor';
  static const appVersion = '1.0.0';
}
