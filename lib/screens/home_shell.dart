import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/nav_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/brand_mark.dart';
import '../widgets/cart_button.dart';
import '../widgets/reveal.dart';
import 'cart_screen.dart';
import 'list_product_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

/// Kerangka utama: header merek + 4 tab + navigasi bawah dengan pil yang meluncur.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  @override
  void initState() {
    super.initState();
    // jumlah pesanan di Profil diambil dari database
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tab = context.select<NavProvider, int>((n) => n.index);
    final pages = <Widget>[
      const ListProductScreen(),
      const SearchScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(key: ValueKey(tab), child: pages[tab]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _PastelNavBar(),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthProvider, String>((a) => a.user?.firstName ?? 'teman');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 14, 6),
      child: Reveal(
        dy: -14,
        child: Row(
          children: [
            const BrandMark(size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MIIARD.MART',
                    style: AppText.serif(size: 20, letterSpacing: 1.6),
                  ),
                  Text(
                    'Halo, $name 👋',
                    style: AppText.sans(size: 12, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            CartButton(targetKey: cartTargetKey),
          ],
        ),
      ),
    );
  }
}

class _PastelNavBar extends StatelessWidget {
  const _PastelNavBar();

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Beranda'),
    (Icons.search_rounded, Icons.search_rounded, 'Cari'),
    (Icons.shopping_bag_rounded, Icons.shopping_bag_outlined, 'Keranjang'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();
    final cartCount = context.select<CartProvider, int>((c) => c.totalQuantity);
    final bottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          boxShadow: AppColors.liftShadow,
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth / _items.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutBack,
                  left: w * nav.index + 6,
                  top: 6,
                  width: w - 12,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradBtn,
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => nav.go(i),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AnimatedScale(
                                    scale: nav.index == i ? 1.12 : 1,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutBack,
                                    child: Icon(
                                      nav.index == i ? _items[i].$1 : _items[i].$2,
                                      size: 24,
                                      color: nav.index == i
                                          ? AppColors.ink
                                          : AppColors.inkFaint,
                                    ),
                                  ),
                                  if (i == 2 && cartCount > 0)
                                    Positioned(
                                      right: -6,
                                      top: -4,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: AppColors.heart,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _items[i].$3,
                                style: AppText.sans(
                                  size: 10.5,
                                  weight: nav.index == i ? FontWeight.w800 : FontWeight.w600,
                                  color: nav.index == i ? AppColors.ink : AppColors.inkFaint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
