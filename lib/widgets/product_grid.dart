// Mengimpor library utama Flutter untuk membuat antarmuka (UI)
import 'package:flutter/material.dart';
// Mengimpor library go_router untuk mengatur navigasi dan perpindahan halaman
import 'package:go_router/go_router.dart';
// Mengimpor provider untuk mengelola state (seperti data keranjang atau favorit)
import 'package:provider/provider.dart';

// Mengimpor file-file lokal yang dibutuhkan seperti model data, provider, dan komponen UI lainnya
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import 'product_actions.dart';
import 'product_card.dart';
import 'skeleton_card.dart';

// Fungsi bantuan (helper) untuk mengatur tata letak (layout) grid.
// Mengembalikan SliverGridDelegate yang menentukan berapa banyak kolom dan ukurannya.
SliverGridDelegateWithFixedCrossAxisCount _delegate(double width) {
  // Menghitung estimasi lebar satu kartu produk. 
  // (width - 14) / 2 berarti lebar layar dikurangi jarak antar kolom (14), lalu dibagi 2 kolom.
  final cardW = (width - 14) / 2;
  
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2, // Menentukan jumlah kolom ke samping (2 kolom)
    mainAxisSpacing: 14, // Jarak vertikal (atas-bawah) antar kartu produk
    crossAxisSpacing: 14, // Jarak horizontal (kiri-kanan) antar kartu produk
    // Menentukan tinggi pasti dari setiap kartu produk. 
    // Diambil dari lebar foto (cardW - 14) ditambah 96 pixel untuk area teks (judul, harga, dll) agar teks tidak terpotong (overflow).
    mainAxisExtent: (cardW - 14) + 96, 
  );
}

/// Grid 2 kolom berisi kartu produk (sliver).
// StatelessWidget digunakan karena halaman ini hanya menampilkan data dari parameter dan provider, 
// tanpa memiliki state internal yang rumit.
class SliverProductGrid extends StatelessWidget {
  // Daftar produk yang akan ditampilkan di dalam grid
  final List<Product> products;
  
  // Constructor untuk menginisialisasi parameter products
  const SliverProductGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    // context.watch() digunakan untuk 'mendengarkan' perubahan dari ProductProvider.
    // Jika ada produk yang di-favoritkan, UI pada grid ini akan otomatis dirender ulang.
    final prov = context.watch<ProductProvider>();
    
    // SliverLayoutBuilder digunakan untuk mendapatkan batasan ukuran layar saat ini (constraints)
    // Berguna untuk mengukur seberapa lebar layar HP pengguna (c.crossAxisExtent).
    return SliverLayoutBuilder(
      builder: (context, c) => SliverGrid(
        // Menetapkan tata letak grid menggunakan fungsi _delegate yang dibuat di atas
        gridDelegate: _delegate(c.crossAxisExtent),
        // SliverChildBuilderDelegate membuat item grid satu per satu (seperti ListView.builder)
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            // Mengambil satu produk berdasarkan indeks (i) dari list products
            final p = products[i];
            
            // Menampilkan widget custom ProductCard untuk setiap produk
            return ProductCard(
              key: ValueKey(p.id), // Memberikan kunci unik agar Flutter tidak bingung saat me-render ulang
              product: p,
              index: i,
              // Mengecek ke provider apakah produk ini masuk daftar favorit atau tidak
              isFavorite: prov.isFavorite(p.id),
              // Aksi saat produk diklik: Pindah ke halaman detail membawa data produk (p) menggunakan go_router
              onTap: () => context.push('/detail/${p.id}', extra: p),
              // Aksi saat tombol ikon hati (favorit) ditekan
              onFavorite: () => toggleFavoriteWithToast(context, p.id),
              // Aksi saat tombol tambah ke keranjang ditekan
              onAddToCart: () => addToCartWithToast(context, p),
            );
          },
          // Jumlah total item yang akan di-render di dalam grid
          childCount: products.length,
        ),
      ),
    );
  }
}

/// Grid kerangka saat data dimuat.
// Widget ini digunakan untuk menampilkan efek loading (tulang/kerangka) sebelum data asli selesai diunduh dari internet.
class SliverSkeletonGrid extends StatelessWidget {
  // Jumlah kerangka loading yang ingin ditampilkan, default-nya 6.
  final int count;
  
  const SliverSkeletonGrid({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    // Sama seperti SliverProductGrid, menggunakan SliverLayoutBuilder untuk perhitungan grid dinamis
    return SliverLayoutBuilder(
      builder: (context, c) => SliverGrid(
        gridDelegate: _delegate(c.crossAxisExtent), // Memakai aturan ukuran grid yang sama agar transisi ke data asli terlihat mulus
        delegate: SliverChildBuilderDelegate(
          // Merender widget SkeletonCard (kerangka abu-abu loading)
          (context, i) => SkeletonCard(index: i),
          childCount: count, // Menampilkan sebanyak nilai count (6)
        ),
      ),
    );
  }
}