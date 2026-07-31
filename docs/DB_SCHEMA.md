# Veritabanı Şeması (v1.0)

> **Sahiplik:** Bu dosyayı SADECE backend ajanı/geliştiricisi günceller (PostgreSQL
> önerilir, bkz. PRD §16). Mobile ajanı salt okur; DB alanları frontend'i doğrudan
> ilgilendirmez ama `data_json` içeriği için referans olabilir.

---

## 1. `users` Tablosu

Kullanıcı hesapları ve kimlik doğrulama verileri.

| Kolon Adı | Veri Tipi | Kısıtlar / Açıklama |
|---|---|---|
| `id` | `INTEGER` | `PRIMARY KEY`, `AUTOINCREMENT` / `SERIAL` |
| `full_name` | `VARCHAR(150)` | `NOT NULL` (Ad Soyad) |
| `phone` | `VARCHAR(30)` | `NOT NULL`, `UNIQUE` (Giriş kimliği) |
| `email` | `VARCHAR(150)` | `NULLABLE`, `UNIQUE` |
| `sicil_no` | `VARCHAR(50)` | `NULLABLE`, `UNIQUE` |
| `password_hash` | `VARCHAR(255)` | `NOT NULL` (bcrypt/argon2 hash) |
| `role` | `VARCHAR(20)` | `NOT NULL`, Default: `'employee'` (`admin` veya `employee`) |
| `is_active` | `BOOLEAN` | `NOT NULL`, Default: `true` |
| `signature_path` | `VARCHAR(255)` | `NULLABLE` (Yüklenen şeffaf PNG imza dosya yolu) |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | `NOT NULL`, Default: `CURRENT_TIMESTAMP` |
| `updated_at` | `TIMESTAMP WITH TIME ZONE` | `NOT NULL`, Default: `CURRENT_TIMESTAMP` |

**İndeksler:**
- `idx_users_phone` (UNIQUE)
- `idx_users_email` (UNIQUE)
- `idx_users_sicil_no` (UNIQUE)

---

## 2. `registration_codes` Tablosu

Admin tarafından oluşturulan tek kullanımlık kayıt davet kodları.

| Kolon Adı | Veri Tipi | Kısıtlar / Açıklama |
|---|---|---|
| `id` | `INTEGER` | `PRIMARY KEY`, `AUTOINCREMENT` / `SERIAL` |
| `code` | `VARCHAR(20)` | `NOT NULL`, `UNIQUE` (Büyük harf/rakam rastgele string) |
| `created_by` | `INTEGER` | `NOT NULL`, `FOREIGN KEY (users.id)` |
| `expires_at` | `TIMESTAMP WITH TIME ZONE` | `NOT NULL` (Oluşturulma + 15 dakika) |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | `NOT NULL`, Default: `CURRENT_TIMESTAMP` |
| `used_at` | `TIMESTAMP WITH TIME ZONE` | `NULLABLE` (Kullanıldığı zaman) |
| `used_by_user_id` | `INTEGER` | `NULLABLE`, `FOREIGN KEY (users.id)` |

**İndeksler:**
- `idx_registration_codes_code` (UNIQUE)

---

## 3. `reports` Tablosu

Saha raporları ve taslak veri kayıtları.

