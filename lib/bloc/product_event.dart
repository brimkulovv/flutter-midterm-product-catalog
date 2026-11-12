sealed class ProductEvent {
  const ProductEvent();
}

final class LoadProducts extends ProductEvent {
  const LoadProducts();
}

final class RetryProducts extends ProductEvent {
  const RetryProducts();
}
