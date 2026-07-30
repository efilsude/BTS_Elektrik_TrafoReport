# API Sözleşmesi (v1.0)

> **Sahiplik:** Bu dosyayı SADECE backend ajanı/geliştiricisi günceller. Mobile ajanı
> salt okur ve buradaki sözleşmeye göre kod yazar. Bir alan/endpoint burada yoksa
> mobile tarafı onu varsaymaz — `docs/DECISIONS.md`'e istek olarak düşer.
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

## 5. Gelecek Faz Uç Noktaları (Faz 2 - 4)

- `GET /templates`
- `POST /admin/templates`
- `GET /reports`
- `POST /reports`
- `GET /reports/{id}`
- `PUT /reports/{id}`
- `POST /reports/{id}/finalize`
- `GET /reports/{id}/download`
- `POST /reports/{id}/photos`
- `GET /drafts`
- `DELETE /reports/{id}`

