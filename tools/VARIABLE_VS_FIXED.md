# VARIABLE VS FIXED CELL CLASSIFICATION

This document defines the strict classification between **VARIABLE** (user data input) cells and **FIXED** (template skeleton) cells across all worksheets in the BTS Trafo Report Excel system.

---

## BUSINESS RULES (UNALTERABLE)

1. **VARIABLE FIELDS (Değişken Alanlar)**:
   - Entered in the app and saved in `dataJson`.
   - If the user did NOT enter a value, the Excel cell MUST BE EMPTY (`None`).
   - `0`, `0.0`, `"0"`, `00.01.1900`, or sample constants ("ULUSOY", "20000"...) MUST NOT BE WRITTEN or left behind.

2. **FIXED FIELDS (Sabit Alanlar)**:
   - Template skeleton structure — MUST NEVER be deleted or set to `None`.
   - Section headers ("KESİCİ BİLGİLERİ", "KONTROLLER", "BASAMAK VOLTAJ TESTİ", etc.)
   - Table column headers ("Evet", "Hayır", "R1 (1.04kV)", "SONUÇ", "TEST VOLTAJI", "TEST AKIMI")
   - Phase row labels ("L-1", "L-2", "L-3")
   - Unit labels ("kV", "ms", "GΩ", "μΩ", "Vdc", "A")
   - Header title texts ("ONAYLAYAN", "UNVAN", "TEST TARİHİ", "RAPOR TARİHİ")
   - Logos, borders/frames, formula skeleton (formulas starting with '=').

---

## SHEET-BY-SHEET CLASSIFICATION

### 1. ANA SAYFA KESİCİ
- **VARIABLE CELLS**:
  - `G11` (breaker_brand), `O11` (breaker_serial_no), `G13` (breaker_model / rated_current), `O13` (breaker_year), `G15` (breaker_voltage), `O15` (breaker_serial_no), `G17` (breaker_motor_voltage), `O17` (breaker_coil_voltage)
  - Control Checkmarks & Text: `G24`, `I24`, `P24`, `R24`, `G26`, `H26`, `I26`, `P26`, `R26`, `G28`, `I28`, `P28`, `R28`, `G30`, `I30`, `P30`, `R30`, `G32`, `I32`, `P32`, `R32`
  - Step Voltage Test Numbers: Rows 39, 41, 43 (Cols `C`, `F`, `I`, `L`, `O`)
  - Insulation Resistance Test Values: `C50`, `G50`, `C52`, `G52`, `C54`, `G54`
  - Contact Resistance Test Values: `K50`, `O50`, `K52`, `O52`, `K54`, `O54`
  - Opening / Closing Times & Coil Currents: `C61`, `J61`, `Q61`, `C63`, `J63`, `Q63`, `C65`, `F65`, `J65`, `M65`, `Q65`
  - Result Paragraph: `D68`
  - Personnel / Date Values: `F74` (test_date), `F75` (report_date), `F76` (operator_title)
- **FIXED CELLS**:
  - Section Headers: `B9`, `B21`, `B35`, `B46`, `K46`, `B57`
  - Table Headers: `I22` ("Evet"), `J22` ("Hayır"), `R22` ("Evet"), `S22` ("Hayır"), `C37:R37` ("R1 (1.04kV)".."SONUÇ"), `C48:O48` ("TEST VOLTAJI".."SONUÇ"), `C59:Q59` ("KESİCİ AÇMA".."SONUÇ")
  - Phase Labels: `B39`, `B41`, `B43`, `B50`, `B52`, `B54`, `B61`, `B63`, `B65` ("L-1", "L-2", "L-3")
  - Unit Labels: `E39:Q43` ("GΩ"), `F50:R54` ("kV", "GΩ", "μΩ"), `E61:O65` ("ms", "A")
  - Header & Personnel Labels: `K74` ("ONAYLAYAN"), `B74` ("Rapor Tarihi"), `B75` ("Test Tarihi"), `B76` ("Unvan")

### 2. KAPAK SAYFASI
- **VARIABLE CELLS**: `D9` (customer_name), `D10` (trafo_label), `D11` (address), `D12` (report_date), `D14` (test_date), `A29` (summary_text), `D55` (operator_title)
- **FIXED CELLS**: `A7` ("TRAFO TEST RAPORU"), `A9:C14` labels ("Müşterinin Adı", "Trafo Etiketi", "ADRESİ", "RAPOR TARİHİ", "REFERANS", "RAPOR KONUSU"), `A27` ("SONUÇ"), `G52` ("ONAYLAYAN"), `A53:C55` labels ("Test Tarihi", "Rapor Tarihi", "Unvan")

### 3. ANA SAYFA
- **VARIABLE CELLS**: `G11` (brand), `O11:S11` (tap_info), `G13` (power_kva), `O13` (manufacture_year), `G15` (voltage), `O15` (serial_no), `G17` (oil_brand), `O17` (oil_weight), `G19` (connection_group), `O19` (short_circuit_imp_pct), `G21` (tank_type), `I21` / `P21` / `U21` (tank_mark), `C55:O59` (winding resistance), `B73` (notes), `F81` (operator_title)
- **FIXED CELLS**: Section headers ("TRAFO BİLGİLERİ", "KONTROLLER", etc.), checklist question labels, "Evet/Hayır" column headers, unit labels ("kVA", "V", "kg", "%", "mΩ"), personnel labels ("ONAYLAYAN", "Test Tarihi", "Rapor Tarihi", "Unvan")

### 4. OG SARGI MEVCUT KADEME & AG SARGI
- **VARIABLE CELLS**: `D11` (operator_name), `J11` (device_model), `O11` (device_serial), measurement grid cells (`C24:Q26`)
- **FIXED CELLS**: Sheet headers, "Operatör:", "Cihaz:", "Cihaz S/N:", table row/column headers ("L1-L2", "L2-L3", "L3-L1", "Kademe"), unit labels ("mΩ")

### 5. İZOLASYON & Ç.O 34500 (TTR)
- **VARIABLE CELLS**: Header info (`D11`, `J11`, `O11`), insulation values (`D16`, `D17`, `D30`, `D31`), TTR values (`B16:D20`)
- **FIXED CELLS**: Sheet headers, section titles, row labels ("OG-GND", "AG-GND", "Sıcaklık", "Nem"), TTR tap labels ("Kademe 1".."Kademe 5"), phase labels ("A", "B", "C")

### 6. TOPRAKLAMALAR
- **VARIABLE CELLS**: Header info (`D9`, `J9`, `O9`), resistance values (`D17`, `D18`, `D19`, `D32`, `D33`, `D34`)
- **FIXED CELLS**: Headers, section titles ("TRAFO TOPRAKLAMA DİRENÇLERİ", "ŞALT SAHASI TOPRAKLAMA DİRENÇLERİ"), row labels ("Gövde Topraklaması", "Nötr Topraklaması", "Kazan Topraklaması", "OG Paratoner", "Pano", "İhata"), unit labels ("Ω")

### 7. HV PF / LV PF / AKIM TRAFOLARI / DİĞER
- **VARIABLE CELLS**: Header info (`D9`/`D11`, `J9`/`J11`, `O9`/`O11`), test measurement values (`D16:M32`, `P17`)
- **FIXED CELLS**: Headers, section titles, row labels ("L1", "L2", "L3"), test voltage/current labels, unit labels ("kV", "VDC", "nA", "GΩ", "μA")
