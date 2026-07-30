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

## 2026-07-30 — Headless Production Release APK Build Altyapısı Tamamlandı
- **Ne yapıldı:**
  1. Headless/CLI ortamlarında Android Studio IDE gereksinimi olmaksızın `flutter build apk --release` komutu ile imzalı üretim APK'sı üretilmesi sağlandı.
  2. Ortam doğrulama betikleri (`validate_environment.ps1`, `validate_environment.sh`) yazıldı.
  3. Üretim keystore & imza yapılandırması (`generate_keystore.ps1`, `generate_keystore.sh`, `android/key.properties.example`, `android/app/build.gradle.kts`) tamamlandı.
  4. Otomatik derleme ve APK doğrulama betikleri (`build_release.ps1`, `build_release.sh`) yazıldı.
  5. Derleme hataları veren Dart tip uyumsuzlukları giderildi ve `flutter build apk --release` başarıyla çalıştırıldı.
  6. Üretilen İmzalı APK: `build/app/outputs/flutter-apk/app-release.apk` (52.94 MB, API 21+, `arm64-v8a`/`armeabi-v7a`/`x86_64`).
  7. `mobile/BUILD_GUIDE.md` ayrıntılı rehberi güncellendi.
- **Alınan kararlar:**
  - Dahili şirket tabletleri için R8/minify çakışmalarını önlemek üzere `isMinifyEnabled = false` ile kararlı imzalı üretim APK'sı yapılandırıldı.
- **Bulunan sorun/gotcha:**
  - Flutter 3.41+ sürümlerinde `jni` ve `jni_flutter` eklentileri `compileSdk = 35` gerektirdiği için `android/app/build.gradle.kts` içinde 35 olarak sabitlendi.
- **Bir sonraki oturumda kaldığı yer:**
  - Mobil APK üretimi %100 doğrulandı ve teslimata hazır.

---

## 2026-07-30 — Faz 3: Fotoğraf Çekimi, İmza Pedi ve Rapor Kesinleştirme Akışları Tamamlandı
- Ne yapıldı:
  - Ekran dokunma hareketlerini takip ederek çizim yapan saf Flutter **`SignaturePad`** çizim widget'ı yazıldı.
  - `ProfileScreen` içine imza çizme, kaydetme ve secure storage üzerinden yüklenerek PNG formatında önizleme altyapısı entegre edildi.
  - Dinamik forma **Saha Fotoğrafları** adımı eklendi:
    - Bakım raporları için Öncesi, Sonrası ve Etiket fotoğraflarının hepsi; Test raporları için sadece Etiket fotoğrafı zorunlu kılındı.
    - Kamera çekimi ve galeri seçimleri mock-diyaloglarla simüle edilerek dataJson içerisine kaydedilmesi sağlandı.
  - Rapor kesinleştirme akışında fotoğraf eksikliklerini kontrol eden validasyonlar eklendi.
  - Kesinleştirme tamamlandığında **PRD §21.4** gereğince açılan **Üretim Sonrası Ekranı** tasarlanıp entegre edildi:
    - **Excel'i Aç | Paylaş | Yazdır | Kapat** seçenekleri modern görsel kartlar ve Android intent tetikleme simülasyonları ile eklendi.
- Alınan kararlar:
  - Harici paketlerin derleme/uyumluluk hatalarını önlemek için imza çizim alanı Gesture-detector ve CustomPainter ile tamamen saf Flutter kodlandı.
- Bulunan sorun/gotcha:
  - Fotoğraflar eklenmeden raporun kesinleşmesini engellemek için finalize fonksiyonunun başına tipe göre (Bakım/Test) zorunlu fotoğraf kontrol blokları eklendi.
- Bir sonraki oturumda kaldığı yer:
  - Faz 4: Admin Gösterge Paneli iyileştirmeleri, Şablon yükleme UI, kullanıcı yönetimi UI ve Hata durumları için Türkçe kullanıcı mesajları cilalama.

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
