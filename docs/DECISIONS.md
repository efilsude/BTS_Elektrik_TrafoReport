# Karar Günlüğü (Append-Only)

Kurallar:
- Sadece ekle. Eski bir kaydı asla silme veya değiştirme (yanlışsa altına düzeltme notu ekle).
- Format: tarih, kim (backend/mobile), ne değişti/karar verildi, neden.
- "Kırmızı bölge" dosyalarını (API_CONTRACT, DB_SCHEMA, EXCEL_CELL_MAPPING, kök CLAUDE.md)
  etkileyen her değişiklik burada kayıt altına alınır.
- Açık sorular da buraya `AÇIK SORU:` önekiyle düşülür.

---

## 2026-08-02 — [mobile] Faz 2: Cihaz Üzerinde Native Excel (.xlsx) Üretimi & Hücresel Haritalama
- Ne: Cihaz üzerinde internet/sunucu bağlantısı olmaksızın orijinal şablon `.xlsx` dosyalarından hücresel haritalama (`CELL_MAPPING`) ile Excel rapor üretimi sağlandı.
- Neden: Saha şartlarında teknisyenin hazırladığı raporların PRD §12 ve Kabul #1 standartlarına %100 uygun biçimde orijinal Excel şablonuna işlenebilmesi için.
- Haritalama Kaynağı: `backend/app/services/excel_engine.py` üzerindeki `CELL_MAPPING` mantığı Dart diline aktarıldı (`lib/excel/cell_mapping.dart`).
- Şablon Asset'leri: `assets/templates/` altına kopyalandı (`hermetik.xlsx`, `kuru_tip.xlsx`, `gt.xlsx`).
- Çalışma Mantığı:
  1. `excel: ^4.0.6` paketi ile asset şablon baytları okunarak bellek üzerinde orijinal stiller, birleşmiş hücreler ve formüller korunur.
  2. Tarih alanları Excel seri numarasına (epoch: 1899-12-30) dönüştürülerek yazılır.
  3. Sayısal ölçümler sayı formatında (int/double) hücrelere işlenir.
  4. Çıktı dosyası `{Müşteri} - {Trafo Etiketi} - {GG.AA.YYYY}.xlsx` biçiminde `documents/reports/` altına kaydedilir.
  5. Rapor kesinleştirildiğinde SQLite veritabanındaki durum `status = 'finalized'`, `finalized_at` ve `excel_path` olarak güncellenir.

---

## 2026-08-02 — [mobile] Ürün Kararı: Tek Tablet Sunucusuz (Offline-First) Faz 1
- Ne: Mobil uygulama tek Android tablet üzerinde tamamen sunucusuz (offline-first) çalışacak şekilde yapılandırıldı. FastAPI, uzak HTTP, JWT, OTP ve davet kodu bağımlılıkları Faz 1 kapsamında mobil taraftan tamamen kaldırıldı veya yerel SQLite veritabanına devredildi.
- Neden: Saha şartlarında internet/sunucu bağlantısı olmaksızın şirkete ait tek tablette tam bağımsız raporlama yapmak için.
- Detaylar:
  1. Yerel Veri Katmanı: `sqflite` veritabanı (`traforeport_local.db`) kullanılarak `users`, `reports` ve `report_photos` tabloları ile SHA-256 şifre hashleme katmanı oluşturuldu.
  2. Yerel Auth & Bootstrap: Cihaz açılışında veritabanı kullanıcı sayısı kontrol edilir. İlk açılışta ilk yönetici kaydı (`role=admin`) doğrudan SQLite'a yazılır. Sonraki girişler yerel veritabanı üzerinden doğrulanır.
  3. Cihaz Üzerinde Fotoğraf Depolama: Saha fotoğrafları uygulamanın yerel belgeler klasörüne (`documents/photos/<report_id>/`) kaydedilir.
  4. Faz 2 Planı: Cihaz üzerinde native Excel (.xlsx) dosya üretimi ve hücre şablonu eşleştirmesi Faz 2 kapsamında geliştirilecektir.

---

## 2026-07-28 — [ikisi] Proje başlangıcı
- Ne: Repo iskeleti, kurallar (CLAUDE.md), görev listeleri ve doküman şablonları oluşturuldu.
- Neden: PRD v1.1'e göre backend/mobile ayrımıyla paralel geliştirme başlatmak için.
- Not: `docs/API_CONTRACT.md`, `docs/DB_SCHEMA.md`, `docs/EXCEL_CELL_MAPPING.md` şu an
  PRD'den türetilmiş taslak (v0) durumda; backend geliştirmesi ilerledikçe netleşecek.

## 2026-07-30 — [mobile] Mobil Faz 1, 2 ve 3 Kararları
- Ne: Mobil tarafta kimlik doğrulama, dinamik form sihirbazı, otomatik kaydetme, imza çizim paneli ve üretim sonrası ekranları geliştirildi.
- Alınan Kararlar:
  1. **Çevrimdışı/Mock Modu**: Backend servisleri hazır olmadığından, uygulamanın sunucu hatası durumunda otomatik olarak (veya manuel geçişle) simülasyon moduna geçmesi ve secure storage üzerinde mock verilerle çalışması sağlandı.
  2. **Saf Flutter İmza Pedi**: Dış kütüphanelerin tablet derleme uyumsuzluklarını önlemek için imza çizim alanı Gesture-detector ve CustomPainter ile tamamen yerel kodlandı.
  3. **Durum Koruma**: Otomatik taslak kaydetme debounced (2 sn) olarak secure storage üzerine JSON formatında aktarılarak tablet kapansa bile %100 durum koruma sağlandı.
  4. **Intent Simülasyonu**: Excel üretimi sonrası paylaşma, yazdırma ve açma işlemleri için Android native intent'leri snackbar/toast bildirimleri ile simüle edildi.

