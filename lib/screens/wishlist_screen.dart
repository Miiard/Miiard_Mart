// Mengimpor pustaka utama material design dari Flutter
import 'package:flutter/material.dart';
// Mengimpor paket go_router untuk manajemen navigasi halaman
import 'package:go_router/go_router.dart';
// Mengimpor paket provider untuk mengakses state management
import 'package:provider/provider.dart';

// Mengimpor state provider produk
import '../providers/product_provider.dart';
// Mengimpor konfigurasi warna kustom aplikasi
import '../theme/app_colors.dart';
// Mengimpor konfigurasi gaya teks aplikasi
import '../theme/app_text.dart';
// Mengimpor widget grid produk
import '../widgets/product_grid.dart';
// Mengimpor widget animasi kemunculan (reveal)
import '../widgets/reveal.dart';
// Mengimpor kumpulan widget UI kit tambahan
import '../widgets/ui_kit.dart';

// Kelas WishlistScreen berupa StatelessWidget untuk menampilkan daftar produk favorit pengguna
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Memantau daftar produk favorit dari ProductProvider via state management
    final list = context.watch<ProductProvider>().favoriteProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      // Menggunakan PastelBackdrop sebagai latar belakang dekoratif pastel
      body: PastelBackdrop(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // Bagian Header Atas (Tombol kembali dan Judul Halaman)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                sliver: SliverToBoxAdapter(
                  child: Reveal(
                    child: Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => context.pop(), // Kembali ke halaman sebelumnya saat ditekan
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text.rich(
                            TextSpan(children: [
                              const TextSpan(text: 'Wishlist '),
                              TextSpan(
                                text: 'Favorit',
                                style: AppText.serif(30,
                                    w: FontWeight.w600,
                                    style: FontStyle.italic,
                                    color: AppColors.purpleText,
                                    height: 1.05),
                              ),
                            ]),
                            style: AppText.serif(30, w: FontWeight.w600, height: 1.05),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Pengkondisian tampilan: Jika daftar favorit kosong, tampilkan EmptyState; jika ada, tampilkan grid produk
              if (list.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: 'Belum ada favorit',
                    text: 'Ketuk ikon hati pada produk untuk menyimpannya di sini.',
                    buttonLabel: 'Jelajahi Produk',
                    onButton: () => context.go('/search'), // Navigasi ke halaman pencarian untuk jelajah produk
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                      18, 0, 18, 26 + MediaQuery.paddingOf(context).bottom), // Padding bawah dinamis aman dari notch/system bar
                  sliver: SliverProductGrid(products: list), // Menampilkan grid daftar produk favorit
                ),
            ],
          ),
        ),
      ),
    );
  }
}