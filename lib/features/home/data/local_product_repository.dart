import 'dart:async';
import 'dart:convert';

import '../../../core/data/mock_data.dart';
import '../../../core/models/product.dart';
import '../../../core/storage/app_preferences.dart';
import 'product_repository.dart';

/// Реалізація [ProductRepository] на базі локального сховища пристрою.
///
/// Кожен користувач має власний список (ключ `products.<uid>`).
/// Під час першого входу список заповнюється демонстраційними даними.
class LocalProductRepository implements ProductRepository {
  LocalProductRepository({
    required AppPreferences preferences,
    required String userId,
    this.latency = const Duration(milliseconds: 500),
  })  : _prefs = preferences,
        _uid = userId;

  final AppPreferences _prefs;
  final String _uid;

  /// Штучна затримка, що імітує звернення до мережі (видно індикатор завантаження).
  final Duration latency;

  /// Черга записів: послідовні зміни не затирають одна одну.
  Future<void> _tail = Future<void>.value();

  @override
  Future<List<Product>> getProducts() async {
    await Future<void>.delayed(latency);
    final raw = _prefs.readProducts(_uid);
    if (raw == null) {
      final seed = MockData.products();
      await _write(seed);
      return seed;
    }
    return _decode(raw);
  }

  @override
  Future<void> addProduct(Product product) => _mutate((list) {
        list.add(product);
      });

  @override
  Future<void> updateProduct(Product product) => _mutate((list) {
        final i = list.indexWhere((p) => p.id == product.id);
        if (i == -1) {
          throw StateError('Продукт ${product.id} не знайдено');
        }
        list[i] = product;
      });

  @override
  Future<void> deleteProduct(String id) => _mutate((list) {
        list.removeWhere((p) => p.id == id);
      });

  // ---------------------------------------------------------- службове ------

  Future<void> _mutate(void Function(List<Product> list) change) {
    final job = _tail.then((_) async {
      final raw = _prefs.readProducts(_uid);
      final list = raw == null ? MockData.products() : _decode(raw);
      change(list);
      await _write(list);
    });
    // Помилка однієї операції не повинна блокувати наступні.
    _tail = job.catchError((Object _) {});
    return job;
  }

  List<Product> _decode(String raw) {
    final data = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in data) Product.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> _write(List<Product> list) => _prefs.writeProducts(
        _uid,
        jsonEncode([for (final p in list) p.toJson()]),
      );
}
