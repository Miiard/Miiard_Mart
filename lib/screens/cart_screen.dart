// Mengimpor FontFeature dari pustaka dart:ui untuk fitur tipografi (seperti angka tabular)
import 'dart:ui' show FontFeature;

// Mengimpor pustaka utama material design dari Flutter
import 'package:flutter/material.dart';
// Mengimpor paket go_router untuk manajemen navigasi halaman
import 'package:go_router/go_router.dart';
// Mengimpor paket provider untuk mendengarkan perubahan state dari state management
import 'package:provider/provider.dart';

// Mengimpor model data item keranjang belanja
import '../models/cart_item.dart';
// Mengimpor model data profil pengguna
import '../models/user_profile.dart';
// Mengimpor state provider keranjang belanja
import '../providers/cart_provider.dart';
// Mengimpor definisi warna kustom aplikasi
import '../theme/app_colors.dart';
// Mengimpor konfigurasi gaya teks aplikasi
import '../theme/app_text.dart';
// Mengimpor widget kustom untuk notifikasi toast
import '../widgets/app_toast.dart';
// Mengimpor widget kustom untuk menampilkan gambar produk
import '../widgets/product_image.dart';
// Mengimpor widget animasi kemunculan (reveal)
import '../widgets/reveal.dart';
// Mengimpor kumpulan widget UI kit tambahan
import '../widgets/ui_kit.dart';

// Kelas CartScreen berupa StatelessWidget untuk menampilkan halaman keranjang belanja
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  // Fungsi privat untuk bernavigasi ke halaman checkout
  void _checkout(BuildContext context) => context.push('/checkout');

  @override
  Widget build(BuildContext context) {
    // Memantau perubahan state dari CartProvider
    final cart = context.watch<CartProvider>();

    // Jika keranjang kosong, tampilkan tampilan status kosong (EmptyState)
    if (cart.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
        children: [
          Reveal(
            child: EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Keranjangmu masih kosong',
              text: 'Yuk, mulai belanja produk pastel impianmu!',
              buttonLabel: 'Mulai Belanja',
              onButton: () => context.go('/home'),
            ),
          ),
        ],
      );
    }

    // Jika keranjang memiliki isi, tampilkan daftar item keranjang dan ringkasan pembayaran
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      children: [
        Reveal(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Keranjang '),
                TextSpan(
                  text: 'Belanja',
                  style: AppText.serif(30,
                      w: FontWeight.w600,
                      style: FontStyle.italic,
                      color: AppColors.purpleText,
                      height: 1.05),
                ),
                TextSpan(text: ' ${kUser.firstName}'),
              ]),
              style: AppText.serif(30, w: FontWeight.w600, height: 1.05),
            ),
          ),
        ),
        // Looping untuk merender setiap baris item produk di dalam keranjang
        for (var i = 0; i < cart.items.length; i++)
          _CartRow(
            key: ValueKey(cart.items[i].product.id),
            item: cart.items[i],
            index: i,
          ),
        // Menampilkan widget ringkasan total belanja di bagian bawah
        Reveal(
          delay: Duration(milliseconds: 75 * (cart.items.length + 1)),
          child: _Summary(cart: cart, onCheckout: () => _checkout(context)),
        ),
      ],
    );
  }
}

// Widget privat _CartRow untuk merepresentasikan satu baris item produk di keranjang
class _CartRow extends StatefulWidget {
  final CartItem item;
  final int index;
  const _CartRow({super.key, required this.item, required this.index});

  @override
  State<_CartRow> createState() => _CartRowState();
}

class _CartRowState extends State<_CartRow> {
  bool _fade = false;     // State lokal untuk efek memudar saat item dihapus
  bool _collapse = false; // State lokal untuk efek menutup/mengecil saat item dihapus

  // Fungsi asinkron untuk menangani animasi penghapusan item dari keranjang
  Future<void> _remove() async {
    if (_fade) return;
    setState(() => _fade = true); // Mulai animasi fade out
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _collapse = true); // Mulai animasi collapse tinggi widget
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;