| Kolon Adı | Veri Tipi | Kısıtlar / Açıklama |
|---|---|---|
| `id` | `INTEGER` | `PRIMARY KEY`, `AUTOINCREMENT` / `SERIAL` |
| `title` | `VARCHAR(255)` | `NOT NULL` (Rapor başlığı) |
| `report_type` | `VARCHAR(50)` | `NOT NULL` (`HERMETIK`, `KURU_TIP`, `GT`) |
| `maintenance_type` | `VARCHAR(50)` | `NOT NULL`, Default: `'maintenance'` (`maintenance` veya `test`) |
| `status` | `VARCHAR(20)` | `NOT NULL`, Default: `'draft'` (`draft` veya `final`) |
| `created_by` | `INTEGER` | `NULLABLE`, `FOREIGN KEY (users.id) ON DELETE SET NULL` |
| `creator_display_name` | `VARCHAR(150)` | `NOT NULL` (Kullanıcı silinse dahi saklanan Ad Soyad) |
| `customer_name` | `VARCHAR(255)` | `NOT NULL` (Müşteri Adı / Şalt Sahası) |
| `trafo_label` | `VARCHAR(150)` | `NOT NULL` (Trafo Etiketi / Lokasyon) |
| `test_date` | `DATE` | `NULLABLE` |
| `report_date` | `DATE` | `NULLABLE` |
| `data_json` | `JSON` / `TEXT` | `NOT NULL` (Tüm dinamik form verisi JSON string/dict) |
| `excel_path` | `VARCHAR(255)` | `NULLABLE` (Üretilen .xlsx dosya yolu) |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | `NOT NULL`, Default: `CURRENT_TIMESTAMP` |
| `updated_at` | `TIMESTAMP WITH TIME ZONE` | `NOT NULL`, Default: `CURRENT_TIMESTAMP` |

**İndeksler:**
- `idx_reports_customer_name`
- `idx_reports_status`
- `idx_reports_created_by`

---

## 4. `photos` Tablosu

Raporlara ait yüklenen saha fotoğrafları.

| Kolon Adı | Veri Tipi | Kısıtlar / Açıklama |
|---|---|---|
| `id` | `INTEGER` | `PRIMARY KEY`, `AUTOINCREMENT` / `SERIAL` |
| `report_id` | `INTEGER` | `NOT NULL`, `FOREIGN KEY (reports.id) ON DELETE CASCADE` |
| `photo_type` | `VARCHAR(30)` | `NOT NULL` (`before`, `after`, `label`, `signature`) |
| `file_path` | `VARCHAR(255)` | `NOT NULL` (Görsel dosya yolu) |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | `NOT NULL`, Default: `CURRENT_TIMESTAMP` |

---

## 5. `templates` Tablosu

Yüklenebilir Excel şablon dosyaları ve versiyonları.

| Kolon Adı | Veri Tipi | Kısıtlar / Açıklama |
|---|---|---|
| `id` | `INTEGER` | `PRIMARY KEY`, `AUTOINCREMENT` / `SERIAL` |
| `name` | `VARCHAR(150)` | `NOT NULL` (Şablon görünen adı) |
| `report_type` | `VARCHAR(50)` | `NOT NULL` (`HERMETIK`, `KURU_TIP`, `GT`) |
| `file_path` | `VARCHAR(255)` | `NOT NULL` (.xlsx dosya yolu) |
| `version` | `VARCHAR(20)` | `NOT NULL`, Default: `'1.0'` |
| `uploaded_at` | `TIMESTAMP WITH TIME ZONE` | `NOT NULL`, Default: `CURRENT_TIMESTAMP` |

**İndeksler:**
- `idx_templates_report_type`

---

## 6. `email_verification_codes` Tablosu

Kullanıcı kaydı öncesi e-posta doğrulama için üretilen 6 haneli tek kullanımlık OTP doğrulama kodları.

| Kolon Adı | Veri Tipi | Kısıtlar / Açıklama |
|---|---|---|
| `id` | `INTEGER` | `PRIMARY KEY`, `AUTOINCREMENT` / `SERIAL` |
| `email` | `VARCHAR(150)` | `NOT NULL` (Doğrulanacak e-posta adresi) |
| `code` | `VARCHAR(6)` | `NOT NULL` (6 haneli alfanümerik/sayısal OTP kodu) |
| `purpose` | `VARCHAR(30)` | `NOT NULL`, Default: `'register'` (`register` doğrulama amacı) |
| `expires_at` | `TIMESTAMP WITH TIME ZONE` | `NOT NULL` (Oluşturulma + 10 dakika) |
| `used_at` | `TIMESTAMP WITH TIME ZONE` | `NULLABLE` (Kullanıldığı zaman) |
| `created_at` | `TIMESTAMP WITH TIME ZONE` | `NOT NULL`, Default: `CURRENT_TIMESTAMP` |

**İndeksler:**
- `idx_email_verification_email`
- `idx_email_verification_code`




