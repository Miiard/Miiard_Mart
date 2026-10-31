// Mengimpor pustaka utama material design dari Flutter
import 'package:flutter/material.dart';
// Mengimpor paket go_router untuk manajemen navigasi halaman
import 'package:go_router/go_router.dart';
// Mengimpor paket provider untuk mengakses state management
import 'package:provider/provider.dart';

// Mengimpor model data produk
import '../models/product_model.dart';
// Mengimpor state provider keranjang belanja
import '../providers/cart_provider.dart';
// Mengimpor state provider produk
import '../providers/product_provider.dart';
// Mengimpor konfigurasi warna kustom aplikasi
import '../theme/app_colors.dart';
// Mengimpor konfigurasi gaya teks aplikasi
import '../theme/app_text.dart';
// Mengimpor widget kustom untuk notifikasi toast
import '../widgets/app_toast.dart';
// Mengimpor widget aksi produk (seperti helper tambah ke keranjang/favorit)
import '../widgets/product_actions.dart';
// Mengimpor widget penampil gambar produk
import '../widgets/product_image.dart';
// Mengimpor widget animasi kemunculan (reveal)
import '../widgets/reveal.dart';
// Mengimpor kumpulan widget UI kit tambahan
import '../widgets/ui_kit.dart';

// Kelas DetailProductScreen berupa StatefulWidget untuk menampilkan halaman detail produk secara lengkap
class DetailProductScreen extends StatefulWidget {
  final String id;
  final Product? product;
  const DetailProductScreen({super.key, required this.id, this.product});

  @override
  State<DetailProductScreen> createState() => _DetailProductScreenState();
}

class _DetailProductScreenState extends State<DetailProductScreen> {
  Product? _fallback;  // Menyimpan data produk cadangan jika belum dimuat atau lewat parameter
  Object? _error;      // Menyimpan objek error jika pengambilan data gagal
  int _qty = 1;        // Kuantitas produk yang dipilih untuk dimasukkan ke keranjang

  @override
  void initState() {
    super.initState();
    _fallback = widget.product;
    if (_fallback == null) _fetch(); // Ambil dari API jika produk dari parameter kosong
  }

