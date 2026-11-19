import '../../../core/models/product.dart';

/// Джерело даних для списку продуктів.
///
/// BLoC залежить лише від цього інтерфейсу, тому локальне сховище
/// пізніше можна замінити на Firestore / REST без змін у BLoC і UI.
abstract class ProductRepository {
  /// Завантажує весь список продуктів поточного користувача.
  Future<List<Product>> getProducts();

  /// Створення.
  Future<void> addProduct(Product product);

  /// Редагування (за `product.id`).
  Future<void> updateProduct(Product product);

  /// Видалення.
  Future<void> deleteProduct(String id);
}
