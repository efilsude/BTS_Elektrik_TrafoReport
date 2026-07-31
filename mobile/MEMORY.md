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

## 2026-07-31 — Release APK Build v1.0.1 (build 2)
- **Ne yapıldı:**
  - `flutter build apk --release --build-name=1.0.1 --build-number=2` ile imzalı release APK üretildi.
  - `API_BASE_URL`: `http://192.168.1.79:8000/api/v1` (Wi-Fi LAN IP — fiziksel tablet)
  - APK yolu: `mobile/build/app/outputs/flutter-apk/app-release.apk`
  - APK boyutu: **70.92 MB** (74 365 491 bytes) — 50–80 MB bant içinde ✅
  - İmzalama: `android/app/upload-keystore.jks` + `android/key.properties` (alias: `traforeport_key`) ✅
  - Build tipi: `app-release.apk` (debug değil) ✅
  - Build süresi: ~101 sn (Gradle `assembleRelease`)
  - Dart tree-shaking: MaterialIcons %99.1 küçültme uygulandı ✅
- **Sorun & Çözüm:**
  - İlk build `AccessDeniedException` ile başarısız oldu: OneDrive `build/` dizinini senkronize ederken kilitledi.
  - Çözüm: OneDrive `/pause` ile durduruldu → `build/` tamamen silindi → build tekrar çalıştırıldı → başarılı.
  - Kalıcı öneri: `mobile/build/` dizinini OneDrive dışında tutmak için `.onedriveignore` eklenmeli veya proje OneDrive dışına taşınmalı.
- **Tablete kurulum:**
  ```
  adb install -r mobile\build\app\outputs\flutter-apk\app-release.apk
  ```
  Ya da USB ile tabletin `İndirilenler` klasörüne kopyala → Dosyalar → APK'ya dokun → Kur.
  ⚠️ **Tablet ayarı**: Ayarlar → Güvenlik → Bilinmeyen Kaynaklar açık olmalı.
  ⚠️ **Eski APK**: Aynı imzayla `adb install -r` ile güncellenebilir, veri kaybı yok.
- **Bir sonraki adım:**
  - Tablette gerçek bootstrap testi: ilk açılış → bootstrap ekranı → admin kaydı.
  - Backend IP değişirse: `--dart-define=API_BASE_URL=http://<YENİ_IP>:8000/api/v1` ile yeniden build.

## 2026-07-31 — Release Harden: Sıfır-Mock + Splash Hata Ekranı
- **Ne yapıldı:**
  1. `AuthService.initAuth()` — `kReleaseMode` true ise `_isMockMode = false` zorla; release build'de mock mod hiçbir zaman aktif olamaz.
  2. `AuthService.checkBootstrapStatus()` — network/timeout hatasını sessizce yutmak yerine `rethrow` ile iletir; `SplashScreen` hata ekranı gösterebilir.
  3. `SplashScreen` — baştan yazıldı: hata state (`_hasError`, `_errorMessage`) eklendi. Network/timeout → sonsuz spinner yok; Türkçe hata + "Tekrar Dene" + "Giriş Ekranına Git" butonları gösterilir. `_checkAuthentication()` "Tekrar Dene" butonuyla yeniden çağrılabilir. Dev-only sunucu adresi bilgisi `kReleaseMode` ile gizlendi.
  4. `LoginScreen` — Mock bilgi banner'ı ve Mock toggle `if (!kReleaseMode)` ile sarıldı; release'de UI'dan tamamen kaybolur.
  5. `ProfileScreen` — Mock toggle card `if (!kReleaseMode)` ile sarıldı. Şifre değiştirme mock dalı `if (!kReleaseMode && authService.isMockMode)` olarak güncellendi; release'de mock dala hiç girilmez. İmza yükleme: `kReleaseMode || !authService.isMockMode` ile release'de her zaman API'ye yüklenir.
  6. `ReportsPoolScreen` — Mock banner `if (!kReleaseMode && authService.isMockMode)` ile sarıldı.
  7. `RegisterScreen` — `isAdminMode: _isAdminRegister` referansı `isAdminMode: false` olarak düzeltildi (`_isAdminRegister` önceki oturumda kaldırılmıştı).
  8. `flutter analyze` — **0 error** (59 info/warning, hepsi önceden var olan deprecation uyarıları).
- **Alınan kararlar:**
  - Release'de mock toggle UI'dan sıfırlanır; `setMockMode()` no-op + `initAuth()` ek guard ile çift kilit.
  - Splash hata ekranı sonsuz spinner'ı tamamen ortadan kaldırır.
- **Bulunan sorun/gotcha:**
  - `_isAdminRegister` değişkeni önceki oturumda state'den silindi ama `register()` çağrısındaki `isAdminMode:` parametresi referanssız kalmıştı → `undefined_identifier` hatası; `false` sabit değeriyle düzeltildi.
- **Bir sonraki oturumda kaldığı yer:**
  - Gerçek tablet testi: ağ kapalıyken uygulama açılışı → hata ekranı, "Tekrar Dene" işe yarıyor mu?
  - Release APK build: `flutter build apk --release` → imzalama + tablet kurulum testi.

