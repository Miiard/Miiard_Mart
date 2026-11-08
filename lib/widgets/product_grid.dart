import 'package:flutter/material.dart';

import '../models/product_model.dart';
import 'product_card.dart';
import 'reveal.dart';

/// Grid 2 kolom. Kartu pertama muncul bergantian (stagger), sisanya langsung.
class SliverProductGrid extends StatelessWidget {
  final List<Product> products;
  const SliverProductGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final p = products[i];
          final card = ProductCard(key: ValueKey('card-${p.id}'), product: p);
          if (i >= 12) return card;
          return Reveal(
            key: ValueKey('reveal-${p.id}'),
            delayMs: (i ~/ 2) * 80 + (i % 2) * 50,
            dy: 26,
            fromScale: 0.96,
            child: card,
          );
        },
        childCount: products.length,
      ),
    );
  }
}
