// Mengimpor library utama Flutter untuk merender UI
import 'package:flutter/material.dart';

// Mengimpor tema warna dan widget custom 'ProductArt' untuk gambar cadangan (fallback)
import '../theme/app_colors.dart';
import 'product_art.dart';

/// Gambar produk yang aman: URL kosong, gagal muat, dan loading ditangani.
/// Bila ada [category], kegagalan diganti ilustrasi pastel; bila tidak, ikon.
// Menggunakan StatelessWidget karena widget ini hanya bertugas merender gambar berdasarkan input (parameter)
class ProductImage extends StatelessWidget {
  // Deklarasi properti yang dibutuhkan
  final String url; // Tautan/URL gambar dari internet
  final String category; // Kategori produk (digunakan untuk menentukan ilustrasi cadangan)
  final int id; // ID produk (opsional, mungkin digunakan di ProductArt untuk variasi warna)
  final double iconSize; // Ukuran ikon jika gambar gagal dimuat (tanpa kategori)
  final double artFactor; // Skala ukuran untuk ilustrasi cadangan (ProductArt)
  final BoxFit fit; // Cara gambar menyesuaikan diri dengan wadahnya (cover, contain, dll)

  // Constructor untuk menerima nilai-nilai di atas saat widget dipanggil
  const ProductImage({
    super.key,
    required this.url, // URL wajib diisi, meskipun bisa berupa string kosong
    this.category = '', // Default kategori kosong
    this.id = 0,
    this.iconSize = 40,
    this.artFactor = .56,
    this.fit = BoxFit.contain, // Secara default, pastikan seluruh gambar terlihat tanpa terpotong
  });

  // Fungsi internal (private) untuk membuat tampilan cadangan jika gambar asli bermasalah
  Widget _fallback() {
    // Jika kategori tidak kosong, tampilkan ilustrasi estetik (ProductArt) berdasarkan kategorinya
    if (category.isNotEmpty) {
      return ProductArt(category: category, id: id, widthFactor: artFactor);
    }
    // Jika tidak ada kategori sama sekali, tampilkan ikon bawaan "image not supported"
    return Center(
      child: Icon(
        Icons.image_not_supported_rounded,
        size: iconSize,
        color: AppColors.ink3, // Warna ikon abu-abu dari tema aplikasi
      ),
    );
  }

  // Fungsi utama untuk membangun widget UI
  @override
  Widget build(BuildContext context) {
    // Cek pertama: Jika string URL ternyata kosong (setelah dihapus spasinya), langsung tampilkan fallback
    if (url.trim().isEmpty) return _fallback();

    // Jika URL ada, coba muat gambar dari internet menggunakan Image.network
    return Image.network(
      url,
      fit: fit, // Mengatur rasio gambar
      // errorBuilder dieksekusi jika URL ada tapi gambarnya error (misal: link mati / internet putus)
      errorBuilder: (_, __, ___) => _fallback(),
      
      // frameBuilder digunakan untuk mengatur transisi saat frame gambar sudah siap dirender
      frameBuilder: (context, child, frame, sync) {
        // Jika sinkron (gambar dari memori cache lokal), langsung tampilkan tanpa efek transisi
        if (sync) return child;
        // Jika dari internet, buat efek 'fade in' (muncul perlahan) menggunakan AnimatedOpacity
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1, // Jika frame belum ada transparan (0), jika siap jadi jelas (1)
          duration: const Duration(milliseconds: 400), // Lama durasi efek fade in
          child: child,
        );
      },
      
      // loadingBuilder menangani apa yang ditampilkan selama proses download (loading) gambar berlangsung
      loadingBuilder: (context, child, progress) => progress == null
          // Jika progress null (artinya loading sudah selesai), kembalikan child (gambarnya)
          ? child
          // Jika masih memuat, tampilkan ikon loading muter (CircularProgressIndicator) di tengah
          : const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
              ),
            ),
    );
  }
}