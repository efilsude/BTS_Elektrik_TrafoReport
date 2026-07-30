class AppConfig {
  // Base URL configuration for API requests:
  // - Android Emulator: http://10.0.2.2:8000/api/v1
  // - Windows / Web / Desktop: http://localhost:8000/api/v1
  // - Physical Device (LAN): http://<YOUR_PC_LAN_IP>:8000/api/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const Duration requestTimeout = Duration(seconds: 15);
}