## 2026-07-30 — [backend] Faz 1 API sözleşmesi ve DB şeması netleştirildi
- Ne: `docs/API_CONTRACT.md` ve `docs/DB_SCHEMA.md` güncellenerek Faz 1 endpoint'lerinin (auth, admin, davet kodları, kullanıcı CRUD) request/response JSON şemaları ve DB sütun tipleri detaylandırıldı.
- Neden: Mobil ajanın auth ve admin ekranlarını tam eşleşen kontrat ile geliştirebilmesi için.
- Etiket: @mobile (DİKKAT mobile: `/auth/login`, `/auth/register`, `/auth/refresh`, `/admin/codes`, `/admin/users` kontratları v1.0 olarak kesinleşti).

## 2026-07-30 — [backend] Faz 2 API sözleşmesi ve DB şeması netleştirildi
- Ne: `docs/API_CONTRACT.md` ve `docs/DB_SCHEMA.md` güncellenerek Faz 2 Rapor Havuzu, Taslaklar ve Fotoğraf Yükleme endpoint'lerinin request/response JSON şemaları ile `reports` ve `photos` tablo şemaları tanımlandı.
- Neden: Mobil ajanın dinamik form motoru, taslak kaydetme ve rapor havuzu arama/filtreleme ekranlarını aynı kontrat ile entegre edebilmesi için.
- Etiket: @mobile (DİKKAT mobile: `/reports`, `/drafts`, `/reports/{id}`, `/reports/{id}/photos` kontratları kesinleşti).

## 2026-07-30 — [backend] Faz 3 Excel üretim motoru ve indirme kontratı tamamlandı
- Ne: `docs/API_CONTRACT.md` ve `docs/EXCEL_CELL_MAPPING.md` güncellenerek `/reports/{id}/finalize` ve `/reports/{id}/download` endpoint'leri ve 3 şablon ailesinin hücre adresleri kesinleştirildi.
- Neden: Mobil istemcinin rapor kesinleştirme sonrası Excel indirme/açma/paylaşma akışını bağlayabilmesi için.
- Etiket: @mobile (DİKKAT mobile: `POST /reports/{id}/finalize` ve `GET /reports/{id}/download` v1.0 olarak eklendi).

## 2026-07-30 — [backend] Faz 4 Şablon yönetimi, istatistikler ve hata yonetimi tamamlandı
- Ne: `docs/API_CONTRACT.md` ve `docs/DB_SCHEMA.md` güncellenerek `/templates`, `POST /admin/templates` ve `GET /admin/stats` endpoint'leri ile `templates` tablo şeması tanımlandı.
- Neden: Mobil istemcinin Admin gösterge paneli istatistiklerini görüntülemesi ve şablon yönetimi gerçekleştirebilmesi için.
- Etiket: @mobile (DİKKAT mobile: `/templates`, `/admin/templates` ve `/admin/stats` v1.0 olarak eklendi).

## 2026-07-31 — [backend] E-posta Doğrulama Kodu (OTP) ve Admin Bildirim Altyapısı Eklendi
- Ne: `docs/API_CONTRACT.md` ve `docs/DB_SCHEMA.md` güncellenerek `POST /auth/request-verification` eklendi, `POST /auth/register` body'sine `verification_code` ve zorunlu `email` eklendi, `email_verification_codes` DB tablosu tanımlandı. Yeni kullanıcı kaydı ve rapor kesinleştirme (`POST /reports/{id}/finalize`) adımlarına Admin SMTP e-posta bildirimleri entegre edildi.
- Neden: Hesap güvenliğini artırmak, sahte e-postalarla kaydı engellemek ve sistem yöneticilerini (admin) yeni üyelik ve tamamlanan saha raporlarından anında haberdar etmek için.

## 2026-07-31 — [backend] İlk Admin Bootstrap ve Davet Kodu Rol Yapılandırması Eklendi
- Ne: Sistemde hiç kullanıcı yokken ilk yöneticinin kaydolması için `GET /auth/bootstrap-status`, `POST /auth/request-verification-bootstrap` ve `POST /auth/bootstrap` uç noktaları eklendi. Davet kodlarına `role` (`"employee"` veya `"admin"`) alanı eklendi (`POST/GET /admin/codes`). Kayıt esnasında kullanıcının rolü davet kodunun rolünden atanır.
- Neden: Prod ortamında veritabanı seed script'ine bağımlı sahte admin kullanımını kaldırmak, gerçek yönetici bilgileriyle ilk kurulumu (bootstrap) sağlamak ve yeni admin/teknisyen davetlerini rol yetkili davet kodları üzerinden yönetmek.
- Etiket: @mobile (DİKKAT mobile: `GET /auth/bootstrap-status` true ise ilk admin kayıt ekranına yönlendirin. Normal kayıtta `Yönetici olarak kayıt ol` seçeneğini kaldırın; rol davet kodundan gelir. `POST /admin/codes` isteğine `role: "admin"|"employee"` ekleyin).











