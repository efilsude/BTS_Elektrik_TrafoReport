# İzolasyon Ölçümleri (30s / 45s / 60s) Hücre Doğrulama Dokümantasyonu

Master Şablonlar: `backend/templates/hybrid/hermetik_hybrid.xlsx`, `gt_hybrid.xlsx`, `kuru_tip_hybrid.xlsx`

## ANA SAYFA Hücre Haritası

| Ölçüm Satırı | Süre | Değer Hücresi | Örnek Şablon Değeri | `field_key` | Alternatif Aliases |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Y.G - TANK** (OG - Tank) | **30 sn** | `F66` | `54.6` | `iso_yg_tank_30s` | `iso_og_gnd_30s`, `iso_og_gnd` |
| **Y.G - TANK** (OG - Tank) | **45 sn** | `I66` | `60.3` | `iso_yg_tank_45s` | `iso_og_gnd_45s` |
| **Y.G - TANK** (OG - Tank) | **60 sn** | `L66` | `64.7` | `iso_yg_tank_60s` | `iso_og_gnd_60s` |
| **A.G - TANK** | **30 sn** | `F68` | `37.7` | `iso_ag_tank_30s` | `iso_ag_gnd_30s`, `iso_ag_gnd` |
| **A.G - TANK** | **45 sn** | `I68` | `44.4` | `iso_ag_tank_45s` | `iso_ag_gnd_45s` |
| **A.G - TANK** | **60 sn** | `L68` | `48.8` | `iso_ag_tank_60s` | `iso_ag_gnd_60s` |
| **Y.G - A.G** (OG - AG) | **30 sn** | `F70` | `57.8` | `iso_yg_ag_30s` | `iso_og_ag_30s`, `iso_og_ag` |
| **Y.G - A.G** (OG - AG) | **45 sn** | `I70` | `63.3` | `iso_yg_ag_45s` | `iso_og_ag_45s` |
| **Y.G - A.G** (OG - AG) | **60 sn** | `L70` | `68.8` | `iso_yg_ag_60s` | `iso_og_ag_60s` |

## İZOLASYON Alt Sayfası (Otomatik Excel Formülleri)

Alt sayfa (`İZOLASYON `) değerleri `ANA SAYFA` üzerindeki hücrelerden otomatik çeker:
- `O.G. TANK İZOLASYON` 30 sn (`B18`) = `="='ANA SAYFA'!F66"`
- `O.G. TANK İZOLASYON` 45 sn (`D18`) = `="='ANA SAYFA'!I66"`
- `O.G. TANK İZOLASYON` 60 sn (`F18`) = `="='ANA SAYFA'!L66"`
- `A.G. TANK İZOLASYON` 30 sn (`B23`) = `="='ANA SAYFA'!F68"`
- `A.G. TANK İZOLASYON` 45 sn (`D23`) = `="='ANA SAYFA'!I68"`
- `A.G. TANK İZOLASYON` 60 sn (`F23`) = `="='ANA SAYFA'!L68"`
- `O.G. A.G. İZOLASYON` 30 sn (`B28`) = `="='ANA SAYFA'!F70"`
- `O.G. A.G. İZOLASYON` 45 sn (`D28`) = `="='ANA SAYFA'!I70"`
- `O.G. A.G. İZOLASYON` 60 sn (`F28`) = `="='ANA SAYFA'!L70"`
