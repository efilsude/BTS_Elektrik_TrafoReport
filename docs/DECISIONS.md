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




