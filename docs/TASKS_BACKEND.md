# Backend Görev Listesi

> Bu dosyayı SADECE backend ajanı/geliştiricisi işaretler ve düzenler. Mobile ajanı
> ilerlemeyi görmek için okuyabilir. Her oturum sonunda ilgili kutucukları güncelle
> ve `backend/MEMORY.md`'e kısa not düş.

## Faz 1 — Temel (PRD §22)
- [x] FastAPI proje iskeleti
- [x] PostgreSQL bağlantısı + temel modeller (`users`, `registration_codes`)
- [x] JWT auth (access + refresh), bcrypt şifre hash
- [x] `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`
- [x] Davet kodu sistemi (15 dk TTL, tek kullanımlık) + `POST/GET /admin/codes`
- [x] E-posta doğrulama kodu (OTP 10 dk TTL, 60s rate-limit) + `POST /auth/request-verification`
- [x] EMAIL_ENABLED güvenli varsayılanı (`false`) + dev/test `debug_code` desteği ve SMTP hata yönetimi
- [x] İlk Admin Bootstrap (`GET /auth/bootstrap-status`, `POST /auth/request-verification-bootstrap`, `POST /auth/bootstrap`) ve rol yetkili davet kodları (`RegistrationCode.role`)
- [x] Kullanıcı CRUD (`GET /admin/users`, `DELETE /admin/users/{id}` — sahiplik ve son aktif admin koruması)





## Faz 2 — Rapor Çekirdeği (PRD §22)
- [x] `reports`, `photos` tabloları + `data_json` modeli
- [x] `POST/GET/PUT/DELETE /reports`, `GET /drafts`
- [x] Rapor Havuzu: filtre/arama/sayfalama (PRD §9)
- [x] Kullanıcı silindiğinde `creator_display_name` denormalizasyonu (PRD §15/§24.13)


## Faz 3 — Excel Motoru (EN KRİTİK, PRD §12)
- [x] Üç şablonun (`HERMETIK`, `KURU TİP`, `GT`) hücre eşlemesini çıkar →
      `docs/EXCEL_CELL_MAPPING.md`'i doldur
- [x] openpyxl üretim motoru: stil/birleşim/formül koruma
- [x] Tarih → Excel seri dönüşümü (epoch 1899-12-30)
- [x] Fotoğraf ekleme (yer tutucu varsa/yoksa mantığı, PRD §10)
- [x] Dosya adlandırma: `{Müşteri} - {Trafo Etiketi} - {GG.AA.YYYY}.xlsx`
- [x] `POST /reports/{id}/finalize`, `GET /reports/{id}/download`
- [x] Doğrulama: üretilen dosya orijinal şablonla düzen bakımından birebir aynı
      (Kabul Kriteri #1, PRD §24)


## Faz 4 — Admin ve Cilalama
- [x] Şablon yükleme (`POST /admin/templates`)
- [x] İstatistik endpoint'leri (`GET /admin/stats`)
- [x] Hata yönetimi senaryoları (PRD §19 tablosu — tümü)


## Faz 5 — Test ve Sürüm
- [x] Uçtan uca API testleri (`tests/test_e2e_full_workflow.py`)
- [x] `docs/API_CONTRACT.md` son hali (tüm "açık nokta"lar kapatıldı, v1.0 Final)
- [x] Performans/güvenlik son kontrol (PRD §15)


## Sürekli (her fazda geçerli)
- [x] Kontrat değişikliklerini `docs/API_CONTRACT.md` / `docs/DB_SCHEMA.md` /
      `docs/EXCEL_CELL_MAPPING.md`'e işle + `docs/DECISIONS.md`'e not düş
- [x] `backend/MEMORY.md`'i güncel tut

