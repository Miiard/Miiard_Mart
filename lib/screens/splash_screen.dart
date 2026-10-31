
// Mengimpor pustaka asynchronous Dart untuk fitur timer/penundaan waktu
import 'dart:async';
// Mengimpor pustaka matematika Dart (alias math) untuk perhitungan sudut dan skala
import 'dart:math' as math;
// Mengimpor pustaka UI Dart untuk efek blur gambar (ImageFilter)
import 'dart:ui' as ui;

// Mengimpor pustaka utama material design dari Flutter
import 'package:flutter/material.dart';
// Mengimpor paket go_router untuk manajemen navigasi halaman
import 'package:go_router/go_router.dart';

// Mengimpor konfigurasi warna kustom aplikasi
import '../theme/app_colors.dart';
// Mengimpor konfigurasi gaya teks aplikasi
import '../theme/app_text.dart';
// Mengimpor kumpulan widget UI kit tambahan
import '../widgets/ui_kit.dart';

/// Layar pembuka: latar blur, logo muncul, kilau, dan garis pengisian.
/// Ketuk untuk melewati.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Controller animasi pengenalan (intro) berdurasi 2400 milidetik
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();
  
  // Controller animasi kilau (twinkle) yang berjalan berulang terus-menerus
  late final AnimationController _twinkle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat();

  // Definisi kurva animasi transisi untuk latar belakang, logo, tagline, dan garis loading
  late final Animation<double> _bg = _iv(0, .6);
  late final Animation<double> _logo = _iv(.06, .62);
  late final Animation<double> _tag = _iv(.56, .9);
  late final Animation<double> _line = _iv(.12, .88, Curves.easeInOutCubic);

  Timer? _timer;          // Timer otomatis untuk berpindah halaman setelah durasi tertentu
  bool _leaving = false;  // Status penanda apakah animasi keluar (exit) sedang berjalan

  // Fungsi helper untuk membuat CurvedAnimation dengan interval tertentu
  Animation<double> _iv(double a, double b, [Curve c = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _intro, curve: Interval(a, b, curve: c));

  @override
  void initState() {
    super.initState();
    // Mengatur timer 2700 milidetik untuk otomatis memicu fungsi pindah halaman (_leave)
    _timer = Timer(const Duration(milliseconds: 2700), _leave);
  }

  // Fungsi untuk menangani transisi keluar (fade-out & zoom) menuju halaman beranda (/home)
  void _leave() {
    if (_leaving || !mounted) return;
    setState(() => _leaving = true);
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();     // Membatalkan timer saat widget dihancurkan
    _intro.dispose();     // Membersihkan intro animation controller
    _twinkle.dispose();   // Membersihkan twinkle animation controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final logoW = math.min(330.0, w - 36); // Menyesuaikan lebar logo dengan ukuran layar perangkat

    return Scaffold(
      backgroundColor: const Color(0xFFEFE6FB),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _leave, // Memungkinkan pengguna melewati splash screen dengan mengetuk layar
        child: AnimatedOpacity(
          opacity: _leaving ? 0 : 1,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOutCubic,
          child: AnimatedScale(
            scale: _leaving ? 1.08 : 1,
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOutCubic,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Latar foto diburamkan (blurred background)
                ClipRect(
                  child: FadeTransition(
                    opacity: _bg,
                    child: AnimatedBuilder(
                      animation: _bg,
                      builder: (context, child) =>
                          Transform.scale(scale: 1.3 - .2 * _bg.value, child: child),
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                        child: Image.asset('assets/images/back.jpg', fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                // Efek animasi kilau (sparkle) pada berbagai posisi di layar
                _sparkle(const Alignment(-.68, -.56), 16, Colors.white, .10),
                _sparkle(const Alignment(.72, -.40), 11, Colors.white, .38),
                _sparkle(const Alignment(-.56, .48), 12, const Color(0xFFFFF0F5), .55),
                _sparkle(const Alignment(.60, .40), 18, Colors.white, .02),
                _sparkle(const Alignment(0, -.72), 9, Colors.white, .32),
                // Bagian Logo + Tagline di tengah layar
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animasi kemunculan logo aplikasi
                        AnimatedBuilder(
                          animation: _logo,
                          builder: (context, child) {
                            final v = _logo.value;
                            return Opacity(
                              opacity: v,
                              child: Transform.translate(
                                offset: Offset(0, 14 * (1 - v)),
                                child: Transform.scale(scale: .9 + .1 * v, child: child),
                              ),
                            );
                          },
                          child: SizedBox(
                            width: logoW,
                            child: AspectRatio(
                              aspectRatio: 491 / 466,
                              child: Image.asset('assets/images/logo.webp', fit: BoxFit.contain),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Animasi teks tagline di bawah logo
                        FadeTransition(
                          opacity: _tag,
                          child: SlideTransition(
                            position: Tween(begin: const Offset(0, .6), end: Offset.zero)
                                .animate(_tag),
                            child: Text(
                              'Belanja manis, serba pastel',
                              style: AppText.serif(19,
                                  w: FontWeight.w600,
                                  style: FontStyle.italic,
                                  color: AppColors.inkSoft,
                                  letterSpacing: .4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Garis pengisian (loading progress line) di bagian bawah
                Align(
                  alignment: const Alignment(0, .78),
                  child: Container(
                    width: 96,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    alignment: Alignment.centerLeft,
                    child: SizeTransition(
                      sizeFactor: _line,
                      axis: Axis.horizontal,
                      axisAlignment: -1,
                      child: Container(
                        width: 96,
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Fungsi helper untuk merender efek kilau bintang (sparkle) dengan animasi berkedip dan berputar
  Widget _sparkle(Alignment at, double size, Color color, double phase) {
    return Align(
      alignment: at,
      child: AnimatedBuilder(
        animation: _twinkle,
        builder: (context, _) {
          final t = (_twinkle.value + phase) % 1;
          final a = math.sin(t * math.pi);
          return Opacity(
            opacity: (a * .95).clamp(0.0, 1.0).toDouble(),
            child: Transform.rotate(
              angle: t * math.pi / 2,
              child: Transform.scale(
                scale: .4 + .6 * a,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: CustomPaint(painter: SparklePainter(color)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}