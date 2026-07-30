# API Sözleşmesi (v1.0 — FINAL)

> **Sahiplik:** Bu dosyayı SADECE backend ajanı/geliştiricisi günceller. Mobile ajanı
> salt okur ve buradaki sözleşmeye göre kod yazar.
>
> Değişiklik yapan backend ajanı: önce burayı güncelle, sonra `docs/DECISIONS.md`'e
> tarihli not düş ve PR açıklamasında mobile'ı etiketle.


Temel yol: `/api/v1`  
Kimlik doğrulama: JWT (access + refresh). `/auth/*` hariç tüm endpoint'ler geçerli
access token gerektirir (`Authorization: Bearer <token>`).

---

## 1. Genel Standartlar ve Hata Formatı

Başarısız isteklerde HTTP durum kodu 4xx / 5xx döner ve response gövdesi aşağıdaki gibidir:

```json
{
  "error": {
    "code": "INVITE_CODE_INVALID",
    "message": "Davet kodu geçersiz veya süresi dolmuş."
  }
}
```

Yaygın Hata Kodları:
- `UNAUTHORIZED` (401): Geçersiz veya süresi dolmuş token.
- `FORBIDDEN` (403): Yetkisiz işlem (ör. admin yetkisi gerekiyor).
- `NOT_FOUND` (404): İstenen kaynak bulunamadı.
- `VALIDATION_ERROR` (422): Eksik veya hatalı istek gövdesi.
- `INVITE_CODE_INVALID` (400): Davet kodu geçersiz/kullanılmış/süresi dolmuş.
- `USER_ALREADY_EXISTS` (400): Telefon, e-posta veya sicil no zaten kayıtlı.
- `INVALID_CREDENTIALS` (400): Kullanıcı adı veya şifre hatalı.
- `INTERNAL_SERVER_ERROR` (500): Sunucu içi beklenmeyen hata.

---

## 2. Auth Uç Noktaları

### 2.1 POST `/auth/register`
Davet kodu ile yeni çalışan kaydı.

- **İstek (Body):**
```json
{
  "full_name": "Ahmet Yılmaz",
  "phone": "05551112233",
  "email": "ahmet@btselektrik.com",
  "sicil_no": "12345",
  "invite_code": "BTS98765",
  "password": "Password123"
}
```
*`email` ve `sicil_no` isteğe bağlıdır (`null` veya gönderilmeyebilir).*

- **Yanıt (201 Created):**
```json
{
  "id": 2,
  "full_name": "Ahmet Yılmaz",
  "phone": "05551112233",
  "email": "ahmet@btselektrik.com",
  "sicil_no": "12345",
  "role": "employee",
  "is_active": true,
  "created_at": "2026-07-30T16:00:00Z"
}
```

---

### 2.2 POST `/auth/login`
Çalışan veya Admin girişi. `identifier` alanına Telefon, E-posta veya Sicil No girilebilir.

- **İstek (Body):**
```json
{
  "identifier": "05551112233",
  "password": "Password123"
}
```

- **Yanıt (200 OK):**
```json
{
  "access_token": "eyJhbGciOi...",
  "refresh_token": "eyJhbGciOi...",
  "token_type": "bearer",
  "user": {
    "id": 2,
    "full_name": "Ahmet Yılmaz",
    "phone": "05551112233",
    "email": "ahmet@btselektrik.com",
    "sicil_no": "12345",
    "role": "employee",
    "is_active": true,
    "has_signature": false,
    "created_at": "2026-07-30T16:00:00Z"
  }
}
```

---

### 2.3 POST `/auth/refresh`
Access token süresi dolduğunda yenileme.

- **İstek (Body):**
```json
{
  "refresh_token": "eyJhbGciOi..."
}
```

- **Yanıt (200 OK):**
```json
{
  "access_token": "eyJhbGciOi...",
  "token_type": "bearer"
}
```

---

## 3. Kullanıcı / Profil Uç Noktaları

