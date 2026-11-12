import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:firstflutterproject/bloc/product_bloc.dart';
import 'package:firstflutterproject/bloc/product_event.dart';
import 'package:firstflutterproject/bloc/product_state.dart';
import 'package:firstflutterproject/product.dart';
import 'package:firstflutterproject/product_repository.dart';

class StubRepository extends ProductRepository {
  final Future<List<Product>> Function() load;
  int calls = 0;
  StubRepository(this.load);
  @override
  Future<List<Product>> getProducts() {
    calls++;
    return load();
  }
}

void main() {
  final products = [Product(id: 1, title: 'Study headphones')];

  test(
    'initial state and successful loading contain actual products',
    () async {
      final repository = StubRepository(() async => products);
      final bloc = ProductBloc(repository: repository);
      addTearDown(bloc.close);
      expect(bloc.state, isA<ProductInitial>());
      final states = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProductLoading>(),
          isA<ProductLoaded>().having((s) => s.products, 'products', products),
        ]),
      );
      bloc.add(const LoadProducts());
      await states;
      expect(repository.calls, 1);
      expect(
        () => (bloc.state as ProductLoaded).products.clear(),
        throwsUnsupportedError,
      );
    },
  );

  test('API failure emits helpful error', () async {
    final bloc = ProductBloc(
      repository: StubRepository(() async {
        throw const ProductRepositoryException('Catalog server unavailable');
      }),
    );
    addTearDown(bloc.close);
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ProductLoading>(),
        isA<ProductError>().having(
          (s) => s.message,
          'message',
          'Catalog server unavailable',
        ),
      ]),
    );
    bloc.add(const LoadProducts());
    await states;
  });

  test('retry after failure makes another request and succeeds', () async {
    var attempts = 0;
    final repository = StubRepository(() async {
      if (++attempts == 1) throw const ProductRepositoryException('Offline');
      return products;
    });
    final bloc = ProductBloc(repository: repository);
    addTearDown(bloc.close);
    final failed = bloc.stream.firstWhere((state) => state is ProductError);
    bloc.add(const LoadProducts());
    await failed;
    final retried = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ProductLoading>(),
        isA<ProductLoaded>().having((s) => s.products, 'products', products),
      ]),
    );
    bloc.add(const RetryProducts());
    await retried;
    expect(repository.calls, 2);
  });

  test('overlapping events do not issue duplicate requests', () async {
    final pending = Completer<List<Product>>();
    final repository = StubRepository(() => pending.future);
    final bloc = ProductBloc(repository: repository);
    addTearDown(bloc.close);
    final loading = bloc.stream.firstWhere((state) => state is ProductLoading);
    bloc.add(const LoadProducts());
    await loading;
    bloc.add(const RetryProducts());
    bloc.add(const LoadProducts());
    await Future<void>.delayed(Duration.zero);
    expect(repository.calls, 1);
    final loaded = bloc.stream.firstWhere((state) => state is ProductLoaded);
    pending.complete(products);
    await loaded;
  });

  test('empty response is a loaded state', () async {
    final bloc = ProductBloc(repository: StubRepository(() async => []));
    addTearDown(bloc.close);
    final loaded = bloc.stream.firstWhere((state) => state is ProductLoaded);
    bloc.add(const LoadProducts());
    expect((await loaded as ProductLoaded).products, isEmpty);
  });
}
