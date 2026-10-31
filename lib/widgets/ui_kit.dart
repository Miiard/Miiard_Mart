// Mengimpor library standar UI dari Flutter
import 'package:flutter/material.dart';

// Mengimpor file konfigurasi warna dan teks khusus untuk aplikasi ini
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

// Fungsi bantuan untuk mengubah angka menjadi format mata uang dolar AS (contoh: $12.50)
String usd(num n) => '\$${n.toStringAsFixed(2)}';

/// 1234567 -> "Rp 1.234.567"
// Fungsi bantuan untuk mengubah angka menjadi format mata uang Rupiah dengan pemisah ribuan (titik)
String rupiah(num n) {
  // Membulatkan angka dan mengubahnya menjadi teks (string)
  final s = n.round().toString();
  // StringBuffer lebih efisien untuk merangkai/menyambung teks berulang kali
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    // Menambahkan titik setiap kelipatan 3 dari belakang (untuk ribuan, jutaan, dst)
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    // Menuliskan angka satu per satu
    b.write(s[i]);
  }
  return 'Rp $b';
}

/// Efek menekan: mengecil sedikit saat disentuh.
// Widget kustom interaktif agar tombol atau kartu terlihat "ditekan" (mengecil)
class Pressable extends StatefulWidget {
  final Widget child; // Komponen yang akan diberi efek tekan
  final VoidCallback? onTap; // Aksi saat ditekan
  final double scale; // Seberapa kecil saat ditekan (default: 0.96 / 96% dari ukuran asli)

  const Pressable({super.key, required this.child, this.onTap, this.scale = .96});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  // State untuk melacak apakah jari sedang menekan layar atau tidak
  bool _down = false;

  // Fungsi untuk mengubah status _down dan memperbarui UI
  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector menangkap sentuhan jari pengguna
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Memastikan seluruh area (termasuk yang transparan) bisa disentuh
      onTapDown: (_) => _set(true), // Saat jari menyentuh layar
      onTapUp: (_) => _set(false), // Saat jari diangkat
      onTapCancel: () => _set(false), // Saat sentuhan batal (misal: jari menggeser ke luar area)
      onTap: widget.onTap, // Mengeksekusi aksi utama
      // AnimatedScale memberikan efek membesar/mengecil dengan mulus
      child: AnimatedScale(
        scale: _down ? widget.scale : 1, // Jika ditekan pakai skala mengecil, jika tidak ukuran normal (1)
        duration: const Duration(milliseconds: 140), // Kecepatan animasi
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Tombol utama bergradien pastel (atau putih untuk di atas hero).
// Tombol serbaguna yang bisa bergradasi warna atau putih polos
class GradientButton extends StatelessWidget {
  final String label; // Teks tombol
  final IconData? icon; // Ikon tombol (opsional)
  final bool trailingIcon; // Jika true, ikon ditaruh di sebelah kanan teks
  final bool white; // Jika true, tombol menjadi putih polos tanpa gradien
  final bool expand; // Jika true, lebar tombol akan memenuhi layar
  final VoidCallback? onTap; // Aksi klik
  final EdgeInsets padding; // Jarak teks/ikon ke tepi tombol
  final double radius; // Lengkungan sudut tombol

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.trailingIcon = false,
    this.white = false,
    this.expand = false,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    // Menyiapkan widget ikon jika parameter ikon diberikan
    final iconW = icon == null ? null : Icon(icon, size: 17, color: AppColors.ink);
    
    // Opacity membuat tombol agak transparan (pudar) jika onTap null (tombol disable)
    return Opacity(
      opacity: onTap == null ? .55 : 1,
      // Menggunakan widget Pressable yang kita buat di atas untuk efek ditekan
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: expand ? double.infinity : null, // Memenuhi layar jika expand true
          padding: padding,
          decoration: BoxDecoration(
            gradient: white ? null : AppColors.gradient, // Gradien dimatikan jika mode putih
            color: white ? Colors.white : null,
            borderRadius: BorderRadius.circular(radius),
            // Bayangan berbeda: gaya putih pakai bayangan lembut, gaya gradien pakai bayangan tebal/menyebar
            boxShadow: white
                ? AppColors.softShadow
                : const [
                    BoxShadow(
                      color: Color(0xCCA888E6),
                      blurRadius: 22,
                      spreadRadius: -10,
                      offset: Offset(0, 12),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Jika ada ikon dan BUKAN ditaruh di kanan, tampilkan ikon di kiri
              if (iconW != null && !trailingIcon) ...[iconW, const SizedBox(width: 8)],
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(12.5, w: FontWeight.w800)),
              ),
              // Jika ada ikon dan diatur di kanan (trailingIcon), tampilkan ikon di kanan
              if (iconW != null && trailingIcon) ...[const SizedBox(width: 8), iconW],
            ],
          ),
        ),
      ),
    );
  }
}

