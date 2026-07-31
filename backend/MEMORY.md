# Backend — Oturum Günlüğü (Hafıza)

Her oturum sonunda buraya kısa bir not ekle (en yeni en üstte). Amaç: yeni bir oturum
başladığında ya da mobile ajanı sana bağlı bir konuyu kontrol ederken bağlamı kaybetmemek.

Format:
```
## YYYY-AA-GG — kısa başlık
- Ne yapıldı:
- Alınan kararlar:
- Bulunan sorun/gotcha:
- Bir sonraki oturumda kaldığı yer:
```

## 2026-07-31 — E-posta Doğrulama Kodu (OTP) & Admin Bildirimleri Tamamlandı
- **Ne yapıldı:**
  1. `app/core/config.py` içine SMTP (SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD, SMTP_FROM, SMTP_USE_TLS), EMAIL_ENABLED, ADMIN_NOTIFY_EMAILS ve VERIFICATION_CODE_TTL_MINUTES env ayarları eklendi. `backend/.env.example` oluşturuldu.
  2. `app/services/email_service.py` modülü yazıldı (`send_email` ile console sink fallback, `notify_admins`, `notify_admins_for_new_user`, `notify_admins_for_finalize`).
  3. `email_verification_codes` tablosu (`app/models/email_verification.py`) tanımlandı ve `docs/DB_SCHEMA.md` güncellendi.
  4. `POST /auth/request-verification` endpoint'i eklendi (davet kodu kontrolü + 6 haneli OTP kodu üretimi + 60s rate-limit + Türkçe HTML e-posta).
  5. `POST /auth/register` endpoint'i güncellendi (zorunlu `email` + zorunlu `verification_code` doğrulama).
  6. Yeni kullanıcı kaydında ve rapor kesinleştirmede (`POST /reports/{id}/finalize`) FastAPI `BackgroundTasks` üzerinden Admin e-posta bildirimleri entegre edildi.
  7. `docs/API_CONTRACT.md` ve `docs/DECISIONS.md` dokümanlarına `@mobile` etiketli notlar düşüldü.
  8. `tests/test_email_verification.py` entegrasyon testleri dahil tüm backend testleri (`test_phase1`, `test_phase2`, `test_phase3`, `test_phase4`, `test_e2e_full_workflow`) çalıştırıldı: **20/20 test %100 başarıyla geçti**.
- **Alınan kararlar:**
  - Mobil istemcinin kayıt ekranında e-posta doğrulama kodunun `POST /auth/request-verification` ile alınması zorunlu kılındı.
- **Bulunan sorun/gotcha:**
  - FastAPI background tasks signature uyuşmazlığını önlemek için `BackgroundTasks` parametre varsayılanı `BackgroundTasks()` olarak ayarlandı.
- **Bir sonraki oturumda kaldığı yer:**
  - Mobil tarafın güncellenen 2 adımlı kayıt sözleşmesini (`request-verification` + `register`) entegre etmesi bekleniyor.

---

