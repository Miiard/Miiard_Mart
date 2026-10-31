// Mengimpor pustaka utama material design dari Flutter
import 'package:flutter/material.dart';

// Mengimpor konfigurasi warna kustom aplikasi
import '../theme/app_colors.dart';

// Enum untuk menentukan jenis/kategori ilustrasi seni pastel
enum ArtKind { lip, bottle, sofa, apple, gift }

// Fungsi helper untuk memetakan string kategori produk ke jenis ilustrasi ArtKind yang sesuai
ArtKind artKindFor(String category) {
  final c = category.toLowerCase();
  if (c.contains('fragran')) return ArtKind.bottle;
  if (RegExp(r'beauty|skin|makeup').hasMatch(c)) return ArtKind.lip;
  if (RegExp(r'furni|home|decor|bed|sofa|table').hasMatch(c)) return ArtKind.sofa;
  if (RegExp(r'groc|food|kitchen').hasMatch(c)) return ArtKind.apple;
  return ArtKind.gift;
}

/// Ilustrasi pastel yang dipakai bila foto produk kosong atau gagal dimuat.
// Kelas ProductArt berupa StatelessWidget untuk merender ilustrasi kustom berbasis CustomPaint
class ProductArt extends StatelessWidget {
  final String category;
  final int id;
  final double widthFactor;

  const ProductArt({
    super.key,
    required this.category,
    required this.id,
    this.widthFactor = .56,
  });

  @override
  Widget build(BuildContext context) {
    // Mendapatkan warna tone pastel berdasarkan ID produk
    final tone = AppColors.toneFor(id).$2;
    return Center(
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(painter: _ArtPainter(artKindFor(category), tone)),
        ),
      ),
    );
  }
}

// CustomPainter (_ArtPainter) untuk menggambar berbagai ilustrasi vektor pastel (lipstik, botol, sofa, apel, kado)
class _ArtPainter extends CustomPainter {
  final ArtKind kind;
  final Color tone;
  _ArtPainter(this.kind, this.tone);

  // Fungsi helper ringkas untuk menggambar persegi panjang dengan sudut melengkung (Rounded Rect)
  void _rr(Canvas c, double x, double y, double w, double h, double r, Paint p) =>
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)), p);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    final a1 = Paint()..color = AppColors.ink;
    final a2 = Paint()..color = Colors.white.withValues(alpha: .8);
    final a3 = Paint()..color = tone;

    // Memilih jenis gambar berdasarkan ArtKind menggunakan switch-case
    switch (kind) {
      case ArtKind.lip:
        // Menggambar ilustrasi kosmetik / lipstik
        _rr(canvas, 33, 58, 34, 26, 6, a1);
        _rr(canvas, 33, 51, 34, 9, 3, a2);
        final bullet = Path()
          ..moveTo(41, 52)
          ..lineTo(41, 34)
          ..lineTo(59, 22)
          ..lineTo(59, 52)
          ..close();
        canvas.drawPath(bullet, a3);
        _rr(canvas, 45, 38, 4, 10, 2, a2);
      case ArtKind.bottle:
        // Menggambar ilustrasi botol parfum / cairan
        _rr(canvas, 43, 14, 14, 12, 3, a1);
        _rr(canvas, 46, 26, 8, 8, 1, a3);
        _rr(canvas, 26, 33, 48, 52, 14, a3);
        _rr(canvas, 35, 47, 30, 24, 8, a2);
      case ArtKind.sofa:
        // Menggambar ilustrasi furnitur / sofa
        _rr(canvas, 24, 30, 52, 30, 12, Paint()..color = tone.withValues(alpha: .75));
        _rr(canvas, 18, 52, 64, 24, 10, a3);
        _rr(canvas, 10, 44, 20, 32, 10, a3);
        _rr(canvas, 70, 44, 20, 32, 10, a3);
        _rr(canvas, 22, 76, 5, 9, 2, a1);
        _rr(canvas, 73, 76, 5, 9, 2, a1);
        _rr(canvas, 32, 57, 36, 6, 3, a2);
      case ArtKind.apple:
        // Menggambar ilustrasi buah / makanan (apel)
        final body = Path()
          ..moveTo(50, 36)
          ..relativeCubicTo(-6, -7, -26, -5, -26, 17)
          ..relativeCubicTo(0, 17, 12, 31, 21, 31)
          ..relativeCubicTo(2, 0, 3.5, -1, 5, -1)
          ..relativeCubicTo(1.5, 0, 3, 1, 5, 1)
          ..relativeCubicTo(9, 0, 21, -14, 21, -31)
          ..relativeCubicTo(0, -22, -20, -24, -26, -17)
          ..close();
        canvas.drawPath(body, a3);
        final stem = Path()
          ..moveTo(49, 36)
          ..relativeCubicTo(0, -9, 4, -15, 10, -18)
          ..relativeLineTo(2, 4)
          ..relativeCubicTo(-5, 3, -6, 8, -6, 14)
          ..close();
        canvas.drawPath(stem, a1);
        canvas.drawOval(const Rect.fromLTWH(58, 16, 18, 9), a2);
        _rr(canvas, 33, 48, 6, 14, 3, a2);
      case ArtKind.gift:
        // Menggambar ilustrasi kotak kado (gift box) sebagai default
        _rr(canvas, 22, 44, 56, 40, 7, a3);
        _rr(canvas, 17, 34, 66, 15, 6, a2);
        canvas.drawRect(const Rect.fromLTWH(45, 34, 10, 50),
            Paint()..color = AppColors.ink.withValues(alpha: .85));
        final bow = Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        canvas.drawOval(const Rect.fromLTWH(34, 22, 17, 12), bow);
        canvas.drawOval(const Rect.fromLTWH(49, 22, 17, 12), bow);
    }
  }

  @override
  bool shouldRepaint(_ArtPainter old) => old.kind != kind || old.tone != tone;
}