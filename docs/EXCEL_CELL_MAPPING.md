# EXCEL_CELL_MAPPING.md — Verified Excel Cell Mapping Documentation

## Overview
This document provides the authoritative, type-based Excel cell mapping specification for **BTS_Elektrik_TrafoReport**.

### Supported Transformer Types
1. **HERMETİK (`hermetik`)** — `backend/templates/HERMETİK TRAFO BAKIM RAPORU HİLMİ.xlsx` / `mobile/assets/templates/hermetik.xlsx`
2. **KURU TİP (`kuru_tip`)** — `backend/templates/KURU TİP HİLMİ.xlsx` / `mobile/assets/templates/kuru_tip.xlsx`
3. **GENLEŞME TANKLI (`gt`)** — `backend/templates/TR BAKIM RAPORU GT HİLMİ.xlsx` / `mobile/assets/templates/gt.xlsx`

---

## Core Rules & Constants

### 1. User-Verified Cell Coordinates (Strict & Immutable)

#### Common Across HERMETİK + GT:
- **KAPAK SAYFASI**:
  - `summary_text` ➔ `A31`
  - `signature` (image anchor) ➔ `G56` (bounding box G55:H58)
- **ANA SAYFA**:
  - `tap_info_1` ➔ `O11`, `tap_info_2` ➔ `Q11`, `tap_info_3` ➔ `S11`
  - Tank Type selection check mark (Row 21):
    - `tank_mark_hermetik` ➔ `I21` (`'ü'`)
    - `tank_mark_gt` ➔ `P21` (`'ü'`)
    - `tank_mark_kuru` ➔ `U21` (`'ü'`)
  - Checklist ('ü') check marks:
    - Left column ➔ starting at `J27` (J27..J42)
    - Right column ➔ starting at `U27` (U27..U42)
  - OG Sargı 2A:
    - `og_rab` ➔ `C55`
    - `og_rbc` ➔ `C57`
    - `og_rca` ➔ `C59`

#### KURU TİP (Row Shifts):
- **KAPAK SAYFASI**:
  - `summary_text` ➔ `A31`, `signature` ➔ `G56` (same as Hermetik/GT)
- **ANA SAYFA**:
  - `tap_info_1` ➔ `O11`, `tap_info_2` ➔ `Q11`, `tap_info_3` ➔ `S11` (same as Hermetik/GT)
  - Tank Type selection check mark (Row 19):
    - `tank_mark_hermetik` ➔ `I19` (`'ü'`)
    - `tank_mark_gt` ➔ `P19` (`'ü'`)
    - `tank_mark_kuru` ➔ `U19` (`'ü'`)
  - Checklist ('ü') check marks:
    - Left column ➔ starting at `J24` (J24..J39)
    - Right column ➔ starting at `U24` (U24..U39)
  - OG Sargı 2A:
    - `og_rab` ➔ `C49`
    - `og_rbc` ➔ `C51`
    - `og_rca` ➔ `C53`

### 2. Checkmark Character
- The checkmark character in the templates is `'ü'` (Wingdings / Marlett character for checkbox check mark).

### 3. Date Formatting
- Excel serial date number calculation: `date.difference(DateTime(1899, 12, 30)).inDays.toDouble()`.

### 4. Formula Protection
- Cells starting with `=` are template formulas and are marked with `TODO_VERIFY: formula_protected =...`. These cells MUST NOT be directly written to; values are supplied through the source input cells on `ANA SAYFA`.

### 5. Media Anchors (KAPAK SAYFASI)
- **Signature Image**: `G56`
- **Cover Photos**: `A35`, `F35`, `A43`, `F43` (embedded directly into existing cover area without adding new sheets).

---

## Type-Based Mapping Matrix (JSON)

