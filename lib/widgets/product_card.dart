import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/format.dart';
import 'app_toast.dart';
import 'cart_button.dart';
import 'fly_to_cart.dart';
import 'product_image.dart';
import 'reveal.dart';

/// Kartu produk pastel: gambar di kotak warna lembut, lencana diskon, hati, dan tombol tambah cepat.
class ProductCard extends StatefulWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final GlobalKey _addKey = GlobalKey();

  void _quickAdd() {
    final p = widget.product;
    final added = context.read<CartProvider>().add(p);
    if (added > 0) {
      flyToCart(
        context,
        from: _addKey,
        to: cartTargetKey,
        imageUrl: p.thumbnail,
      );
    }
    showCartToast(context, product: p, added: added);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final tone = AppColors.toneFor(p.id);
    final fav = context.select<ProductProvider, bool>((m) => m.isFavorite(p.id));
    final hasDiscount = p.discountPercentage >= 1;

    return Pressable(
      scale: 0.97,
      onTap: () => context.push('/detail/${p.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Hero(
                        tag: 'product-image-${p.id}',
                        child: Container(
                          decoration: BoxDecoration(
                            color: tone.bg,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: ProductImage(url: p.thumbnail, iconSize: 34),
                        ),
                      ),
                    ),
                    if (hasDiscount)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.o(0.85),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '-${p.discountPercentage.round()}%',
                            style: AppText.sans(
                              size: 10.5,
                              weight: FontWeight.w800,
                              color: AppColors.heart,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Pressable(
                        scale: 0.85,
                        onTap: () => context.read<ProductProvider>().toggleFavorite(p.id),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.o(0.85),
                            shape: BoxShape.circle,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                            child: Icon(
                              fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              key: ValueKey(fav),
                              size: 18,
                              color: fav ? AppColors.heart : AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 10, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryLabel(p.category).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(
                      size: 9.5,
                      weight: FontWeight.w700,
                      color: AppColors.inkFaint,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 13, weight: FontWeight.w700, height: 1.25),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              money(p.discountedPrice),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.sans(size: 14.5, weight: FontWeight.w800),
                            ),
                            if (hasDiscount)
                              Text(
                                money(p.price),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.sans(
                                  size: 11,
                                  color: AppColors.inkFaint,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Pressable(
                        scale: 0.85,
                        onTap: _quickAdd,
                        child: Container(
                          key: _addKey,
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: AppColors.gradBtn,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.lav2.o(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add_rounded, color: AppColors.ink, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
