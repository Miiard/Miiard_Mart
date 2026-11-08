import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/nav_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../models/user_model.dart';
import '../widgets/app_toast.dart';
import '../widgets/brand_mark.dart';
import '../widgets/reveal.dart';

/// Profil: avatar dengan cincin putus-putus berputar, statistik berhitung naik, menu.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.select<OrderProvider, int>((o) => o.activeCount);
    final inCart = context.select<CartProvider, int>((c) => c.totalQuantity);
    final favs = context.select<ProductProvider, int>((p) => p.favoritesCount);
    final bottomPad = 120 + MediaQuery.of(context).padding.bottom;
    final user = context.select<AuthProvider, AppUser?>((a) => a.user);
    final isAdmin = user?.isAdmin ?? false;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad),
      children: [
        Reveal(
          fromScale: 0.9,
          child: Center(
            child: _Avatar(
              initial: user?.initial ?? 'M',
              imageUrl: user?.avatarFullUrl,
              onTap: () => _pickAvatar(context, hasPhoto: user?.avatarUrl != null),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Reveal(
          delayMs: 120,
          child: Column(
            children: [
              Text(user?.name ?? 'Tamu', style: AppText.serif(size: 32)),
              Text(
                user?.email ?? '',
                style: AppText.sans(size: 12.5, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  isAdmin ? 'ADMIN MIIARD' : 'MEMBER MIIARD',
                  style: AppText.sans(size: 10.5, weight: FontWeight.w800, letterSpacing: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Reveal(
          delayMs: 220,
          child: Row(
            children: [
              Expanded(child: _stat(orders, 'Pesanan', AppColors.peach)),
              const SizedBox(width: 10),
              Expanded(child: _stat(favs, 'Wishlist', AppColors.rose)),
              const SizedBox(width: 10),
              Expanded(child: _stat(inCart, 'Keranjang', AppColors.mint)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Reveal(
          delayMs: 320,
          child: _menu(
            context,
            Icons.favorite_rounded,
            'Wishlist saya',
            AppColors.rose,
            () => context.push('/wishlist'),
          ),
        ),
        if (isAdmin)
          Reveal(
            delayMs: 380,
            child: _menu(
              context,
              Icons.admin_panel_settings_rounded,
              'Panel admin (produk & pengguna)',
              AppColors.mint,
              () => context.push('/admin'),
            ),
          ),
        Reveal(
          delayMs: 440,
          child: _menu(
            context,
            Icons.local_shipping_rounded,
            'Pesanan saya',
            AppColors.peach,
            () => context.push('/orders'),
          ),
        ),
        Reveal(
          delayMs: 500,
          child: _menu(
            context,
            Icons.help_outline_rounded,
            'Bantuan',
            AppColors.sky,
            () => showAppToast(
              context,
              message: 'Hai ${user?.firstName ?? 'teman'} 👋',
              subtitle: 'Tim Miiard siap membantu kapan saja',
              icon: Icons.chat_bubble_outline_rounded,
              color: AppColors.sky,
            ),
          ),
        ),
        Reveal(
          delayMs: 540,
          child: _menu(
            context,
            Icons.logout_rounded,
            'Keluar',
            AppColors.rose,
            () => _logout(context),
          ),
        ),
        const SizedBox(height: 26),
        Reveal(
          delayMs: 600,
          child: Column(
            children: [
              const BrandMark(size: 52),
              const SizedBox(height: 8),
              Text('MIIARD.MART', style: AppText.serif(size: 18, letterSpacing: 1.6)),
              Text(
                'Versi 1.0',
                style: AppText.sans(size: 11, color: AppColors.inkFaint),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickAvatar(BuildContext context, {required bool hasPhoto}) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Widget item(IconData icon, String label, String value, Color bg) => ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.ink, size: 21),
              ),
              title: Text(label, style: AppText.sans(size: 14, weight: FontWeight.w700)),
              onTap: () => Navigator.pop(ctx, value),
            );
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(3)),
                  ),
                  item(Icons.photo_library_rounded, 'Pilih dari galeri', 'gallery', AppColors.lavender),
                  item(Icons.photo_camera_rounded, 'Ambil foto', 'camera', AppColors.mint),
                  if (hasPhoto) item(Icons.delete_outline_rounded, 'Hapus foto', 'remove', AppColors.rose),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (choice == null || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    String? error;
    if (choice == 'remove') {
      error = await auth.removeAvatar();
    } else {
      final XFile? file;
      try {
        file = await ImagePicker().pickImage(
          source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 640,
          maxHeight: 640,
          imageQuality: 82,
        );
      } catch (_) {
        if (!context.mounted) return;
        showAppToast(
          context,
          message: 'Tidak bisa membuka ${choice == 'camera' ? 'kamera' : 'galeri'}',
          subtitle: 'Periksa izin aplikasi di pengaturan HP',
          icon: Icons.error_outline_rounded,
          color: AppColors.rose,
        );
        return;
      }
      if (file == null) return; // dibatalkan
      error = await auth.changeAvatar(await file.readAsBytes());
    }
    if (!context.mounted) return;
    showAppToast(
      context,
      message: error == null ? (choice == 'remove' ? 'Foto dihapus' : 'Foto profil diperbarui') : 'Gagal mengubah foto',
      subtitle: error,
      icon: error == null ? Icons.check_circle_rounded : Icons.error_outline_rounded,
      color: error == null ? AppColors.mint : AppColors.rose,
    );
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Keluar dari akun?', style: AppText.sans(size: 17, weight: FontWeight.w800)),
        content: Text(
          'Keranjangmu akan dikosongkan.',
          style: AppText.sans(color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.ink)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final auth = context.read<AuthProvider>();
    context.read<CartProvider>().clear();
    context.read<OrderProvider>().clear();
    context.read<NavProvider>().go(0);
    await auth.logout(); // router otomatis kembali ke halaman login
  }

  Widget _stat(int value, String label, Color bg) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            CountUpText(
              value: value.toDouble(),
              format: (v) => v.round().toString(),
              style: AppText.serif(size: 30),
            ),
            Text(label, style: AppText.sans(size: 11.5, weight: FontWeight.w700)),
          ],
        ),
      );

  Widget _menu(
    BuildContext context,
    IconData icon,
    String label,
    Color bg,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppColors.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)),
                child: Icon(icon, color: AppColors.ink, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label, style: AppText.sans(size: 14, weight: FontWeight.w700)),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatefulWidget {
  final String initial;
  final String? imageUrl;
  final VoidCallback onTap;
  const _Avatar({required this.initial, this.imageUrl, required this.onTap});

  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 14));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.of(context).disableAnimations) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _c,
            child: CustomPaint(
              size: const Size(132, 132),
              painter: _DashedRing(),
            ),
          ),
          Pressable(
            scale: 0.95,
            onTap: widget.onTap,
            child: Container(
              width: 104,
              height: 104,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: widget.imageUrl == null
                  ? Text(widget.initial, style: AppText.serif(size: 54))
                  : Image.network(
                      widget.imageUrl!,
                      width: 104,
                      height: 104,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(widget.initial, style: AppText.serif(size: 54)),
                    ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: IgnorePointer(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.softShadow,
                ),
                child: const Icon(Icons.photo_camera_rounded, size: 17, color: AppColors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRing extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 3;
    final paint = Paint()
      ..color = AppColors.lav2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const dashes = 28;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
