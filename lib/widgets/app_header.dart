// Mengimpor pustaka utama material design dari Flutter
import 'package:flutter/material.dart';
// Mengimpor paket go_router untuk manajemen navigasi halaman
import 'package:go_router/go_router.dart';
// Mengimpor paket provider untuk mengakses state management
import 'package:provider/provider.dart';

// Mengimpor model data profil pengguna
import '../models/user_profile.dart';
// Mengimpor state provider keranjang belanja
import '../providers/cart_provider.dart';
// Mengimpor konfigurasi warna kustom aplikasi
import '../theme/app_colors.dart';
// Mengimpor konfigurasi gaya teks aplikasi
import '../theme/app_text.dart';
// Mengimpor widget animasi kemunculan (reveal)
import 'reveal.dart';
// Mengimpor kumpulan widget UI kit tambahan
import 'ui_kit.dart';

/// Header tetap: logo, sapaan, dan tombol keranjang dengan badge.
// Kelas AppHeader berupa StatelessWidget untuk menampilkan bagian kepala aplikasi di setiap halaman utama
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // Memantau total kuantitas item di keranjang belanja melalui CartProvider
    final count = context.select<CartProvider, int>((c) => c.totalQuantity);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: const BoxDecoration(
        color: Color(0xD6FFFAF6),
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          // Widget Reveal untuk animasi masuk pada logo merek
          Reveal(
            duration: const Duration(seconds: 1),
            offset: Offset.zero,
            scaleFrom: .7,
            rotateFrom: -.244,
            child: const BrandMark(size: 46),
          ),
          const SizedBox(width: 11),
          // Bagian Teks Judul Toko dan Sapaan Nama Pengguna
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MIIARD.MART',
                    style: AppText.serif(11.5,
                        w: FontWeight.w600,
                        color: AppColors.inkSoft,
                        letterSpacing: 2.8,
                        height: 1.1)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text('Halo, ${kUser.firstName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(14, w: FontWeight.w800)),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFFE9A6C0)),
                  ],
                ),
              ],
            ),
          ),
          // Tombol ikon keranjang belanja di sebelah kanan header
          _BagButton(count: count),
        ],
      ),
    );
  }
}

// Widget privat _BagButton untuk menampilkan tombol keranjang beserta badge jumlah item yang berdenyut (elastic)
class _BagButton extends StatelessWidget {
  final int count;
  const _BagButton({required this.count});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => context.go('/cart'), // Navigasi ke halaman keranjang saat ditekan
      scale: .9,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppColors.softShadow,
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 20, color: AppColors.ink),
            ),
            // Badge jumlah item hanya muncul jika jumlahnya lebih dari 0
            if (count > 0)
              Positioned(
                top: 0,
                right: 0,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(count),
                  tween: Tween(begin: 1.6, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut, // Efek animasi melenting (elastic) saat jumlah item berubah
                  builder: (context, s, child) => Transform.scale(scale: s, child: child),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text('$count',
                        style: AppText.sans(10, w: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}