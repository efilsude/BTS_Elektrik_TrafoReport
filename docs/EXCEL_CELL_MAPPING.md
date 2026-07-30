# Excel Hücre Eşleme Stratejisi (v1.0)

> **Sahiplik:** Bu dosyayı SADECE backend ajanı/geliştiricisi doldurur — gerçek
> `.xlsx` şablonları (`backend/templates/`) tek tek incelenerek her yazılabilir
> hücrenin adresi burada kilitlenmiştir.

---

## 1. Genel Hücre Haritası (Mapping)

```json
{
  "HERMETIK": {
    "KAPAK SAYFASI": {
      "D9": "customer_name",
      "D10": "trafo_label",
      "D11": "address",
      "D12": "report_date",
      "D14": "test_date",
      "D54": "test_date",
      "D55": "report_date",
      "D56": "operator_title",
      "D57": "sicil_no",
      "D58": "ekipnet_no",
      "B31": "summary_text"
    },
    "ANA SAYFA": {
      "K2": "customer_name",
      "K5": "trafo_label",
      "G11": "brand",
      "O11": "tap_info",
      "G13": "power_kva",
      "O13": "manufacture_year",
      "G15": "voltage",
      "O15": "serial_no",
      "G17": "oil_brand",
      "O17": "oil_weight",
      "G19": "connection_group",
      "O19": "short_circuit_imp_pct",
      "G21": "tank_type"
    },
    "OG SARGI MEVCUT KADEME": {
      "K24": "og_r_a",
      "K25": "og_r_b",
      "K26": "og_r_c"
    },
    "AG SARGI": {
      "K24": "ag_r_a",
      "K25": "ag_r_b",
      "K26": "ag_r_c"
    }
  },
  "KURU_TIP": {
    "KAPAK SAYFASI": {
      "D9": "customer_name",
      "D10": "trafo_label",
      "D11": "address",
      "D12": "report_date",
      "D14": "test_date",
      "D54": "test_date",
      "D55": "report_date",
      "D56": "operator_title",
      "D57": "sicil_no",
      "D58": "ekipnet_no",
      "B31": "summary_text"
    },
    "ANA SAYFA": {
      "K2": "customer_name",
      "K5": "trafo_label",
      "G11": "brand",
      "O11": "tap_info",
      "G13": "power_kva",
      "O13": "manufacture_year",
      "G15": "voltage",
      "O15": "serial_no",
      "G19": "connection_group",
      "O19": "short_circuit_imp_pct",
      "G21": "tank_type"
    },
    "OG SARGI MEVCUT KADEME": {
      "K24": "og_r_a",
      "K25": "og_r_b",
      "K26": "og_r_c"
    },
    "AG SARGI": {
      "K24": "ag_r_a",
      "K25": "ag_r_b",
      "K26": "ag_r_c"
    }
  },
  "GT": {
    "KAPAK SAYFASI": {
      "D9": "customer_name",
      "D10": "trafo_label",
      "D11": "address",
      "D12": "report_date",
      "D14": "test_date",
      "D54": "test_date",
      "D55": "report_date",
      "D56": "operator_title",
      "D57": "sicil_no",
      "D58": "ekipnet_no",
      "B31": "summary_text"
    },
    "ANA SAYFA": {
      "K2": "customer_name",
      "K5": "trafo_label",
      "G11": "brand",
      "O11": "tap_info",
      "G13": "power_kva",
      "O13": "manufacture_year",
      "G15": "voltage",
      "O15": "serial_no",
      "G17": "oil_brand",
      "O17": "oil_weight",
      "G19": "connection_group",
      "O19": "short_circuit_imp_pct",
      "G21": "tank_type"
    },
    "OG SARGI MEVCUT KADEME": {
      "K24": "og_r_a",
      "K25": "og_r_b",
      "K26": "og_r_c"
    },
    "AG SARGI": {
      "K24": "ag_r_a",
      "K25": "ag_r_b",
      "K26": "ag_r_c"
    }
  }
}
```

---

## 2. Değişmez Kurallar ve Uygulama Rehberi

1. **Tarih Dönüşümü:** `report_date` ve `test_date` hücrelerine değer yazılırken Excel seri tarihi yazılır (`epoch: 1899-12-30`).
2. **Sayısal Değerler:** Ölçüm değerleri (`power_kva`, `og_r_a`, `ag_r_a` vb.) `float` / `int` olarak aktarılır ki mevcut formüller otomatik çalışabilsin.
3. **Formül Koruma:** Formül içeren hiçbir hücrenin üzerine yazılmaz.
4. **Fotoğraf ve İmza Konumlandırma:**
   - İmza resmi `KAPAK SAYFASI` `G56` hücresi üzerine eklenir.
   - Saha fotoğrafları (`before`, `after`, `label`) `KAPAK SAYFASI` `A35:E48` bölgesindeki mevcut alanlara eklenir; asla yeni sayfa açılmaz.

