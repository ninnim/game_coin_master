class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mobileproject-production-c3ce.up.railway.app',
  );
  static const String signalRUrl = '$apiBaseUrl/hubs/game';
}
