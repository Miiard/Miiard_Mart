import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_toast.dart';
import '../widgets/product_form.dart';

class EditProductScreen extends StatelessWidget {
  final Product product;
  const EditProductScreen({super.key, required this.product});

  Product _applyChanges(Map<String, dynamic> data) {
    final thumbnail = (data['thumbnail'] as String?) ?? '';
    final stock = data['stock'] as int;
    return product.copyWith(
      title: data['title'] as String,
      description: data['description'] as String,
      category: data['category'] as String,
      price: data['price'] as double,
      stock: stock,
      brand: data['brand'] as String,
      thumbnail: thumbnail,
      // gambar tambahan dipertahankan bila URL gambar utama tidak diubah
      images: thumbnail == product.thumbnail ? product.images : [thumbnail],
      availabilityStatus:
          stock != product.stock ? (stock > 0 ? 'In Stock' : 'Out of Stock') : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: const Text(
          'Edit Produk',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ProductForm(
          initial: product,
          submitLabel: 'Perbarui Produk',
          onSubmit: (data) async {
            final provider = context.read<ProductProvider>();
            final cart = context.read<CartProvider>();
            final updated = _applyChanges(data);
            final ok = await provider.updateProduct(product.id, updated);
            if (!context.mounted) return;
            if (ok) cart.syncProduct(updated);
            showAppToast(
              context,
              message: ok ? 'Produk berhasil diperbarui' : 'Gagal memperbarui produk',
              subtitle: ok ? null : provider.actionError,
              icon: ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: ok ? AppColors.mint : AppColors.pink,
            );
            if (ok) context.pop(updated);
          },
        ),
      ),
    );
  }
}
