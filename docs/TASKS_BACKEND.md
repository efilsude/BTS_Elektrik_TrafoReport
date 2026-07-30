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
- [x] Kullanıcı CRUD (`GET /admin/users`, `DELETE /admin/users/{id}` — sahiplik korunarak)


## Faz 2 — Rapor Çekirdeği (PRD §22)
- [x] `reports`, `photos` tabloları + `data_json` modeli
- [x] `POST/GET/PUT/DELETE /reports`, `GET /drafts`
- [x] Rapor Havuzu: filtre/arama/sayfalama (PRD §9)
- [x] Kullanıcı silindiğinde `creator_display_name` denormalizasyonu (PRD §15/§24.13)


## Faz 3 — Excel Motoru (EN KRİTİK, PRD §12)
- [ ] Üç şablonun (`HERMETIK`, `KURU TİP`, `GT`) hücre eşlemesini çıkar →
      `docs/EXCEL_CELL_MAPPING.md`'i doldur
- [ ] openpyxl üretim motoru: stil/birleşim/formül koruma
- [ ] Tarih → Excel seri dönüşümü (epoch 1899-12-30)
- [ ] Fotoğraf ekleme (yer tutucu varsa/yoksa mantığı, PRD §10)
- [ ] Dosya adlandırma: `{Müşteri} - {Trafo Etiketi} - {GG.AA.YYYY}.xlsx`
- [ ] `POST /reports/{id}/finalize`, `GET /reports/{id}/download`
- [ ] Doğrulama: üretilen dosya orijinal şablonla düzen bakımından birebir aynı
      (Kabul Kriteri #1, PRD §24)

## Faz 4 — Admin ve Cilalama
- [ ] Şablon yükleme (`POST /admin/templates`)
- [ ] İstatistik endpoint'leri
- [ ] Hata yönetimi senaryoları (PRD §19 tablosu — tümü)

## Faz 5 — Test ve Sürüm
- [ ] Uçtan uca API testleri
- [ ] `docs/API_CONTRACT.md` son hali (tüm "açık nokta"lar kapatıldı)
- [ ] Performans/güvenlik son kontrol (PRD §15)

## Sürekli (her fazda geçerli)
- [ ] Kontrat değişikliklerini `docs/API_CONTRACT.md` / `docs/DB_SCHEMA.md` /
      `docs/EXCEL_CELL_MAPPING.md`'e işle + `docs/DECISIONS.md`'e not düş
- [ ] `backend/MEMORY.md`'i güncel tut
