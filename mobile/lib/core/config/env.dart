/// Runtime configuration. Override via `--dart-define=...`.
class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  /// Optional explicit public web base for ticket QR codes (no trailing slash).
  /// Example: `--dart-define=PUBLIC_WEB_URL=https://countryboy.co.zw`
  ///
  /// When omitted, the host is taken from [apiBaseUrl] so QR codes follow the
  /// same machine/IP you used for the API (e.g. `10.40.0.142`).
  static const _publicWebUrlOverride = String.fromEnvironment('PUBLIC_WEB_URL');

  /// Frontend port used when deriving the verify URL from [apiBaseUrl].
  /// Example: `--dart-define=PUBLIC_WEB_PORT=5173`
  static const _publicWebPort = String.fromEnvironment(
    'PUBLIC_WEB_PORT',
    defaultValue: '8080',
  );

  static const appName = 'countryboy';
  static const appVersion = '1.0.0';

  /// Public web app base used in ticket QR codes (no trailing slash).
  static String get publicWebUrl {
    final override = _publicWebUrlOverride.trim();
    if (override.isNotEmpty) {
      return _stripTrailingSlash(override);
    }
    return _derivePublicWebUrlFromApi(apiBaseUrl);
  }

  static String ticketVerifyUrl(String ticketId) =>
      '$publicWebUrl/verify/$ticketId';

  static String _derivePublicWebUrlFromApi(String apiUrl) {
    final uri = Uri.tryParse(apiUrl);
    if (uri == null || uri.host.isEmpty) {
      return 'http://127.0.0.1:8080';
    }

    final port = int.tryParse(_publicWebPort) ?? 8080;
    return Uri(
      scheme: uri.scheme.isEmpty ? 'http' : uri.scheme,
      host: uri.host,
      port: port,
    ).toString();
  }

  static String _stripTrailingSlash(String value) {
    if (value.length > 1 && value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }
}
