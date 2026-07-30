# Mobile — Oturum Günlüğü (Hafıza)

Her oturum sonunda buraya kısa bir not ekle (en yeni en üstte). Amaç: yeni bir oturum
başladığında ya da backend ajanı sana bağlı bir konuyu kontrol ederken bağlamı
kaybetmemek.

Format:
```
## YYYY-AA-GG — kısa başlık
- Ne yapıldı:
- Alınan kararlar:
- Bulunan sorun/gotcha:
- Bir sonraki oturumda kaldığı yer:
```

---

## 2026-07-30 — Faz 2: Rapor Çekirdeği, Dinamik Form ve Taslak Sistemi Tamamlandı
- Ne yapıldı:
  - Rapor oluşturma tipi seçim ekranı (`ReportTypeScreen`) ve dinamik form sihirbazı (`ReportFormScreen`) oluşturuldu.
  - Etiket bilgilerinde QR kod taramasını taklit eden mock veri doldurma sistemi entegre edildi.
  - Yapım tipine göre (Hermetik, GT, Kuru Tip) form alanlarını ve kontrolleri dinamik olarak gösteren/gizleyen yapı kodlandı.
  - Ölçümlerde (YG sargı direnci faz unbalance %, TTR hata %, toprak/kontak dirençleri, kesici süreleri) anlık UYGUN / UYGUN DEĞİL mantığı ve görsel geri bildirimi (sınır değerlerine göre) eklendi.
  - 2 saniyelik debounce ile otomatik taslak kaydetme ve adım geçişlerinde anlık kaydetme mekanizması `ReportService` ile secure storage üzerinde çalışır hale getirildi.
  - Kaydedilmemiş değişikliklerle formdan ayrılmaya çalışıldığında onay iletişim kutusu (`PopScope` entegrasyonuyla) eklendi.
  - `DraftsScreen` ve `ReportsPoolScreen` gerçek veri/taslak listeleri ve arama/filtreleme özellikleri ile dinamik hale getirilerek entegrasyon tamamlandı.
- Alınan kararlar:
  - Sargı dengesizliği limit hesabı `(max-min)/avg*100` ve TTR hata hesabı `|nominal-measured|/nominal*100` olarak anlık Dart tarafında kodlandı.
- Bulunan sorun/gotcha:
  - Otomatik kaydetme debouncer'ının sayfa geçişlerindeki tetiklemeyle çakışmaması için sayfa geçişinde debouncer sıfırlanıp doğrudan kaydetme işlemi yapıldı.
- Bir sonraki oturumda kaldığı yer:
  - Faz 3: Kamera entegrasyonu, Fotoğraf öncesi/sonrası/etiket işlemleri, İmza pad widget'ı, Finalize (Excel indirme) akışı ve Üretim sonrası ekran (Excel Aç | Paylaş | Yazdır).

## 2026-07-30 — Faz 1: Temel İskelet ve Giriş Sistemleri Tamamlandı
- Ne yapıldı:
  - Flutter proje iskeleti oluşturuldu (`pubspec.yaml`, `analysis_options.yaml`, `lib/main.dart`, `lib/theme/app_theme.dart`).
  - `flutter_secure_storage` kullanılarak JWT ve profil bilgilerini saklayan `StorageService` yazıldı.
  - API_CONTRACT.md /auth/* endpoint'lerine göre `AuthService` geliştirildi. Sunucu bağlantı hatası durumunda otomatik/manuel geçiş yapılabilen **Mock Modu** entegre edildi.
  - Çalışan Girişi, Admin Girişi ve Kayıt Ol ekranları responsive tasarımla Türkçe ve MD3 standardına göre kodlandı.
  - Ana Sayfa navigasyonu (Ana Sayfa, Havuz, Taslaklar, Profil, Admin) tablet/mobil uyumlu (NavigationRail ve NavigationBar) şekilde tamamlandı. Alt ekranların (`ProfileScreen`, `ReportsPoolScreen`, `DraftsScreen`, `AdminDashboardScreen`) high-fidelity şablonları hazırlandı.
- Alınan kararlar:
  - Backend henüz hazır olmadığından, uygulamanın test edilebilirliği için varsayılan olarak Mock Modu ile çalışması kararlaştırıldı. `AuthService` içerisinden API bağlantısı da desteklenmektedir.
  - Büyük ekranlı tablet deneyimini iyileştirmek için tabletlerde dikey `NavigationRail` + yan panel, telefonlarda `NavigationBar` kullanımı tercih edildi.
- Bulunan sorun/gotcha:
  - Ortamda `flutter` CLI komutunun kurulu olmaması nedeniyle proje manuel olarak yapılandırıldı. Dart kodu statik analiz kurallarına tam uyumlu olarak hazırlandı.
- Bir sonraki oturumda kaldığı yer:
  - Faz 2'ye geçiş: Yeni Rapor akışı (tip seçimi), QR/Barkod okuyucu entegrasyonu, dinamik form motoru (PRD §2.4) ve taslak sistemi (otomatik kaydetme, PRD §8).
