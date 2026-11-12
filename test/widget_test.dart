import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firstflutterproject/main.dart';
import 'package:firstflutterproject/product.dart';
import 'package:firstflutterproject/product_page.dart';
import 'package:firstflutterproject/widgets/product_view.dart';
import 'package:firstflutterproject/product_repository.dart';

class WidgetRepository extends ProductRepository {
  final Future<List<Product>> Function() load;
  WidgetRepository(this.load);
  @override
  Future<List<Product>> getProducts() => load();
}

void main() {
  testWidgets('shows loading then empty catalog', (tester) async {
    final pending = Completer<List<Product>>();
    await tester.pumpWidget(
      MyApp(repository: WidgetRepository(() => pending.future)),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No products available yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failure shows message and Retry reloads catalog', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      MyApp(
        repository: WidgetRepository(() async {
          if (++attempts == 1) {
            throw const ProductRepositoryException('Server unavailable');
          }
          return [];
        }),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Server unavailable'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('No products available yet.'), findsOneWidget);
  });

  testWidgets('catalog cards open details and return without layout errors', (
    tester,
  ) async {
    final product = Product(id: 1, title: 'Study headphones', price: 79.99);
    await tester.pumpWidget(
      MyApp(repository: WidgetRepository(() async => [product])),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProductCard), findsOneWidget);
    await tester.ensureVisible(find.text('Study headphones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Study headphones'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductPage), findsOneWidget);
    expect(find.text('Study headphones'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ProductPage), findsNothing);
    expect(find.byType(ProductCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