```json
{
  "HERMETIK": {
    "KAPAK SAYFASI": {
      "D9": "customer_name",
      "D10": "trafo_label",
      "D11": "address",
      "D12": "report_date",
      "D14": "test_date",
      "A31": "summary_text",
      "D54": "TODO_VERIFY: formula_protected =D14",
      "D55": "TODO_VERIFY: formula_protected =D12",
      "D56": "creator_display_name",
      "D57": "sicil_no",
      "D58": "ekipnet_no",
      "G56": "signature"
    },
    "ANA SAYFA": {
      "K2": "TODO_VERIFY: formula_protected =KAPAK SAYFASI!D9",
      "K5": "TODO_VERIFY: formula_protected =KAPAK SAYFASI!D10",
      "G11": "brand",
      "O11": "tap_info_1",
      "Q11": "tap_info_2",
      "S11": "tap_info_3",
      "G13": "power_kva",
      "O13": "manufacture_year",
      "G15": "voltage",
      "O15": "serial_no",
      "G17": "oil_brand",
      "O17": "oil_weight",
      "G19": "connection_group",
      "O19": "short_circuit_imp_pct",
      "G21": "tank_type",
      "I21": "tank_mark_hermetik",
      "P21": "tank_mark_gt",
      "U21": "tank_mark_kuru",
      "J27": "checklist_1",
      "J28": "checklist_2",
      "J29": "checklist_3",
      "J30": "checklist_4",
      "J31": "checklist_5",
      "J32": "checklist_6",
      "J33": "checklist_7",
      "J34": "checklist_8",
      "J35": "checklist_9",
      "J36": "checklist_10",
      "J37": "checklist_11",
      "J38": "checklist_12",
      "J39": "checklist_13",
      "J40": "checklist_14",
      "J41": "checklist_15",
      "J42": "checklist_16",
      "U27": "checklist_17",
      "U28": "checklist_18",
      "U29": "checklist_19",
      "U30": "checklist_20",
      "U31": "checklist_21",
      "U32": "checklist_22",
      "U33": "checklist_23",
      "U34": "checklist_24",
      "U35": "checklist_25",
      "U36": "checklist_26",
      "U37": "checklist_27",
      "U38": "checklist_28",
      "U39": "checklist_29",
      "U40": "checklist_30",
      "U41": "checklist_31",
      "U42": "checklist_32",
      "C55": "og_rab",
      "C57": "og_rbc",
      "C59": "og_rca",
      "J55": "ag_ran",
      "J57": "ag_rbn",
      "J59": "ag_rcn",
      "O55": "ag_rab",
      "O57": "ag_rbc",
      "O59": "ag_rca",
      "C61": "ground_trafo_body",
      "F61": "ground_neutral",
      "J61": "ground_tank",
      "C63": "ground_og_lightning",
      "F63": "ground_panel",
      "J63": "ground_fence"
    },
    "OG SARGI MEVCUT KADEME": {
      "K24": "TODO_VERIFY: formula_protected =ANA SAYFA!C55",
      "K25": "TODO_VERIFY: formula_protected =ANA SAYFA!C59",
      "K26": "TODO_VERIFY: formula_protected =ANA SAYFA!C57"
    },
    "AG SARGI": {
      "K24": "TODO_VERIFY: formula_protected =ANA SAYFA!G55",
      "K25": "TODO_VERIFY: formula_protected =ANA SAYFA!G57",
      "K26": "TODO_VERIFY: formula_protected =ANA SAYFA!G59"
    },
    "İZOLASYON ": {
      "D16": "iso_og_gnd",
      "D17": "iso_ag_gnd",
      "D18": "TODO_VERIFY: formula_protected =ANA SAYFA!I66",
      "D23": "TODO_VERIFY: formula_protected =ANA SAYFA!I68",
      "D30": "iso_temp",
      "D31": "iso_humidity"
    },
    "Ç.O 34500": {
      "B16": "ttr_tap1_a",
      "C16": "ttr_tap1_b",
      "D16": "ttr_tap1_c",
      "B17": "ttr_tap2_a",
      "C17": "ttr_tap2_b",
      "D17": "ttr_tap2_c",
      "B18": "ttr_tap3_a",
      "C18": "ttr_tap3_b",
      "D18": "ttr_tap3_c",
      "B19": "ttr_tap4_a",
      "C19": "ttr_tap4_b",
      "D19": "ttr_tap4_c",
      "B20": "ttr_tap5_a",
      "C20": "ttr_tap5_b",
      "D20": "ttr_tap5_c"
    },
    "TOPRAKLAMALAR": {
      "D17": "ground_r_trafo_body",
      "D18": "ground_r_neutral",
      "D19": "ground_r_tank",
      "D32": "ground_r_og_lightning",
      "D33": "ground_r_panel",
      "D34": "ground_r_fence"
    },
    "HV PF": {
      "P15": "TODO_VERIFY: formula_protected =ANA SAYFA!G27",
      "P17": "pf_hv_humidity"
    },
    "LV PF": {
      "P15": "TODO_VERIFY: formula_protected =HV PF!P15",
      "P17": "pf_lv_humidity"
    },
    "ANA SAYFA KESİCİ": {
      "G11": "breaker_brand",
      "O11": "breaker_serial_no",
      "G13": "breaker_model",
      "O13": "breaker_year"
    },
    "KESİCİ İZOLASYON": {
      "D10": "breaker_iso_r_gnd"
    },
    "KESİCİ KONTAK": {
      "D10": "breaker_contact_r"
    },
    "AÇMA-KAPAMA": {
      "D10": "breaker_timing_open"
    },
    "DİĞER": {
      "D16": "device_model",
      "D17": "device_serial"
    },
    "AKIM TRAFOLARI": {
      "D16": "ct_ratio"
    },
    "HERMETİK YAĞ DİLEKÇESİ": {
      "D16": "oil_test_breakdown_voltage",
      "D18": "oil_test_water_content"
    }
  },
  "KURU_TIP": {
    "KAPAK SAYFASI": {
      "D9": "customer_name",
      "D10": "trafo_label",
      "D11": "address",
      "D12": "report_date",
      "D14": "test_date",
      "A31": "summary_text",
      "D54": "TODO_VERIFY: formula_protected =D14",
      "D55": "TODO_VERIFY: formula_protected =D12",
      "D56": "creator_display_name",
      "D57": "sicil_no",
      "D58": "ekipnet_no",
      "G56": "signature"
    },
    "ANA SAYFA": {
      "K2": "TODO_VERIFY: formula_protected =KAPAK SAYFASI!D9",
      "K5": "TODO_VERIFY: formula_protected =KAPAK SAYFASI!D10",
      "G11": "brand",
      "O11": "tap_info_1",
      "Q11": "tap_info_2",
      "S11": "tap_info_3",
      "G13": "power_kva",
      "O13": "manufacture_year",
      "G15": "voltage",
      "O15": "serial_no",
      "G17": "connection_group",
      "O17": "short_circuit_imp_pct",
      "G19": "tank_type",
      "I19": "tank_mark_hermetik",
      "P19": "tank_mark_gt",
      "U19": "tank_mark_kuru",
      "J24": "checklist_1",
      "J25": "checklist_2",
      "J26": "checklist_3",
      "J27": "checklist_4",
      "J28": "checklist_5",
      "J29": "checklist_6",
      "J30": "checklist_7",
      "J31": "checklist_8",
      "J32": "checklist_9",
      "J33": "checklist_10",
      "J34": "checklist_11",
      "J35": "checklist_12",
      "J36": "checklist_13",
      "J37": "checklist_14",
      "J38": "checklist_15",
      "J39": "checklist_16",
      "U24": "checklist_17",
      "U25": "checklist_18",
      "U26": "checklist_19",
      "U27": "checklist_20",
      "U28": "checklist_21",
      "U29": "checklist_22",
      "U30": "checklist_23",
      "U31": "checklist_24",
      "U32": "checklist_25",
      "U33": "checklist_26",
      "U34": "checklist_27",
      "U35": "checklist_28",
      "U36": "checklist_29",
      "U37": "checklist_30",
      "U38": "checklist_31",
      "U39": "checklist_32",
      "C49": "og_rab",
      "C51": "og_rbc",
      "C53": "og_rca",
      "J49": "ag_ran",
      "J51": "ag_rbn",
      "J53": "ag_rcn",
      "O49": "ag_rab",
      "O51": "ag_rbc",
      "O53": "ag_rca",
      "C55": "ground_trafo_body",
      "F55": "ground_neutral",
      "J55": "ground_tank",
      "C57": "ground_og_lightning",
      "F57": "ground_panel",
      "J57": "ground_fence"
    },
    "OG SARGI MEVCUT KADEME": {
      "K24": "TODO_VERIFY: formula_protected =ANA SAYFA!C49",
      "K25": "TODO_VERIFY: formula_protected =ANA SAYFA!C53",
      "K26": "TODO_VERIFY: formula_protected =ANA SAYFA!C51"
    },
    "AG SARGI": {
      "K24": "TODO_VERIFY: formula_protected =ANA SAYFA!G49",
      "K25": "TODO_VERIFY: formula_protected =ANA SAYFA!G51",
      "K26": "TODO_VERIFY: formula_protected =ANA SAYFA!G53"
    },
    "İZOLASYON ": {
      "D16": "iso_og_gnd",
      "D17": "iso_ag_gnd",
      "D18": "TODO_VERIFY: formula_protected =ANA SAYFA!I60",
      "D23": "TODO_VERIFY: formula_protected =ANA SAYFA!I62",
      "D30": "iso_temp",
      "D31": "iso_humidity"
    },
    "Ç.O 34500": {
      "B16": "ttr_tap1_a",
      "C16": "ttr_tap1_b",
      "D16": "ttr_tap1_c",
      "B17": "ttr_tap2_a",
      "C17": "ttr_tap2_b",
      "D17": "ttr_tap2_c",
      "B18": "ttr_tap3_a",
      "C18": "ttr_tap3_b",
      "D18": "ttr_tap3_c",
      "B19": "ttr_tap4_a",
      "C19": "ttr_tap4_b",
      "D19": "ttr_tap4_c",
      "B20": "ttr_tap5_a",
      "C20": "ttr_tap5_b",
      "D20": "ttr_tap5_c"
    },
    "TOPRAKLAMALAR": {
      "D17": "ground_r_trafo_body",
      "D18": "ground_r_neutral",
      "D19": "ground_r_tank",
      "D32": "ground_r_og_lightning",
      "D33": "ground_r_panel",
      "D34": "ground_r_fence"
    },
    "HV PF": {
      "P15": "TODO_VERIFY: formula_protected =ANA SAYFA!G26",
      "P17": "pf_hv_humidity"
    },
    "LV PF": {
      "P15": "TODO_VERIFY: formula_protected =HV PF!P15",
      "P17": "pf_lv_humidity"
    },
    "ANA SAYFA KESİCİ": {
      "G11": "breaker_brand",
      "O11": "breaker_serial_no",
      "G13": "breaker_model",
      "O13": "breaker_year"
    },
    "KESİCİ İZOLASYON": {
      "D10": "breaker_iso_r_gnd"
    },
    "KESİCİ KONTAK": {
      "D10": "breaker_contact_r"
    },
    "AÇMA-KAPAMA": {
      "D10": "breaker_timing_open"
    },
    "DİĞER": {
      "D16": "device_model",
      "D17": "device_serial"
    },
    "AKIM TRAFOLARI": {
      "D16": "ct_ratio"
    }
  },
  "GT": {
    "KAPAK SAYFASI": {
      "D9": "customer_name",
      "D10": "trafo_label",
      "D11": "address",
      "D12": "report_date",
      "D14": "test_date",
      "A31": "summary_text",
      "D54": "TODO_VERIFY: formula_protected =D14",
      "D55": "TODO_VERIFY: formula_protected =D12",
      "D56": "creator_display_name",
      "D57": "sicil_no",
      "D58": "ekipnet_no",
      "G56": "signature"
    },
    "ANA SAYFA": {
      "K2": "TODO_VERIFY: formula_protected =KAPAK SAYFASI!D9",
      "K5": "TODO_VERIFY: formula_protected =KAPAK SAYFASI!D10",
      "G11": "brand",
      "O11": "tap_info_1",
      "Q11": "tap_info_2",
      "S11": "tap_info_3",
      "G13": "power_kva",
      "O13": "manufacture_year",
      "G15": "voltage",
      "O15": "serial_no",
      "G17": "oil_brand",
      "O17": "oil_weight",
      "G19": "connection_group",
      "O19": "short_circuit_imp_pct",
      "G21": "tank_type",
      "I21": "tank_mark_hermetik",
      "P21": "tank_mark_gt",
      "U21": "tank_mark_kuru",
      "J27": "checklist_1",
      "J28": "checklist_2",
      "J29": "checklist_3",
      "J30": "checklist_4",
      "J31": "checklist_5",
      "J32": "checklist_6",
      "J33": "checklist_7",
      "J34": "checklist_8",
      "J35": "checklist_9",
      "J36": "checklist_10",
      "J37": "checklist_11",
      "J38": "checklist_12",
      "J39": "checklist_13",
      "J40": "checklist_14",
      "J41": "checklist_15",
      "J42": "checklist_16",
      "U27": "checklist_17",
      "U28": "checklist_18",
      "U29": "checklist_19",
      "U30": "checklist_20",
      "U31": "checklist_21",
      "U32": "checklist_22",
      "U33": "checklist_23",
      "U34": "checklist_24",
      "U35": "checklist_25",
      "U36": "checklist_26",
      "U37": "checklist_27",
      "U38": "checklist_28",
      "U39": "checklist_29",
      "U40": "checklist_30",
      "U41": "checklist_31",
      "U42": "checklist_32",
      "C55": "og_rab",
      "C57": "og_rbc",
      "C59": "og_rca",
      "J55": "ag_ran",
      "J57": "ag_rbn",
      "J59": "ag_rcn",
      "O55": "ag_rab",
      "O57": "ag_rbc",
      "O59": "ag_rca",
      "C61": "ground_trafo_body",
      "F61": "ground_neutral",
      "J61": "ground_tank",
      "C63": "ground_og_lightning",
      "F63": "ground_panel",
      "J63": "ground_fence"
    },
    "OG SARGI MEVCUT KADEME": {
      "K24": "TODO_VERIFY: formula_protected =ANA SAYFA!C55",
      "K25": "TODO_VERIFY: formula_protected =ANA SAYFA!C59",
      "K26": "TODO_VERIFY: formula_protected =ANA SAYFA!C57"
    },
    "AG SARGI": {
      "K24": "TODO_VERIFY: formula_protected =ANA SAYFA!G55",
      "K25": "TODO_VERIFY: formula_protected =ANA SAYFA!G57",
      "K26": "TODO_VERIFY: formula_protected =ANA SAYFA!G59"
    },
    "İZOLASYON ": {
      "D16": "iso_og_gnd",
      "D17": "iso_ag_gnd",
      "D18": "TODO_VERIFY: formula_protected =ANA SAYFA!I66",
      "D23": "TODO_VERIFY: formula_protected =ANA SAYFA!I68",
      "D30": "iso_temp",
      "D31": "iso_humidity"
    },
    "Ç.O 34500": {
      "B16": "ttr_tap1_a",
      "C16": "ttr_tap1_b",
      "D16": "ttr_tap1_c",
      "B17": "ttr_tap2_a",
      "C17": "ttr_tap2_b",
      "D17": "ttr_tap2_c",
      "B18": "ttr_tap3_a",
      "C18": "ttr_tap3_b",
      "D18": "ttr_tap3_c",
      "B19": "ttr_tap4_a",
      "C19": "ttr_tap4_b",
      "D19": "ttr_tap4_c",
      "B20": "ttr_tap5_a",
      "C20": "ttr_tap5_b",
      "D20": "ttr_tap5_c"
    },
    "TOPRAKLAMALAR": {
      "D17": "ground_r_trafo_body",
      "D18": "ground_r_neutral",
      "D19": "ground_r_tank",
      "D32": "ground_r_og_lightning",
      "D33": "ground_r_panel",
      "D34": "ground_r_fence"
    },
    "ANA SAYFA KESİCİ": {
      "G11": "breaker_brand",
      "O11": "breaker_serial_no",
      "G13": "breaker_model",
      "O13": "breaker_year"
    },
    "KESİCİ İZOLASYON": {
      "D10": "breaker_iso_r_gnd"
    },
    "KESİCİ KONTAK": {
      "D10": "breaker_contact_r"
    },
    "AÇMA-KAPAMA": {
      "D10": "breaker_timing_open"
    },
    "YAĞ RAPORU": {
      "D16": "oil_test_breakdown_voltage",
      "D18": "oil_test_water_content"
    },
    "HERMETİK YAĞ DİLEKÇESİ": {
      "D16": "oil_test_breakdown_voltage",
      "D18": "oil_test_water_content"
    }
  }
}
```

