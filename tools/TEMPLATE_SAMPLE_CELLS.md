# TEMPLATE_SAMPLE_CELLS.md — Hermetik Şablon Hücre Taraması ve Örnek Veri Analizi

Bu doküman, `backend/templates/HERMETİK TRAFO BAKIM RAPORU HİLMİ.xlsx` ve `mobile/assets/templates/hermetik.xlsx` şablonlarındaki **örnek veri**, **Hilmi GÜL**, **ONAYLAYAN**, **Personel/İmza**, **Cihaz** ve **NOTLAR** hücrelerinin açık adres ve eşleme haritasını içerir.

---

## 1. "Hilmi GÜL" / Operatör Hücre Listesi

Şablonda operatör adının yazıldığı veya formül ile taşındığı tüm hücreler:

| Sayfa Adı | Hücre Adı | Mevcut Örnek Metin / İçerik | Hücre Tipi | Önerilen `field_key` |
|---|---|---|---|---|
| **OG SARGI MEVCUT KADEME** | `D11` | `Hilmi GÜL` | Metin (Literal) | `operator_name` |
| **AG SARGI** | `D11` | `='OG SARGI MEVCUT KADEME'!D11` | Formül | `operator_name` (Otomatik formül) |
| **İZOLASYON** | `D11` | `='OG SARGI MEVCUT KADEME'!D11` | Formül | `operator_name` (Otomatik formül) |
| **Ç.O 34500** | `D11` | `='OG SARGI MEVCUT KADEME'!D11` | Formül | `operator_name` (Otomatik formül) |
| **TOPRAKLAMALAR** | `D9` | `='OG SARGI MEVCUT KADEME'!D11` | Formül | `operator_name` (Otomatik formül) |
| **HV PF** | `D11` | `='OG SARGI MEVCUT KADEME'!D11` | Formül | `operator_name` (Otomatik formül) |
| **LV PF** | `D11` | `='OG SARGI MEVCUT KADEME'!D11` | Formül | `operator_name` (Otomatik formül) |
| **KESİCİ İZOLASYON** | `D10` | `Hilmi GÜL` | Metin (Literal) | `operator_name` |
| **KESİCİ KONTAK** | `D10` | `Hilmi GÜL` | Metin (Literal) | `operator_name` |
| **AÇMA-KAPAMA** | `D9` | `='KESİCİ İZOLASYON'!D10:G10` | Formül | `operator_name` (Otomatik formül) |
| **DİĞER** | `D9` | `Hilmi GÜL` | Metin (Literal) | `operator_name` |
| **AKIM TRAFOLARI** | `D9` | `='İZOLASYON '!D11:G11` | Formül | `operator_name` (Otomatik formül) |

---

## 2. KAPAK SAYFASI ve ANA SAYFA Personel / İmza / NOTLAR Hücreleri

### KAPAK SAYFASI Alt Blok:
| Hücre Adı | Birleşik Alan (Merged) | Mevcut Şablon Değeri | Açıklama | Önerilen `field_key` |
|---|---|---|---|---|
| `D54` | `D54:F54` | `=D14` | Test Tarihi | `test_date` |
| `D55` | `D55:F55` | `=D12` | Rapor Tarihi | `report_date` |
| `D56` | `D56:F56` | `Elektrik Mühendisi` | Personel Unvanı | `operator_title` / `creator_display_name` |
| `D57` | `D57:F57` | `88258` | Sicil No | `sicil_no` |
| `D58` | `D58:F58` | `K202439698` | Ekipnet No | `ekipnet_no` |
| `G54` | `G54:M54` | `ONAYLAYAN` | Başlık | - |
| `G55` / `G56` | `G55:M58` | Drawing / Görsel | Dijital İmza Çapa (Anchor) | `signature` (Resim Çapası) / `operator_name` |

