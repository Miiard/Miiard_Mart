import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'reveal.dart';

/// Banner promo: gradasi pastel yang bergeser, logo melayang, cincin berdenyut, kilau berkala.
class HeroBanner extends StatefulWidget {
  final VoidCallback onShop;
  const HeroBanner({super.key, required this.onShop});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 8));
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

  Widget _ring(double phase) {
    final t = (_c.value * 2 + phase) % 1;
    return Opacity(
      opacity: (1 - t) * 0.55,
      child: Container(
        width: 150 * (0.55 + t * 0.9),
        height: 150 * (0.55 + t * 0.9),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final a = _c.value * 2 * math.pi;
        final drift = math.sin(a);
        final sheen = ((_c.value * 2) % 1) * 1.6 - 0.3;
        double s(double v) => v.clamp(0.0, 1.0).toDouble();

        return Container(
          height: 172,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment(-1 + drift * 0.5, -1),
              end: Alignment(1, 1 - drift * 0.5),
              colors: const [AppColors.pink, AppColors.lavender, AppColors.sky],
            ),
            boxShadow: AppColors.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.o(0),
                          Colors.white.o(0.35),
                          Colors.white.o(0),
                        ],
                        stops: [s(sheen - 0.15), s(sheen), s(sheen + 0.15)],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 6,
                top: 10,
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _ring(0),
                      _ring(0.5),
                      Transform.translate(
                        offset: Offset(0, math.sin(a * 2) * 6),
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo_mark.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.storefront_rounded,
                                color: AppColors.ink,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 18,
                bottom: 18,
                right: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.o(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'KOLEKSI BARU',
                        style: AppText.sans(
                          size: 9.5,
                          weight: FontWeight.w800,
                          letterSpacing: 1,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belanja lembut,\nhati ikut senang',
                      style: AppText.serif(size: 24, height: 1.05),
                    ),
                    const SizedBox(height: 12),
                    Pressable(
                      onTap: widget.onShop,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Cari produk',
                          style: AppText.sans(
                            size: 12,
                            weight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
