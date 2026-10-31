// Mengimpor library asinkron dart untuk menggunakan fitur 'Timer' (jeda waktu)
import 'dart:async';
// Mengimpor material UI dasar Flutter untuk pembuatan widget dan animasi
import 'package:flutter/material.dart';

/// Animasi masuk: muncul pelan sambil naik/bergeser, dengan jeda (stagger).
// Menggunakan StatefulWidget karena widget ini butuh mengelola siklus hidup sebuah animasi (play, stop)
class Reveal extends StatefulWidget {
  // Widget/komponen anak yang akan diberikan efek animasi ini
  final Widget child;
  // Waktu tunggu (jeda) sebelum animasi mulai dimainkan
  final Duration delay;
  // Lama waktu animasi dari awal sampai selesai (durasi)
  final Duration duration;
  // Posisi awal (geser) widget sebelum dianimasikan kembali ke posisi aslinya
  final Offset offset;
  // Ukuran awal (skala) widget sebelum kembali ke ukuran aslinya (1.0 = 100%)
  final double scaleFrom;
  // Sudut putaran awal (rotasi) dalam satuan radian, default-nya 0 (tidak berputar)
  final double rotateFrom; // radian
  // Gaya pergerakan animasi (misal: melambat di akhir, atau memantul). Default: easeOutCubic
  final Curve curve;

  // Constructor wajib untuk menampung seluruh pengaturan animasi dari luar
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero, // Default tanpa jeda
    this.duration = const Duration(milliseconds: 850),
    this.offset = const Offset(0, 18), // Default akan bergeser naik dari bawah sejauh 18 piksel
    this.scaleFrom = 1, // Default tidak ada efek perbesaran
    this.rotateFrom = 0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  // Menyambungkan widget ini dengan state class-nya
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal>
    // SingleTickerProviderStateMixin: Wajib ditambahkan agar state ini bisa menjadi penggerak (ticker) frame per frame animasi
    // AutomaticKeepAliveClientMixin: Menjaga state widget (seperti ListView/Grid) agar animasinya tidak mengulang-ulang terus saat di-scroll
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
      
  // AnimationController adalah 'mesin' utama yang menggerakkan nilai animasi dari 0.0 sampai 1.0 (maju)
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
      
  // Deklarasi timer untuk menangani efek jeda (delay)
  Timer? _timer;

  // Fitur dari AutomaticKeepAliveClientMixin: membalas dengan 'true' agar widget tidak dihancurkan saat di luar layar
  @override
  bool get wantKeepAlive => true;

  // initState berjalan satu kali saat widget pertama kali dilahirkan
  @override
  void initState() {
    super.initState();
    // Jika delay diset nol, langsung jalankan mesin animasi (forward)
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      // Jika ada delay, buat Timer yang akan menjalankan animasi setelah waktu tunggu habis
      _timer = Timer(widget.delay, () {
        // Cek mounted sebelum forward agar tidak error jika widget keburu dihapus saat timer belum selesai
        if (mounted) _c.forward();
      });
    }
  }

  // dispose membersihkan sampah memori saat widget ini sudah tidak terpakai/dihapus dari layar
  @override
  void dispose() {
    // Matikan timer yang mungkin masih menghitung mundur
    _timer?.cancel();
    // Buang mesin controller animasi
    _c.dispose();
    super.dispose();
  }

  // Metode untuk menggambar komponen UI dengan animasi
  @override
  Widget build(BuildContext context) {
    // Wajib dipanggil saat menggunakan AutomaticKeepAliveClientMixin
    super.build(context);
    
    // AnimatedBuilder akan me-rebuild dirinya sendiri secara otomatis setiap frame dari AnimationController
    return AnimatedBuilder(
      animation: _c,
      child: widget.child, // Meneruskan widget aslinya agar performa lebih efisien (tidak dibuat ulang tiap frame)
      builder: (context, child) {
        // Menerapkan efek kelenturan (curve) pada nilai animasi saat ini (v akan berjalan dari 0 ke 1)
        final v = widget.curve.transform(_c.value);
        Widget w = child!;
        
        // 1. Jika ada efek rotasi yang diatur (rotateFrom != 0), putar balik widget
        // Saat v=0 putaran penuh sebesar rotateFrom, saat v=1 putarannya menjadi 0 (normal)
        if (widget.rotateFrom != 0) {
          w = Transform.rotate(angle: widget.rotateFrom * (1 - v), child: w);
        }
        
        // 2. Jika ada efek perbesaran/skala, perbesar komponen
        // Saat v=0 skalanya adalah scaleFrom, saat v=1 skalanya mencapai angka 1 (normal/100%)
        if (widget.scaleFrom != 1) {
          w = Transform.scale(
              scale: widget.scaleFrom + (1 - widget.scaleFrom) * v, child: w);
        }
        
        // 3 & 4. Kembalikan widget dengan efek Transparansi (Opacity) dan Posisi (Translate)
        return Opacity(
          // Transparansi berjalan dari 0 (hilang) ke 1 (jelas). Fungsi clamp menjaga agar nilai tidak error (kurang dari 0 / lebih dari 1)
          opacity: v.clamp(0.0, 1.0).toDouble(),
          // Posisi berjalan dari offset awal menuju (0,0) letak asli
          child: Transform.translate(offset: widget.offset * (1 - v), child: w),
        );
      },
    );
  }
}