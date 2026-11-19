import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Тонка обгортка над Firebase Analytics.
/// Помилки аналітики ніколи не повинні ламати застосунок, тому всі виклики
/// огорнуті в try/catch.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics get _fa => FirebaseAnalytics.instance;

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Перегляд екрана (відображається в розділі Analytics → Events → screen_view).
  Future<void> logScreen(String name) => _safe(
        () => _fa.logScreenView(screenName: name, screenClass: name),
      );

  Future<void> logLogin(String method) =>
      _safe(() => _fa.logLogin(loginMethod: method));

  Future<void> logSignUp(String method) =>
      _safe(() => _fa.logSignUp(signUpMethod: method));

  Future<void> logEvent(String name, [Map<String, Object>? params]) =>
      _safe(() => _fa.logEvent(name: name, parameters: params));

  /// Прив'язує події до користувача (null — при виході).
  Future<void> setUser(String? uid) => _safe(() => _fa.setUserId(id: uid));
}