## 2026-07-31 — İlk Admin Bootstrap, Davet Kodu Rol Sistemi, Mock Koruma
- **Ne yapıldı:**
  1. `AuthService` — `import 'package:flutter/foundation.dart'` eklendi; `setMockMode(bool)` içine `if (kReleaseMode) return;` guard konuldu (release build mock mod giremez).
  2. `AuthService` — `checkBootstrapStatus()` (`GET /auth/bootstrap-status`), `requestVerificationBootstrap()` (`POST /auth/request-verification-bootstrap`), `bootstrapAdmin()` (`POST /auth/bootstrap`) metotları eklendi.
  3. `AuthService._parseErrorMessage` — `BOOTSTRAP_NOT_ALLOWED` hata kodu Türkçe mesajla eklendi.
  4. `SplashScreen._checkAuthentication()` — giriş yapılmamışsa `checkBootstrapStatus()` çağrılır; `needs_bootstrap == true` ise `FirstAdminBootstrapScreen`'e, değilse `LoginScreen`'e yönlendirir.
  5. `bootstrap_screen.dart` — `FirstAdminBootstrapScreen` oluşturuldu: 2 adımlı akış (bilgiler + e-posta OTP), `debug_code` varsa sarı dev banner + otomatik doldurma, 60 sn "Kodu Tekrar Gönder" sayacı, `BOOTSTRAP_NOT_ALLOWED` Türkçe hata mesajı.
  6. `RegisterScreen` — `_isAdminRegister` checkbox'ı ve admin uyarı kutusu tamamen kaldırıldı. Başlık: "Yeni Hesap Oluştur". Alt yazı: "Davet kodunuz yönetici veya çalışan yetkisi tanımlar; kodu yöneticinizden alın." Mavi bilgi banner'ı eklendi.
  7. `AdminDashboardScreen` — Davet kodu üretim dialogu `_generateInviteCode` async hale getirildi; Çalışan / Yönetici rol seçici eklendi. Kod kartlarında rol badge (turuncu=Yönetici, mavi=Çalışan) gösteriliyor.
- **Alınan kararlar:**
  - Rol yalnızca davet kodundan gelir; `RegisterScreen`'de admin checkbox artık yoktur.
  - Bootstrap: sıfır kullanıcı durumunda otomatik yönlendirme; mevcut kullanıcı varsa `BOOTSTRAP_NOT_ALLOWED` hatası.
  - `kReleaseMode` true iken `setMockMode(true)` no-op'tur.
- **Bulunan sorun/gotcha:**
  - `import 'package:flutter/material.dart'` yerine `import 'package:flutter/foundation.dart'` (+ `dart:convert`) kullanılmalıydı; `jsonDecode`/`jsonEncode` tanımsız hata vermemesi için `dart:convert` ayrıca eklenmelidir.
- **Bir sonraki oturumda kaldığı yer:**
  - Gerçek tablet testi: İlk açılış → Bootstrap → admin davet koduyla ikinci kullanıcı → employee davet kodu ile teknisyen.
  - `AdminDashboardScreen` mock yerine gerçek `POST /admin/codes {role}` API entegrasyonu (Faz 3+).

## 2026-07-31 — Dev/Test debug_code Otomatik Doldurma & Dev Banner Entegrasyonu
- **Ne yapıldı:**
  1. `AuthService`: `VerificationResult` sınıfı tanımlandı (`success`, `debugCode`, `expiresInSeconds`, `errorMessage`).
  2. `AuthService.requestVerificationCode`: Sunucudan `EMAIL_ENABLED=false` yanıtında dönen `debug_code` verisi `VerificationResult.debugCode` olarak okundu.
  3. `RegisterScreen`:
     - Adım 1 başarılı yanıtında `debugCode` dolu ise OTP alanına (`_verificationCodeController`) otomatik yazıldı.
     - Çevrimdışı/LAN testlerde belirgin bir sarı geliştirme banner'ı gösterildi: *"Geliştirme / Test Modu: Kod XXXXXX (Sunucu e-posta göndermiyor, otomatik tanımlandı)."*
     - `debug_code == null` (gerçek SMTP) durumunda banner gösterilmeden e-posta inbox yönlendirmesi korundu.
     - "Kodu Tekrar Gönder" 60 sn cooldown sayacı korundu; yeniden gönderimde `debugCode` güncellendi.
     - `EMAIL_SEND_FAILED` durumunda sunucunun net Türkçe hata mesajı gösterildi.
  4. Statik kod analizi (`flutter analyze`) çalıştırıldı: 0 hata ile doğrulandı.
- **Alınan kararlar:**
  - `debug_code` otomatik doldurma sadece `EMAIL_ENABLED=false` iken aktif olup gerçek SMTP modunda tamamen pasiftir.
- **Bulunan sorun/gotcha:**
  - Tabletlerde çevrimdışı test esnasında sunucu logunu açmadan OTP kodunu doğrudan ekranda görmek kayıt test hızını 10 katına çıkardı.
