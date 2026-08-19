import 'package:flutter_test/flutter_test.dart';
import 'package:trafo_report_mobile/utils/validators.dart';

void main() {
  group('Validators Tests', () {
    test('validateFullName enforces non-empty and min length of 2', () {
      expect(Validators.validateFullName(null), 'Ad Soyad zorunludur.');
      expect(Validators.validateFullName(''), 'Ad Soyad zorunludur.');
      expect(Validators.validateFullName('   '), 'Ad Soyad zorunludur.');
      expect(Validators.validateFullName('A'), 'Ad Soyad en az 2 karakter olmalıdır.');
      expect(Validators.validateFullName('Ali Yılmaz'), isNull);
    });

    test('validateTitle enforces non-empty', () {
      expect(Validators.validateTitle(null), 'Unvan zorunludur.');
      expect(Validators.validateTitle(''), 'Unvan zorunludur.');
      expect(Validators.validateTitle('Elektrik Mühendisi'), isNull);
    });

    test('validatePhone enforces 10-11 digit Turkey phone numbers', () {
      expect(Validators.validatePhone(null), 'Telefon numarası zorunludur.');
      expect(Validators.validatePhone('123'), 'Geçerli bir telefon numarası girin (örn. 05XXXXXXXXX).');
      expect(Validators.validatePhone('02123334455'), 'Geçerli bir telefon numarası girin (örn. 05XXXXXXXXX).');
      expect(Validators.validatePhone('05551234567'), isNull);
      expect(Validators.validatePhone('5551234567'), isNull);
      expect(Validators.validatePhone('0 555 123 45 67'), isNull);
    });

    test('validateEmailOptional permits empty and validates format when provided', () {
      expect(Validators.validateEmailOptional(null), isNull);
      expect(Validators.validateEmailOptional(''), isNull);
      expect(Validators.validateEmailOptional('   '), isNull);
      expect(Validators.validateEmailOptional('abc'), 'Geçerli bir e-posta adresi girin.');
      expect(Validators.validateEmailOptional('user@domain.com'), isNull);
    });

    test('validatePassword enforces min length', () {
      expect(Validators.validatePassword(null), 'Şifre zorunludur.');
      expect(Validators.validatePassword('123'), 'Şifre en az 4 karakter olmalıdır.');
      expect(Validators.validatePassword('1234'), isNull);
    });

    test('validateConfirmPassword enforces matching', () {
      expect(Validators.validateConfirmPassword(null, '1234'), 'Şifre tekrarı zorunludur.');
      expect(Validators.validateConfirmPassword('12345', '1234'), 'Şifreler eşleşmiyor.');
      expect(Validators.validateConfirmPassword('1234', '1234'), isNull);
    });
  });
}
