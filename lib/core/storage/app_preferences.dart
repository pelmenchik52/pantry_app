import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../models/sort_mode.dart';

/// Сховище даних на пристрої (обгортка над `shared_preferences`).
///
/// На Android/iOS дані лежать у SharedPreferences / NSUserDefaults,
/// на Web — у localStorage браузера. Тут зберігаються:
///  * налаштування застосунку (режим сортування, фільтр категорії);
///  * остання використана електронна пошта (автозаповнення на екрані входу);
///  * кеш списку продуктів кожного користувача (JSON).
///
/// Токени Firebase Auth зберігає сам SDK, тому власної реалізації
/// збереження JWT тут не потрібно.
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  /// Ініціалізація сховища (викликається один раз у `main`).
  static Future<AppPreferences> init() async =>
      AppPreferences(await SharedPreferences.getInstance());

  static const _kSortMode = 'settings.sort_mode';
  static const _kCategory = 'settings.category';
  static const _kLastEmail = 'auth.last_email';
  static const _kProductsPrefix = 'products.';

  // ------------------------------------------------- налаштування -----------

  SortMode get sortMode {
    final name = _prefs.getString(_kSortMode);
    return SortMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => SortMode.expiry,
    );
  }

  Future<void> setSortMode(SortMode mode) =>
      _prefs.setString(_kSortMode, mode.name);

  /// `null` — фільтр «Всі».
  ProductCategory? get category {
    final name = _prefs.getString(_kCategory);
    for (final c in ProductCategory.values) {
      if (c.name == name) return c;
    }
    return null;
  }

  Future<void> setCategory(ProductCategory? category) => category == null
      ? _prefs.remove(_kCategory)
      : _prefs.setString(_kCategory, category.name);

  // ----------------------------------------------------- акаунт ------------

  String get lastEmail => _prefs.getString(_kLastEmail) ?? '';

  Future<void> setLastEmail(String email) =>
      _prefs.setString(_kLastEmail, email);

  // -------------------------------------------- кеш продуктів ---------------

  /// Сирий JSON зі списком продуктів користувача [uid] (або `null`).
  String? readProducts(String uid) => _prefs.getString('$_kProductsPrefix$uid');

  Future<void> writeProducts(String uid, String json) =>
      _prefs.setString('$_kProductsPrefix$uid', json);
}
