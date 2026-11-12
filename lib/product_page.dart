import 'package:flutter/material.dart';

import 'widgets/product_view.dart';
import 'product.dart';

class ProductPage extends StatelessWidget {
  final Product product;
  const ProductPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(child: ProductCard(product: product)),
    );
  }
}
