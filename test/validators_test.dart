import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/core/utils/validators.dart';

void main() {
  group('email', () {
    test('порожнє поле — помилка', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
    });
    test('некоректний формат — помилка', () {
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email('a b@c.com'), isNotNull);
    });
    test('коректна пошта — ОК', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('  user.name+tag@mail.co.ua '), isNull);
    });
  });

  group('password', () {
    test('коротший за 6 символів — помилка', () {
      expect(Validators.newPassword('12345'), isNotNull);
    });
    test('із пробілом — помилка', () {
      expect(Validators.newPassword('abc 1234'), isNotNull);
    });
    test('коректний — ОК', () {
      expect(Validators.newPassword('secret123'), isNull);
    });
    test('підтвердження має збігатися', () {
      final v = Validators.confirmPassword(() => 'secret123');
      expect(v('other'), isNotNull);
      expect(v(''), isNotNull);
      expect(v('secret123'), isNull);
    });
  });

  group('name', () {
    test('обов’язкове', () => expect(Validators.name('  '), isNotNull));
    test('мінімум 2 символи', () => expect(Validators.name('А'), isNotNull));
    test('коректне', () => expect(Validators.name('Влад'), isNull));
  });

  group('httpsUrl', () {
    test('http не дозволено', () {
      expect(Validators.httpsUrl('http://site.com/a.png'), isNotNull);
    });
    test('не посилання', () {
      expect(Validators.httpsUrl('просто текст'), isNotNull);
    });
    test('https — ОК', () {
      expect(Validators.httpsUrl('https://site.com/a.png'), isNull);
    });
  });

  group('positiveNumber', () {
    test('кома як роздільник', () => expect(Validators.positiveNumber('2,5'), isNull));
    test('нуль і текст — помилка', () {
      expect(Validators.positiveNumber('0'), isNotNull);
      expect(Validators.positiveNumber('abc'), isNotNull);
    });
  });
}