---

## Summary of Mapped Sheets & Coordinates Count

| Transformer Type | Mapped Sheets Count | Total Mapped Cell Coordinates | Formula Protected Cells |
| :--- | :--- | :--- | :--- |
| **HERMETİK** | 16 | 123 | 12 |
| **KURU TİP** | 15 | 123 | 12 |
| **GT** | 13 | 123 | 12 |

---

## Verified TODO_VERIFY List
The following cells contain internal template formulas (`=...`) and are flagged as `TODO_VERIFY: formula_protected =...` so that write logic skips overwriting them:

1. `KAPAK SAYFASI!D54`: `=D14` (test date reflection)
2. `KAPAK SAYFASI!D55`: `=D12` (report date reflection)
3. `ANA SAYFA!K2`: `='KAPAK SAYFASI'!D9` (customer name reflection)
4. `ANA SAYFA!K5`: `='KAPAK SAYFASI'!D10` (trafo label reflection)
5. `OG SARGI MEVCUT KADEME!K24`: `='ANA SAYFA'!C55` / `C49` (og_rab reflection)
6. `OG SARGI MEVCUT KADEME!K25`: `='ANA SAYFA'!C59` / `C53` (og_rca reflection)
7. `OG SARGI MEVCUT KADEME!K26`: `='ANA SAYFA'!C57` / `C51` (og_rbc reflection)
8. `AG SARGI!K24`: `='ANA SAYFA'!G55` / `G49` (ag_ran reflection)
9. `AG SARGI!K25`: `='ANA SAYFA'!G57` / `G51` (ag_rbn reflection)
10. `AG SARGI!K26`: `='ANA SAYFA'!G59` / `G53` (ag_rcn reflection)
11. `İZOLASYON !D18`: `='ANA SAYFA'!I66` / `I60` (isolation og-ag reflection)
12. `İZOLASYON !D23`: `='ANA SAYFA'!I68` / `I62` (isolation core-gnd reflection)
