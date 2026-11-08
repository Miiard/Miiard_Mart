import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Layar pembuka: logo muncul dari buram ke tajam, kilau menyapu, kilauan bintang, garis progres.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() => _leave());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_left || !mounted) return;
    _left = true;
    // tunggu pemeriksaan sesi login; router lalu memilih beranda atau halaman login
    await context.read<AuthProvider>().restore();
    if (mounted) context.go('/');
  }

  double _seg(double a, double b, [Curve curve = Curves.easeOutCubic]) {
    final t = ((_c.value - a) / (b - a)).clamp(0.0, 1.0).toDouble();
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _leave(),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final logoIn = _seg(0.0, 0.4);
            final textIn = _seg(0.35, 0.6);
            final bar = _seg(0.1, 0.95, Curves.easeInOut);
            final sweep = _seg(0.4, 0.75, Curves.easeInOut);
            final blur = (1 - logoIn) * 14;

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.9,
                    child: Image.asset(
                      'assets/images/splash_bg.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppColors.background.o(0.0),
                          AppColors.background.o(0.55),
                        ],
                        radius: 0.95,
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < 7; i++) _sparkle(context, i),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: logoIn,
                        child: Transform.scale(
                          scale: 0.82 + 0.18 * logoIn,
                          child: ImageFiltered(
                            imageFilter: _blur(blur),
                            child: ShaderMask(
                              blendMode: BlendMode.srcATop,
                              shaderCallback: (rect) => LinearGradient(
                                colors: [
                                  Colors.white.o(0),
                                  Colors.white.o(0.75),
                                  Colors.white.o(0),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                                transform: _Slide(sweep),
                              ).createShader(rect),
                              child: Image.asset(
                                'assets/images/logo_full.png',
                                width: 230,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.storefront_rounded,
                                  size: 90,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Opacity(
                        opacity: textIn,
                        child: Transform.translate(
                          offset: Offset(0, 14 * (1 - textIn)),
                          child: Column(
                            children: [
                              Text(
                                'Miiard.Mart',
                                style: AppText.serif(size: 38, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'BELANJA LEMBUT, HATI SENANG',
                                style: AppText.sans(
                                  size: 10.5,
                                  weight: FontWeight.w700,
                                  color: AppColors.inkSoft,
                                  letterSpacing: 2.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 64,
                  child: Center(
                    child: Container(
                      width: 120,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.ink.o(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: bar,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.gradBtn,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sparkle(BuildContext context, int i) {
    final size = MediaQuery.of(context).size;
    final rnd = math.Random(i * 7 + 3);
    final x = 0.08 + rnd.nextDouble() * 0.84;
    final y = 0.1 + rnd.nextDouble() * 0.75;
    final phase = rnd.nextDouble();
    final tw = (math.sin((_c.value * 3 + phase) * 2 * math.pi) + 1) / 2;
    final s = 8.0 + rnd.nextDouble() * 10;
    return Positioned(
      left: size.width * x,
      top: size.height * y,
      child: Opacity(
        opacity: 0.15 + 0.6 * tw,
        child: Transform.scale(
          scale: 0.6 + 0.6 * tw,
          child: Icon(Icons.auto_awesome_rounded, size: s, color: AppColors.lav2),
        ),
      ),
    );
  }

  ImageFilter _blur(double sigma) => ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
}

/// Menggeser gradasi kilau dari kiri ke kanan logo.
class _Slide extends GradientTransform {
  final double t; // 0..1
  const _Slide(this.t);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = bounds.width * (t * 2 - 1);
    return Matrix4.translationValues(dx, 0, 0);
  }
}
