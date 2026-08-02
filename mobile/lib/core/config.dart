class AppConfig {
  /// Standalone Single-Tablet Offline Mode (Phase 1)
  static const bool isOfflineOnly = true;

  // Legacy Base URL configuration for remote sync (Phase 2+)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const Duration requestTimeout = Duration(seconds: 15);
}
