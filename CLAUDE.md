# TrafoReport — Proje Ajan Kuralları (KÖK)

Bu dosya, bu repoda çalışan HER AI kod ajanı (agy) tarafından oturum başında otomatik
okunur. Hem backend hem mobile ajanı için geçerli, istisnasız temel kurallardır.
Kendi klasörüne özel ek kurallar için `backend/CLAUDE.md` veya `mobile/CLAUDE.md`'e bak.

## Proje nedir

TrafoReport, saha teknisyenlerinin trafo bakım/test verilerini tablette girip, mevcut
Excel şablonlarıyla birebir aynı düzende imzaya hazır .xlsx rapor üreten kurumsal dahili
bir sistemdir (Flutter mobil istemci + FastAPI backend + Excel üretim motoru).

Tam gereksinimler: `docs/PRD.md` — bu proje için **tek doğruluk kaynağıdır**. PRD ile
çelişen hiçbir varsayımda bulunma. Emin değilsen `docs/DECISIONS.md`'e "AÇIK SORU:" olarak
not düş, en makul yorumla ilerle, oturum özetinde insan geliştiriciye açıkça belirt.

## Repo yapısı ve sahiplik

```
/
├── docs/                       ORTAK ALAN — okuma herkese açık, yazma kısıtlı
│   ├── PRD.md                  Salt okunur referans. Hiçbir ajan değiştirmez.
│   ├── API_CONTRACT.md         SADECE backend ajanı yazar. mobile salt okur.
│   ├── DB_SCHEMA.md            SADECE backend ajanı yazar.
│   ├── EXCEL_CELL_MAPPING.md   SADECE backend ajanı yazar.
│   ├── DECISIONS.md            HERKES ekleyebilir (append-only, eski kayıt silinmez)
│   ├── CHANGELOG.md            HERKES kendi bölümüne ekler
│   ├── TASKS_BACKEND.md        SADECE backend ajanı işaretler/düzenler
│   └── TASKS_MOBILE.md         SADECE mobile ajanı işaretler/düzenler
├── backend/                    BACKEND AJANININ TERİTORYASI — mobile buraya dokunmaz
│   ├── CLAUDE.md                Backend'e özel kurallar (nested memory)
│   └── MEMORY.md                Backend ajanının oturum günlüğü
├── mobile/                     MOBILE AJANININ TERİTORYASI — backend buraya dokunmaz
│   ├── CLAUDE.md                Mobile'a özel kurallar (nested memory)
│   └── MEMORY.md                Mobile ajanının oturum günlüğü
└── .github/
    └── PULL_REQUEST_TEMPLATE.md
```

## MUTLAK KURALLAR (istisnasız, her ajan için)

1. **Oturuma HER ZAMAN `git pull origin main` (veya `git fetch && git rebase origin/main`)
   ile başla.** Güncel olmayan kod üzerinde çalışmak yasak — hiçbir değişiklik bu adım
   atlanarak yapılmaz.
2. **Sadece kendi klasörünü değiştir.** Backend ajanı → yalnızca `backend/**` (+ izin
   verilen `docs/*` dosyaları). Mobile ajanı → yalnızca `mobile/**` (+ izin verilen
   `docs/*` dosyaları). Diğer tarafın klasörüne yazma; gerekirse oku ama düzenleme.
3. **"Kırmızı bölge" dosyaları:** `docs/API_CONTRACT.md`, `docs/DB_SCHEMA.md`,
   `docs/EXCEL_CELL_MAPPING.md`, kök `CLAUDE.md`. Bu dosyalardan birini değiştiren PR,
   **diğer geliştiricinin onayı olmadan `main`'e merge edilmez.** Sessizce değiştirip
   direkt push etmek yasak.
4. **Küçük, sık commit + push yap.** İş saatler/günler boyunca sende kilitli kalmasın;
   diğer taraf pull yaptığında güncel durumu görebilsin.
5. **`main` branch'ine asla force-push yapma.** Ortak geçmişi bozma.
6. **Branch adlandırma:** `backend/<kısa-açıklama>` veya `mobile/<kısa-açıklama>`
   (örn. `backend/excel-hermetik-mapping`).
7. **Commit mesaj öneki:** `[backend] ...` veya `[mobile] ...`
   (örn. `[backend] hermetik şablon hücre eşlemesi eklendi`).
8. **Şablon dosyaları (`backend/templates/*.xlsx`) DEĞİŞTİRİLEMEZ kaynaklardır.** Kod
   bunları asla üzerine yazmaz; sadece okuyup yeni bir dosya üretir.
9. **Kontrat değişikliği = önce dosya, sonra kod.** API/DB/Excel-mapping'de bir değişiklik
   gerekiyorsa: önce ilgili `docs/*.md` dosyasını güncelle → `docs/DECISIONS.md`'e tarihli
   not düş → diğer tarafı PR açıklamasında açıkça etiketle → sonra kodu yaz.
10. **Oturum sonunda** kendi `MEMORY.md`'ine kısa bir günlük notu ekle (ne yapıldı, ne
    kaldı, hangi kararlar alındı) ve kendi `TASKS_*.md` dosyandaki ilgili kutucukları
    işaretle.

## Görev ve hafıza sistemi

- **Görevler:** `docs/TASKS_BACKEND.md`, `docs/TASKS_MOBILE.md` — PRD §22 yol
  haritasından türetilmiştir. Her ajan sadece kendi dosyasını düzenler, diğerini
  bağlam için okur (kim ne bitirdi, kim neyi bekliyor).
- **Hafıza:** her ajan kendi klasöründeki `MEMORY.md`'i günceller ve git'e commit eder.
  Bu, ajanların kendi otomatik/lokal hafızasına ek olarak, **iki tarafın da erişebildiği
  kalıcı ve paylaşılan** gerçek kaynaktır — yeni bir oturumda veya diğer ajan baktığında
  geçmiş kararlar kaybolmaz.
- **Kararlar:** `docs/DECISIONS.md` — sadece eklenir, asla eski kayıt silinmez/değiştirilmez
  (tarih + kim + ne + neden formatı).

## Teknoloji özeti (detay: `docs/PRD.md` §16)

- Backend: FastAPI (Python 3.11+), PostgreSQL, openpyxl, JWT
- Mobil: Flutter 3.x (Dart)
- Ortak sınır: REST API — `docs/API_CONTRACT.md`