### 3.1 GET `/users/me`
Mevcut oturum açmış kullanıcının profil detayları.

- **Yanıt (200 OK):**
```json
{
  "id": 2,
  "full_name": "Ahmet Yılmaz",
  "phone": "05551112233",
  "email": "ahmet@btselektrik.com",
  "sicil_no": "12345",
  "role": "employee",
  "is_active": true,
  "has_signature": true,
  "created_at": "2026-07-30T16:00:00Z"
}
```

---

### 3.2 PUT `/users/me/password`
Mevcut kullanıcının şifresini değiştirme.

- **İstek (Body):**
```json
{
  "current_password": "OldPassword123",
  "new_password": "NewPassword456"
}
```

- **Yanıt (200 OK):**
```json
{
  "message": "Şifreniz başarıyla değiştirildi."
}
```

---

### 3.3 PUT `/users/me/signature`
Kullanıcının kayıtlı el yazısı imzasını yükleme/güncelleme (multipart/form-data veya base64).

- **İstek (Body - multipart/form-data):** `file`: PNG imza görseli
- **Yanıt (200 OK):**
```json
{
  "message": "İmza başarıyla yüklendi.",
  "has_signature": true
}
```

---

## 4. Admin Uç Noktaları (Sadece Role: `admin`)

### 4.1 POST `/admin/codes`
Tek kullanımlık 15 dk TTL'li davet kodu oluşturma.

- **İstek (Body - Opsiyonel):**
```json
{
  "code": "BTS12345"
}
```
*(Boş gönderilirse sistem otomatik 8 karakterlik rastgele alfanümerik kod üretir).*

- **Yanıt (201 Created):**
```json
{
  "id": 1,
  "code": "BTS12345",
  "created_by": 1,
  "expires_at": "2026-07-30T16:15:00Z",
  "created_at": "2026-07-30T16:00:00Z",
  "used_at": null,
  "used_by_user_id": null,
  "is_valid": true
}
```

---

### 4.2 GET `/admin/codes`
Son üretilen davet kodlarını listeleme.

- **Yanıt (200 OK):**
```json
[
  {
    "id": 1,
    "code": "BTS12345",
    "created_by": 1,
    "expires_at": "2026-07-30T16:15:00Z",
    "created_at": "2026-07-30T16:00:00Z",
    "used_at": "2026-07-30T16:05:00Z",
    "used_by_user_id": 2,
    "is_valid": false
  }
]
```

---

### 4.3 GET `/admin/users`
Kullanıcıları listeleme / arama.

- **Query Parametreleri:**
  - `search` (string, opsiyonel): İsim, telefon veya sicil no araması
  - `role` (string, opsiyonel): `admin` veya `employee`
  - `page` (int, varsayılan: 1)
  - `limit` (int, varsayılan: 20)

- **Yanıt (200 OK):**
```json
{
  "items": [
    {
      "id": 2,
      "full_name": "Ahmet Yılmaz",
      "phone": "05551112233",
      "email": "ahmet@btselektrik.com",
      "sicil_no": "12345",
      "role": "employee",
      "is_active": true,
      "created_at": "2026-07-30T16:00:00Z"
    }
  ],
  "total": 1,
  "page": 1,
  "limit": 20
}
```

---

