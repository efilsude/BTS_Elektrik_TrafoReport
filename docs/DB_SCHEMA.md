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

## 3. Gelecek Faz Tabloları (Özet)

### `templates`
`id, name, report_type (hermetik/kuru/gt/kesici), file_path, mapping_json, version, uploaded_at`

### `reports`
`id, title, report_type, status (draft/final), created_by, creator_display_name, customer_name, trafo_label, test_date, report_date, data_json, excel_path, created_at, updated_at`
- **Önemli:** `creator_display_name` alanı kullanıcı silinse dahi geçmiş raporlarda oluşturucu adını korumak için denormalize saklanır (PRD §15/§24.13).

### `photos`
`id, report_id, photo_type (before/after/label/signature), file_path, created_at`

