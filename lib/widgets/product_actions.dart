// Mengimpor pustaka utama material design dari Flutter
import 'package:flutter/material.dart';
// Mengimpor paket provider untuk mengakses state management
import 'package:provider/provider.dart';

// Mengimpor model data produk
import '../models/product_model.dart';
// Mengimpor state provider keranjang belanja
import '../providers/cart_provider.dart';
// Mengimpor state provider produk
import '../providers/product_provider.dart';
// Mengimpor widget notifikasi toast
import 'app_toast.dart';

/// Tambah ke keranjang + toast, dipakai kartu produk dan halaman detail.
// Fungsi global untuk menambahkan produk ke keranjang belanja sekaligus menampilkan notifikasi toast
int addToCartWithToast(BuildContext context, Product p, {int quantity = 1}) {
  // Menambahkan produk ke dalam CartProvider dan mendapatkan jumlah aktual yang berhasil ditambahkan
  final added = context.read<CartProvider>().add(p, quantity: quantity);
  // Menampilkan notifikasi toast keranjang belanja
  showCartToast(context, product: p, added: added);
  return added;
}

// Fungsi global untuk mengubah status favorit (wishlist) suatu produk sekaligus menampilkan notifikasi toast
void toggleFavoriteWithToast(BuildContext context, int id) {
  final prov = context.read<ProductProvider>();
  final was = prov.isFavorite(id); // Mengecek status apakah produk sebelumnya sudah menjadi favorit
  prov.toggleFavorite(id);         // Membalikkan (toggle) status favorit produk di provider
  // Menampilkan notifikasi toast status wishlist
  showAppToast(
    context,
    message: was ? 'Dihapus dari Wishlist' : 'Ditambahkan ke Wishlist',
    icon: Icons.favorite_rounded,
    duration: const Duration(milliseconds: 1600),
  );
}