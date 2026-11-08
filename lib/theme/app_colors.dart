import 'package:flutter/material.dart';

/// Transparansi yang aman di semua versi Flutter (tanpa withOpacity / withValues).
extension ColorOpacityX on Color {
  Color o(double opacity) => withAlpha((opacity * 255).round().clamp(0, 255));
}

/// Pasangan warna pastel: latar kotak produk + warna ilustrasi/aksen.
class Tone {
  final Color bg;
  final Color strong;
  const Tone(this.bg, this.strong);
}

class AppColors {
  // dasar
  static const background = Color(0xFFFFFAF6);
  static const ink = Color(0xFF483858); // ungu plum dari huruf M pada logo
  static const inkSoft = Color(0xFF7C6E8E);
  static const inkFaint = Color(0xFFA99DB8);
  static const star = Color(0xFFEEB23A);
  static const heart = Color(0xFFE9658B);

  // palet pastel
  static const pink = Color(0xFFFFD6E0);
  static const rose = Color(0xFFF8D3DF);
  static const peach = Color(0xFFFFDCC7);
  static const yellow = Color(0xFFFFF3BF);
  static const butter = Color(0xFFFDEBC4);
  static const mint = Color(0xFFCDF0E4);
  static const sky = Color(0xFFD4E7FF);
  static const lavender = Color(0xFFE8DEF9);
  static const lav2 = Color(0xFFC9B8F2);
  static const accent = Color(0xFFB9A4F0);
  static const primary = Color(0xFFCDBCF4);

  static const pastels = [pink, peach, yellow, mint, sky, lavender];

  /// Warna pastel konsisten per produk (kartu & halaman detail sama).
  static Color pastelFor(int id) => pastels[id % pastels.length];

  static const tones = [
    Tone(Color(0xFFFFE6D6), Color(0xFFF4B393)), // persik
    Tone(Color(0xFFECE3FC), Color(0xFFB49AE9)), // lavender
    Tone(Color(0xFFD9F4EA), Color(0xFF7FCDAE)), // mint
    Tone(Color(0xFFFBDDE7), Color(0xFFEC97B3)), // mawar
    Tone(Color(0xFFFDF0CC), Color(0xFFEEBF5C)), // mentega
  ];
  static Tone toneFor(int id) => tones[id % tones.length];

  // gradasi
  static const gradBtn = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFCDBCF4), Color(0xFFF6BFD1)],
  );
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, lavender, sky],
  );

  // bayangan lembut
  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x14483858), blurRadius: 18, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x1F483858), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> liftShadow = [
    BoxShadow(color: Color(0x33483858), blurRadius: 28, offset: Offset(0, 12)),
  ];
}
