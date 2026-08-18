# ANA SAYFA Form ve Excel Hücre Hizalaması (Inventory & Alignment)

Bu doküman, `HERMETİK`, `GT` ve `KURU_TİP` şablonlarında **ANA SAYFA** sekmesine yazılan tüm değişkenlerin Excel hücre karşılıklarını, önceki durumlarını ve güncel mobil sihirbaz adım düzenini tanımlar.

## 1. ANA SAYFA Değişken Envanteri ve Adım Eşleşme Tablosu

| field_key | Excel Hücresi (Hermetik / GT / Kuru Tip) | Önceki Form Adımı | Güncel Form Adımı | Açıklama |
|---|---|---|---|---|
| `brand` | G11 | Etiket Bilgileri | Etiket Bilgileri | Trafo Markası |
| `tap_info_1` | O11 | Etiket Bilgileri | Etiket Bilgileri | Kademe Pozisyonu 1 |
| `tap_info_2` | Q11 | Etiket Bilgileri | Etiket Bilgileri | Kademe Pozisyonu 2 |
| `tap_info_3` | S11 | Etiket Bilgileri | Etiket Bilgileri | Kademe Pozisyonu 3 |
| `power_kva` | G13 | Etiket Bilgileri | Etiket Bilgileri | Trafo Gücü (kVA) |
| `manufacture_year` | O13 | Etiket Bilgileri | Etiket Bilgileri | İmal Yılı |
| `voltage` | G15 | Etiket Bilgileri | Etiket Bilgileri | Anma Gerilimi (V) |
| `serial_no` | O15 | Etiket Bilgileri | Etiket Bilgileri | Seri Numarası |
| `oil_brand` | G17 (Hermetik/GT) | Etiket Bilgileri | Etiket Bilgileri | Yağ Markası |
| `oil_weight` | O17 (Hermetik/GT) | Etiket Bilgileri | Etiket Bilgileri | Yağ Miktarı (kg) |
| `connection_group` | G19 (H/GT) / G17 (Kuru) | Etiket Bilgileri | Etiket Bilgileri | Bağlantı Grubu (Dyn11 vb.) |
| `short_circuit_imp_pct` | O19 (H/GT) / O17 (Kuru) | Etiket Bilgileri | Etiket Bilgileri | Kısa Devre Empedansı (%) |
| `tank_type` | G21 (H/GT) / G19 (Kuru) | Etiket Bilgileri | Etiket Bilgileri | Kazan / Tank Tipi |
| `tank_mark_hermetik` | I21 (H) / I19 (Kuru) | Otomatik | Otomatik (Tip Seçimi) | Kazan İşareti (Hermetik 'ü') |
| `tank_mark_gt` | P21 (GT) / P19 (Kuru) | Otomatik | Otomatik (Tip Seçimi) | Kazan İşareti (GT 'ü') |
| `tank_mark_kuru` | U21 (H/GT) / U19 (Kuru) | Otomatik | Otomatik (Tip Seçimi) | Kazan İşareti (Kuru Tip 'ü') |
| `checklist_1` .. `16` | I27/J27 .. R41/S41 | Kontroller | Kontroller | Fiziksel Gözlem ve Kontrol Çiftleri |
| `dc_redresor_voltage` | G31 | Kontroller | Kontroller | DC Redresör Voltajı (24 VDC / 110 VDC / Null) |
| `notes` | B73 (Hermetik/GT) / B67 (Kuru) | **Özet & Bitir (Hatalı Konum)** | **Kontroller (Doğru Konum)** | **ANA SAYFA Not Alanı (Notlar)** |
| `og_rab`, `og_rbc`, `og_rca` | C55, C57, C59 (H/GT) / C49..C53 (Kuru) | Sargı Ölçümleri | Sargı Ölçümleri | OG Sargı Faz-Faz Dirençleri (mΩ) |
| `ag_ran`, `ag_rbn`, `ag_rcn` | J55, J57, J59 (H/GT) / J49..J53 (Kuru) | Sargı Ölçümleri | Sargı Ölçümleri | AG Sargı Nötr Dirençleri (mΩ) |
| `ag_rab`, `ag_rbc`, `ag_rca` | O55, O57, O59 (H/GT) / O49..O53 (Kuru) | Sargı Ölçümleri | Sargı Ölçümleri | AG Sargı Faz-Faz Dirençleri (mΩ) |
| `ground_r_*` (Kuru Tip) | C55, F55, J55, C57, F57, J57 (Kuru) | TTR & Toprak | TTR & Toprak | Topraklama Dirençleri (Kuru Tip ANA SAYFA) |
| `operator_title` | F81 / F74 | Genel Bilgiler | Genel Bilgiler | Operatör Unvanı |
| `operator_name` | F82 / F75 | Genel Bilgiler | Genel Bilgiler | Operatör Adı Soyadı |
| `summary_text` | KAPAK A29 / A31 | Özet & Bitir | Özet & Bitir | Kapak Sayfası Genel Sonuç Özeti |

## 2. Taşınan Alanlar ve Düzenleme Rasyoneli

1. **`notes` (Rapor Notları)**:
   - **Önceki Durum**: Sihirbazın 10. ve son adımı olan `Özet & Bitir` ekranındaydı.
   - **Yeni Durum**: `Kontroller` adımına taşındı. Böylece kullanıcı trafonun fiziki kontrol sonuçlarını işaretlerken aynı sayfada rapora ait ANA SAYFA notlarını da girer.
2. **`tap_info_1/2/3` (Kademe Bilgileri)**:
   - `Etiket Bilgileri` adımında görünür ve düzenlenebilir durumdadır.
3. **`Özet & Bitir` (Son Adım)**:
   - Sadece `summary_text` (Kapak sayfası genel sonuç özeti) ve nihai rapor künyesini içerir. ANA SAYFA verilerini tekrar sormaz.
