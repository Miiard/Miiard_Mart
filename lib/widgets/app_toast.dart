import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/nav_provider.dart';
import '../theme/app_colors.dart';
import 'product_image.dart';

/// Notifikasi pastel melayang di bawah layar.
void showAppToast(
  BuildContext context, {
  required String message,
  String? subtitle,
  IconData icon = Icons.check_circle_rounded,
  Color color = AppColors.mint,
  Widget? leading,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      elevation: 4,
      duration: duration,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      content: Row(
        children: [
          leading ??
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.o(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.ink, size: 22),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppColors.ink,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                  ),
              ],
            ),
          ),
        ],
      ),
      action: actionLabel == null
          ? null
          : SnackBarAction(
              label: actionLabel,
              textColor: AppColors.ink,
              onPressed: onAction ?? () {},
            ),
    ),
  );
}

/// Notifikasi setelah menambah ke keranjang, lengkap dengan tombol "LIHAT".
void showCartToast(
  BuildContext context, {
  required Product product,
  required int added,
}) {
  if (added <= 0) {
    showAppToast(
      context,
      message: product.stock <= 0 ? 'Stok habis' : 'Stok maksimal tercapai',
      subtitle: product.stock <= 0
          ? 'Produk ini sedang tidak tersedia'
          : 'Jumlah di keranjang sudah sama dengan stok',
      icon: Icons.inventory_2_rounded,
      color: AppColors.yellow,
    );
    return;
  }

  final router = GoRouter.of(context);
  final nav = context.read<NavProvider>();
  showAppToast(
    context,
    message: 'Masuk keranjang! 🛍️',
    subtitle: '$added× ${product.title}',
    leading: Container(
      width: 46,
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.o(0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ProductImage(url: product.thumbnail, iconSize: 20),
    ),
    actionLabel: 'LIHAT',
    onAction: () => openCartTab(nav, router),
  );
}
