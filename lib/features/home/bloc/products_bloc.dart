import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/product.dart';
import '../../../core/models/sort_mode.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/utils/formatters.dart';
import '../data/product_repository.dart';

part 'products_event.dart';
part 'products_state.dart';

/// Список продуктів: завантаження, створення, редагування, видалення,
/// пошук, фільтр за категорією та сортування.
/// Фільтр і сортування зберігаються на пристрої ([AppPreferences]).
class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  ProductsBloc({
    required ProductRepository repository,
    required AppPreferences preferences,
    AnalyticsService? analytics,
  })  : _repo = repository,
        _prefs = preferences,
        _analytics = analytics ?? AnalyticsService.instance,
        super(ProductsState(
          sort: preferences.sortMode,
          category: preferences.category,
        )) {
    on<ProductsLoadRequested>(_onLoad);
    on<ProductAdded>(_onAdded);
    on<ProductUpdated>(_onUpdated);
    on<ProductDeleted>(_onDeleted);
    on<ProductQuantityChanged>(_onQuantityChanged);
    on<ProductsQueryChanged>(_onQueryChanged);
    on<ProductsCategoryChanged>(_onCategoryChanged);
    on<ProductsSortChanged>(_onSortChanged);
  }

  final ProductRepository _repo;
  final AppPreferences _prefs;
  final AnalyticsService _analytics;

  // ------------------------------------------------ завантаження списку -----

  Future<void> _onLoad(
    ProductsLoadRequested event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(status: ProductsStatus.loading, clearError: true));
    try {
      final products = await _repo.getProducts();
      emit(state.copyWith(status: ProductsStatus.success, products: products));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(
        status: ProductsStatus.failure,
        error: 'Не вдалося завантажити список продуктів.',
      ));
    }
  }

  // ------------------------------- створення, редагування, видалення --------

  Future<void> _onAdded(
    ProductAdded event,
    Emitter<ProductsState> emit,
  ) {
    return _mutate(
      emit,
      next: [...state.products, event.product],
      persist: () => _repo.addProduct(event.product),
      failureMessage: 'Не вдалося додати продукт.',
      onSuccess: () => _analytics
          .logEvent('product_added', {'category': event.product.category.name}),
    );
  }

  Future<void> _onUpdated(
    ProductUpdated event,
    Emitter<ProductsState> emit,
  ) {
    return _mutate(
      emit,
      next: _replace(event.product),
      persist: () => _repo.updateProduct(event.product),
      failureMessage: 'Не вдалося зберегти зміни.',
    );
  }

  Future<void> _onDeleted(
    ProductDeleted event,
    Emitter<ProductsState> emit,
  ) {
    final removed = _byId(event.id);
    return _mutate(
      emit,
      next: [
        for (final p in state.products)
          if (p.id != event.id) p,
      ],
      persist: () => _repo.deleteProduct(event.id),
      failureMessage: 'Не вдалося видалити продукт.',
      onSuccess: removed == null
          ? null
          : () => _analytics.logEvent(
              'product_deleted', {'category': removed.category.name}),
    );
  }

  Future<void> _onQuantityChanged(
    ProductQuantityChanged event,
    Emitter<ProductsState> emit,
  ) {
    final product = _byId(event.id);
    if (product == null) return Future.value();
    final step = quantityStep(product.unit);
    final next = math.max(0, product.quantity + event.direction * step);
    final updated = product.copyWith(
      quantity: double.parse(next.toStringAsFixed(2)),
    );
    return _mutate(
      emit,
      next: _replace(updated),
      persist: () => _repo.updateProduct(updated),
      failureMessage: 'Не вдалося змінити кількість.',
    );
  }

  /// Оптимістичне оновлення: інтерфейс змінюється одразу, а за помилки
  /// запису список повертається до попереднього стану.
  Future<void> _mutate(
    Emitter<ProductsState> emit, {
    required List<Product> next,
    required Future<void> Function() persist,
    required String failureMessage,
    void Function()? onSuccess,
  }) async {
    final previous = state.products;
    emit(state.copyWith(products: next, clearError: true));
    try {
      await persist();
      onSuccess?.call();
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(products: previous, error: failureMessage));
    }
  }

  // ----------------------------------------- пошук, фільтр, сортування ------

  void _onQueryChanged(
    ProductsQueryChanged event,
    Emitter<ProductsState> emit,
  ) {
    emit(state.copyWith(query: event.query));
  }

  Future<void> _onCategoryChanged(
    ProductsCategoryChanged event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(
      category: event.category,
      clearCategory: event.category == null,
    ));
    await _prefs.setCategory(event.category);
  }

  Future<void> _onSortChanged(
    ProductsSortChanged event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(sort: event.sort));
    await _prefs.setSortMode(event.sort);
  }

  // ------------------------------------------------------- службове --------

  Product? _byId(String id) {
    for (final p in state.products) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Product> _replace(Product updated) => [
        for (final p in state.products) p.id == updated.id ? updated : p,
      ];
}
