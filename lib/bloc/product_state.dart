import '../product.dart';

sealed class ProductState {
  const ProductState();
}

final class ProductInitial extends ProductState {
  const ProductInitial();
}

final class ProductLoading extends ProductState {
  const ProductLoading();
}

final class ProductLoaded extends ProductState {
  final List<Product> products;
  ProductLoaded(List<Product> products)
    : products = List.unmodifiable(products);
}

final class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);
}