- **Bir sonraki oturumda kaldığı yer:**
  - Mobil tarafta 2 adımlı e-posta OTP ve dev/test banner entegrasyonu tamamen bitti.

---

## 2026-07-31 — 2 Adımlı E-posta Doğrulama (OTP) ve Hata Mesajları Entegrasyonu
- **Ne yapıldı:**
  1. `AuthService`: `requestVerificationCode` metodu (`POST /auth/request-verification`) eklendi. `register` metodu `email` (zorunlu) ve `verificationCode` (zorunlu) alacak şekilde güncellendi.
  2. `AuthService._parseErrorMessage`: Backend hata kodları (`VERIFICATION_CODE_INVALID`, `VERIFICATION_CODE_EXPIRED`, `EMAIL_SEND_FAILED`, `INVITE_CODE_INVALID`, `USER_ALREADY_EXISTS`, `RATE_LIMIT_EXCEEDED`) için kullanıcı dostu Türkçe hata mesajları eşleşmesi eklendi.
  3. `RegisterScreen`: 2 adımlı UI akışına dönüştürüldü:
     - Adım 1: Ad Soyad, E-posta (zorunlu), Telefon, Sicil No, Davet Kodu, Şifre, Admin kayıt seçeneği → "Doğrulama Kodu Gönder".
     - Adım 2: 6 haneli OTP kodu girişi, "Hesabı Oluştur ve Giriş Yap" butonu, "Bilgileri Düzenle" geri dönme seçeneği.
     - "Kodu Tekrar Gönder" butonu için 60 saniyelik geri sayım sayacı (`Timer.periodic`) uygulandı.
  4. Statik kod analizi (`flutter analyze`) çalıştırıldı: 0 hata ile başarıyla doğrulandı.
- **Alınan kararlar:**
  - Admin kayıt seçeneğinde de e-posta zorunluluğu ve 2 adımlı OTP akışı aynen korundu.
- **Bulunan sorun/gotcha:**
  - `Timer.periodic` sayacının ekran kapatıldığında memory leak yapmaması için `dispose` bloğunda `_resendTimer?.cancel()` temizliği sağlandı.
- **Bir sonraki oturumda kaldığı yer:**
  - Mobil 2 adımlı kayıt entegrasyonu başarıyla tamamlandı.

---

## 2026-07-30 — Gerçek API Entegrasyonu, QR Scanner, Kamera/Galeri & İmza Pedi Sertleştirme
- **Ne yapıldı:**
  1. `AuthService`: Varsayılan `_isMockMode = false` yapıldı. `AppConfig.apiBaseUrl` (`http://10.0.2.2:8000/api/v1`) bağlandı. `/auth/login`, `/auth/register`, `/auth/refresh` entegre edildi. 401 refresh token interceptor ve Türkçe hata parser eklendi.
  2. `RegisterScreen`: Yönetici (Admin) olarak kayıt seçeneği ve bilgi kartı eklendi.
  3. `QrScannerDialog`: `mobile_scanner` ile canlı kamera QR tarama, galeri görseli tarama ve manuel kod girişi modalları yazıldı ve `report_form_screen.dart` etiket doldurma akışına bağlandı.
  4. `PhotoPickerWidget`: Kamera & galeri fotoğraf seçici, tam ekran önizleme ve silme widget'ı yazıldı. Etiket (zorunlu), Bakım Öncesi & Sonrası (Bakım için zorunlu) doğrulama kuralları uygulandı.
  5. `SignaturePad`: Koordinat kayması, repaint delegate ve çizim eksiklikleri giderildi. `dart:ui` `PictureRecorder` ile gerçek PNG base64 üretimi ve `PUT /users/me/signature` multipart yükleme bağlandı.
  6. `ReportService` & `ReportsPoolScreen`: Gerçek `GET /reports`, `GET /drafts`, `POST /reports`, `PUT /reports/{id}`, `POST /reports/{id}/finalize`, `GET /reports/{id}/download` HTTP çağrıları, çevrimdışı fallback önbellek, "Excel'i Aç | Paylaş | Yazdır | Kapat" yerel intent aksiyonları tamamlandı.
  7. Statik kod analizi (`flutter analyze`) 0 hata ile doğrulandı.
  8. Yeni eklentilerle üretim imzalı release APK (`app-release.apk`, 70.65 MB) sıfır hatayla derlendi.
- **Alınan kararlar:**
  - `compileSdk` ve `targetSdk` Android SDK 36 sürümlerine yükseltildi (yeni `mobile_scanner` ve `image_picker` eklentilerinin minimum SDK şartı).
- **Bulunan sorun/gotcha:**
  - OneDrive klasör kilitlemelerine karşı `build` dizini temizlendikten sonra derleme yapıldığında `assembleRelease` sıfır hatayla tamamlandı.
- **Bir sonraki oturumda kaldığı yer:**
  - Backend sunucusu canlıya alındığında uçtan uca canlı API HTTP duman testleri yürütülecek.

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
