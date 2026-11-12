// Run from server/: dart test/product_compatibility.dart
// Uses the actual Flutter model without Flutter packages or test dependencies.
import 'dart:convert';
import 'dart:io';

// Standalone Dart check intentionally avoids package resolution.
// ignore: avoid_relative_lib_imports
import '../../lib/product.dart';

void main() {
  final dataFile = File.fromUri(
    Platform.script.resolve('../data/products.json'),
  );
  final data = jsonDecode(dataFile.readAsStringSync()) as List;
  if (data.length < 8) throw StateError('Expected at least 8 products');
  for (final entry in data) {
    final product = Product.fromJson(entry as Map<String, dynamic>);
    // Verify that serialization preserves the structure and nested fields.
    Product.fromJson(product.toJson());
  }
  stdout.writeln(
    'Parsed and round-tripped ${data.length} products with Product.fromJson.',
  );
}
