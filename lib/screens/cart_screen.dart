import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../providers/nav_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/format.dart';
import '../widgets/app_toast.dart';
import '../widgets/grad_button.dart';
import '../widgets/product_image.dart';
import '../widgets/reveal.dart';
import '../models/product_model.dart';

/// Tab Keranjang: geser untuk hapus (bisa diurungkan), ubah jumlah, ringkasan, checkout.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _checkout(BuildContext context) => context.push('/checkout');

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items;
    final bottomPad = 120 + MediaQuery.of(context).padding.bottom;

    if (items.isEmpty) return _empty(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad),
      children: [
        Reveal(
          child: Row(
            children: [
              Expanded(
                child: Text('Keranjang', style: AppText.serif(size: 30)),
              ),
              Pressable(
                onTap: () {
                  cart.clear();
                  showAppToast(
                    context,
                    message: 'Keranjang dikosongkan',
                    icon: Icons.delete_sweep_rounded,
                    color: AppColors.rose,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.rose,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Kosongkan',
                    style: AppText.sans(size: 12, weight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${cart.totalQuantity} barang • geser ke kiri untuk menghapus',
          style: AppText.sans(size: 12, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < items.length; i++)
          Dismissible(
            key: ValueKey('cart-${items[i].product.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.only(right: 24),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: AppColors.rose,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.ink),
            ),
            onDismissed: (_) {
              final removed = cart.remove(items[i].product.id);
              if (removed == null) return;
              showAppToast(
                context,
                message: 'Dihapus dari keranjang',
                subtitle: removed.item.product.title,
                icon: Icons.delete_outline_rounded,
                color: AppColors.rose,
                actionLabel: 'URUNGKAN',
                onAction: () => cart.restore(removed),
              );
            },
            child: Reveal(
              delayMs: 80 + (i < 6 ? i * 70 : 0),
              child: _CartTile(item: items[i]),
            ),
          ),
        const SizedBox(height: 8),
        Reveal(delayMs: 260, child: _summary(context, cart)),
      ],
    );
  }

  Widget _row(String label, Widget value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: AppText.sans(size: 13, color: AppColors.inkSoft)),
            ),
            value,
          ],
        ),
      );

  Widget _summary(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          _row(
            'Subtotal',
            Text(money(cart.originalTotal), style: AppText.sans(weight: FontWeight.w700)),
          ),
          if (cart.savings > 0.005)
            _row(
              'Hemat diskon',
              Text(
                '- ${money(cart.savings)}',
                style: AppText.sans(weight: FontWeight.w800, color: const Color(0xFF3FA27F)),
              ),
            ),
          _row(
            'Ongkir',
            Text('Gratis', style: AppText.sans(weight: FontWeight.w800, color: const Color(0xFF3FA27F))),
          ),
          const Divider(height: 22, color: AppColors.lavender),
          Row(
            children: [
              Expanded(child: Text('Total', style: AppText.serif(size: 22))),
              CountUpText(
                value: cart.total,
                format: money,
                style: AppText.sans(size: 21, weight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GradButton(
            label: 'Checkout',
            icon: Icons.lock_rounded,
            onTap: () => _checkout(context),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Reveal(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (context, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.ink),
                ),
              ),
              const SizedBox(height: 18),
              Text('Keranjang masih kosong', style: AppText.serif(size: 26)),
              const SizedBox(height: 6),
              Text(
                'Yuk pilih produk pastel favoritmu.',
                style: AppText.sans(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 20),
              GradButton(
                label: 'Mulai belanja',
                icon: Icons.storefront_rounded,
                onTap: () => context.read<NavProvider>().go(0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  final CartItem item;
  const _CartTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final p = item.product;
    final tone = AppColors.toneFor(p.id);

    Widget stepBtn(IconData icon, VoidCallback? onTap) => Pressable(
          scale: 0.85,
          onTap: onTap,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: onTap == null ? AppColors.lavender.o(0.5) : AppColors.lavender,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: AppColors.ink),
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(18)),
            child: ProductImage(url: p.thumbnail, iconSize: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
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
                Text(
                  p.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 13.5, weight: FontWeight.w700, height: 1.25),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    stepBtn(
                      Icons.remove_rounded,
                      item.quantity > 1 ? () => cart.decrement(p.id) : null,
                    ),
                    SizedBox(
                      width: 30,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                        child: Text(
                          '${item.quantity}',
                          key: ValueKey(item.quantity),
                          textAlign: TextAlign.center,
                          style: AppText.sans(size: 14, weight: FontWeight.w800),
                        ),
                      ),
                    ),
                    stepBtn(
                      Icons.add_rounded,
                      item.quantity < p.stock ? () => cart.increment(p.id) : null,
                    ),
                    const Spacer(),
                    Text(
                      money(item.lineTotal),
                      style: AppText.sans(size: 14.5, weight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
