# Trafo Raporu Excel Hücre Eşleme Denetimi (Mapping Audit)

Bu doküman, mobil uygulamadan ve backend API'den gelen `dataJson` alanlarının Excel rapor sayfalarındaki hangi hücrelere yazıldığını, tarih formatlama kurallarını ve boş alan politikalarını detaylandırır.

---

## 1. Genel Kurallar & Veri Dönüştürme İlkeleri

1. **Tarih Dönüştürme (`date_to_excel_serial`)**:
   - Tarih değerleri (`test_date`, `report_date`) Excel seri tarih numarasına (`epoch 1899-12-30`) dönüştürülür ve hücre biçimi `"dd.mm.yyyy"` olarak ayarlanır.
   - `0`, `0.0`, `None`, `""` veya geçersiz tarih girişlerinde kesinlikle **`00.01.1900` ÜRETİLMEZ**; hücre değeri `None` bırakılarak boş veya varsayılan şablon değerinde kalması sağlanır.

2. **Formül Koruma (`Formula Protection`)**:
   - Şablonda formül içeren hücreler (`=D12`, `='KAPAK SAYFASI'!D9` vb.) dinamik olarak korunur; yalnızca operatör bilgileri ve notlar gibi özel alanlarda formül üzerine yazılır.

3. **Operatör & Unvan Etiket Kuralı**:
   - KAPAK SAYFASI sol alt personel bloğunda (`A52:D55`):
     - `A52`: `İsim Soyad` | `C52`: `:` | `D52`: `{operator_name}`
     - `A53`: `Test Tarihi` | `C53`: `:` | `D53`: `{test_date}` (dd.mm.yyyy)
     - `A54`: `Rapor Tarihi` | `C54`: `:` | `D54`: `{report_date}` (dd.mm.yyyy)
     - `A55`: `Unvan` | `C55`: `:` | `D55`: `{operator_title}`
   - Sağ `ONAYLAYAN` imza alanı tamamen boş kalır.

4. **Boş Form Verisi Politikası**:
   - Formda `field_key` bulunmadığında rastgele veya uydurma veri yazılmaz; numune/örnek metinler temizlenir.

---

## 2. Şablon Türlerine Göre Hücre Mappings

### A) KAPAK SAYFASI
| Alan (field_key) | Hermetik Hücre | GT Hücre | Kuru Tip Hücre | Açıklama |
|---|---|---|---|---|
| `customer_name` | D9 | D9 | D9 | Müşteri / Firma Adı |
| `trafo_label` | D10 | D10 | D10 | Trafo Etiketi / Şalt Sahası |
| `address` | D11 | D11 | D11 | Lokasyon / Adres |
| `report_date` | D12 | D12 | D12 | Rapor Tarihi (dd.mm.yyyy) |
| `test_date` | D14 | D14 | D14 | Test Tarihi (dd.mm.yyyy) |
| `summary_text` | A29 | A29 | A29 | Rapor Özet Metni |
| `operator_name` | D52 | D52 | D52 | Operatör İsim Soyad |
| `operator_title` | D55 | D55 | D55 | Operatör Unvanı |

### B) ANA SAYFA (Trafo Etiket ve Ölçüm Özet Verileri)
| Alan (field_key) | Hermetik Hücre | GT Hücre | Kuru Tip Hücre | Açıklama |
|---|---|---|---|---|
| `brand` | G11 | G11 | G11 | Marka |
| `tap_info_1` | O11 | O11 | O11 | Kademe Bilgisi 1 |
| `tap_info_2` | Q11 | Q11 | Q11 | Kademe Bilgisi 2 |
| `tap_info_3` | S11 | S11 | S11 | Kademe Bilgisi 3 |
| `power_kva` | G13 | G13 | G13 | Güç (kVA) |
| `manufacture_year` | O13 | O13 | O13 | İmal Yılı |
| `voltage` | G15 | G15 | G15 | Gerilim (V) |
| `serial_no` | O15 | O15 | O15 | Seri No |
| `oil_brand` / `weight` | G17 / O17 | G17 / O17 | - | Yağ Markası / Ağırlığı |
| `connection_group` | G19 | G19 | G17 | Bağlantı Grubu |
| `short_circuit_imp_pct` | O19 | O19 | O17 | Kısa Devre Empedansı (%) |
| `og_rab`, `og_rbc`, `og_rca` | C55, C57, C59 | C55, C57, C59 | C49, C51, C53 | OG Sargı Dirençleri (Ω) |
| `ag_ran`, `ag_rbn`, `ag_rcn` | J55, J57, J59 | J55, J57, J59 | J49, J51, J53 | AG Sargı Nötr Dirençleri (mΩ) |
| `ag_rab`, `ag_rbc`, `ag_rca` | O55, O57, O59 | O55, O57, O59 | O49, O51, O53 | AG Sargı Faz Dirençleri (mΩ) |
| `notes` | B73 | B73 | B67 | Notlar Metni |

### C) TOPRAKLAMALAR
| Alan (field_key) | Hermetik Hücre | GT Hücre | Kuru Tip Hücre | Açıklama |
|---|---|---|---|---|
| `operator_name` | D9 | D9 | D9 | Operatör Adı |
| `device_model` | J9 | J9 | J9 | Ölçüm Cihazı Modeli |
| `device_serial` | O9 | O9 | O9 | Ölçüm Cihazı Seri No |
| `ground_r_trafo_body` | D17 | D17 | D17 | Trafo Gövde Topraklama (Ω) |
| `ground_r_neutral` | D18 | D18 | D18 | İşletme Nötr Topraklama (Ω) |
| `ground_r_tank` | D19 | D19 | D19 | Tank / Şasi Topraklama (Ω) |
| `ground_r_og_lightning` | D32 | D32 | D32 | Parafudr Topraklama (Ω) |
| `ground_r_panel` | D33 | D33 | D33 | Pano Topraklama (Ω) |
| `ground_r_fence` | D34 | D34 | D34 | Çit / İhata Topraklama (Ω) |

### D) HERMETİK YAĞ DİLEKÇESİ
| Alan | Hedef Hücre | Değişim Şekli |
|---|---|---|
| Müşteri / Şalt | J2 | `='KAPAK SAYFASI'!D9` (Formül korumalı) |
| Adres / Lokasyon | J3 | `='KAPAK SAYFASI'!D11` (Formül korumalı - `0` yazılması engellendi) |
| Gövde Metni Paragrafı | B10 | Metin içi dinamik regex replace: tarih (`DD.MM.YYYY`), marka (`brand`), güç (`power_kva`), seri no (`serial_no`) |

---

## 3. Alt Sayfalar & Formül Bağlantıları (Sub-Sheet Propagation)

`OG SARGI MEVCUT KADEME`, `AG SARGI`, `İZOLASYON`, `HV PF` ve `LV PF` sayfalarının başlık bloklarında Excel formülleri tanımlıdır:
- `OTURUM TARİHİ` -> `='KAPAK SAYFASI'!D54`
- `Operatör` -> `='OG SARGI MEVCUT KADEME'!D11`
Bu formüller sayesinde KAPAK SAYFASI'na yazılan `test_date`, `report_date` ve `operator_name` tüm alt sayfalara otomatik ve sorunsuz yansımaktadır.