## 2026-07-30 — Faz 5 Test, Güvenlik ve Sürüm Tamamlandı (Backend Tamamlandı)
- **Ne yapıldı:**
  1. Uçtan uca tüm senaryoyu test eden [tests/test_e2e_full_workflow.py](file:///C:/Users/User/OneDrive/Desktop/BTS_Elektrik/backend/tests/test_e2e_full_workflow.py) geliştirildi: Admin girişi -> davet kodu oluşturma -> çalışan kaydı -> imza ve fotoğraf yükleme -> taslak oluşturma -> Excel raporu kesinleştirme & indirme -> Admin istatistik kontrolü -> kullanıcı devre dışı bırakma ve geçmiş raporlarda oluşturan adının korunduğunun doğrulanması.
  2. `docs/API_CONTRACT.md` v1.0 FINAL sürümüne getirildi. Tüm "açık nokta"lar kapatıldı.
  3. Güvenlik ve performans son kontrolleri yapıldı (JWT doğrulama, bcrypt 72-byte sınırlama, CORS desteği, soft-delete ve denormalize creator_display_name).
  4. Tüm test takımı (`test_phase1`, `test_phase2`, `test_phase3`, `test_phase4`, `test_e2e_full_workflow`) çalıştırıldı: **14/14 test %100 başarıyla geçti**.
- **Alınan kararlar:**
  - Tüm backend fazları (Faz 1 - Faz 5) eksiksiz tamamlandı ve canlıya alıma hazır hale getirildi.
- **Bulunan sorun/gotcha:** —
- **Bir sonraki oturumda kaldığı yer:**
  - Backend tarafının tüm fazları başarıyla teslim edildi. Mobil ajanın entegrasyonu tamamlaması bekleniyor.

---

## 2026-07-30 — Faz 4 Admin Yönetimi, İstatistikler ve Hata Yönetimi Tamamlandı

- **Ne yapıldı:**
  1. `docs/API_CONTRACT.md`, `docs/DB_SCHEMA.md` ve `docs/DECISIONS.md` güncellenerek `/templates`, `POST /admin/templates/admin/upload` ve `GET /admin/stats` endpoint'leri ile `Template` DB tablosu tanımlandı.
  2. `Template` SQLAlchemy ORM modeli ([app/models/template.py](file:///C:/Users/User/OneDrive/Desktop/BTS_Elektrik/backend/app/models/template.py)) ve Pydantic şemaları yazıldı.
  3. `GET /templates` (varsayılan kanonik şablonları veritabanında otomatik tohumlayan sistem) ve `POST /api/v1/templates/admin/upload` (Admin yeni şablon yükleme) eklendi.
  4. `GET /admin/stats` endpoint'i yazılarak toplam raporlar, taslaklar, kesinleşmiş raporlar, tipe göre dağılım, oluşturan teknisyene göre dağılım, aktif kullanıcılar ve aktif davet kodları istatistikleri sunuldu.
  5. PRD §19 hata yönetimi tablosundaki tüm senaryolar (400, 401, 403, 404, 422, 500) özelleştirilmiş standart JSON hata formatında bağlandı.
  6. `tests/test_phase4.py` entegrasyon testleri yazıldı ve tüm 13 test %100 başarıyla geçti.
- **Alınan kararlar:**
  - Yetkisiz erişim denemelerinde doğrudan 403 Forbidden ve standart hata nesnesi döndürüldü.
- **Bulunan sorun/gotcha:**
  - `templates` DB tablosu boş olduğunda kanonik şablonlar varsayılan versiyon "1.0" ile otomatik tohumlandı.
- **Bir sonraki oturumda kaldığı yer:**
  - Faz 5 — Test ve Sürüm: Uçtan uca API testlerinin tamamlanması, `docs/API_CONTRACT.md` son hali ve canlıya alım/performans kontrolü.

---

## 2026-07-30 — Faz 3 Excel Motoru ve İndirme Tamamlandı

- **Ne yapıldı:**
  1. `docs/API_CONTRACT.md`, `docs/EXCEL_CELL_MAPPING.md` ve `docs/DECISIONS.md` güncellenerek `/reports/{id}/finalize` ve `/reports/{id}/download` endpoint'leri ile 3 şablon ailesi (`HERMETIK`, `KURU_TIP`, `GT`) hücre adresleri kaydedildi.
  2. `openpyxl` tabanlı Excel üretim motoru ([app/services/excel_engine.py](file:///C:/Users/User/OneDrive/Desktop/BTS_Elektrik/backend/app/services/excel_engine.py)) geliştirildi. Stil, hücresel birleşme ve orijinal formüller dokunulmadan korundu.
  3. Tarih değerlerinin Excel seri numarasına (`epoch 1899-12-30`) ve ölçüm değerlerinin sayısal tipe dönüştürülmesi sağlandı.
  4. El yazısı imzasının ve saha fotoğraflarının yeni sayfa açılmaksızın kapak alanındaki uygun hücrelere yerleştirilmesi sağlandı.
  5. Dosya adlandırma standardı `{Müşteri} - {Trafo Etiketi} - {GG.AA.YYYY}.xlsx` uygulandı.
  6. `POST /reports/{id}/finalize` ve `GET /reports/{id}/download` endpoint'leri bağlandı.
  7. `tests/test_phase3.py` birim/entegrasyon testleri yazıldı ve 11/11 test %100 başarıyla geçti.
- **Alınan kararlar:**
  - Orijinal şablonlar asla üzerine yazılmaz, üretilen raporlar `uploads/reports/` dizinine temizlenmiş dosya adıyla kaydedilir.
- **Bulunan sorun/gotcha:**
  - `openpyxl` tarih biçimli hücreleri okurken otomatik `datetime` nesnesine çevirdiği için test assertions nesne tipi veya sayısal seri eşliğiyle doğrulandı.
- **Bir sonraki oturumda kaldığı yer:**
  - Faz 4 — Admin ve Cilalama: Şablon yükleme (`POST /admin/templates`), istatistik endpoint'leri ve PRD §19 hata yönetimi senaryoları.

---

## 2026-07-30 — Faz 2 Rapor Çekirdeği ve Rapor Havuzu Tamamlandı

- **Ne yapıldı:**
  1. `docs/API_CONTRACT.md` ve `docs/DB_SCHEMA.md` güncellenerek Faz 2 Rapor Havuzu, Taslaklar ve Fotoğraf Yükleme endpoint'lerinin JSON şemaları ve tablo modelleri netleştirildi; `docs/DECISIONS.md`'e kayıt düşüldü.
  2. `Report` ve `Photo` SQLAlchemy modelleri ([app/models/report.py](file:///C:/Users/User/OneDrive/Desktop/BTS_Elektrik/backend/app/models/report.py), [app/models/photo.py](file:///C:/Users/User/OneDrive/Desktop/BTS_Elektrik/backend/app/models/photo.py)) ve Pydantic şemaları yazıldı.
  3. `POST /reports`, `GET /reports` (Rapor Havuzu filtreleme/arama/sayfalama), `GET /drafts`, `GET /reports/{id}`, `PUT /reports/{id}`, `DELETE /reports/{id}` ve `POST /reports/{id}/photos` endpoint'leri kodlandı.
  4. Kullanıcı devre dışı bırakılsa dahi geçmiş raporlardaki `creator_display_name` bilgisinin ve ilişkilerin bozulmadan kaldığı doğrulandı.
  5. `tests/test_phase2.py` entegrasyon testleri yazıldı ve 8/8 test %100 başarıyla geçti.
- **Alınan kararlar:**
  - `data_json` alanı veritabanında JSON string/TEXT olarak saklanıp getter/setter property ile Pydantic ve mobile için tam dict nesnesine dönüştürüldü.
  - Taslak silme yetkisi oluşturan teknisyene ve Admin'e verilirken, kesinleşmiş rapor düzenleme yetkisi Admin'e tanımlandı.
- **Bulunan sorun/gotcha:**
  - Git histoirik birleşmesinde `main` ile bağımsız geçmiş birleşimi (`--allow-unrelated-histories`) yapıldı.
- **Bir sonraki oturumda kaldığı yer:**
  - Faz 3 — Excel Motoru: 3 şablon (`HERMETIK`, `KURU_TIP`, `GT`) için hücre eşlemesinin çıkarılıp `docs/EXCEL_CELL_MAPPING.md`'nin doldurulması, openpyxl motoru ile `.xlsx` üretimi, tarih/seri dönüştürme ve fotoğraf yerleştirme.

---

## 2026-07-30 — Faz 1 Temel Sistem ve Kimlik Doğrulama Tamamlandı

- **Ne yapıldı:**
  1. `docs/API_CONTRACT.md` ve `docs/DB_SCHEMA.md` güncellenerek Faz 1 request/response JSON şemaları ile DB yapıları netleştirildi; `docs/DECISIONS.md`'e not düşüldü.
  2. FastAPI proje iskeleti (`backend/app`) modüler katmanlı mimaride oluşturuldu.
  3. SQLAlchemy ORM modelleri (`User`, `RegistrationCode`) tanımlandı.
  4. JWT authentication (access + refresh token), bcrypt şifre hashleme, custom API exception handler geliştirildi.
  5. Auth endpoint'leri (`POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`) ve profil endpoint'leri (`GET /users/me`, `PUT /users/me/password`, `PUT /users/me/signature`) yazıldı.
  6. Davet kodu sistemi (15 dk TTL, tek kullanımlık) ve Admin endpoint'leri (`POST/GET /admin/codes`, `GET /admin/users`, `DELETE /admin/users/{id}`) tamamlandı. Soft delete yapısı kuruldu.
  7. `create_initial_admin.py` tohumlama betiği yazıldı ve 6 birim/entegrasyon testi (`tests/test_phase1.py`) %100 başarıyla geçti.
- **Alınan kararlar:**
  - `passlib` kütüphanesinin yeni Python / bcrypt sürümlerindeki bilinen uyuşmazlığı nedeniyle doğrudan `bcrypt` kütüphanesi kullanıldı.
  - Pydantic v2 uyumluluğu için `ConfigDict` standardına geçildi.
  - Kullanıcı silme/devre dışı bırakma işlemi soft-delete (`is_active=False`) olarak uygulandı. Bu sayede geçmiş raporlardaki `creator_display_name` ve FK tutarlılığı korundu.
- **Bulunan sorun/gotcha:**
  - Pydantic `EmailStr` doğrulama tipi için `email-validator` paketi eklendi.
- **Bir sonraki oturumda kaldığı yer:**
  - Faz 2 — Rapor Çekirdeği: `reports` ve `photos` tablolarının oluşturulması, `data_json` şemasının ve Rapor Havuzu endpoint'lerinin (`POST/GET/PUT/DELETE /reports`, `GET /drafts`) kodlanması.

