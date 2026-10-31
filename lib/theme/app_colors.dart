import 'package:flutter/material.dart';

/// Palet Miiard.Mart: krem hangat, tinta ungu plum, aksen pastel.
/// Nama lama (pink, yellow, lavender, primary, ...) dipertahankan agar
/// layar Tambah/Edit dan ProductForm tetap jalan tanpa perubahan.
class AppColors {
  static const background = Color(0xFFFFFAF6);
  static const ink = Color(0xFF483858); // teks & ikon
  static const inkSoft = Color(0xFF7C6E8E);
  static const ink3 = Color(0xFFA99DB8);
  static const plum = Color(0xFF3D3152);
  static const line = Color(0x17483858);
  static const star = Color(0xFFEEB23A);
  static const heart = Color(0xFFE9658B);
  static const purpleText = Color(0xFFA98AE0); // kata miring pada judul
  static const link = Color(0xFFA07FDC);
  static const mintDeep = Color(0xFF3F9D7C);

  // pastel
  static const lavender = Color(0xFFE8DEF9);
  static const accent = Color(0xFFC9B8F2);
  static const primary = Color(0xFFCDBCF4);
  static const peach = Color(0xFFFFDCC7);
  static const mint = Color(0xFFCDF0E4);
  static const pink = Color(0xFFF8D3DF);
  static const yellow = Color(0xFFFDEBC4);
  static const sky = Color(0xFFD4E7FF);

  static const pastels = [pink, peach, yellow, mint, sky, lavender];
  static Color pastelFor(int id) => pastels[id % pastels.length];

  /// (latar, aksen) per produk, konsisten di kartu dan halaman detail.
  static const tones = [
    (Color(0xFFFFE6D6), Color(0xFFF4B393)),
    (Color(0xFFECE3FC), Color(0xFFB49AE9)),
    (Color(0xFFD9F4EA), Color(0xFF7FCDAE)),
    (Color(0xFFFBDDE7), Color(0xFFEC97B3)),
    (Color(0xFFFDF0CC), Color(0xFFEEBF5C)),
  ];
  static (Color, Color) toneFor(int id) => tones[id % tones.length];

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFCDBCF4), Color(0xFFF6BFD1)],
  );
  static const heroGradient = gradient;

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x47483858),
      blurRadius: 16,
      spreadRadius: -8,
      offset: Offset(0, 5),
    ),
  ];
  static const List<BoxShadow> shadow = [
    BoxShadow(
      color: Color(0x52483858),
      blurRadius: 30,
      spreadRadius: -14,
      offset: Offset(0, 14),
    ),
  ];
}
