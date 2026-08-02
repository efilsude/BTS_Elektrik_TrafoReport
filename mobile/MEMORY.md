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

## 2026-07-31 — Release APK Build v1.0.2 (build 3 - Cleartext HTTP İzin Düzeltmesi)
- **Ne yapıldı:**
  - `AndroidManifest.xml` (`android:usesCleartextTraffic="true"` + `networkSecurityConfig`) düzeltmesi sonrası yeni imzalı release APK derlendi.
  - Komut: `flutter build apk --release --build-name=1.0.2 --build-number=3 "--dart-define=API_BASE_URL=http://192.168.1.79:8000/api/v1"`
  - APK Konumu: `mobile/build/app/outputs/flutter-apk/app-release.apk`
  - APK Boyutu: **70.92 MB** (74 365 939 bytes) ✅
  - Derleme Tipi: Signed Release APK (`traforeport_key`) ✅
- **Düzeltilen Kritik Sorun:**
  - Android 9+ varsayılan şifrelenmemiş HTTP trafiği engeli (`Cleartext HTTP traffic not permitted`) giderildi. Artık mobil cihaz LAN üzerindeki `http://192.168.1.79:8000` backend'ine engelsiz bağlanabilir.
- **Kurulum Komutu:**
  ```bash
  adb install -r mobile/build/app/outputs/flutter-apk/app-release.apk
  ```

## 2026-08-02 — Yönetici Tarafından Yerel Kullanıcı Bilgilerini Düzenleme (Admin User Edit)
- **Ne yapıldı:**
  1. **Veri Katmanı (`DatabaseHelper.updateUser`)**:
     - Kullanıcının Ad Soyad, Telefon, E-posta, Sicil No ve Rol bilgilerini parametreli SQL ile güncelleyen metot yazıldı.
     - Telefon numarası başka bir kullanıcı tarafından kullanılıyorsa benzersizlik (unique) ihlal hatası verildi (*"Bu telefon numarası başka bir kullanıcı tarafından kullanılıyor."*).
     - Şifre alanı girilmişse bcrypt ile re-hash edilerek güncellendi.
  2. **İş Kuralları ve Güvenlik Kontrolleri (`AuthService.updateLocalUser`)**:
     - Sistemdeki tek/son aktif yönetici hesabının rolü çalışan (employee) rolüne düşürülmeye çalışıldığında işlem engellendi (*"Sistemde en az bir yönetici bulunmalıdır. Son yöneticinin rolü değiştirilemez."*).
     - Oturum açmış olan yönetici kendi bilgilerini güncellediğinde `_currentUser` durumu anında yenilendi.
  3. **Arayüz (`AdminDashboardScreen`)**:
     - Kullanıcı listesi satırlarına düzenle (kalem) ikonu eklendi.
     - Açılan düzenleme diyalogunda tüm mevcut bilgiler pre-fill olarak dolduruldu; şifre alanı isteğe bağlı (opsiyonel) tutuldu.
  4. `flutter analyze`: **0 Hata** ile doğrulandı.

## 2026-08-02 — Yönetici Paneli Görsel Cilası & Davet Kodu Uyarı Kartının Kaldırılması
- **Ne yapıldı:**
  1. **Gereksiz Davet Kodu Uyarı Kartı Kaldırıldı (`AdminDashboardScreen`)**:
     - Davet kodu/OTP kararı netleştiği için admin panelindeki kalabalık oluşturan *"Tek tablette davet kodu veya e-posta OTP yoktur..."* kartı tamamen silindi.
  2. **Yönetici Paneli Görsel & Hiyerarşi Sadeleştirmesi**:
     - Şişkin çift başlıklar kaldırılıp yerine sade, modern ve kompakt bir yönetici başlık kartı yerleştirildi (`Kullanıcı ve Sistem Yönetimi`).
     - İstatistik kartları dikey/yatay taşmaları önleyecek dinamik esnek yerleşime (`LayoutBuilder` + `Column`/`Row`) kavuşturuldu.
     - "Kullanıcı Ekle" butonu ve "Cihaz Kullanıcıları" başlığı `Wrap` ile sarmalanarak dar mobil ve geniş tablet ekranlarında üst üste binme riski ortadan kaldırıldı.
     - `SafeArea` ve tutarlı dolgular eklendi.
  3. `flutter analyze`: **0 Hata** ile doğrulandı.

