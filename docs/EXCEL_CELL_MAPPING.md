# Excel Hücre Eşleme Stratejisi (v0 — taslak)

> **Sahiplik:** Bu dosyayı SADECE backend ajanı/geliştiricisi doldurur — gerçek
> `.xlsx` şablonları (`backend/templates/`) tek tek incelenerek her yazılabilir
> hücrenin adresi burada (ya da eşlik eden bir JSON dosyasında) sabitlenir.
>
> Mobile ajanı burayı SADECE alan anahtarı (`field key`) isimlerini `data_json`
> ile tutarlı tutmak için okur — hücre adresleriyle ilgilenmez.

## Yapı

Her şablon için: `{ "ŞABLON_TİPİ": { "SAYFA_ADI": { "HÜCRE": "field_key", ... } } }`

```json
{
  "HERMETIK": {
    "KAPAK SAYFASI": { "C9": "customer_name", "C10": "trafo_label" },
    "ANA SAYFA": { }
  },
  "KURU_TIP": { },
  "GT": { }
}
```

Eşlemede listelenmeyen hiçbir hücreye dokunulmaz (bkz. kök `CLAUDE.md` mutlak kural 8).

## Ortak alan anahtarları (field keys) — PRD §2.3'ten türetilmiştir

Bu isimler `data_json` ve mobile formundaki alan adlarıyla birebir aynı olmalı:

- `customer_name`, `trafo_label`, `report_date`, `test_date`
- `brand`, `power_kva`, `voltage`, `serial_no`, `manufacture_year`,
  `connection_group`, `short_circuit_imp_pct`, `oil_brand_weight`,
  `tap_info`, `tank_type`
- Ölçüm grupları: `winding_resistance.*`, `insulation.*`, `ttr.*`, `grounding.*`,
  `power_factor.*`, `breaker_contact_resistance.*`, `breaker_timing.*`
- Sonuç/geçti-kaldı alanları: `*_result` (UYGUN / UYGUN DEĞİL)
- `operator_name`, `device_model`, `device_serial`
- Fotoğraflar: `photo_before`, `photo_after`, `photo_label`
- Kapak özet metni: `summary_text`

## Şablona özel alanlar (görünürlük PRD §2.4/§7.2 karar ağacına göre)

| Alan | Sadece hangi tipte |
|---|---|
| `oil_level`, `oil_leak`, `buchholz`, `silica_gel`, `oil_sample`, `oil_addition` | Genleşme Tanklı |
| `pressure_release`, `gas_release` | Hermetik |
| `fan_on_off`, `epoxy`, `thermistor` | Kuru Tip |

## Değişmez kurallar (kök `CLAUDE.md` ve `backend/CLAUDE.md` ile aynı, tekrar vurgu)

- Tarihler Excel seri numarası olarak yazılır (epoch 1899-12-30)
- Sayısal ölçümler sayı olarak yazılır (metin değil)
- Mevcut formüller korunur, sadece değer hücrelerinin üzerine yazılır
- Fotoğraf yer tutucusu yoksa: yeni sayfa açma, mevcut boş hücre/kapak alanına yerleştir

## Açık noktalar (backend doldurmalı)

- [ ] HERMETIK şablonu için tam hücre adresleri (üç sayfa: KAPAK, ANA SAYFA, ...)
- [ ] KURU_TIP şablonu için tam hücre adresleri
- [ ] GT şablonu için tam hücre adresleri
- [ ] Fotoğraf yer tutucu hücre/alan konumları (şablon başına)
- [ ] Kesici alt modülü hücre adresleri (ANA SAYFA KESİCİ, KESİCİ İZOLASYON, KESİCİ KONTAK, AÇMA-KAPAMA)
