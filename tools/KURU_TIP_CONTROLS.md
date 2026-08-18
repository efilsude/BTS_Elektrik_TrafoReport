# Kuru Tip Trafo ANA SAYFA Kontrol Maddeleri (KURU_TIP_CONTROLS)

Bu doküman, Kuru Tip trafolar için **ANA SAYFA** sekmesindeki KONTROLLER bölümünün hücre konumlarını, etiket metinlerini ve form eşleşme anahtarlarını (`checklist_*`) tanımlar.

## 1. Kuru Tip Kontrol Satırları Haritası

| Satır | Sol Etiket (B Sütunu) | G Voltaj Hücresi | Sol Evet/Hayır (I / J) | Sağ Etiket (K Sütunu) | Sağ Evet/Hayır (R / S) | Sol Key / Sağ Key |
|---|---|---|---|---|---|---|
| **27** | Trafo Sıcaklık Kontrolü | - | I27 / J27 | Trafo Temizliği | R27 / S27 | `checklist_1` / `checklist_7` |
| **29** | Fan ON | - | I29 / J29 | Bina Temizliği | R29 / S29 | `checklist_2` / `checklist_8` |
| **31** | DC Redresör Kontrolü | G31 (24 VDC / 110 VDC / Null) | I31 / J31 | Kablo Sıkılık Kontrolü | R31 / S31 | `checklist_3` / `checklist_9` |
| **33** | Termometre Alarm | - | I33 / J33 | Epoksi Kontrolü | R33 / S33 | `checklist_4` / `checklist_10` |
| **35** | Termometre Trip | - | I35 / J35 | Termistor Kontrolü | R35 / S35 | `checklist_5` / `checklist_11` |
| **37** | Fan OFF | - | I37 / J37 | Topraklama Bağlantısı | R37 / S37 | `checklist_6` / `checklist_12` |
| **39** | *(Boş - Yağ/Basınç Maddesi Yok)* | - | *(Temiz)* | *(Boş - Conta Maddesi Yok)* | *(Temiz)* | *(Kullanılmıyor)* |
| **41** | *(Boş - İzolatör Maddesi Yok)* | - | *(Temiz)* | *(Boş - Conta Maddesi Yok)* | *(Temiz)* | *(Kullanılmıyor)* |

## 2. Kuru Tip vs Hermetik/GT Ayrımı

- **Hermetik / GT**: Yağ seviyesi, basınç açma, gaz açma, termik alarm/açma, yağ kaçağı, kademe/OG/AG/kapak conta kontrolleri dahil **16 madde** içerir (satır 27..41 dolu).
- **Kuru Tip**: Yağ, basınç, gaz ve conta maddeleri bulunmaz. Fan ON/OFF, Epoksi, Termistör, Termometre Alarm/Trip maddeleri dahil **12 özel madde** içerir (satır 27..37). Satır 39 ve 41 boştur.
