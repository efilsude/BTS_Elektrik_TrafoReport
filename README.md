# TrafoReport

Trafo bakım ve test saha raporlama sistemi — kurumsal dahili Android (Flutter)
uygulaması + FastAPI backend + Excel üretim motoru.

Bu repo **iki kişi + iki AI kod ajanı** tarafından paralel geliştirilecek şekilde
bölünmüştür:

- `backend/` → Backend geliştiricisi + kendi ajanı (FastAPI, DB, Excel motoru)
- `mobile/` → Mobil geliştiricisi + kendi ajanı (Flutter)
- `docs/` → İkisinin de okuduğu, belirli dosyaların belirli kişi tarafından
  güncellendiği ortak alan

## İlk kurulum (bu zip'i boş repoya yerleştirme)

```bash
git clone <repo-url>
cd <repo-klasörü>
# bu zip'in içeriğini buraya kopyala (klasörleriyle birlikte)
git add .
git commit -m "chore: proje iskeleti, PRD, kurallar ve görev listeleri"
git push origin main
```

Ardından backend geliştiricisi kendi 3 gerçek `.xlsx` şablon dosyasını
`backend/templates/` altına ekleyip commit'lemeli (bu dosyalar kanoniktir, bir
daha elle değiştirilmez).

## Her oturuma başlarken (İKİ TARAF İÇİN DE)

```bash
git pull origin main
```

Bu adım atlanmadan hiçbir kod değişikliği yapılmaz (bkz. kök `CLAUDE.md`).

## Okuma sırası (ajanın/geliştiricinin ilk oturumda okuması gerekenler)

1. `CLAUDE.md` (kök) — herkes için geçerli mutlak kurallar
2. `docs/PRD.md` — ürünün tam gereksinim dokümanı (tek doğruluk kaynağı)
3. Kendi klasöründeki `CLAUDE.md` (`backend/` veya `mobile/`) — sana özel kurallar
4. `docs/TASKS_BACKEND.md` veya `docs/TASKS_MOBILE.md` — görev listen
5. `backend/MEMORY.md` veya `mobile/MEMORY.md` — önceki oturumlardan kalan bağlam

## Ortak dosyalar (docs/) — kim neyi yazar

| Dosya | Yazar | Okuyan |
|---|---|---|
| `PRD.md` | kimse (salt okunur) | herkes |
| `API_CONTRACT.md` | backend | mobile (salt okur) |
| `DB_SCHEMA.md` | backend | mobile (referans) |
| `EXCEL_CELL_MAPPING.md` | backend | mobile (sadece alan anahtarları için) |
| `DECISIONS.md` | herkes (append-only) | herkes |
| `CHANGELOG.md` | herkes (kendi bölümü) | herkes |
| `TASKS_BACKEND.md` | backend | mobile (referans) |
| `TASKS_MOBILE.md` | mobile | backend (referans) |

Detaylı kurallar için `CLAUDE.md` dosyasına bak.
