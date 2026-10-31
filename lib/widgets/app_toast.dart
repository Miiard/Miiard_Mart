// Mengimpor pustaka utama material design dari Flutter
import 'package:flutter/material.dart';
// Mengimpor paket go_router untuk manajemen navigasi halaman
import 'package:go_router/go_router.dart';

// Mengimpor model data produk
import '../models/product_model.dart';
// Mengimpor konfigurasi warna kustom aplikasi
import '../theme/app_colors.dart';
// Mengimpor konfigurasi gaya teks aplikasi
import '../theme/app_text.dart';

/// Notifikasi gelap melayang dengan ikon bergradien pastel.
/// [color] mewarnai lingkaran ikon (default gradien lavender-mawar).
// Fungsi global untuk menampilkan notifikasi toast mengapung (floating SnackBar) yang dapat dikustomisasi
void showAppToast(
  BuildContext context, {
  required String message,
  String? subtitle,
  IconData icon = Icons.check_rounded,
  Color? color,
  Widget? leading,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar(); // Menyembunyikan snackbar aktif sebelumnya agar tidak bertumpuk
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating, // Membuat SnackBar melayang di atas layar
      backgroundColor: const Color(0xF0483858), // Warna latar belakang gelap dengan transparansi
      elevation: 6,
      duration: duration,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 14), // Margin luar untuk mengatur posisi melayang
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Sudut melengkung
      content: Row(
        children: [
          // Widget ikon utama di sebelah kiri (mendukung widget kustom atau otomatis berupa lingkaran bergradien)
          leading ??
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  gradient: color == null ? AppColors.gradient : null, // Gradien pastel default jika warna kosong
                ),
                child: Icon(icon, size: 15, color: AppColors.ink),
              ),
          const SizedBox(width: 10),
          // Bagian Teks Pesan Utama dan Subtitle (jika ada)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(12, w: FontWeight.w600, color: Colors.white, height: 1.35)),
                if (subtitle != null)
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(11, color: Colors.white70)),
              ],
            ),
          ),
          // Bagian Tombol Aksi Opsional (misalnya tombol "Lihat") pada toast
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                messenger.hideCurrentSnackBar(); // Sembunyikan toast saat aksi ditekan
                onAction?.call();               // Jalankan callback aksi
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(actionLabel,
                    style: AppText.sans(11, w: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Notifikasi setelah menambah ke keranjang, dengan tombol "Lihat".
// Fungsi helper khusus untuk menampilkan toast keranjang belanja setelah produk ditambahkan
void showCartToast(
  BuildContext context, {
  required Product product,
  required int added,
}) {
  // Jika jumlah yang ditambah kurang dari atau sama dengan 0 (stok habis atau batas maksimal tercapai)
  if (added <= 0) {
    showAppToast(
      context,
      message: product.stock <= 0 ? 'Stok habis' : 'Jumlah maksimal sudah di keranjang',
      icon: Icons.close_rounded,
      duration: const Duration(milliseconds: 1800),
    );
    return;
  }
  final router = GoRouter.of(context);
  // Menampilkan toast sukses produk masuk keranjang beserta tombol aksi untuk melihat keranjang
  showAppToast(
    context,
    message: '$added× ${product.title} masuk keranjang',
    actionLabel: 'Lihat',
    onAction: () => router.go('/cart'), // Navigasi ke halaman keranjang saat tombol "Lihat" ditekan
  );
}