### ANA SAYFA Alt Blok:
| Hücre Adı | Birleşik Alan (Merged) | Mevcut Şablon Değeri | Açıklama | Önerilen `field_key` |
|---|---|---|---|---|
| `B73` | `B73:V75` | `NOTLAR : Trafonun, trafo odasının, hücre odasının, trafo koruma hücresinin, kesicinin test, kontrol ve temizliği yapıldı. Test sonuçlarının değerlendirilmesi kapak sayfasında yapılmıştır.` | Rapor Notları | `notes` |
| `F78` | `F78:J78` | `='KAPAK SAYFASI'!D55` | Rapor Tarihi | `report_date` (Formül) |
| `F79` | `F79:J79` | `='KAPAK SAYFASI'!D54` | Test Tarihi | `test_date` (Formül) |
| `F80` | `F80:J80` | `='KAPAK SAYFASI'!D56` | Unvan | `operator_title` (Formül) |
| `F81` | `F81:J81` | `='KAPAK SAYFASI'!D57` | Sicil No | `sicil_no` (Formül) |
| `F82` | `F82:J82` | `='KAPAK SAYFASI'!D58` | Ekipnet No | `ekipnet_no` (Formül) |
| `K78` | `K78:S78` | `ONAYLAYAN` | Başlık | - |
| `K79` | `K79:S82` | Drawing / Görsel | Ana Sayfa İmza / Personel Alanı | `operator_name` |

---

## 3. Detay Sayfaları Header Cihaz ve Cihaz S/N Alanları

| Sayfa Adı | Cihaz Modeli Hücresi | Cihaz Seri No Hücresi | Önerilen `field_key` (Model / Serial) |
|---|---|---|---|
| **OG SARGI MEVCUT KADEME** | `J11` (`STS 5000`) | `O11` (`19B20`) | `device_model`, `device_serial` |
| **AG SARGI** | `J11` (`STS 5000`) | `O11` (`19B20`) | `device_model`, `device_serial` |
| **İZOLASYON** | `J11` (`METREL-MI3210`) | `O11` (`16060016`) | `device_model`, `device_serial` |
| **Ç.O 34500** | `J11` (`STS 5000`) | `O11` (`19B20`) | `device_model`, `device_serial` |
| **TOPRAKLAMALAR** | `J9` (`METREL-MI3123`) | `O9` (`16350177`) | `device_model`, `device_serial` |
| **HV PF** | `J11` (`STS 5000`) | `O11` (`19B20`) | `device_model`, `device_serial` |
| **LV PF** | `J11` (`STS 5000`) | `O11` (`19B20`) | `device_model`, `device_serial` |
| **KESİCİ İZOLASYON** | `J10` (`METREL MI 3210`) | `O10` (`16060016`) | `device_model`, `device_serial` |
| **KESİCİ KONTAK** | `J10` (`STS 5000`) | `O10` (`19B20`) | `device_model`, `device_serial` |
| **AÇMA-KAPAMA** | `J9` (`METREL MI 3210`) | `O9` (`16060016`) | `device_model`, `device_serial` |
| **DİĞER** | `D16` / `J9` | `D17` / `O9` | `device_model`, `device_serial` |
| **AKIM TRAFOLARI** | `J9` (`METREL MI 3210`) | `O9` (`16060016`) | `device_model`, `device_serial` |

---

## 4. Detay Sayfaları Örnek Ölçüm Hücreleri Özeti (Temizlik / Ezme İçin)

Aşağıdaki sayısal ölçüm değerleri şablonda örnek veri olarak yer almaktadır. Formda karşılık gelen anahtarlar (`og_rab`, `iso_og_gnd` vb.) dolu girildiğinde ezilmektedir.

- **OG SARGI MEVCUT KADEME**: `F20`, `U21..U23`, `C24..G24`
- **AG SARGI**: `F20`, `U21..U23`, `C24..G24`
- **İZOLASYON**: `X12..AA12`, `B18..H18`, `D16..D17`
- **Ç.O 34500**: `B16..D20`, `F18`, `F19`
- **TOPRAKLAMALAR**: `D16..D19`, `D32..D34`
- **KESİCİ İZOLASYON / KONTAK**: `D10`, `F17`, `N17`, `N18`
- **HERMETİK YAĞ DİLEKÇESİ**: `D16` (Breakdown Voltage), `D18` (Water Content)
