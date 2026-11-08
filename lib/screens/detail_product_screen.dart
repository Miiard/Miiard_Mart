import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/format.dart';
import '../widgets/app_toast.dart';
import '../widgets/cart_button.dart';
import '../widgets/fly_to_cart.dart';
import '../widgets/grad_button.dart';
import '../widgets/product_image.dart';
import '../widgets/reveal.dart';

class DetailProductScreen extends StatefulWidget {
  final String id;
  final Product? product;
  const DetailProductScreen({super.key, required this.id, this.product});

  @override
  State<DetailProductScreen> createState() => _DetailProductScreenState();
}

class _DetailProductScreenState extends State<DetailProductScreen> {
  Product? _product;
  String? _error;
  final _pageController = PageController();
  final GlobalKey _buyKey = GlobalKey();
  final GlobalKey _localCartKey = GlobalKey();
  int _page = 0;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    if (_product == null) _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final p = await context.read<ProductProvider>().fetchProduct(widget.id);
      if (mounted) setState(() => _product = p);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat detail produk.');
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _edit(Product p) async {
    final updated = await context.push<Product>('/edit/${p.id}', extra: p);
    if (updated != null && mounted) {
      setState(() {
        _product = updated;
        _page = 0;
      });
    }
  }

  Future<void> _confirmDelete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Hapus produk?', style: AppText.sans(size: 17, weight: FontWeight.w800)),
        content: Text(
          '"${p.title}" akan dihapus dari daftar.',
          style: AppText.sans(color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.ink)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.pink,
              foregroundColor: AppColors.ink,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final cart = context.read<CartProvider>();
    final done = await context.read<ProductProvider>().deleteProduct(p.id);
    if (!mounted) return;

    if (done) cart.remove(p.id);
    showAppToast(
      context,
      message: done ? 'Produk dihapus' : 'Gagal menghapus produk',
      icon: done ? Icons.delete_outline_rounded : Icons.error_outline_rounded,
      color: AppColors.pink,
    );
    if (done) _goBack();
  }

