# Topraklama Ölçümleri Hücre Eşleme ve Etiket Dokümantasyonu

Master Şablonlar: `backend/templates/hybrid/hermetik_hybrid.xlsx`, `gt_hybrid.xlsx`, `kuru_tip_hybrid.xlsx`

## 1. Doğrulanmış Ölçüm Hücreleri (ANA SAYFA)

| Form Sırası | Form & Rapor Etiketi | `field_key` | Hermetik / GT Hücre | Kuru Tip Hücre | Topraklamalar Formül Referansı | Max İzin Verilen Sınır |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | **İşletme (Nötr) Topraklama Direnci (Ω)** | `ground_isletme_notr` | `ANA SAYFA!H48` | `ANA SAYFA!H42` | `TOPRAKLAMALAR!K16` | **Max. 4 Ω** |
| 2 | **Koruma – Trafo Topraklama Direnci (Ω)** | `ground_koruma_trafo` | `ANA SAYFA!H46` | `ANA SAYFA!H40` | `TOPRAKLAMALAR!K26` | **Max. 4 Ω** |
| 3 | **Koruma – Hücre Topraklama Direnci (Ω)** | `ground_koruma_hucre` | `ANA SAYFA!H50` | `ANA SAYFA!H44` | `TOPRAKLAMALAR!K27` | **Max. 4 Ω** |
| 4 | **Koruma – Kapılar Topraklama Direnci (Ω)** | `ground_koruma_kapilar` | `ANA SAYFA!Q48` | `ANA SAYFA!Q42` | `TOPRAKLAMALAR!K28` | **Max. 4 Ω** |
| 5 | **Koruma – AG. Pano Topraklama Direnci (Ω)** | `ground_koruma_ag_pano` | `ANA SAYFA!Q46` | `ANA SAYFA!Q40` | `TOPRAKLAMALAR!K29` | **Max. 4 Ω** |

---

## 2. Aliases & Geriye Dönük Uyumluluk (Fallback Keys)

- `ground_isletme_notr` -> fallback: `ground_r_neutral`
- `ground_koruma_trafo` -> fallback: `ground_r_trafo_body`, `ground_trafo_body`, `ground_r_tank`
- `ground_koruma_hucre` -> fallback: `ground_r_hucre`
- `ground_koruma_kapilar` -> fallback: `ground_r_kapilar`, `ground_r_og_lightning`
- `ground_koruma_ag_pano` -> fallback: `ground_r_panel`, `ground_r_ag_pano`

---

## 3. Kaldırılan / Temizlenen Eski Yanlış Alanlar ve Hücreler

- `ground_r_og_lightning` (Eski OG Paratoner) -> Şablonda bulunmuyor, form UI'ından kaldırıldı.
- `ground_r_fence` (Eski İhata) -> Şablonda bulunmuyor, form UI'ından kaldırıldı.
- Eski yanlış `TOPRAKLAMALAR` sub-sheet hücre yazımları (`D17`, `D18`, `D19`, `D32`, `D33`, `D34`) hücre haritalarından temizlendi. `TOPRAKLAMALAR` alt sayfası otomatik Excel formülleri ile `ANA SAYFA` verilerini canlı okur.
