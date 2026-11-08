import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_toast.dart';
import '../widgets/product_form.dart';

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

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
          'Tambah Produk',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ProductForm(
          submitLabel: 'Simpan Produk',
          onSubmit: (data) async {
            final provider = context.read<ProductProvider>();
            final ok = await provider.addProduct(data);
            if (!context.mounted) return;
            showAppToast(
              context,
              message: ok ? 'Produk berhasil ditambahkan' : 'Gagal menambahkan produk',
              subtitle: ok ? null : provider.actionError,
              icon: ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: ok ? AppColors.mint : AppColors.pink,
            );
            if (ok) context.pop();
          },
        ),
      ),
    );
  }
}
