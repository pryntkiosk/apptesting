/// Central app configuration.
///
/// Override [apiBaseUrl] at build time with:
///   flutter run --dart-define=API_BASE_URL=https://api.yourdomain.com
class AppConfig {
  AppConfig._();

  /// Base URL of the Prynt backend (FastAPI). All endpoints live under `/api`.
  ///
  /// Defaults:
  ///  - Android emulator reaches host machine via 10.0.2.2
  ///  - Use --dart-define for staging/production.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Mobile API prefix.
  static const String mobilePrefix = '/api/mobile';

  static String get loginUrl => '$apiBaseUrl$mobilePrefix/auth/login';

  /// Network timeout.
  static const Duration requestTimeout = Duration(seconds: 20);

  /// How often the dashboards/lists auto-refresh (in addition to FCM pushes).
  static const Duration pollInterval = Duration(seconds: 25);

  /// Android notification channel used for FCM alerts.
  static const String notificationChannelId = 'prynt_alerts';
  static const String notificationChannelName = 'Prynt Alerts';
  static const String notificationChannelDesc =
      'Refill alerts and service request notifications';
}
