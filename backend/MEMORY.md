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