  // Fungsi asinkron untuk mengambil data detail produk dari server via provider
  Future<void> _fetch() async {
    try {
      final p = await context.read<ProductProvider>().fetchProduct(widget.id);
      if (mounted) setState(() => _fallback = p);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  // Fungsi untuk bernavigasi ke halaman edit produk
  Future<void> _edit(Product p) async {
    await context.push<Product>('/edit/${p.id}', extra: p);
  }

  // Fungsi untuk menghapus produk dengan menampilkan dialog konfirmasi terlebih dahulu
  Future<void> _delete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Hapus produk?', style: AppText.serif(24)),
        content: Text('"${p.title}" akan dihapus dari daftar produk.',
            style: AppText.sans(13, color: AppColors.inkSoft, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: AppText.sans(13, w: FontWeight.w700, color: AppColors.inkSoft)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final prov = context.read<ProductProvider>();
    final cart = context.read<CartProvider>();
    final done = await prov.deleteProduct(p.id);
    if (!mounted) return;
    if (done) cart.remove(p.id); // Hapus juga dari keranjang jika produk dihapus
    showAppToast(
      context,
      message: done ? 'Produk dihapus' : 'Gagal menghapus produk',
      icon: done ? Icons.delete_outline_rounded : Icons.close_rounded,
    );
    if (done) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final pid = int.tryParse(widget.id) ?? -1;
    final live = context.watch<ProductProvider>().byId(pid);
    final p = live ?? _fallback;

    // Jika data produk belum ada/null, tampilkan indikator loading atau pesan error
    if (p == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: _error == null
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : EmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Produk tidak ditemukan',
                        text: 'Produk ini mungkin sudah dihapus.',
                        buttonLabel: 'Kembali',
                        onButton: () => context.pop(),
                      ),
              ),
              Positioned(
                top: 14,
                left: 18,
                child: RoundIconButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
              ),
            ],
          ),
        ),
      );
    }
    return _buildDetail(context, p);
  }

  // Fungsi utama untuk merender tampilan antarmuka detail produk
  Widget _buildDetail(BuildContext context, Product p) {
    final (bg, _) = AppColors.toneFor(p.id);
    final top = MediaQuery.paddingOf(context).top;
    final heroH = 320 + top;
    final have = context.select<CartProvider, int>((c) => c.quantityOf(p.id));
    final remaining = context.select<CartProvider, int>((c) => c.remainingFor(p));
    final fav = context.select<ProductProvider, bool>((v) => v.isFavorite(p.id));
    final saving = p.price - p.discountedPrice;

    // Menentukan warna dan teks status ketersediaan stok produk
    final (stockColor, stockText) = p.stock <= 0
        ? (AppColors.pink, 'Stok habis')
        : p.stock < 10
            ? (AppColors.yellow, 'Stok menipis (${p.stock})')
            : (AppColors.mint, 'Tersedia, ${p.stock} stok');

    final qty = _qty > remaining && remaining > 0 ? remaining : _qty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // ---- Bagian Hero (Latar belakang warna pastel dan ilustrasi gambar produk)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: heroH,
              child: Container(
                color: bg,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: top),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Lingkaran latar belakang animasi pertama
                          Reveal(
                            duration: const Duration(milliseconds: 1400),
                            offset: Offset.zero,
                            scaleFrom: .6,
                            child: Container(
                              width: 290,
                              height: 290,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: .55),
                              ),
                            ),
                          ),
                          // Lingkaran border latar belakang animasi kedua
                          Reveal(
                            delay: const Duration(milliseconds: 100),
                            duration: const Duration(milliseconds: 1800),
                            offset: Offset.zero,
                            scaleFrom: .6,
                            child: Container(
                              width: 350,
                              height: 350,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: .6), width: 1.5),
                              ),
                            ),
                          ),
                          // Gambar produk utama dengan efek reveal dan rotasi
                          Reveal(
                            duration: const Duration(milliseconds: 1100),
                            offset: const Offset(0, 22),
                            scaleFrom: .78,
                            rotateFrom: -.07,
                            child: SizedBox(
                              width: 230,
                              height: 230,
                              child: ProductImage(
                                url: p.thumbnail,
                                category: p.category,
                                id: p.id,
                                artFactor: .78,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tombol Kembali (Back) di pojok kiri atas
                    Positioned(
                      top: top + 14,
                      left: 18,
                      child: _Fab(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                    ),
                    // Tombol Aksi (Menu opsi edit/hapus dan tombol Favorit) di pojok kanan atas
                    Positioned(
                      top: top + 14,
                      right: 18,
                      child: Row(
                        children: [
                          PopupMenuButton<String>(
                            tooltip: 'Menu',
                            color: Colors.white,
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            onSelected: (v) => v == 'edit' ? _edit(p) : _delete(p),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  const Icon(Icons.edit_outlined, size: 18, color: AppColors.ink),
                                  const SizedBox(width: 10),
                                  Text('Edit produk', style: AppText.sans(13, w: FontWeight.w600)),
                                ]),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  const Icon(Icons.delete_outline_rounded,
                                      size: 18, color: AppColors.heart),
                                  const SizedBox(width: 10),
                                  Text('Hapus',
                                      style: AppText.sans(13, w: FontWeight.w600, color: AppColors.heart)),
                                ]),
                              ),
                            ],
                            child: const _Fab(icon: Icons.more_horiz_rounded),
                          ),
                          const SizedBox(width: 8),
                          _Fab(
                            icon: fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: fav ? AppColors.heart : AppColors.ink,
                            onTap: () => toggleFavoriteWithToast(context, p.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ---- Lembar isi detail produk (bagian bawah dengan sudut melengkung)
            Column(
              children: [
                SizedBox(height: heroH - 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x4D483858),
                        blurRadius: 30,
                        spreadRadius: -20,
                        offset: Offset(0, -18),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label kategori, brand, dan status stok
                      Reveal(
                        delay: const Duration(milliseconds: 75),
                        child: Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            InfoTag(prettyCategory(p.category)),
                            if (p.brand.isNotEmpty) InfoTag(p.brand, color: AppColors.peach),
                            InfoTag(stockText, color: stockColor),
                          ],
                        ),
                      ),
                      // Judul nama produk
                      Reveal(
                        delay: const Duration(milliseconds: 150),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(p.title, style: AppText.serif(29, height: 1.05)),
                        ),
                      ),
                      // Rating produk dan info jumlah produk yang sudah ada di keranjang
                      Reveal(
                        delay: const Duration(milliseconds: 225),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              RatingPill(rating: p.rating, fontSize: 11.5),
                              if (have > 0) ...[
                                const SizedBox(width: 8),
                                InfoTag('$have di keranjang', color: AppColors.mint),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Kotak harga diskon, harga asli, dan besaran hemat
                      Reveal(
                        delay: const Duration(milliseconds: 300),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.lavender.withValues(alpha: .8),
                                AppColors.pink.withValues(alpha: .7),
                              ],
                            ),
                          ),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.end,
                            spacing: 10,
                            runSpacing: 6,
                            children: [
                              Text(usd(p.discountedPrice), style: AppText.serif(38, height: 1)),
                              if (p.discountPercentage >= 1) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Text(usd(p.price),
                                      style: AppText.sans(14,
                                          w: FontWeight.w600,
                                          color: AppColors.ink3,
                                          decoration: TextDecoration.lineThrough)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text('Hemat ${usd(saving)}',
                                      style: AppText.sans(11, w: FontWeight.w800)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Bagian deskripsi produk
                      Reveal(
                        delay: const Duration(milliseconds: 375),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Deskripsi', style: AppText.serif(20)),
                              const SizedBox(height: 6),
                              Text(p.description,
                                  style: AppText.sans(13,
                                      color: const Color(0xFF6B5D7C), height: 1.7)),
                            ],
                          ),
                        ),
                      ),
                      // Bagian informasi layanan (garansi, pengiriman, kebijakan pengembalian)
                      Reveal(
                        delay: const Duration(milliseconds: 450),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Layanan', style: AppText.serif(20)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _Tile(
                                      icon: Icons.verified_user_outlined,
                                      color: AppColors.mint,
                                      text: p.warrantyInformation,
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: _Tile(
                                      icon: Icons.local_shipping_outlined,
                                      color: AppColors.peach,
                                      text: p.shippingInformation,
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: _Tile(
                                      icon: Icons.replay_rounded,
                                      color: AppColors.lavender,
                                      text: p.returnPolicy,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      // Tombol bar bawah (Bottom Navigation Bar) untuk stepper kuantitas dan tombol tambah ke keranjang
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xF7FFFAF6),
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Row(
              children: [
                QtyStepper(
                  value: qty,
                  onDec: () => setState(() => _qty = qty > 1 ? qty - 1 : 1),
                  onInc: () => setState(() => _qty = qty < remaining ? qty + 1 : qty),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    label: 'Tambah ke Keranjang',
                    icon: Icons.shopping_bag_outlined,
                    expand: true,
                    radius: 18,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    onTap: p.stock <= 0
                        ? null // Tombol disable jika stok habis
                        : () {
                            final added = addToCartWithToast(context, p, quantity: qty);
                            if (added > 0) setState(() => _qty = 1); // Reset kuantitas input jika berhasil
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget privat _Fab untuk mendesain tombol bulat aksi (Floating Action Button style) di bagian atas
class _Fab extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  const _Fab({required this.icon, this.onTap, this.color = AppColors.ink});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: .88,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .86),
          shape: BoxShape.circle,
          boxShadow: AppColors.softShadow,
        ),
        child: Icon(icon, size: 19, color: color),
      ),
    );
  }
}

// Widget privat _Tile untuk menampilkan kartu informasi layanan kecil
class _Tile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _Tile({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: AppColors.ink),
          ),
          const SizedBox(height: 7),
          Text(text,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppText.sans(10.5, w: FontWeight.w600, color: AppColors.inkSoft, height: 1.3)),
        ],
      ),
    );
  }
}