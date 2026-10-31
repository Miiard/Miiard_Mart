// Mengimpor pustaka utama material design dari Flutter untuk komponen UI
import 'package:flutter/material.dart';
// Mengimpor paket go_router untuk manajemen navigasi halaman
import 'package:go_router/go_router.dart';
// Mengimpor paket provider untuk mengakses state management
import 'package:provider/provider.dart';

// Mengimpor model data produk
import '../models/product_model.dart';
// Mengimpor state provider keranjang belanja
import '../providers/cart_provider.dart';
// Mengimpor state provider produk
import '../providers/product_provider.dart';
// Mengimpor konfigurasi warna kustom aplikasi
import '../theme/app_colors.dart';
// Mengimpor widget kustom untuk notifikasi toast
import '../widgets/app_toast.dart';
// Mengimpor widget formulir input data produk
import '../widgets/product_form.dart';

// Kelas EditProductScreen berupa StatelessWidget untuk menampilkan halaman edit produk
class EditProductScreen extends StatelessWidget {
  final Product product; // Menyimpan data produk yang sedang diedit
  const EditProductScreen({super.key, required this.product});

  // Fungsi helper untuk menerapkan perubahan data dari form ke objek Product yang ada
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
        surfaceTintColor: Colors.transparent, // Menghilangkan warna tint material 3 pada scroll
        foregroundColor: AppColors.ink,       // Warna teks dan ikon pada app bar
        elevation: 0,                         // Menghilangkan bayangan di bawah app bar
        title: const Text(
          'Edit Produk',
          style: TextStyle(fontWeight: FontWeight.w800), // Judul teks tebal
        ),
      ),
      body: SafeArea(
        child: ProductForm(
          initial: product,             // Mengisi form awal dengan data produk yang sedang diedit
          submitLabel: 'Perbarui Produk', // Label teks tombol submit pada form
          onSubmit: (data) async {      // Callback ketika formulir disubmit membawa data perubahan
            final provider = context.read<ProductProvider>();
            final cart = context.read<CartProvider>();
            
            // Menerapkan perubahan data ke dalam objek produk baru
            final updated = _applyChanges(data);
            
            // Memanggil fungsi updateProduct untuk memperbarui data ke server/state
            final ok = await provider.updateProduct(product.id, updated);
            
            // Mengecek apakah context masih aktif / mounted
            if (!context.mounted) return;
            
            // Jika pembaruan produk berhasil, sinkronkan juga data produk di keranjang belanja
            if (ok) cart.syncProduct(updated);
            
            // Menampilkan toast notifikasi berhasil atau gagal
            showAppToast(
              context,
              message: ok ? 'Produk berhasil diperbarui' : 'Gagal memperbarui produk',
              icon: ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: ok ? AppColors.mint : AppColors.pink,
            );
            
            // Jika berhasil, kembali ke halaman sebelumnya dan membawa objek hasil update
            if (ok) context.pop(updated);
          },
        ),
      ),
    );
  }
}