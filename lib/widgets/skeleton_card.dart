// Mengimpor library standar UI dari Flutter
import 'package:flutter/material.dart';

// Mengimpor palet warna kustom dari tema aplikasi
import '../theme/app_colors.dart';

/// Kartu placeholder berdenyut saat data produk sedang dimuat.
// Menggunakan StatefulWidget karena kartu ini memiliki animasi berdenyut (perubahan state secara terus-menerus)
class SkeletonCard extends StatefulWidget {
  // Indeks kartu (digunakan untuk menentukan variasi warna background agar tidak monoton)
  final int index;
  const SkeletonCard({super.key, required this.index});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    // Wajib menambahkan SingleTickerProviderStateMixin agar State ini bisa menjadi penggerak (ticker) untuk animasi
    with SingleTickerProviderStateMixin {
      
  // Menginisialisasi controller animasi sebagai 'mesin' penggerak
  late final AnimationController _controller = AnimationController(
    vsync: this, // Menyambungkan controller dengan Ticker dari State ini
    duration: const Duration(milliseconds: 1000), // Lama satu siklus animasi adalah 1 detik
  )..repeat(reverse: true); 
  // Titik dua (..) disebut cascade operator. Langsung memerintahkan animasi untuk diulang (repeat) secara bolak-balik (reverse) agar efeknya seperti berdenyut/bernapas.

  // Membersihkan memori saat widget kerangka ini selesai digunakan (dihapus dari layar karena data asli sudah muncul)
  @override
  void dispose() {
    _controller.dispose(); // Wajib dimatikan agar tidak terjadi kebocoran memori (memory leak)
    super.dispose();
  }

  // Fungsi bantuan (helper) untuk menggambar kotak abu-abu yang seolah-olah adalah baris teks (judul/harga/dsb)
  Widget _bar(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          // Menggunakan warna hitam/gelap dari tema dengan tingkat transparansi sangat rendah (8%) menjadi abu-abu pudar
          color: AppColors.ink.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(8), // Sudut kotak teks membulat
        ),
      );

  @override
  Widget build(BuildContext context) {
    // Mengambil warna pastel acak berdasarkan urutan indeks kartu untuk area gambar
    final (bg, _) = AppColors.toneFor(widget.index);
    
    // FadeTransition memberikan efek transisi perubahan transparansi (opacity) yang dikendalikan oleh animasi
    return FadeTransition(
      // Tween mengatur rentang transparansi. Mulai dari 45% (agak pudar) menuju 100% (jelas)
      opacity: Tween<double>(begin: .45, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut), // Gerakan transisi dihaluskan (ease in out)
      ),
      // Wadah utama kartu kerangka (desain luar disamakan persis dengan kartu produk asli)
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24), // Sudut kartu membulat 24 piksel
          boxShadow: AppColors.softShadow, // Memberikan bayangan lembut yang sama dengan kartu asli
        ),
        child: Column(
          children: [
            // Expanded memastikan area gambar mengambil seluruh sisa ruang kosong di atas area teks
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(7), // Jarak ruang gambar terhadap tepi kartu
                decoration: BoxDecoration(
                  color: bg, // Menggunakan warna pastel
                  borderRadius: BorderRadius.circular(18), // Sudut gambar membulat
                ),
                // Ikon gambar di tengah-tengah sebagai penanda bahwa area ini adalah area foto produk
                child: Center(
                  child: Icon(Icons.image_rounded,
                      size: 40, color: Colors.white.withValues(alpha: .8)),
                ),
              ),
            ),
            // Area khusus untuk baris teks palsu (kerangka judul, kategori, dan harga)
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 3, 13, 13), // Margin untuk menyesuaikan dengan ProductCard asli
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Menyusun semua kotak kerangka teks ke kiri
                children: [
                  _bar(100, 12), // Kotak kerangka untuk judul (lebar 100, tinggi 12)
                  const SizedBox(height: 7), // Jarak vertikal
                  _bar(60, 10), // Kotak kerangka untuk kategori (lebih pendek dan kecil)
                  const SizedBox(height: 10), // Jarak vertikal yang lebih besar
                  _bar(70, 14), // Kotak kerangka untuk harga (sedikit lebih tebal)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}