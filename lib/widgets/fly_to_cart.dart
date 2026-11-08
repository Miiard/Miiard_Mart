import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'product_image.dart';

/// Titik kecil bergambar produk yang terbang melengkung ke ikon keranjang.
/// Bila ikon keranjang tidak terlihat di layar, langsung memanggil [onDone].
void flyToCart(
  BuildContext context, {
  required GlobalKey from,
  required GlobalKey to,
  String imageUrl = '',
  VoidCallback? onDone,
}) {
  final a = from.currentContext?.findRenderObject();
  final b = to.currentContext?.findRenderObject();
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (a is! RenderBox || b is! RenderBox || !a.attached || !b.attached || overlay == null) {
    onDone?.call();
    return;
  }
  final start = a.localToGlobal(a.size.center(Offset.zero));
  final end = b.localToGlobal(b.size.center(Offset.zero));

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _FlyDot(
      start: start,
      end: end,
      imageUrl: imageUrl,
      onFinished: () {
        entry.remove();
        onDone?.call();
      },
    ),
  );
  overlay.insert(entry);
}

class _FlyDot extends StatefulWidget {
  final Offset start;
  final Offset end;
  final String imageUrl;
  final VoidCallback onFinished;

  const _FlyDot({
    required this.start,
    required this.end,
    required this.imageUrl,
    required this.onFinished,
  });

  @override
  State<_FlyDot> createState() => _FlyDotState();
}

class _FlyDotState extends State<_FlyDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Offset _bezier(double t) {
    final control = Offset(
      (widget.start.dx + widget.end.dx) / 2,
      (widget.start.dy < widget.end.dy ? widget.start.dy : widget.end.dy) - 90,
    );
    final u = 1 - t;
    return widget.start * (u * u) + control * (2 * u * t) + widget.end * (t * t);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_c.value);
          final p = _bezier(t);
          final size = 44 - 26 * t;
          return Stack(
            children: [
              Positioned(
                left: p.dx - size / 2,
                top: p.dy - size / 2,
                child: Opacity(
                  opacity: 1 - 0.35 * t,
                  child: Container(
                    width: size,
                    height: size,
                    padding: EdgeInsets.all(size * 0.14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.lav2, width: 2),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: ClipOval(
                      child: ProductImage(
                        url: widget.imageUrl,
                        iconSize: 14,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