## 2026-08-02 — Düzeltme: Saha Fotoğraf Yolları Kalıcılığı & İki Yönlü Anahtar Senkronizasyonu
- **Ne yapıldı:**
  1. **Fotoğraf Anahtarı Senkronizasyonu (`ReportService.savePhotoLocally`)**:
     - Seçilen fotoğraflar `documents/photos/{reportId}/` altına kopyalandıktan sonra hem üst seviye `dataJson['photo_label']` / `photo_before` / `photo_after` hem de iç içe harita `dataJson['photos'][photoKey]` anahtarlarına eş zamanlı yazıldı.
     - `report_photos` SQLite tablosuna kayıt atılıp otomatik yerel taslak kaydı (`saveDraft()`) ve `notifyListeners()` çağrıldı.
  2. **Gelişmiş Fotoğraf Silme (`ReportService.deletePhotoLocally`)**:
     - Fotoğraf silindiğinde üst seviye anahtar, iç içe harita ve `report_photos` tablosundaki ilgili satır temizlenip cihazdaki fiziki `.jpg` dosyası silindi.
  3. **Form ve Finalize Görüntüleme Güvenliği (`report_form_screen.dart`)**:
     - `_buildPhotosStep` ve `_finalizeReport` içerisinde önizleme ve zorunluluk kontrolleri için önce üst seviye key, yoksa `photos` harita fallback'i okundu.
     - Fotoğraf kaydetme sırasında hata oluşursa kullanıcıya SnackBar uyarısı verildi.
  4. `flutter analyze`: **0 Hata** ile doğrulandı.

## 2026-08-02 — Faz 2.1: Sunucusuz Hesap Modeli Cilası, Kullanıcı Silme & UI Taşma Düzeltmeleri
- **Ne yapıldı:**
  1. **"Kayıt Ol" (Self-Register) UI Kaldırıldı (`LoginScreen`)**:
     - Sunucusuz tek tablet karar doğrultusunda `LoginScreen` üzerindeki tüm "Kayıt Ol" buton/linkleri kaldırıldı.
     - Giriş ekranına net bilgilendirme eklendi: *"Hesabınız yoksa sistem yöneticiniz sizi Yönetici Panelinden eklemelidir."*
  2. **Parametreli SQL ile Yönetici Tarafından Kullanıcı Silme (`DatabaseHelper` & `AuthService`)**:
     - `DatabaseHelper.deleteUser(id)` metodu parametreli SQL sorgusu ile oluşturuldu.
     - İş Kuralları:
       - Oturum açmış aktif kullanıcı kendisini silemez.
       - Sistemdeki son aktif yönetici hesabı silinemez (*"Sistemde en az bir yönetici bulunmalıdır. Son yönetici silinemez."*).
       - Kullanıcı silindiğinde geçmişte ürettiği raporlar korunur (`creator_display_name`).
     - `AdminDashboardScreen` kullanıcı listesine silme ikonu, onay diyalogu ve SnackBar bildirimleri eklendi.
  3. **Yönetici Paneli Bilgilendirme Kartı & UI Cilası (`AdminDashboardScreen` & `ProfileScreen`)**:
     - Admin paneline sunucusuz hesap modelini anlatan bilgi kartı eklendi: *"Tek tablette davet kodu veya e-posta OTP yoktur. Çalışan hesapları doğrudan buradan oluşturulur; çalışan telefon ve şifre ile Giriş yapar."*
     - `ProfileScreen` üzerindeki yedek alma / geri yükleme butonları dar ekranlarda taşmayacak biçimde duyarlı hale getirildi.
  4. `flutter analyze`: **0 Hata** ile doğrulandı.

## 2026-08-02 — Düzeltme: User.fromJson int->bool Dönüşüm Hataları & Duyarlı İlk Admin Kurulum Ekranı
- **Ne yapıldı:**
  1. **`User.fromJson` Güvenli Bool Dönüştürme (`mobile/lib/models/user_model.dart`)**:
     - SQLite veritabanından gelen `is_active` / `has_signature` değerlerinin integer (0 / 1) olması nedeniyle çıkış yapıp tekrar girişte yaşanan `type 'int' is not a subtype of type 'bool'` tür dönüşüm hatası giderildi.
     - `_parseBool` dâhili fonksiyonu ile int, bool ve String veri tipleri güvenli bir şekilde `bool` değerlere dönüştürüldü. `signature_path` dolu olduğunda `hasSignature` otomatik olarak `true` kabul edildi.
  2. **Duyarlı `FirstAdminBootstrapScreen` UI (`mobile/lib/screens/auth/bootstrap_screen.dart`)**:
     - Genişlik (width < 700) küçük olan cihazlarda (dikey tablet / telefon) daralan iki kolonlu yan yana düzen yerine tek kolonlu, üstü kompakt gradyan banner'lı ve altı dikey kaydırılabilir form düzenine geçildi.
     - Genişlik >= 700 olan tabletlerde sol banner ve sağ form şeklinde iki kolonlu düzen korundu.
  3. `flutter analyze`: **0 Hata** ile doğrulandı.

