import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/product_grid.dart';
import '../widgets/reveal.dart';

/// Daftar produk yang diberi tanda hati.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favs = context.watch<ProductProvider>().favoriteProducts;
    final bottomPad = 40 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text('Wishlist', style: AppText.serif(size: 28)),
      ),
      body: favs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Reveal(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          color: AppColors.rose,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          size: 42,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Belum ada favorit', style: AppText.serif(size: 26)),
                      const SizedBox(height: 6),
                      Text(
                        'Ketuk ikon hati pada produk untuk menyimpannya di sini.',
                        textAlign: TextAlign.center,
                        style: AppText.sans(color: AppColors.inkSoft, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad),
                  sliver: SliverProductGrid(products: favs),
                ),
              ],
            ),
    );
  }
}
