# HYBRID TEMPLATE ARCHITECTURE PLAN (BTS Trafo Report)

## 1. Overview & Strategy

This document outlines the hybrid template strategy for BTS Trafo Report Excel generation.

### Template Classification & Sourcing Rules
1. **Hermetik & GT (Genleşme Tanklı)**:
   - `KAPAK SAYFASI` + `ANA SAYFA`: Taken **EXCLUSIVELY** from `backend/templates/reference/yeni_tasarim_referans.xlsx` (new visual design, new corporate headers, updated layout & signature anchors).
   - Remaining detail measurement sheets (`OG SARGI MEVCUT KADEME`, `AG SARGI`, `İZOLASYON `, `Ç.O 34500`, `TOPRAKLAMALAR`, `HV PF`, `LV PF`, `HERMETİK YAĞ DİLEKÇESİ`, `YAĞ RAPORU`, `DİĞER`, `AKIM TRAFOLARI`): Taken from old Hermetik / GT templates.
   - Breaker sheets (`ANA SAYFA KESİCİ`, `KESİCİ İZOLASYON`, `KESİCİ KONTAK`, `AÇMA-KAPAMA`): Included in master hybrid templates, dynamically stripped at runtime if `has_breaker` / `breaker_included` is `False`.

2. **Kuru Tip**:
   - Base workbook: Old Kuru Tip template (`backend/templates/KURU TİP HİLMİ.xlsx`).
   - `ANA SAYFA` checklist question rows (rows 26..36, 12 questions): **PRESERVED AS IS** (not converted to Hermetik/GT checklist).
   - Visual styling (logo, top emblem layout, header bands, approval box styling): Aligned with `yeni_tasarim_referans.xlsx`.

---

## 2. Sheet Inventory

### Reference Template (`yeni_tasarim_referans.xlsx`)
- `KAPAK SAYFASI` (New cover design, G52 signature anchor)
- `ANA SAYFA` (New main page design, K78 signature anchor)
- `OG SARGI MEVCUT KADEME`
- `AG SARGI`
- `İZOLASYON `
- `Ç.O 34500`
- `HERMETİK YAĞ DİLEKÇESİ`

### Master Hybrid Output Targets (`backend/templates/hybrid/`)
- `hermetik_hybrid.xlsx`
- `gt_hybrid.xlsx`
- `kuru_tip_hybrid.xlsx`

### Breaker Sheets List (Stripped if `has_breaker=False`)
- `ANA SAYFA KESİCİ`
- `KESİCİ İZOLASYON`
- `KESİCİ KONTAK`
- `AÇMA-KAPAMA`

---

## 3. Cell Coordinate Mapping Updates

### KAPAK SAYFASI (New Reference Layout)
- `D9`: `customer_name`
- `D10`: `trafo_label`
- `D11`: `address`
- `D12`: `report_date`
- `D14`: `test_date`
- `A29`: `summary_text`
- `D55`: `operator_title`
- `D56`: `sicil_no`
- `D57`: `ekipnet_no`
- `G52`: `operator_name` / Signature anchor

### ANA SAYFA (New Reference Layout - Hermetik & GT)
- `K2`: `='KAPAK SAYFASI'!D9` (Customer name / Şalt Sahası)
- `K5`: `='KAPAK SAYFASI'!D10` (Trafo label / Lokasyon)
- `G11`: `brand`
- `O11`: `tap_info_1`
- `Q11`: `tap_info_2`
- `S11`: `tap_info_3`
- `G13`: `power_kva`
- `O13`: `manufacture_year`
- `G15`: `voltage`
- `O15`: `serial_no`
- `G17`: `oil_brand`
- `O17`: `oil_weight`
- `G19`: `connection_group`
- `O19`: `short_circuit_imp_pct`
- `G21`: `tank_type`
- `I21`: `tank_mark_hermetik`
- `P21`: `tank_mark_gt`
- `U21`: `tank_mark_kuru`
- `B73`: `notes`
- `F81`: `operator_title`
- `F82`: `sicil_no`
- `F83`: `ekipnet_no`
- `K78`: `operator_name` / Signature anchor

### Kuru Tip ANA SAYFA Checklist Items (Preserved)
- `checklist_1`..`12` pairs on rows 26, 28, 30, 32, 34, 36:
  - `checklist_1`: Evet `I26`, Hayır `J26` (Trafo Sıcaklık Kontrolü)
  - `checklist_2`: Evet `I28`, Hayır `J28` (Fan ON)
  - `checklist_3`: Evet `I30`, Hayır `J30` (DC Redresör Kontrolü)
  - `checklist_4`: Evet `I32`, Hayır `J32` (Termometre Alarm)
  - `checklist_5`: Evet `I34`, Hayır `J34` (Termometre Trip)
  - `checklist_6`: Evet `I36`, Hayır `J36` (Fan OFF)
  - `checklist_7`: Evet `R26`, Hayır `S26` (Trafo Temizliği)
  - `checklist_8`: Evet `R28`, Hayır `S28` (Bina Temizliği)
  - `checklist_9`: Evet `R30`, Hayır `S30` (Kablo Sıkılık Kontrolü)
  - `checklist_10`: Evet `R32`, Hayır `S32` (Epoksi Kontrolü)
  - `checklist_11`: Evet `R34`, Hayır `S34` (Termistor Kontrolü)
  - `checklist_12`: Evet `R36`, Hayır `S36` (Topraklama Bağlantısı)

---

## 4. Implementation Strategy

1. **Master Hybrid Template Construction (`tools/build_hybrid_templates.py`)**:
   - Load `reference/yeni_tasarim_referans.xlsx` and old template workbooks.
   - For `hermetik_hybrid.xlsx` and `gt_hybrid.xlsx`: Copy `KAPAK SAYFASI` and `ANA SAYFA` from reference workbook; copy remaining detail sheets from old Hermetik/GT workbooks.
   - For `kuru_tip_hybrid.xlsx`: Copy visual header/brand styling from reference while leaving `ANA SAYFA` checklist rows (26..36) untouched.
   - Save output files into `backend/templates/hybrid/` and copy to `backend/templates/` for runtime loading.

2. **Runtime Breaker Sheet Pruning**:
   - `generate_excel.py` and `excel_engine.py` inspect `has_breaker` (or `breaker_included` in data_dict).
   - If `False` or no breaker data present, remove breaker sheets (`ANA SAYFA KESİCİ`, `KESİCİ İZOLASYON`, `KESİCİ KONTAK`, `AÇMA-KAPAMA`) from the workbook before saving.

3. **Cell Mapping Synchronization**:
   - Update `TYPE_CELL_MAPPINGS` in `tools/generate_excel.py`, `backend/app/services/excel_engine.py`, and `mobile/lib/excel/cell_mapping.dart`.