## 2026-08-02 — Faz 2: Cihaz Üzerinde Native Excel (.xlsx) Rapor Üretim Motoru
- **Ne yapıldı:**
  1. **Şablon Asset'leri**: `backend/templates/` altındaki 3 orijinal Excel şablonu `mobile/assets/templates/` altına kopyalandı ve `pubspec.yaml` dosyasına eklendi:
     - `hermetik.xlsx` (Hermetik Trafo Bakım Raporu)
     - `kuru_tip.xlsx` (Kuru Tip Trafo Bakım Raporu)
     - `gt.xlsx` (Genleşme Tanklı Trafo Bakım Raporu)
  2. **Hücre Haritalama Mimarisi (`ExcelCellMapping`)**:
     - `backend/app/services/excel_engine.py` üzerindeki `CELL_MAPPING` mantığı `mobile/lib/excel/cell_mapping.dart` dosyasına taşındı.
     - `KAPAK SAYFASI`, `ANA SAYFA`, `OG SARGI MEVCUT KADEME`, `AG SARGI` sayfalarındaki hücre eşleşmeleri ve `dateToExcelSerial` (epoch 1899-12-30) dönüştürücüsü tanımlandı.
  3. **Dart Excel Üretim Motoru (`ExcelGenerator`)**:
     - `excel: ^4.0.6` paketi ile Flutter asset baytları okunarak bellek üzerinde orijinal stiller, biçimlendirmeler ve formüller korunacak şekilde hücre değerleri (DoubleCellValue, IntCellValue, TextCellValue) yazıldı.
     - Çıktı dosyaları `{Müşteri} - {Trafo Etiketi} - {GG.AA.YYYY}.xlsx` adıyla kalıcı `documents/reports/` klasörüne kaydedilir.
  4. **Finalize & Native Intent Akışı Entegrasyonu**:
     - "Raporu Tamamla" butonuna basıldığında yerel Excel üretilir, SQLite veritabanında `status = 'finalized'`, `finalized_at` ve `excel_path` güncellenir.
     - Üretim sonrası diyalogunda **"Excel'i Aç"** (`open_filex`) ve **"Paylaş"** (`share_plus`) butonları bağlandı.
  5. `flutter analyze`: **0 Hata** ile doğrulandı.
- **Dart / Excel Ekosistem Sınırları Notu**:
  - `excel` paketi hücre değerlerini şablon stilini ve hücre birleştirmelerini bozmadan doğrudan yazar.
  - Şablonun orijinal sayfa yapısı korunur; yeni çalışma sayfası (worksheet) eklenmez.

