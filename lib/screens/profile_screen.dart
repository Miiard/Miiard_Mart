// Mengimpor pustaka matematika Dart (alias math) untuk perhitungan geometri (lingkaran/sudut)
import 'dart:math' as math;

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
// Mengimpor state provider produk
import '../providers/product_provider.dart';
// Mengimpor konfigurasi warna kustom aplikasi
import '../theme/app_colors.dart';
// Mengimpor konfigurasi gaya teks aplikasi
import '../theme/app_text.dart';
// Mengimpor widget kustom untuk notifikasi toast
import '../widgets/app_toast.dart';
// Mengimpor widget animasi kemunculan (reveal)
import '../widgets/reveal.dart';
// Mengimpor kumpulan widget UI kit tambahan
import '../widgets/ui_kit.dart';

// Kelas ProfileScreen berupa StatelessWidget untuk menampilkan halaman profil pengguna
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Memantau data statistik pesanan, jumlah item di keranjang, dan total produk favorit via provider
    final orders = context.select<CartProvider, int>((c) => c.orders);
    final inCart = context.select<CartProvider, int>((c) => c.totalQuantity);
    final favs = context.select<ProductProvider, int>((p) => p.favoritesCount);

    // Fungsi helper lokal untuk menampilkan toast notifikasi fitur yang segera hadir
    void soon(String name) => showAppToast(
          context,
          message: '$name segera hadir',
          icon: Icons.auto_awesome_rounded,
          duration: const Duration(milliseconds: 1700),
        );

    // Daftar menu opsi navigasi pada halaman profil beserta ikon, warna latar, dan aksi ketuknya
    final menu = <(IconData, String, Color, VoidCallback)>[
      (Icons.inventory_2_outlined, 'Pesanan Saya', AppColors.lavender, () => soon('Pesanan Saya')),
      (Icons.favorite_border_rounded, 'Wishlist Favorit', AppColors.pink, () => context.push('/wishlist')),
      (Icons.place_outlined, 'Alamat Pengiriman', AppColors.mint, () => soon('Alamat Pengiriman')),
      (Icons.tune_rounded, 'Pengaturan Akun', AppColors.yellow, () => soon('Pengaturan Akun')),
      (Icons.add_box_outlined, 'Tambah Produk', AppColors.peach, () => context.push('/add')),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 26),
      children: [
        // Bagian Informasi Header Profil (Avatar, Nama, dan Email Pengguna)
        Reveal(
          child: Column(
            children: [
              const _Avatar(),
              const SizedBox(height: 14),
              Text(kUser.name, style: AppText.serif(26, height: 1.1)),
              const SizedBox(height: 3),
              Text(kUser.email, style: AppText.sans(13, color: AppColors.inkSoft)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Bagian Kartu Statistik Ringkasan (Pesanan, Favorit, Keranjang)
        Reveal(
          delay: const Duration(milliseconds: 75),
          child: Row(
            children: [
              Expanded(child: _Stat(value: orders, label: 'Pesanan', color: AppColors.peach)),
              const SizedBox(width: 9),
              Expanded(child: _Stat(value: favs, label: 'Favorit', color: AppColors.pink)),
              const SizedBox(width: 9),
              Expanded(child: _Stat(value: inCart, label: 'Keranjang', color: AppColors.mint)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Bagian Daftar Menu Navigasi Profil
        Reveal(
          delay: const Duration(milliseconds: 150),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              children: [
                for (final m in menu)
                  Pressable(
                    onTap: m.$4,
                    scale: .98,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: m.$3,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(m.$1, size: 17, color: AppColors.ink),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(m.$2, style: AppText.sans(12.5, w: FontWeight.w700))),
                          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.ink3),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Bagian Logo Gambar di bagian bawah halaman profil
        Reveal(
          delay: const Duration(milliseconds: 225),
          child: Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Center(
              child: Opacity(
                opacity: .9,
                child: SizedBox(
                  width: 170,
                  child: AspectRatio(
                    aspectRatio: 491 / 466,
                    child: Image.asset('assets/images/logo.webp', fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Widget privat _Stat untuk menampilkan kotak kartu statistik angka dengan animasi
class _Stat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _Stat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text('$v', style: AppText.serif(26, height: 1)),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppText.sans(10.5, w: FontWeight.w700, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

// Widget privat _Avatar untuk menampilkan foto profil/avatar dengan efek lingkaran putus-putus berputar
class _Avatar extends StatefulWidget {
  const _Avatar();

  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> with SingleTickerProviderStateMixin {
  // Controller animasi putar lambat untuk lingkaran putus-putus (durasi 26 detik)
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 26))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _c,
            child: CustomPaint(size: const Size(110, 110), painter: _DashedCircle()),
          ),
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: AppColors.shadow,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD6C0), Color(0xFFE5D6FB), Color(0xFFC8EEE1)],
                stops: [0, .55, 1],
              ),
            ),
            // Menampilkan huruf pertama dari nama depan pengguna di dalam avatar
            child: Text(kUser.firstName.substring(0, 1), style: AppText.serif(40)),
          ),
        ],
      ),
    );
  }
}

// CustomPainter (_DashedCircle) untuk menggambar garis lingkaran putus-putus di sekeliling avatar
class _DashedCircle extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xB3A98AE0);
    final r = size.width / 2 - 1;
    const dashes = 36;
    for (var i = 0; i < dashes; i++) {
      final a = i * 2 * math.pi / dashes;
      canvas.drawArc(
        Rect.fromCircle(center: size.center(Offset.zero), radius: r),
        a,
        math.pi / dashes,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}