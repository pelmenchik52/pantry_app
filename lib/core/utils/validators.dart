/// Валідатори для полів Form. Кожен повертає текст помилки або null (все ОК).
class Validators {
  Validators._();

  static final RegExp _emailRe = RegExp(
    r"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}$",
  );

  static String? required(String? v, [String field = 'Це поле']) {
    if (v == null || v.trim().isEmpty) return '$field обов’язкове';
    return null;
  }

  static String? name(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Введіть ім’я';
    if (value.length < 2) return 'Ім’я має містити щонайменше 2 символи';
    if (value.length > 50) return 'Ім’я занадто довге (максимум 50 символів)';
    return null;
  }

  static String? email(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Введіть електронну пошту';
    if (!_emailRe.hasMatch(value)) {
      return 'Введіть коректну пошту, напр. name@example.com';
    }
    return null;
  }

  /// Пароль для реєстрації / нового пароля.
  static String? newPassword(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Введіть пароль';
    if (value.length < 6) return 'Пароль має містити щонайменше 6 символів';
    if (value.length > 128) return 'Пароль занадто довгий';
    if (value.contains(' ')) return 'Пароль не повинен містити пробілів';
    return null;
  }

  /// Пароль на екрані входу: лише перевірка на порожнє поле.
  static String? passwordRequired(String? v) {
    if (v == null || v.isEmpty) return 'Введіть пароль';
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) {
    return (v) {
      if (v == null || v.isEmpty) return 'Повторіть пароль';
      if (v != original()) return 'Паролі не збігаються';
      return null;
    };
  }

  /// Новий пароль не повинен збігатися зі старим.
  static String? Function(String?) differentFrom(
    String Function() old,
    String message,
  ) {
    return (v) => (v != null && v.isNotEmpty && v == old()) ? message : null;
  }

  /// Посилання на зображення: лише абсолютний HTTPS.
  static String? httpsUrl(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Введіть посилання';
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      return 'Некоректне посилання';
    }
    if (uri.scheme != 'https') return 'Посилання має починатись з https://';
    return null;
  }

  /// Додатне число (кількість продукту). Допускає кому як роздільник.
  static String? positiveNumber(String? v) {
    final value = v?.trim().replaceAll(',', '.') ?? '';
    if (value.isEmpty) return 'Введіть кількість';
    final n = double.tryParse(value);
    if (n == null) return 'Введіть число';
    if (n <= 0) return 'Кількість має бути більшою за 0';
    if (n > 100000) return 'Занадто велике значення';
    return null;
  }

  static String? productName(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Введіть назву продукту';
    if (value.length < 2) return 'Назва занадто коротка';
    if (value.length > 60) return 'Назва занадто довга (максимум 60 символів)';
    return null;
  }

  static String? optionalMaxLength(String? v, int max) {
    if (v != null && v.trim().length > max) {
      return 'Максимум $max символів';
    }
    return null;
  }
}