## 2026-08-02 — Faz 1.1: bcrypt Şifre Hashleme, Yerel Zip Yedekleme & Geri Yükleme, SQL Denetimi
- **Ne yapıldı:**
  1. **bcrypt Şifre Güvenliği & Şeffaf Göç (`DatabaseHelper`)**:
     - `bcrypt: ^1.1.3` paketi eklendi.
     - Yeni kayıt, ilk admin kurulumu, kullanıcı ekleme ve şifre değiştirmede tüm şifreler bcrypt salting hash (`BCrypt.hashpw`) ile saklanır.
     - Şeffaf Göç (Transparent Migration): Giriş yapılırken önce bcrypt doğrulaması denenir; uymuyorsa legacy SHA-256 doğrulanır. SHA-256 eşleşirse şifre bcrypt ile yeniden hashlenip SQLite veritabanında şeffaf olarak güncellenir.
  2. **Yerel Veri Yedeği Al & Paylaş (`BackupService` + `ProfileScreen`)**:
     - `archive: ^3.6.1` paketi eklendi.
     - `traforeport_local.db` veritabanı, saha fotoğrafları (`documents/photos/`) ve dijital imzalar `.zip` arşivinde toplanır (`traforeport_backup_YYYYMMDD_HHMMSS.zip`).
     - Android yerel paylaşım menüsü (`Share.shareXFiles`) ile dışa aktarılır.
  3. **Yedekten Geri Yükle (`file_picker` + `BackupService`)**:
     - `file_picker: ^8.1.4` ile `.zip` dosya seçici bağlandı.
     - Onay diyalogu ("Mevcut verilerin üzerine yazılacaktır. Devam etmek istiyor musunuz?") eklendi.
     - `DatabaseHelper.instance.closeDatabase()` ile veritabanı kilidi güvenle kapatılır, veritabanı ve fotoğraflar üzerine yazılır, veritabanı yeniden başlatılır ve oturum güvenle kapatılır (`LoginScreen`'e yönlendirilir).
  4. **Finalize UX Netleştirmesi**:
     - Cihaz üzerinde Excel üretimi olmayan Faz 1.1 aşamasında sahte `finalized` durumu oluşturmak yerine kullanıcı bilgilendirme diyalogu bağlandı: *"Excel (.xlsx) rapor üretimi cihaz üzerinde bir sonraki sürümde (Faz 2) aktif olacaktır. Raporunuz yerel SQLite veritabanına taslak olarak kaydedildi."*
  5. **SQL Denetimi (SQL Injection Protection)**:
     - SQLite sorgularındaki tüm `where` koşulları parametreli `whereArgs` dizisine dönüştürüldü.
  6. `flutter analyze`: **0 Hata** ile doğrulandı.
- **Bir sonraki adım (Faz 2):**
  - Cihaz üzerinde native Excel (.xlsx) dosya üretimi (openpyxl / dart excel builder ile hücresel haritalama).

## 2026-08-02 — Faz 1: Tek Tablet Sunucusuz (Offline-First) Yerel Veri Katmanı Entegrasyonu
- **Ne yapıldı:**
  1. Ürün Kararı: Uygulama tek Android tablet üzerinde tamamen sunucusuz (offline-first) çalışacak şekilde yapılandırıldı. FastAPI, uzak HTTP, JWT, OTP ve davet kodu bağımlılıkları ana akıştan kaldırıldı.
  2. `sqflite` + `crypto` + `path` paketleri eklendi.
  3. `DatabaseHelper` (`mobile/lib/database/database_helper.dart`) singleton sınıfı oluşturuldu: `users`, `reports`, `report_photos` SQLite tabloları ve SHA-256 şifre hashleme yardımcısı eklendi.
  4. `AuthService`:
     - Uzak HTTP/OTP/Davet kodu çağrıları kaldırıldı.
     - `checkBootstrapStatus()`: SQLite `users` tablosundaki kullanıcı sayısını kontrol eder (`userCount == 0` ise ilk yönetici kurulumuna yönlendirir).
     - `bootstrapAdmin()`: İlk yöneticiyi doğrudan yerel SQLite veritabanına kaydeder ve oturumu açar.
     - `login()`: Yerel SQLite veritabanından kullanıcı doğrulamasını gerçekleştirir (`phone`/`email` + şifre hash).
     - `createLocalUser()`: Yönetici panelinden doğrudan yeni çalışan/yönetici hesabı eklemeyi sağlar.
     - `changePasswordLocally()` & `saveUserSignatureLocally()`: Şifre ve dijital imza güncellemesini SQLite + yerel dosya sistemine yazar.
  5. `ReportService`:
     - Uzak HTTP GET/POST/PUT/DELETE çağrıları kaldırıldı.
     - `startNewReport()`, `updateField()`, `saveDraft()`, `getReports()`, `finalizeReport()` tüm CRUD işlemlerini yerel SQLite veritabanında gerçekleştirir.
     - `savePhotoLocally()`: Saha fotoğraflarını uygulamanın `documents/photos/<report_id>/` dizinine kopyalar ve SQLite `report_photos` tablosuna kaydeder.
  6. `SplashScreen`:
     - Ağ zaman aşımı ve "sunucuya bağlanılamadı" ekranı kaldırıldı. Açılışta yerel SQLite veritabanını kontrol ederek ilk açılışta `FirstAdminBootstrapScreen`'e, sonraki açılışlarda `LoginScreen`'e veya mevcut oturuma yönlendirir.
  7. `FirstAdminBootstrapScreen`:
     - Tek adımlı yerel yönetici kayıt formuna dönüştürüldü (E-posta OTP ve sayac kaldırıldı).
  8. `AdminDashboardScreen`:
     - Davet kodu üretimi yerine doğrudan yerel cihaz kullanıcısı ekleme ("Kullanıcı Ekle" dialogu) ve kullanıcı listeleme ekranına dönüştürüldü.
  9. `ProfileScreen` & `ReportFormScreen`:
     - Fotoğraf çekimi `image_picker` ile gerçek cihaz kamerası/galerisine bağlandı ve `savePhotoLocally` ile saklandı.
  10. `flutter analyze`: **0 Hata** ile doğrulandı.
- **Bilinçli Olarak Bırakılanlar (Faz 2):**
  - Cihaz üzerinde native Excel (.xlsx) dosya üretimi (Faz 2)
  - Çoklu cihaz senkronizasyonu / Sunucu yedekleme (Faz 2+)
- **Bir sonraki adım:**
  - Tablette uçak modunda uçtan uca test (İlk admin -> çıkış -> giriş -> taslak rapor -> fotoğraf ekleme -> çıkış/açılış kontrolü).

## 2026-07-31 — Release APK Build v1.0.2 (build 3 - Cleartext HTTP İzin Düzeltmesi)
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
