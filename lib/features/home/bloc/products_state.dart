part of 'products_bloc.dart';

enum ProductsStatus { initial, loading, success, failure }

final class ProductsState extends Equatable {
  const ProductsState({
    this.status = ProductsStatus.initial,
    this.products = const [],
    this.query = '',
    this.category,
    this.sort = SortMode.expiry,
    this.error,
  });

  final ProductsStatus status;
  final List<Product> products;
  final String query;
  final ProductCategory? category;
  final SortMode sort;

  /// Повідомлення про помилку (показується snackbar-ом або екраном-заглушкою).
  final String? error;

  /// Продукти після пошуку, фільтра за категорією та сортування.
  List<Product> get visibleProducts {
    final q = query.toLowerCase().trim();
    final list = products.where((p) {
      final matchCategory = category == null || p.category == category;
      final matchQuery = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.place.toLowerCase().contains(q);
      return matchCategory && matchQuery;
    }).toList();

    switch (sort) {
      case SortMode.expiry:
        list.sort((a, b) => a.expiry.compareTo(b.expiry));
      case SortMode.name:
        list.sort((a, b) => a.name.compareTo(b.name));
      case SortMode.category:
        list.sort((a, b) => a.category.label.compareTo(b.category.label));
    }
    return list;
  }

  int count(ExpiryStatus status) =>
      products.where((p) => p.status == status).length;

  ProductsState copyWith({
    ProductsStatus? status,
    List<Product>? products,
    String? query,
    ProductCategory? category,
    bool clearCategory = false,
    SortMode? sort,
    String? error,
    bool clearError = false,
  }) {
    return ProductsState(
      status: status ?? this.status,
      products: products ?? this.products,
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      sort: sort ?? this.sort,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [status, products, query, category, sort, error];
}
