import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firstflutterproject/product_api.dart';
import 'package:firstflutterproject/product_repository.dart';

class StubAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions) respond;
  StubAdapter(this.respond);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);
  @override
  void close({bool force = false}) {}
}

void main() {
  final products =
      jsonDecode(File('server/data/products.json').readAsStringSync()) as List;

  ProductApiImpl apiWith(ResponseBody Function(RequestOptions) respond) {
    final dio = Dio()..httpClientAdapter = StubAdapter(respond);
    addTearDown(() => dio.close(force: true));
    return ProductApiImpl(dio: dio, baseUrl: 'http://localhost:3000/');
  }

  ResponseBody jsonBody(Object body) => ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  test('repository requests our configured endpoint and parses all nested product data', () async {
    final api = apiWith((options) {
      expect(options.uri.toString(), 'http://localhost:3000/api/products');
      return jsonBody({'products': products, 'total': products.length});
    });
    final result = await ProductRepository(api: api).getProducts();
    expect(result.length, 8);
    expect(result.first.dimensions, isNotNull);
    expect(result.first.reviews, isNotEmpty);
    expect(result.first.meta, isNotNull);
  });

  test('individual product uses the Express details endpoint', () async {
    final api = apiWith((options) {
      expect(options.uri.path, '/api/products/1');
      return jsonBody(products.first);
    });
    expect((await api.getProductById(1)).id, 1);
  });

  test('network failure becomes a helpful repository exception', () async {
    final api = apiWith((options) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    });
    await expectLater(
      ProductRepository(api: api).getProducts(),
      throwsA(
        isA<ProductRepositoryException>().having(
          (e) => e.message,
          'message',
          contains('server'),
        ),
      ),
    );
  });

  test(
    'malformed server data does not silently become an empty catalog',
    () async {
      final api = apiWith(
        (options) => jsonBody({
          'products': [{}],
        }),
      );
      await expectLater(
        ProductRepository(api: api).getProducts(),
        throwsA(isA<ProductRepositoryException>()),
      );
    },
  );
}
