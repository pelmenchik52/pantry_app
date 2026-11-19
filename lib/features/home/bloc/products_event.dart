part of 'products_bloc.dart';

sealed class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

/// Завантажити (або перезавантажити) список.
final class ProductsLoadRequested extends ProductsEvent {
  const ProductsLoadRequested();
}

final class ProductAdded extends ProductsEvent {
  const ProductAdded(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}

final class ProductUpdated extends ProductsEvent {
  const ProductUpdated(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}

final class ProductDeleted extends ProductsEvent {
  const ProductDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Кнопки «+» / «−»: [direction] = 1 або -1.
final class ProductQuantityChanged extends ProductsEvent {
  const ProductQuantityChanged(this.id, this.direction);

  final String id;
  final int direction;

  @override
  List<Object?> get props => [id, direction];
}

final class ProductsQueryChanged extends ProductsEvent {
  const ProductsQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// `null` — «Всі категорії».
final class ProductsCategoryChanged extends ProductsEvent {
  const ProductsCategoryChanged(this.category);

  final ProductCategory? category;

  @override
  List<Object?> get props => [category];
}

final class ProductsSortChanged extends ProductsEvent {
  const ProductsSortChanged(this.sort);

  final SortMode sort;

  @override
  List<Object?> get props => [sort];
}
