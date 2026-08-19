class Validators {
  /// Validates Full Name (Ad Soyad)
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ad Soyad zorunludur.';
    }
    if (value.trim().length < 2) {
      return 'Ad Soyad en az 2 karakter olmalıdır.';
    }
    return null;
  }

  /// Validates Operator Title (Unvan)
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Unvan zorunludur.';
    }
    return null;
  }

  /// Validates Phone Number (Telefon)
  /// Cleans non-digits, checks for 10-11 digit Turkey phone format (5XXXXXXXXX or 05XXXXXXXXX)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefon numarası zorunludur.';
    }
    final String cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^(05\d{9}|5\d{9})$').hasMatch(cleaned)) {
      return 'Geçerli bir telefon numarası girin (örn. 05XXXXXXXXX).';
    }
    return null;
  }

  /// Validates Optional Email (E-posta)
  static String? validateEmailOptional(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Empty is valid since email is optional
    }
    final String trimmed = value.trim();
    final RegExp emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegExp.hasMatch(trimmed)) {
      return 'Geçerli bir e-posta adresi girin.';
    }
    return null;
  }

  /// Validates Required Password (Şifre)
  static String? validatePassword(String? value, {int minLength = 4}) {
    if (value == null || value.isEmpty) {
      return 'Şifre zorunludur.';
    }
    if (value.length < minLength) {
      return 'Şifre en az $minLength karakter olmalıdır.';
    }
    return null;
  }

  /// Validates Optional Password (Yeni Şifre - Edit User)
  static String? validatePasswordOptional(String? value, {int minLength = 4}) {
    if (value == null || value.isEmpty) {
      return null; // Empty is valid (do not change password)
    }
    if (value.length < minLength) {
      return 'Şifre en az $minLength karakter olmalıdır.';
    }
    return null;
  }

  /// Validates Confirm Password (Şifre Tekrar)
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Şifre tekrarı zorunludur.';
    }
    if (value != password) {
      return 'Şifreler eşleşmiyor.';
    }
    return null;
  }
}