    final cart = context.read<CartProvider>();
    final title = widget.item.product.title;
    final removed = cart.remove(widget.item.product.id); // Hapus item dari provider
    // Jika berhasil dihapus, tampilkan toast dengan tombol opsi "Urungkan" (Undo)
    if (removed != null && mounted) {
      showAppToast(
        context,
        message: '$title dihapus dari keranjang',
        icon: Icons.close_rounded,
        actionLabel: 'Urungkan',
        onAction: () => cart.restore(removed), // Kembalikan item jika tombol ditekan
        duration: const Duration(milliseconds: 2600),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final p = widget.item.product;
    final (bg, _) = AppColors.toneFor(p.id);

    // Desain tampilan baris kartu produk keranjang
    final row = Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          // Gambar produk yang dapat diklik untuk menuju halaman detail produk
          GestureDetector(
            onTap: () => context.push('/detail/${p.id}', extra: p),
            child: Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
              clipBehavior: Clip.antiAlias,
              child: ProductImage(
                url: p.thumbnail,
                category: p.category,
                id: p.id,
                artFactor: .9,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Informasi judul dan harga produk
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(12.5, w: FontWeight.w700, height: 1.3)),
                const SizedBox(height: 5),
                Text(usd(p.discountedPrice), style: AppText.sans(13.5, w: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Tombol hapus dan pengatur jumlah (stepper kuantitas)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Pressable(
                onTap: _remove,
                scale: .8,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded, size: 17, color: AppColors.ink3),
                ),
              ),
              const SizedBox(height: 6),
              QtyStepper(
                compact: true,
                value: widget.item.quantity,
                onDec: () => cart.decrement(p.id),
                onInc: () {
                  // Cek apakah kuantitas sudah mencapai batas stok maksimum
                  if (widget.item.quantity >= p.stock) {
                    showAppToast(context,
                        message: 'Stok maksimal tercapai',
                        icon: Icons.close_rounded,
                        duration: const Duration(milliseconds: 1500));
                  } else {
                    cart.increment(p.id);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );

    // Membungkus baris dengan animasi reveal, ukuran, slide, dan opacity saat dihapus
    return Reveal(
      delay: Duration(milliseconds: 75 * (widget.index + 1)),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: _collapse
            ? const SizedBox(width: double.infinity)
            : AnimatedSlide(
                offset: _fade ? const Offset(.12, 0) : Offset.zero,
                duration: const Duration(milliseconds: 250),
                child: AnimatedOpacity(
                  opacity: _fade ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: row,
                ),
              ),
      ),
    );
  }
}

// Widget privat _Summary untuk menampilkan rincian total belanja dan tombol checkout
class _Summary extends StatelessWidget {
  final CartProvider cart;
  final VoidCallback onCheckout;
  const _Summary({required this.cart, required this.onCheckout});

  // Fungsi helper privat untuk membuat baris teks rincian total
  Widget _row(String l, Widget r) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: AppText.sans(13, w: FontWeight.w600, color: AppColors.inkSoft)),
            r,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final save = cart.savings;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          _row('Total Belanja',
              Text(usd(cart.originalTotal), style: AppText.sans(13, w: FontWeight.w600, color: AppColors.inkSoft))),
          if (save >= .005)
            _row('Hemat',
                Text('-${usd(save)}', style: AppText.sans(13, w: FontWeight.w800, color: AppColors.mintDeep))),
          _row('Biaya Pengiriman',
              Text('Gratis', style: AppText.sans(13, w: FontWeight.w800, color: AppColors.mintDeep))),
          const SizedBox(height: 4),
          // Garis putus-putus pembatas menggunakan CustomPaint
          SizedBox(height: 1, width: double.infinity, child: CustomPaint(painter: _DashPainter())),
          const SizedBox(height: 14),
          // Baris total pembayaran akhir dengan animasi perubahan angka
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Total Pembayaran', style: AppText.serif(20)),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: cart.total),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Text(
                  usd(v),
                  style: AppText.serif(30, height: 1).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tombol aksi utama untuk melanjutkan ke halaman checkout
          GradientButton(
            label: 'Checkout Sekarang',
            icon: Icons.arrow_forward_rounded,
            trailingIcon: true,
            expand: true,
            padding: const EdgeInsets.symmetric(vertical: 15),
            onTap: onCheckout,
          ),
        ],
      ),
    );
  }
}

// CustomPainter (_DashPainter) untuk menggambar garis putus-putus pada ringkasan pembayaran
class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.ink.withValues(alpha: .2)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}