  void _addToCart(Product p, int qty) {
    final added = context.read<CartProvider>().add(p, quantity: qty);
    if (added > 0) {
      flyToCart(
        context,
        from: _buyKey,
        to: _localCartKey,
        imageUrl: p.thumbnail,
      );
    }
    setState(() => _qty = 1);
    showCartToast(context, product: p, added: added);
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => Pressable(
        scale: 0.88,
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.o(0.9),
            shape: BoxShape.circle,
            boxShadow: AppColors.softShadow,
          ),
          child: Icon(icon, color: AppColors.ink, size: 21),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = _product;
    if (p == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.ink,
          elevation: 0,
        ),
        body: Center(
          child: _error == null
              ? const CircularProgressIndicator(color: AppColors.ink)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: AppText.sans(color: AppColors.inkSoft)),
                    const SizedBox(height: 14),
                    GradButton(label: 'Coba lagi', icon: Icons.refresh_rounded, onTap: _load),
                  ],
                ),
        ),
      );
    }

    final tone = AppColors.toneFor(p.id);
    final cart = context.watch<CartProvider>();
    final remaining = cart.remainingFor(p);
    final maxQty = remaining < 1 ? 1 : remaining;
    final qty = _qty > maxQty ? maxQty : _qty;
    final fav = context.select<ProductProvider, bool>((m) => m.isFavorite(p.id));
    final isAdmin = context.select<AuthProvider, bool>((a) => a.isAdmin);
    final images = p.images.isEmpty ? [p.thumbnail] : p.images;
    final soldOut = p.stock <= 0;
    final canAdd = !soldOut && remaining > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              // ---- galeri
              SizedBox(
                height: 360,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: tone.bg,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(40),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(40, 76, 40, 44),
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: images.length,
                          onPageChanged: (i) => setState(() => _page = i),
                          itemBuilder: (_, i) {
                            final img = ProductImage(url: images[i], iconSize: 60);
                            if (i != 0) return img;
                            return Hero(
                              tag: 'product-image-${p.id}',
                              child: Material(color: Colors.transparent, child: img),
                            );
                          },
                        ),
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 18,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < images.length; i++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _page ? 22 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: i == _page ? AppColors.ink : AppColors.ink.o(0.25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // ---- isi
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Reveal(
                      delayMs: 120,
                      child: Row(
                        children: [
                          _chip(categoryLabel(p.category), tone.bg),
                          const SizedBox(width: 8),
                          if (p.brand.isNotEmpty) _chip(p.brand, AppColors.lavender),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Reveal(
                      delayMs: 200,
                      child: Text(p.title, style: AppText.serif(size: 30, height: 1.05)),
                    ),
                    const SizedBox(height: 10),
                    Reveal(
                      delayMs: 280,
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.star, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            p.rating.toStringAsFixed(1),
                            style: AppText.sans(size: 14, weight: FontWeight.w800),
                          ),
                          Text(
                            '  •  ${p.reviews.length} ulasan',
                            style: AppText.sans(size: 13, color: AppColors.inkSoft),
                          ),
                          const Spacer(),
                          _stockPill(p),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Reveal(
                      delayMs: 360,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            money(p.discountedPrice),
                            style: AppText.sans(size: 28, weight: FontWeight.w800),
                          ),
                          const SizedBox(width: 10),
                          if (p.discountPercentage >= 1) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                money(p.price),
                                style: AppText.sans(
                                  size: 14,
                                  color: AppColors.inkFaint,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: _chip(
                                '-${p.discountPercentage.round()}%',
                                AppColors.rose,
                                color: AppColors.heart,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Reveal(
                      delayMs: 440,
                      child: Text(
                        p.description,
                        style: AppText.sans(size: 14, color: AppColors.inkSoft, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Reveal(
                      delayMs: 520,
                      child: Row(
                        children: [
                          Expanded(
                            child: _service(
                              Icons.local_shipping_rounded,
                              'Pengiriman',
                              p.shippingInformation,
                              AppColors.mint,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _service(
                              Icons.verified_user_rounded,
                              'Garansi',
                              p.warrantyInformation,
                              AppColors.lavender,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _service(
                              Icons.assignment_return_rounded,
                              'Retur',
                              p.returnPolicy,
                              AppColors.peach,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (p.reviews.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      Reveal(
                        delayMs: 600,
                        child: Text('Ulasan pembeli', style: AppText.serif(size: 24)),
                      ),
                      const SizedBox(height: 10),
                      for (var i = 0; i < p.reviews.length && i < 3; i++)
                        Reveal(
                          delayMs: 660 + i * 80,
                          child: _review(p.reviews[i]),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // ---- tombol atas
          Positioned(
            left: 16,
            right: 16,
            top: MediaQuery.of(context).padding.top + 8,
            child: Row(
              children: [
                _circleBtn(Icons.arrow_back_ios_new_rounded, _goBack),
                const Spacer(),
                _circleBtn(
                  fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  () => context.read<ProductProvider>().toggleFavorite(p.id),
                ),
                const SizedBox(width: 8),
                CartButton(targetKey: _localCartKey),
                if (isAdmin)
                  PopupMenuButton<String>(
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.ink),
                  onSelected: (v) {
                    if (v == 'edit') _edit(p);
                    if (v == 'delete') _confirmDelete(p);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18, color: AppColors.ink),
                          SizedBox(width: 10),
                          Text('Edit produk'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.heart),
                          SizedBox(width: 10),
                          Text('Hapus produk'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ---- bar beli
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Reveal(
              delayMs: 300,
              dy: 40,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  14 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: AppColors.liftShadow,
                ),
                child: Row(
                  children: [
                    if (canAdd) ...[
                      _stepper(qty, maxQty),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: KeyedSubtree(
                        key: _buyKey,
                        child: GradButton(
                          label: soldOut
                              ? 'Stok habis'
                              : remaining <= 0
                                  ? 'Stok maksimal di keranjang'
                                  : 'Tambah • ${money(p.discountedPrice * qty)}',
                          icon: Icons.shopping_bag_rounded,
                          onTap: canAdd ? () => _addToCart(p, qty) : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color bg, {Color color = AppColors.ink}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Text(
          text,
          style: AppText.sans(size: 11.5, weight: FontWeight.w800, color: color),
        ),
      );

  Widget _stockPill(Product p) {
    final out = p.stock <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: out ? AppColors.rose : AppColors.mint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        out ? 'Habis' : 'Stok ${p.stock}',
        style: AppText.sans(size: 11.5, weight: FontWeight.w800),
      ),
    );
  }

  Widget _service(IconData icon, String title, String text, Color bg) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.ink),
            const SizedBox(height: 8),
            Text(title, style: AppText.sans(size: 12, weight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppText.sans(size: 10.5, color: AppColors.inkSoft, height: 1.3),
            ),
          ],
        ),
      );

  Widget _review(Review r) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.reviewerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 13, weight: FontWeight.w800),
                  ),
                ),
                const Icon(Icons.star_rounded, size: 16, color: AppColors.star),
                const SizedBox(width: 2),
                Text('${r.rating}', style: AppText.sans(size: 12.5, weight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              r.comment,
              style: AppText.sans(size: 12.5, color: AppColors.inkSoft, height: 1.5),
            ),
          ],
        ),
      );

  Widget _stepper(int qty, int maxQty) {
    Widget btn(IconData icon, VoidCallback? onTap) => Pressable(
          scale: 0.85,
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: onTap == null ? AppColors.lavender.o(0.5) : AppColors.lavender,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.ink),
          ),
        );
    return Row(
      children: [
        btn(Icons.remove_rounded, qty > 1 ? () => setState(() => _qty = qty - 1) : null),
        SizedBox(
          width: 32,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Text(
              '$qty',
              key: ValueKey(qty),
              textAlign: TextAlign.center,
              style: AppText.sans(size: 16, weight: FontWeight.w800),
            ),
          ),
        ),
        btn(Icons.add_rounded, qty < maxQty ? () => setState(() => _qty = qty + 1) : null),
      ],
    );
  }
}
