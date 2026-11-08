import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/nav_provider.dart';
import '../theme/app_colors.dart';
import 'reveal.dart';

/// Target animasi "terbang ke keranjang" pada header beranda.
final GlobalKey cartTargetKey = GlobalKey(debugLabel: 'cartTarget');

/// Ikon keranjang dengan lencana jumlah yang membal saat bertambah.
class CartButton extends StatelessWidget {
  final GlobalKey? targetKey;
  final VoidCallback? onTap;

  const CartButton({super.key, this.targetKey, this.onTap});

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartProvider, int>((c) => c.totalQuantity);
    return Pressable(
      onTap: onTap ??
          () => openCartTab(context.read<NavProvider>(), GoRouter.of(context)),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              key: targetKey,
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppColors.softShadow,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.ink,
                size: 22,
              ),
            ),
            if (count > 0)
              Positioned(
                right: 0,
                top: 0,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(count),
                  tween: Tween<double>(begin: 0.4, end: 1),
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.elasticOut,
                  builder: (context, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: AppColors.heart,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
