// Mengimpor material UI standar dari Flutter
import 'package:flutter/material.dart';

// Mengimpor model data, konfigurasi tema (warna & teks), serta komponen UI kustom lainnya
import '../models/product_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'product_image.dart';
import 'reveal.dart';
import 'ui_kit.dart';

// Widget ProductCard menggunakan StatelessWidget karena tampilannya hanya bergantung pada data 
// yang dikirim dari luar (parameter), tidak menyimpan statenya sendiri.
class ProductCard extends StatelessWidget {
  // Data produk yang akan ditampilkan
  final Product product;
  // Indeks atau urutan produk di dalam list/grid (berguna untuk mengatur delay animasi)
  final int index;
  // Status apakah produk ini disukai/masuk favorit
  final bool isFavorite;
  // Aksi ketika seluruh area kartu diklik
  final VoidCallback onTap;
  // Aksi ketika tombol ikon hati diklik
  final VoidCallback onFavorite;
  // Aksi ketika tombol tambah ke keranjang diklik
  final VoidCallback onAddToCart;

  // Constructor wajib untuk menerima data saat widget ini dipanggil
  const ProductCard({
    super.key,
    required this.product,
    required this.index,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    // Membatasi indeks maksimum di angka 11 agar animasi tidak delay terlalu lama untuk item di bawahnya
    final i = index < 11 ? index : 11;
    
    // Reveal adalah widget kustom (kemungkinan untuk animasi fade-in / slide-up saat pertama kali muncul)
    return Reveal(
      // Mengatur jeda animasi berdasarkan urutan indeks, sehingga muncul bergiliran
      delay: Duration(milliseconds: 120 + i * 60),
      duration: const Duration(milliseconds: 800), // Lama animasi berjalan
      offset: const Offset(0, 24), // Posisi awal animasi (agak ke bawah 24 pixel)
      scaleFrom: .94, // Ukuran awal sebelum animasi (sedikit mengecil 94%)
      // Pressable adalah widget kustom untuk efek ditekan (mengecil) pada kartu
      child: Pressable(
        onTap: onTap,
        scale: .97, // Skala ketika kartu ditekan
        // Wadah utama kartu produk
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24), // Sudut membulat pada kartu
            boxShadow: AppColors.softShadow, // Efek bayangan lembut di belakang kartu
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Menyusun elemen ke kiri
            // Membagi kartu menjadi dua bagian: gambar (_thumb) dan deskripsi (_body)
            children: [_thumb(), _body()],
          ),
        ),
      ),
    );
  }

  // Fungsi bantuan (helper) untuk membuat tombol bulat kecil (digunakan untuk ikon favorit & keranjang)
  Widget _mini({required Widget child, required VoidCallback onTap}) {
    return Pressable(
      onTap: onTap,
      scale: .82, // Efek mengecil saat ikon ini ditekan
      child: Container(
        width: 31,
        height: 31,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .88), // Warna putih dengan sedikit transparansi (88%)
          shape: BoxShape.circle, // Membuat bentuk container menjadi bulat sempurna
        ),
        child: child, // Ikon yang akan dimasukkan ke dalam tombol bulat
      ),
    );
  }

  // Fungsi untuk membangun bagian atas kartu (Thumbnail / Gambar Produk)
  Widget _thumb() {
    // Menghasilkan warna latar belakang dinamis berdasarkan ID produk
    final (bg, _) = AppColors.toneFor(product.id);
    
    return Padding(
      padding: const EdgeInsets.all(7), // Memberi jarak antara tepi kartu dan gambar
      // Memaksa rasio kotak gambar menjadi 1:1 (persegi)
      child: AspectRatio(
        aspectRatio: 1,
        // ClipRRect memastikan gambar atau elemen di dalamnya terpotong mengikuti sudut membulat
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          // Stack digunakan agar kita bisa menumpuk elemen (background, gambar, tombol)
          child: Stack(
            fit: StackFit.expand, // Memenuhi seluruh ruang yang tersedia
            children: [
              // 1. Layer paling bawah: Warna solid
              ColoredBox(color: bg),
              // 2. Layer efek gradasi cahaya dari atas
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -.24),
                    radius: .7,
                    colors: [
                      Colors.white.withValues(alpha: .7),
                      Colors.white.withValues(alpha: 0), // Menghilang (transparan)
                    ],
                  ),
                ),
              ),
              // 3. Layer Gambar Utama Produk
              Padding(
                padding: const EdgeInsets.all(10),
                child: ProductImage(
                  url: product.thumbnail,
                  category: product.category,
                  id: product.id,
                ),
              ),
              // 4. Layer Label Diskon (hanya muncul jika diskon >= 5%)
              if (product.discountPercentage >= 5)
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .88),
                      borderRadius: BorderRadius.circular(999), // Bentuk kapsul
                    ),
                    // Menampilkan angka diskon yang dibulatkan (.round())
                    child: Text('-${product.discountPercentage.round()}%',
                        style: AppText.sans(10, w: FontWeight.w800)),
                  ),
                ),
              // 5. Layer Tombol Favorit (Ikon Hati) di kanan atas
              Positioned(
                right: 8,
                top: 8,
                child: _mini(
                  onTap: onFavorite,
                  // Animasi membesar/mengecil saat ikon hati berubah status (disukai/tidak)
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                    child: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      key: ValueKey(isFavorite), // Key penting agar AnimatedSwitcher tahu widget berubah
                      size: 16,
                      color: isFavorite ? AppColors.heart : AppColors.inkSoft, // Merah jika favorit, abu-abu jika tidak
                    ),
                  ),
                ),
              ),
              // 6. Layer Tombol Tambah ke Keranjang (+) di kanan bawah
              Positioned(
                right: 8,
                bottom: 8,
                child: _mini(
                  onTap: onAddToCart,
                  child: const Icon(Icons.add_rounded, size: 18, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi untuk membangun bagian bawah kartu (Teks judul, kategori, harga, dan rating)
  Widget _body() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 3, 13, 13), // Margin kiri-kanan dan bawah
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul Produk
          Text(product.title,
              maxLines: 1, // Dibatasi 1 baris
              overflow: TextOverflow.ellipsis, // Jika teks kepanjangan akan dipotong menjadi '...'
              style: AppText.sans(12.5, w: FontWeight.w700, height: 1.3)),
          // Nama Kategori (diproses formatnya dengan fungsi prettyCategory)
          Text(prettyCategory(product.category),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sans(10.5, color: AppColors.ink3)),
          
          const SizedBox(height: 8), // Jarak vertikal antara teks kategori dan baris harga
          
          // Baris yang berisi Harga di kiri dan Rating di kanan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Dorong anak ke ujung kiri dan kanan
            children: [
              // Flexible mencegah teks harga menyebabkan error overflow (kepanjangan ke samping)
              Flexible(
                // Menampilkan harga setelah diskon yang diformat dengan fungsi usd()
                child: Text(usd(product.discountedPrice),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(13.5, w: FontWeight.w800)),
              ),
              const SizedBox(width: 6), // Jarak kecil antara harga dan rating
              // Widget kustom bentuk kapsul untuk menampilkan angka rating produk
              RatingPill(rating: product.rating),
            ],
          ),
        ],
      ),
    );
  }
}