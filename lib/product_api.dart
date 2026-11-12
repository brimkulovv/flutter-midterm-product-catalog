import 'package:dio/dio.dart';

import 'product.dart';
import 'rest_api.dart';

abstract class ProductApi extends RestApi {
  ProductApi({super.baseUrl});
  Future<List<Product>> getProducts();
  Future<Product> getProductById(Object? id);
}

class ProductApiImpl extends ProductApi {
  final Dio _dio;

  ProductApiImpl({Dio? dio, super.baseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  @override
  Future<List<Product>> getProducts() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$baseUrl/api/products',
    );
    final entries = response.data?['products'];
    if (entries is! List) {
      throw const FormatException('Expected a products list from the server');
    }
    return entries
        .map((entry) => Product.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Product> getProductById(Object? id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$baseUrl/api/products/${Uri.encodeComponent(id.toString())}',
    );
    if (response.data == null) {
      throw const FormatException('Expected a product from the server');
    }
    return Product.fromJson(response.data!);
  }
}
