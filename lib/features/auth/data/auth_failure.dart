import 'package:firebase_auth/firebase_auth.dart';

/// Зрозуміла користувачу помилка авторизації.
class AuthFailure implements Exception {
  /// Текст, який показується в інтерфейсі.
  final String message;

  /// Код Firebase (для логів / аналітики).
  final String code;

  /// true — Firebase вимагає свіжого входу (операція чутлива до безпеки).
  final bool requiresRecentLogin;

  /// true — користувач сам закрив вікно входу; помилку показувати не треба.
  final bool cancelled;

  const AuthFailure(
    this.message, {
    this.code = 'unknown',
    this.requiresRecentLogin = false,
    this.cancelled = false,
  });

  /// Перетворює FirebaseAuthException на повідомлення українською.
  factory AuthFailure.fromException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return AuthFailure('Некоректний формат електронної пошти.', code: e.code);
      case 'user-disabled':
        return AuthFailure('Цей акаунт заблоковано.', code: e.code);
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return AuthFailure('Невірна електронна пошта або пароль.', code: e.code);
      case 'email-already-in-use':
        return AuthFailure(
          'Акаунт з такою поштою вже існує. Спробуйте увійти.',
          code: e.code,
        );
      case 'weak-password':
        return AuthFailure(
          'Пароль занадто слабкий. Використайте щонайменше 6 символів.',
          code: e.code,
        );
      case 'operation-not-allowed':
        return AuthFailure(
          'Цей спосіб входу не увімкнено у Firebase Console.',
          code: e.code,
        );
      case 'too-many-requests':
        return AuthFailure(
          'Забагато спроб. Зачекайте кілька хвилин і спробуйте знову.',
          code: e.code,
        );
      case 'network-request-failed':
        return AuthFailure(
          'Немає з’єднання з мережею. Перевірте інтернет.',
          code: e.code,
        );
      case 'requires-recent-login':
        return AuthFailure(
          'Для цієї дії потрібно повторно увійти в акаунт. '
          'Вийдіть і увійдіть знову.',
          code: e.code,
          requiresRecentLogin: true,
        );
      case 'account-exists-with-different-credential':
        return AuthFailure(
          'Ця пошта вже зареєстрована іншим способом входу. '
          'Увійдіть через пошту й пароль, а Google підключіть у профілі.',
          code: e.code,
        );
      case 'credential-already-in-use':
        return AuthFailure(
          'Цей Google-акаунт уже підключений до іншого користувача.',
          code: e.code,
        );
      case 'provider-already-linked':
        return AuthFailure('Цей спосіб входу вже підключено.', code: e.code);
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'popup-blocked':
        return AuthFailure(
          e.code == 'popup-blocked'
              ? 'Браузер заблокував вікно входу. Дозвольте спливні вікна.'
              : 'Вікно входу закрито.',
          code: e.code,
          cancelled: e.code != 'popup-blocked',
        );
      default:
        return AuthFailure(
          'Сталася помилка (${e.code}). Спробуйте ще раз.',
          code: e.code,
        );
    }
  }

  @override
  String toString() => 'AuthFailure($code): $message';
}
