# TEMPLATE SAMPLE CELLS & CLEAR RANGES DOCUMENTATION

This document defines the clear ranges for hardcoded sample data in master templates.
When generating reports, if user input is missing for a field, the sample data cell must be cleared (`None`) rather than displaying leftover template sample values.

---

## 1. KAPAK SAYFASI
- **Data Input Cells**:
  - `D9`: customer_name
  - `D10`: trafo_label
  - `D11`: address
  - `D12`: report_date
  - `D14`: test_date
  - `A29`: summary_text
  - `D55`: operator_title

## 2. ANA SAYFA
- **Transformer Info Cells**: `G11`, `O11`, `Q11`, `S11`, `G13`, `O13`, `G15`, `O15`, `G17`, `O17`, `G19`, `O19`, `G21`
- **Tank Checkmarks**: `I21`, `P21`, `U21` (or `I19`, `P19`, `U19` for kuru tip)
- **Checklist Pairs**:
  - `C61`, `F61`, `J61`, `C63`, `F63`, `J63`
- **Measurement Cells**: `C55`, `C57`, `C59`, `J55`, `J57`, `J59`, `O55`, `O57`, `O59`
- **Footer/Operator Cells**: `B73`, `F81`

## 3. ANA SAYFA KESİCİ
- **Breaker Info Data Cells**:
  - `G11` (Marka), `O11` (Tip), `G13` (Akım), `O13` (İmal Yılı), `G15` (Gerilim), `O15` (Seri No), `G17` (Motor Volt), `O17` (Bobin Volt)
- **Checkmark & Status Cells**:
  - `G24`, `I24`, `P24`, `R24`, `G26`, `P26`, `I26`, `R26`, `G28`, `P28`, `I28`, `R28`, `G30`, `P30`, `I30`, `R30`, `G32`, `P32`, `I32`, `R32`
- **Step Voltage Table Numbers**:
  - Rows 39, 41, 43: Cols `C`, `F`, `I`, `L`, `O`
- **Insulation & Contact Resistance Data**:
  - Rows 50, 52, 54: `C50`, `G50`, `K50`, `O50`, `C52`, `G52`, `K52`, `O52`, `C54`, `G54`, `K54`, `O54`
- **Timing & Auxiliary Data**:
  - Rows 61, 63, 65: `C61`, `J61`, `Q61`, `C63`, `J63`, `Q63`, `C65`, `F65`, `J65`, `M65`, `Q65`
- **Footer Residuals**: `F76`, `F77`, `F78`

## 4. OG SARGI MEVCUT KADEME & AG SARGI
- **Header Cells**: `D11` (operator_name), `J11` (device_model), `O11` (device_serial)
- **Measurement Grid**: Rows 24..26 (Columns `C`, `E`, `G`, `I`, `K`, `M`, `O`, `Q`)

## 5. İZOLASYON & Ç.O 34500 (TTR)
- **İzolasyon Data Cells**: `D16`, `D17`, `D30`, `D31`
- **TTR Data Cells**: Rows 16..20 (Columns `B`, `C`, `D`)

## 6. TOPRAKLAMALAR
- **Ground Resistance Data Cells**: `D17`, `D18`, `D19`, `D32`, `D33`, `D34`

## 7. HV PF / LV PF / AKIM TRAFOLARI / DİĞER
- **Measurement Cells**: `D16`, `D17`, `D18`, `D23`, `D24`, `D25`, `D30`, `D31`, `D32`, `P17`
