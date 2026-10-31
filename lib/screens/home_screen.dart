// Mengimpor pustaka matematika Dart (alias math) untuk fungsi trigonometri (sin, cos, pi)
import 'dart:math' as math;

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
// Mengimpor widget kategori pilihan (chips)
import '../widgets/category_chips.dart';
// Mengimpor widget grid produk
import '../widgets/product_grid.dart';
// Mengimpor widget animasi kemunculan (reveal)
import '../widgets/reveal.dart';
// Mengimpor kumpulan widget UI kit tambahan
import '../widgets/ui_kit.dart';

// Kelas HomeScreen berupa StatelessWidget untuk menampilkan halaman utama aplikasi
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Memantau perubahan state dari ProductProvider
    final prov = context.watch<ProductProvider>();
    // Mendapatkan daftar produk hasil filter tanpa query pencarian teks
    final list = prov.filteredProducts(withQuery: false);
    // Mengecek apakah ini pertama kalinya data sedang dimuat dan list produk masih kosong
    final loadingFirst = prov.loading && prov.allProducts.isEmpty;

    // Menggunakan RefreshIndicator untuk fitur tarik untuk memuat ulang (pull-to-refresh)
    return RefreshIndicator(
      color: AppColors.ink,
      backgroundColor: Colors.white,
      onRefresh: prov.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Bagian Banner Hero di bagian atas
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
            sliver: SliverToBoxAdapter(child: Reveal(child: _Hero())),
          ),
          // Bagian Header dan Chip Kategori Pilihan
          SliverToBoxAdapter(
            child: Reveal(
              delay: const Duration(milliseconds: 75),
              child: Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: SectionHeader(
                        title: 'Kategori Pilihan',
                        trailing: GestureDetector(
                          onTap: () => context.go('/search'), // Navigasi ke halaman pencarian/semua kategori
                          child: Text('Lihat Semua',
                              style: AppText.sans(12, w: FontWeight.w700, color: AppColors.link)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const CategoryChips(), // Widget deretan chip kategori
                  ],
                ),
              ),
            ),
          ),
          // Bagian Header untuk Rekomendasi Produk
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            sliver: SliverToBoxAdapter(
              child: Reveal(
                delay: const Duration(milliseconds: 150),
                child: SectionHeader(
                  title: 'Rekomendasi Untukmu',
                  trailing: Text('${list.length} produk',
                      style: AppText.sans(12, w: FontWeight.w600, color: AppColors.ink3)),
                ),
              ),
            ),
          ),
          // Pengkondisian tampilan berdasarkan status data (Loading, Error, Kosong, atau Menampilkan Grid Produk)
          if (loadingFirst)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 26),
              sliver: SliverSkeletonGrid(), // Menampilkan kerangka loading (skeleton)
            )
          else if (prov.error != null && list.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Gagal memuat produk',
                text: prov.error!,
                buttonLabel: 'Coba lagi',
                onButton: prov.refresh,
              ),
            )
          else if (list.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.search_rounded,
                title: 'Belum ada produk',
                text: 'Tidak ada produk pada kategori ini.',
                buttonLabel: 'Lihat semua kategori',
                onButton: () => prov.setFilterCategory('all'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
              sliver: SliverProductGrid(products: list), // Menampilkan grid produk
            ),
        ],
      ),
    );
  }
}

/// Kartu hero "Flash Sale" dengan gradien yang bergeser pelan.
class _Hero extends StatefulWidget {
  const _Hero();

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  // 18 dtk = 1 siklus gradien = 5 siklus cincin (3,6 dtk) = 3 siklus melayang (6 dtk)
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat(); // Membuat animasi berulang secara terus-menerus

  @override
  void dispose() {
    _c.dispose(); // Membersihkan controller saat widget dihancurkan
    super.dispose();
  }

  // Fungsi helper untuk merender teks kata demi kata dengan animasi Reveal
  Widget _word(String w, int k, {bool em = false}) {
    return Reveal(
      delay: Duration(milliseconds: 400 + k * 110),
      duration: const Duration(milliseconds: 900),
      offset: const Offset(0, 17),
      rotateFrom: .05,
      child: Text(
        w,
        style: AppText.serif(31,
            height: 1,
            style: em ? FontStyle.italic : null,
            w: em ? FontWeight.w600 : FontWeight.w700,
            color: em ? AppColors.purpleText : AppColors.ink),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final drift = (1 - math.cos(2 * math.pi * t)) / 2;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: AppColors.shadow,
            // Membuat efek gradien warna pastel yang bergeser dinamis
            gradient: LinearGradient(
              begin: Alignment(-3 + drift * 2, -1),
              end: Alignment(1 + drift * 2, 1),
              tileMode: TileMode.mirror,
              colors: const [
                Color(0xFFFFD6C0),
                Color(0xFFECD8FB),
                Color(0xFFC8EEE1),
                Color(0xFFFBD5E2),
                Color(0xFFFFD6C0),
              ],
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                right: 14,
                bottom: 14,
                child: _art(t), // Ilustrasi seni hiasan di pojok kanan bawah
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge label "SPESIAL NAZHMI"
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 11, color: Color(0xFF8A5FC8)),
                          const SizedBox(width: 6),
                          Text('SPESIAL NAZHMI',
                              style: AppText.sans(10,
                                  w: FontWeight.w700,
                                  color: Color(0xFF8A5FC8),
                                  letterSpacing: 1.2)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(children: [_word('Flash', 0), const SizedBox(width: 7), _word('Sale', 1)]),
                    Row(children: [
                      _word('Pastel', 2, em: true),
                      const SizedBox(width: 7),
                      _word('Style!', 3),
                    ]),
                    const SizedBox(height: 9),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 170),
                      child: Text('Diskon hingga 50% untuk produk pilihan hari ini.',
                          style: AppText.sans(12, color: const Color(0xFF665878), height: 1.45)),
                    ),
                    const SizedBox(height: 14),
                    // Tombol ajakan bertindak (Call to Action)
                    GradientButton(
                      label: 'Belanja Sekarang',
                      icon: Icons.arrow_forward_rounded,
                      trailingIcon: true,
                      white: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      onTap: () => context.go('/search'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Fungsi helper untuk menggambar efek cincin animasi berdenyut
  Widget _ring(double phase) {
    final p = (phase) % 1;
    return Opacity(
      opacity: ((1 - p) * .9).clamp(0.0, 1.0).toDouble(),
      child: Transform.scale(
        scale: .82 + .5 * p,
        child: Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: .85), width: 1.5),
          ),
        ),
      ),
    );
  }

  // Fungsi helper untuk menggabungkan animasi cincin dan elemen BrandMark yang melayang
  Widget _art(double t) {
    final float = -7 * (1 - math.cos(2 * math.pi * 3 * t)) / 2;
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ring(t * 5),
          _ring(t * 5 + .5),
          Transform.translate(
            offset: Offset(0, float),
            child: const BrandMark(size: 92),
          ),
        ],
      ),
    );
  }
}