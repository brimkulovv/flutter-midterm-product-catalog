import 'dart:convert';
import 'dart:io';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

void usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('shows loading then empty catalog', (tester) async {
    usePhoneViewport(tester);
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
    usePhoneViewport(tester);
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
    usePhoneViewport(tester);
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

  testWidgets('sample cards fit a phone and expose no inactive cart controls', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final entries = jsonDecode(
      File('server/data/products.json').readAsStringSync(),
    ) as List;
    for (final entry in entries) {
      final product = Product.fromJson(entry as Map<String, dynamic>);
      await tester.pumpWidget(
        MyApp(
          key: ValueKey(product.id),
          repository: WidgetRepository(() async => [product]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add_rounded), findsNothing);
      final title = find.text(product.title!);
      await tester.ensureVisible(title);
      await tester.pumpAndSettle();
      final paragraph = tester.renderObject<RenderParagraph>(title);
      expect(paragraph.didExceedMaxLines, isFalse, reason: product.title);
      expect(tester.takeException(), isNull, reason: product.title);
      await tester.tap(title);
      await tester.pumpAndSettle();
      expect(find.byType(ProductPage), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsNothing);
      await tester.ensureVisible(find.text(product.title!));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: product.title);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ProductPage), findsNothing);
    }
  });
}