### 4.4 DELETE `/admin/users/{id}`
Kullanıcıyı devre dışı bırakma / silme.  
*(Not: DB'de `is_active=False` yapılır. Kullanıcının geçmişte oluşturduğu raporlardaki `creator_display_name` alanı bozulmadan korunur).*

- **Yanıt (200 OK):**
```json
{
  "message": "Kullanıcı devre dışı bırakıldı.",
  "user_id": 2
}
```

---

---

## 5. Rapor Havuzu ve Taslak Uç Noktaları (Faz 2)

### 5.1 GET `/reports`
Rapor Havuzu (arama, filtreleme, sayfalama).

- **Query Parametreleri:**
  - `search` (string, opsiyonel): Müşteri adı, trafo etiketi, seri no veya oluşturan adı araması
  - `report_type` (string, opsiyonel): `HERMETIK`, `KURU_TIP`, `GT`
  - `maintenance_type` (string, opsiyonel): `maintenance` veya `test`
  - `status` (string, opsiyonel): `draft` veya `final`
  - `page` (int, varsayılan: 1)
  - `limit` (int, varsayılan: 20)

- **Yanıt (200 OK):**
```json
{
  "items": [
    {
      "id": 10,
      "title": "ABC Fabrikası - TR1 - 30.07.2026",
      "report_type": "HERMETIK",
      "maintenance_type": "maintenance",
      "status": "final",
      "created_by": 2,
      "creator_display_name": "Ahmet Yılmaz",
      "customer_name": "ABC Fabrikası",
      "trafo_label": "TR1",
      "test_date": "2026-07-30",
      "report_date": "2026-07-30",
      "excel_path": "uploads/reports/ABC_Fabrikasi_TR1_30.07.2026.xlsx",
      "created_at": "2026-07-30T16:00:00Z",
      "updated_at": "2026-07-30T16:00:00Z"
    }
  ],
  "total": 1,
  "page": 1,
  "limit": 20
}
```

---

### 5.2 GET `/drafts`
Oturum açmış kullanıcının kendi taslak raporları.

- **Yanıt (200 OK):**
```json
[
  {
    "id": 11,
    "title": "XYZ Tesisleri - TR2 - 30.07.2026",
    "report_type": "KURU_TIP",
    "maintenance_type": "maintenance",
    "status": "draft",
    "created_by": 2,
    "creator_display_name": "Ahmet Yılmaz",
    "customer_name": "XYZ Tesisleri",
    "trafo_label": "TR2",
    "created_at": "2026-07-30T16:10:00Z",
    "updated_at": "2026-07-30T16:15:00Z"
  }
]
```

---

### 5.3 POST `/reports`
Yeni rapor (taslak veya kesinleştirilecek veri gövdesi) oluşturma.

- **İstek (Body):**
```json
{
  "title": "ABC Fabrikası - TR1 - 30.07.2026",
  "report_type": "HERMETIK",
  "maintenance_type": "maintenance",
  "status": "draft",
  "customer_name": "ABC Fabrikası",
  "trafo_label": "TR1",
  "test_date": "2026-07-30",
  "report_date": "2026-07-30",
  "data_json": {
    "brand": "Schneider",
    "power_kva": "1600",
    "serial_no": "SN998877",
    "winding_resistance": {},
    "insulation": {}
  }
}
```

- **Yanıt (201 Created):**
```json
{
  "id": 12,
  "title": "ABC Fabrikası - TR1 - 30.07.2026",
  "report_type": "HERMETIK",
  "maintenance_type": "maintenance",
  "status": "draft",
  "created_by": 2,
  "creator_display_name": "Ahmet Yılmaz",
  "customer_name": "ABC Fabrikası",
  "trafo_label": "TR1",
  "test_date": "2026-07-30",
  "report_date": "2026-07-30",
  "data_json": { ... },
  "excel_path": null,
  "created_at": "2026-07-30T16:20:00Z",
  "updated_at": "2026-07-30T16:20:00Z"
}
```

---

### 5.4 GET `/reports/{id}`
Rapor detayı, tam `data_json` ve bağlı fotoğraflar.

- **Yanıt (200 OK):**
```json
{
  "id": 12,
  "title": "ABC Fabrikası - TR1 - 30.07.2026",
  "report_type": "HERMETIK",
  "maintenance_type": "maintenance",
  "status": "draft",
  "created_by": 2,
  "creator_display_name": "Ahmet Yılmaz",
  "customer_name": "ABC Fabrikası",
  "trafo_label": "TR1",
  "test_date": "2026-07-30",
  "report_date": "2026-07-30",
  "data_json": { ... },
  "excel_path": null,
  "photos": [
    {
      "id": 1,
      "photo_type": "before",
      "file_path": "uploads/photos/report_12_before_abc.jpg",
      "created_at": "2026-07-30T16:22:00Z"
    }
  ],
  "created_at": "2026-07-30T16:20:00Z",
  "updated_at": "2026-07-30T16:20:00Z"
}
```

---

### 5.5 PUT `/reports/{id}`
Taslak raporu güncelleme (sahibi olan teknisyen) veya kesinleşmiş raporu düzenleme (Admin).

- **İstek (Body):**
```json
{
  "title": "ABC Fabrikası - TR1 - 30.07.2026",
  "customer_name": "ABC Fabrikası",
  "trafo_label": "TR1",
  "test_date": "2026-07-30",
  "report_date": "2026-07-30",
  "data_json": { ... }
}
```

- **Yanıt (200 OK):** Güncellenmiş rapor nesnesi.

---

### 5.6 DELETE `/reports/{id}`
Taslak raporu silme (sahip) veya herhangi bir raporu silme (Admin).

- **Yanıt (200 OK):**
```json
{
  "message": "Rapor başarıyla silindi.",
  "report_id": 12
}
```

---

---

### 5.8 POST `/reports/{id}/finalize`
Raporu kesinleştirme ve `.xlsx` Excel dosyasını üretme.

- **Yanıt (200 OK):**
```json
{
  "id": 12,
  "title": "ABC Fabrikası - TR1 - 30.07.2026",
  "status": "final",
  "excel_path": "uploads/reports/ABC_Fabrikasi_TR1_30.07.2026.xlsx",
  "updated_at": "2026-07-30T16:30:00Z"
}
```

---

### 5.9 GET `/reports/{id}/download`
Üretilen `.xlsx` rapor dosyasını indirme (`application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`).

- **Headers:** `Content-Disposition: attachment; filename="ABC Fabrikası - TR1 - 30.07.2026.xlsx"`
- **Response Body:** Binary `.xlsx` file stream.

---

## 6. Şablon Yönetimi Uç Noktaları (Faz 4)

### 6.1 GET `/templates`
Mevcut şablonları listeleme.

- **Yanıt (200 OK):**
```json
[
  {
    "id": 1,
    "name": "HERMETİK TRAFO BAKIM RAPORU HİLMİ.xlsx",
    "report_type": "HERMETIK",
    "version": "1.0",
    "file_path": "templates/HERMETİK TRAFO BAKIM RAPORU HİLMİ.xlsx",
    "uploaded_at": "2026-07-30T16:00:00Z"
  }
]
```

---

### 6.2 POST `/admin/templates`
Yeni `.xlsx` şablon dosyası yükleme ve tipe atama (Sadece Admin).

- **İstek (multipart/form-data):**
  - `name` (string): Şablon adı
  - `report_type` (string): `HERMETIK`, `KURU_TIP`, `GT`
  - `file`: `.xlsx` uzantılı dosya

- **Yanıt (201 Created):**
```json
{
  "id": 4,
  "name": "Yeni Hermetik Şablonu.xlsx",
  "report_type": "HERMETIK",
  "version": "1.1",
  "file_path": "uploads/templates/hermetik_v1.1.xlsx",
  "uploaded_at": "2026-07-30T16:40:00Z"
}
```

---

## 7. Admin İstatistik Uç Noktaları (Faz 4)

### 7.1 GET `/admin/stats`
Gösterge paneli istatistikleri (Sadece Admin).

- **Yanıt (200 OK):**
```json
{
  "total_reports": 15,
  "draft_reports": 3,
  "final_reports": 12,
  "reports_by_type": {
    "HERMETIK": 8,
    "KURU_TIP": 4,
    "GT": 3
  },
  "reports_by_user": [
    { "creator_display_name": "Ahmet Yılmaz", "count": 10 },
    { "creator_display_name": "Mehmet Teknisyen", "count": 5 }
  ],
  "total_active_users": 5,
  "active_invite_codes": 2
}
```





