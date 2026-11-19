import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sentry_flutter/sentry_flutter.dart';

import 'auth_failure.dart';

/// Єдина точка взаємодії застосунку з Firebase Auth.
/// Екрани нічого не знають про FirebaseAuth — лише викликають методи цього
/// класу й отримують або результат, або [AuthFailure] з готовим текстом.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Спільний екземпляр для всього застосунку.
  static final AuthRepository instance = AuthRepository();

  final FirebaseAuth _auth;

  // ---------------------------------------------------------------- стан ----

  /// Події входу / виходу. Саме звідси відновлюється сеанс після перезапуску.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Те саме + події зміни профілю (ім'я, фото, підключені провайдери).
  Stream<User?> userChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  /// Ідентифікатори способів входу поточного користувача
  /// (`password`, `google.com`).
  List<String> get providerIds =>
      _auth.currentUser?.providerData.map((p) => p.providerId).toList() ??
      const [];

  bool get hasPasswordProvider => providerIds.contains('password');
  bool get hasGoogleProvider => providerIds.contains('google.com');

  // --------------------------------------------- реєстрація та вхід ---------

  /// Реєстрація через email/пароль. Ім'я зберігається в профілі користувача.
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _guard(() async {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final name = displayName?.trim();
      if (name != null && name.isNotEmpty) {
        await cred.user?.updateProfile(displayName: name);
        await cred.user?.reload();
      }
    });
  }

  /// Вхід через email/пароль.
  Future<void> signIn({required String email, required String password}) {
    return _guard(() async {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  /// Вхід через Google. Якщо пошта вже є в системі, Firebase (за налаштуванням
  /// «одна пошта — один акаунт») використовує той самий акаунт.
  Future<void> signInWithGoogle() {
    return _guard(() async {
      final provider = GoogleAuthProvider();
      if (kIsWeb) {
        await _auth.signInWithPopup(provider);
      } else {
        await _auth.signInWithProvider(provider);
      }
    });
  }

  /// Лист для скидання пароля.
  Future<void> sendPasswordResetEmail({required String email}) {
    return _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  Future<void> signOut() => _guard(() => _auth.signOut());

  // ------------------------------------------------------------ профіль -----

  /// Оновлює ім'я та/або фото профілю. Фото — лише HTTPS-посилання.
  Future<void> updateProfile({String? displayName, String? photoUrl}) {
    return _guard(() async {
      final user = _requireUser();
      await user.updateProfile(displayName: displayName, photoURL: photoUrl);
      await user.reload();
    });
  }

  /// Оновлює дані поточного користувача із сервера Firebase.
  Future<void> reloadUser() => _guard(() => _requireUser().reload());

  /// Зміна пароля. Firebase вимагає свіжого входу, тому спершу
  /// перевіряємо поточний пароль (повторна автентифікація).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _guard(() async {
      final user = _requireUser();
      final email = user.email;
      if (!hasPasswordProvider || email == null) {
        throw const AuthFailure(
          'Ваш акаунт увійшов через Google — пароля немає. '
          'Скористайтесь функцією «Забули пароль?» на екрані входу, '
          'щоб його створити.',
          code: 'no-password-provider',
        );
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      try {
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          throw const AuthFailure('Поточний пароль введено невірно.',
              code: 'wrong-password');
        }
        rethrow;
      }
      await user.updatePassword(newPassword);
    });
  }

  /// Підключає Google до поточного акаунта (кілька способів входу = один акаунт).
  Future<void> linkGoogle() {
    return _guard(() async {
      final user = _requireUser();
      final provider = GoogleAuthProvider();
      if (kIsWeb) {
        await user.linkWithPopup(provider);
      } else {
        await user.linkWithProvider(provider);
      }
      await user.reload();
    });
  }

  // ---------------------------------------------------------- службове -----

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailure('Сеанс завершено. Увійдіть знову.',
          code: 'no-current-user');
    }
    return user;
  }

  /// Виконує дію й перетворює будь-яку помилку на [AuthFailure].
  /// Неочікувані помилки додатково відправляються в Sentry.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e, st) {
      final failure = AuthFailure.fromException(e);
      if (failure.message.startsWith('Сталася помилка')) {
        await Sentry.captureException(e, stackTrace: st);
      }
      throw failure;
    } catch (e, st) {
      await Sentry.captureException(e, stackTrace: st);
      throw const AuthFailure('Сталася непередбачувана помилка. Спробуйте ще раз.');
    }
  }
}