/// Stepper jumlah berbentuk pil.
// Komponen plus-minus (+ / -) untuk mengatur jumlah produk di keranjang
class QtyStepper extends StatelessWidget {
  final int value; // Angka jumlah saat ini
  final VoidCallback? onDec; // Aksi saat tombol minus ditekan (decrease)
  final VoidCallback? onInc; // Aksi saat tombol plus ditekan (increase)
  final bool compact; // Mode ringkas (ukurannya lebih kecil)

  const QtyStepper({
    super.key,
    required this.value,
    this.onDec,
    this.onInc,
    this.compact = false,
  });

  // Fungsi internal untuk membangun tombol plus / minus
  Widget _btn(IconData icon, VoidCallback? onTap) {
    final s = compact ? 26.0 : 30.0; // Ukuran tombol menyesuaikan mode compact
    return Pressable(
      onTap: onTap,
      scale: .8,
      child: Container(
        width: s,
        height: s,
        decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
        child: Icon(icon, size: compact ? 13 : 15, color: AppColors.ink),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999), // Membulat sempurna seperti pil
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Lebar row menyesuaikan isi
        children: [
          _btn(Icons.remove_rounded, onDec), // Tombol Minus
          SizedBox(
            width: compact ? 24 : 30, // Ruang untuk teks angka
            // AnimatedSwitcher memberi efek animasi keren saat angka berubah
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              // Kombinasi efek fade (transparansi) dan geser naik-turun (slide)
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, .5), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              // ValueKey wajib ada agar sistem tahu angka sudah berubah dan memicu animasi
              child: Text('$value',
                  key: ValueKey(value),
                  textAlign: TextAlign.center,
                  style: AppText.sans(13, w: FontWeight.w800)),
            ),
          ),
          _btn(Icons.add_rounded, onInc), // Tombol Plus
        ],
      ),
    );
  }
}

/// Tombol ikon bundar putih (kembali, dll).
// Digunakan untuk tombol back, tombol favorit, dll yang desainnya melayang (floating)
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color color;

  const RoundIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 42,
    this.color = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: .9, // Mengecil jadi 90% saat ditekan
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: AppColors.softShadow,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

// Layar "kosong" (Empty State), muncul ketika daftar produk atau keranjang tidak ada isinya
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final String? buttonLabel; // Opsional: Tombol untuk mengajak user melakukan aksi
  final VoidCallback? onButton;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    this.buttonLabel,
    this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 46, 20, 46),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Tinggi kolom menyesuaikan konten agar bisa ditaruh di tengah layar
        children: [
          // Lingkaran gradien sebagai latar belakang ikon
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.lavender, AppColors.pink],
              ),
              boxShadow: AppColors.softShadow,
            ),
            child: Icon(icon, size: 40, color: AppColors.ink),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: AppText.serif(22)), // Judul utama
          const SizedBox(height: 6),
          // ConstrainedBox membatasi lebar teks deskripsi agar tidak terlalu melebar ke samping (maks 240px)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(text,
                textAlign: TextAlign.center,
                style: AppText.sans(13, color: AppColors.inkSoft, height: 1.45)),
          ),
          // Menampilkan tombol jika buttonLabel diisi (tidak null)
          if (buttonLabel != null) ...[
            const SizedBox(height: 16),
            GradientButton(label: buttonLabel!, onTap: onButton),
          ],
        ],
      ),
    );
  }
}

// Varian lain dari judul bagian (SectionTitle sebelumnya), digunakan untuk tata letak sejajar (baseline)
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing; // Widget di kanan judul (misal: "Lihat Semua")
  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline, // Menyejajarkan teks di garis bawah yang sama
      textBaseline: TextBaseline.alphabetic,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(title, style: AppText.serif(21, height: 1.1))),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// Label nilai rating berbentuk kapsul/pil (contoh: Bintang 4.5)
