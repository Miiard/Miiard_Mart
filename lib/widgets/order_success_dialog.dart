// Mengimpor pustaka matematika Dart (alias math) untuk perhitungan posisi percikan titik (sparkles)
import 'dart:math' as math;
// Mengimpor pustaka UI Dart untuk efek blur (ImageFilter) dan metrik jalur path (PathMetric)
import 'dart:ui' as ui;

// Mengimpor pustaka utama material design dari Flutter
import 'package:flutter/material.dart';

// Mengimpor model data profil pengguna
import '../models/user_profile.dart';
// Mengimpor konfigurasi warna kustom aplikasi
import '../theme/app_colors.dart';
// Mengimpor konfigurasi gaya teks aplikasi
import '../theme/app_text.dart';
// Mengimpor kumpulan widget UI kit tambahan
import 'ui_kit.dart';

/// Dialog "Pesanan berhasil" dengan cincin dan centang yang tergambar.
/// Selesai (Future) saat dialog ditutup lewat tombol.
// Fungsi global untuk menampilkan dialog pop-up konfirmasi pesanan berhasil dengan efek blur dan animasi transisi
Future<void> showOrderSuccess(
  BuildContext context, {
  required int count,
  required double total,
  String? totalLabel,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Pesanan berhasil',
    barrierColor: const Color(0x4D483858), // Warna latar belakang di luar dialog dengan efek gelap semi-transparan
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (ctx, a, b) => Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7), // Memberikan efek blur pada latar belakang layar di balik dialog
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        Center(child: _Dialog(count: count, total: total, totalLabel: totalLabel)),
      ],
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .06), end: Offset.zero).animate(curved),
          child: ScaleTransition(
            scale: Tween(begin: .94, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

// Widget utama pembungkus isi dialog yang bersifat Stateful untuk mengelola animasi
class _Dialog extends StatefulWidget {
  final int count;
  final double total;
  final String? totalLabel;
  const _Dialog({required this.count, required this.total, this.totalLabel});

  @override
  State<_Dialog> createState() => _DialogState();
}

class _DialogState extends State<_Dialog> with SingleTickerProviderStateMixin {
  // AnimationController untuk menjalankan urutan animasi ikon sukses berdurasi 1900 milidetik
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..forward();

  @override
  void dispose() {
    _c.dispose(); // Membersihkan animation controller saat dialog ditutup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 310,
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99483858),
              blurRadius: 60,
              spreadRadius: -20,
              offset: Offset(0, 30),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bagian CustomPaint untuk menggambar animasi lingkaran dan ikon centang (checkmark)
            SizedBox(
              width: 92,
              height: 92,
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => CustomPaint(
                  painter: _OkPainter(_c.value),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text('Pesanan berhasil', style: AppText.serif(26, height: 1.1)),
            const SizedBox(height: 8),
            // Menampilkan pesan informasi sapaan nama pengguna, jumlah item, dan total harga belanjaan
            Text(
              'Terima kasih, ${kUser.firstName}. ${widget.count} item senilai ${widget.totalLabel ?? usd(widget.total)} sedang disiapkan.',
              textAlign: TextAlign.center,
              style: AppText.sans(13, color: AppColors.inkSoft, height: 1.45),
            ),
            const SizedBox(height: 18),
            // Tombol untuk kembali ke beranda dan menutup dialog
            GradientButton(
              label: 'Kembali ke Beranda',
              expand: true,
              padding: const EdgeInsets.symmetric(vertical: 15),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// Kelas CustomPainter (_OkPainter) untuk menggambar animasi cincin, latar warna mint, centang, dan percikan titik
class _OkPainter extends CustomPainter {
  final double t; // Nilai progress animasi dari 0 hingga 1
  _OkPainter(this.t);

  // Fungsi helper untuk menghitung tahapan animasi berdasarkan interval waktu tertentu
  double _seg(double a, double b, [Curve c = Curves.easeOutCubic]) =>
      c.transform(((t - a) / (b - a)).clamp(0.0, 1.0).toDouble());

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 92, size.height / 92);
    const center = Offset(46, 46);

    // Menggambar latar lingkaran mint (muncul bersamaan dengan cincin)
    canvas.drawCircle(
      center,
      43,
      Paint()..color = AppColors.mint.withValues(alpha: _seg(0, .3)),
    );

    // Menggambar garis pinggir cincin (ring) secara bertahap
    final ring = Path()..addOval(Rect.fromCircle(center: center, radius: 43));
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF7FCDAE);
    _drawPartial(canvas, ring, _seg(.08, .5), ringPaint);

    // Menggambar ikon centang (checkmark) secara bertahap setelah cincin terbentuk
    final check = Path()
      ..moveTo(29, 47)
      ..relativeLineTo(12, 12)
      ..relativeLineTo(23, -25);
    final checkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.ink;
    _drawPartial(canvas, check, _seg(.38, .72), checkPaint);

    // Daftar warna untuk efek percikan titik (sparkles)
    const colors = [
      Color(0xFFF6BFD1),
      Color(0xFFCDBCF4),
      Color(0xFFC8EEE1),
      Color(0xFFFFD6C0),
      Color(0xFFFDEBC4),
    ];
    final k = _seg(.42, 1, Curves.easeOutCubic);
    if (k > 0 && k < 1) {
      // Menggambar 10 titik percikan melingkar keluar dari pusat
      for (var i = 0; i < 10; i++) {
        final ang = (i * 36 - 90) * math.pi / 180;
        final dist = 46 + 62 * k;
        final pos = center + Offset(math.cos(ang), math.sin(ang)) * dist;
        final r = 3.5 * (1 - .7 * k);
        canvas.drawCircle(
          pos,
          r,
          Paint()..color = colors[i % colors.length].withValues(alpha: 1 - k),
        );
      }
    }
  }

  // Fungsi helper untuk menggambar jalur (path) secara parsial berdasarkan persentase progress
  void _drawPartial(Canvas canvas, Path path, double progress, Paint paint) {
    if (progress <= 0) return;
    for (final ui.PathMetric m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_OkPainter old) => old.t != t;
}