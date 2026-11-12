import 'package:dio/dio.dart';

import 'product.dart';
import 'product_api.dart';

class ProductRepositoryException implements Exception {
  final String message;
  const ProductRepositoryException(this.message);
}

class ProductRepository {
  final ProductApi _api;
  ProductRepository({ProductApi? api}) : _api = api ?? ProductApiImpl();

  Future<List<Product>> getProducts() async {
    try {
      return await _api.getProducts();
    } on DioException {
      throw const ProductRepositoryException(
        'Could not load products. Check your connection and make sure the catalog server is running.',
      );
    } on FormatException {
      throw const ProductRepositoryException(
        'The server returned invalid product data.',
      );
    } on TypeError {
      throw const ProductRepositoryException(
        'The server returned invalid product data.',
      );
    }
  }
}
