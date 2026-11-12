import 'package:flutter_bloc/flutter_bloc.dart';

import '../product_repository.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;

  ProductBloc({required this.repository}) : super(const ProductInitial()) {
    on<LoadProducts>(_load);
    on<RetryProducts>(_load);
  }

  Future<void> _load(ProductEvent event, Emitter<ProductState> emit) async {
    // Both event types share this guard to prevent overlapping HTTP requests.
    if (state is ProductLoading) return;
    emit(const ProductLoading());
    try {
      final products = await repository.getProducts();
      if (!emit.isDone) emit(ProductLoaded(products));
    } on ProductRepositoryException catch (error) {
      if (!emit.isDone) emit(ProductError(error.message));
    } catch (_) {
      if (!emit.isDone) {
        emit(
          const ProductError('Unable to load the catalog. Please try again.'),
        );
      }
    }
  }
}
