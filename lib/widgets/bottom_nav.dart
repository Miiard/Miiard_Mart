// Mengimpor pustaka utama material design dari Flutter
import 'package:flutter/material.dart';

// Mengimpor konfigurasi warna kustom aplikasi
import '../theme/app_colors.dart';
// Mengimpor konfigurasi gaya teks aplikasi
import '../theme/app_text.dart';
// Mengimpor kumpulan widget UI kit tambahan
import 'ui_kit.dart';

// Kelas MiiardBottomNav berupa StatelessWidget untuk menampilkan navigasi bilah bawah kustom (bottom navigation bar)
class MiiardBottomNav extends StatelessWidget {
  final int index;          // Indeks tab yang sedang aktif saat ini
  final ValueChanged<int> onTap; // Callback ketika salah satu item navigasi ditekan

  const MiiardBottomNav({super.key, required this.index, required this.onTap});

  // Daftar item menu navigasi bawah yang berisi pasangan ikon dan label teks
  static const _items = [
    (Icons.home_outlined, 'Beranda'),
    (Icons.search_rounded, 'Cari'),
    (Icons.shopping_bag_outlined, 'Keranjang'),
    (Icons.person_outline_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94), // Latar belakang putih semi-transparan
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)), // Sudut atas melengkung
        boxShadow: const [
          BoxShadow(
            color: Color(0x61483858),
            blurRadius: 30,
            spreadRadius: -18,
            offset: Offset(0, -12), // Efek bayangan lembut di atas bilah navigasi
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
          child: LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth / _items.length; // Menghitung lebar untuk setiap item navigasi
              return SizedBox(
                height: 52,
                child: Stack(
                  children: [
                    // Penanda aktif meluncur (sliding indicator) dengan animasi halus
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutBack, // Efek kurva membal (bounce) yang dinamis
                      left: w * index,
                      top: 0,
                      width: w,
                      child: Center(
                        child: Container(
                          width: 56,
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: AppColors.gradient, // Gradien warna latar penanda aktif
                            borderRadius: BorderRadius.circular(17),
                          ),
                          foregroundDecoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .4),
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                      ),
                    ),
                    // Deretan tombol item navigasi
                    Row(
                      children: [
                        for (var i = 0; i < _items.length; i++)
                          Expanded(
                            child: Pressable(
                              onTap: () => onTap(i), // Memanggil callback saat item ditekan
                              scale: .88,
                              child: _NavItem(
                                icon: _items[i].$1,
                                label: _items[i].$2,
                                active: i == index, // Menandai apakah item ini sedang aktif
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Widget privat _NavItem untuk menampilkan ikon dan label teks pada setiap item navigasi
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _NavItem({required this.icon, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    // Warna ikon dan teks berubah tergantung apakah item sedang aktif atau tidak
    final color = active ? AppColors.ink : AppColors.ink3;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 34,
          child: AnimatedScale(
            scale: active ? 1.08 : 1, // Ikon sedikit membesar saat aktif
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            child: Icon(icon, size: 21, color: color),
          ),
        ),
        const SizedBox(height: 3),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 350),
          style: AppText.sans(10, w: FontWeight.w700, color: color),
          child: Text(label),
        ),
      ],
    );
  }
}