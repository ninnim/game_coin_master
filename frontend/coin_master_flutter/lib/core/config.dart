class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5001',
  );
  static const String signalRUrl = '$apiBaseUrl/hubs/game';
}
