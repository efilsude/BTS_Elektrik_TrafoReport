# Karar Günlüğü (Append-Only)

Kurallar:
- Sadece ekle. Eski bir kaydı asla silme veya değiştirme (yanlışsa altına düzeltme notu ekle).
- Format: tarih, kim (backend/mobile), ne değişti/karar verildi, neden.
- "Kırmızı bölge" dosyalarını (API_CONTRACT, DB_SCHEMA, EXCEL_CELL_MAPPING, kök CLAUDE.md)
  etkileyen her değişiklik burada kayıt altına alınır.
- Açık sorular da buraya `AÇIK SORU:` önekiyle düşülür.

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

## 2026-07-31 — [backend] EMAIL_ENABLED Güvenli Varsayılanlar ve Dev/Test debug_code Desteği Eklendi
- Ne: `EMAIL_ENABLED` varsayılan değeri `false` olarak ayarlandı. `POST /auth/request-verification` yanıtına opsiyonel `debug_code` alanı eklendi (`EMAIL_ENABLED=false` iken 6 haneli OTP kodu döner, `EMAIL_ENABLED=true` iken `null` döner). SMTP yapılandırması eksik iken `EMAIL_ENABLED=true` seçilirse net `EMAIL_SEND_FAILED` hatası verilmesi sağlandı.
- Neden: SMTP ayarı olmayan yerel/LAN/E2E test ortamlarında uygulamanın çökmesini önlemek, çevrimdışı ve test cihazlarında e-posta erişimi olmadan OTP kodunu istemciye sunmak.
- Etiket: @mobile (DİKKAT mobile: `POST /auth/request-verification` yanıtında `EMAIL_ENABLED=false` ise `debug_code` alanı içinde 6 haneli OTP kodu okunabilir).