class RatingPill extends StatelessWidget {
  final double rating;
  final double fontSize;
  const RatingPill({super.key, required this.rating, this.fontSize = 10.5});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.yellow,
        borderRadius: BorderRadius.circular(999), // Bentuk pil bulat
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: fontSize + 1.5, color: AppColors.star),
          const SizedBox(width: 3),
          // Membulatkan nilai rating ke 1 angka desimal (contoh: 4.56 jadi 4.6)
          Text(rating.toStringAsFixed(1),
              style: AppText.sans(fontSize, w: FontWeight.w800, color: const Color(0xFF8D6A1D))),
        ],
      ),
    );
  }
}

// Kotak informasi kecil (Badge / Tag) untuk kategori atau status
class InfoTag extends StatelessWidget {
  final String label;
  final Color color;
  const InfoTag(this.label, {super.key, this.color = AppColors.lavender});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: AppText.sans(10.5, w: FontWeight.w700)),
    );
  }
}

/// Logo bulat "M" dengan cincin lavender.
// Digunakan sebagai penanda brand aplikasi
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2), // Ruang untuk memberi efek cincin putih/bayangan
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        // Dua bayangan berbeda yang memberikan efek cahaya neon / mengambang eksklusif
        boxShadow: [
          BoxShadow(color: Color(0xBFC9B8F2), spreadRadius: 3.5),
          BoxShadow(
            color: Color(0x73483858),
            blurRadius: 18,
            spreadRadius: -8,
            offset: Offset(0, 10),
          ),
        ],
      ),
      // Memotong gambar (image aset lokal) agar benar-benar membulat
      child: ClipOval(child: Image.asset('assets/images/mark.webp', fit: BoxFit.cover)),
    );
  }
}

/// Latar krem dengan semburat persik dan mint di sudut atas.
// Latar belakang utama aplikasi yang memberikan gaya estetik/modern
class PastelBackdrop extends StatelessWidget {
  final Widget child; // Halaman atau konten utama yang akan diberi latar ini
  const PastelBackdrop({super.key, required this.child});

  // Fungsi internal untuk menggambar noda warna blur (blob) bercahaya
  Widget _blob(Color c, double a, double size) => IgnorePointer(
        // IgnorePointer memastikan bulatan gradien ini tidak mengganggu/menghalangi klik tombol di bawahnya
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // RadialGradient menyebarkan warna dari tengah yang tebal, memudar transparan ke luar
            gradient: RadialGradient(colors: [
              c.withValues(alpha: a),
              c.withValues(alpha: 0),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Lapisan 1 (Dasar): Latar warna penuh (krem/background)
        const Positioned.fill(child: ColoredBox(color: AppColors.background)),
        // Lapisan 2: Cahaya / Blob warna peach di kiri atas, digeser menjorok ke luar layar (minus)
        Positioned(top: -110, left: -130, child: _blob(AppColors.peach, .55, 420)),
        // Lapisan 3: Cahaya / Blob warna mint di kanan atas
        Positioned(top: -70, right: -150, child: _blob(AppColors.mint, .6, 380)),
        // Lapisan 4 (Atas): Menaruh halaman/konten utamanya
        Positioned.fill(child: child),
      ],
    );
  }
}

/// Bintang empat sudut (kilau).
// Komponen gambar vektor kustom menggunakan kanvas murni untuk menggambar efek bintang
class SparklePainter extends CustomPainter {
  final Color color;
  const SparklePainter(this.color);

  // Fungsi untuk menggambar manual di atas kanvas
  @override
  void paint(Canvas canvas, Size size) {
    // Menyesuaikan rasio gambar dengan ukuran kanvas yang tersedia
    canvas.scale(size.width / 24, size.height / 24);
    
    // Membentuk path/jalur garis bintang menggunakan fungsi matematika kurva (Bézier Curve)
    final p = Path()
      ..moveTo(12, 0) // Mulai dari titik atas tengah
      ..relativeCubicTo(.8, 6, 3, 9.2, 12, 12) // Melengkung ke kanan
      ..relativeCubicTo(-9, 2.8, -11.2, 6, -12, 12) // Melengkung ke bawah
      ..relativeCubicTo(-.8, -6, -3, -9.2, -12, -12) // Melengkung ke kiri
      ..cubicTo(9, 9.2, 11.2, 6, 12, 0) // Melengkung kembali ke titik awal
      ..close(); // Menutup jalur
      
    // Mengecat bentuk yang sudah digambar dengan warna solid
    canvas.drawPath(p, Paint()..color = color);
  }

  // Mengontrol apakah kanvas perlu digambar ulang (jika warnanya berubah)
  @override
  bool shouldRepaint(SparklePainter old) => old.color != color;
}