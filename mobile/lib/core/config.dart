class AppConfig {
  /// Standalone Single-Tablet Offline Mode (Phase 1)
  static const bool isOfflineOnly = true;

  // Legacy Base URL configuration for remote sync (Phase 2+)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const Duration requestTimeout = Duration(seconds: 15);

  /// Tüm testlerde kullanılan sabit test cihazı bilgileri.
  /// Cihaz değişmediği sürece kullanıcıdan tekrar tekrar sorulmaz,
  /// tüm raporlara otomatik olarak yazılır.
  static const String testDeviceModel = 'STS 5000';
  static const String testDeviceSerial = '19B20';

  /// İkinci sabit test cihazı: İZOLASYON, TOPRAKLAMALAR, KESİCİ İZOLASYON ve
  /// AÇMA-KAPAMA sayfalarında kullanılan ayrı ölçüm cihazı.
  static const String testDeviceModel2 = 'METREL-MI3123';
  static const String testDeviceSerial2 = '16060016';
}
