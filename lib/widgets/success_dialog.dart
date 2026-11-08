import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'grad_button.dart';

/// Dialog sukses: lingkaran membal, centang tergambar, percikan titik.
class SuccessDialog extends StatefulWidget {
  final String title;
  final String line1;
  final String? line2;
  final String button;
  const SuccessDialog({
    super.key,
    required this.title,
    required this.line1,
    this.line2,
    this.button = 'Lanjut',
  });

  @override
  State<SuccessDialog> createState() => SuccessDialogState();
}

class SuccessDialogState extends State<SuccessDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 130,
              height: 130,
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) =>
                    CustomPaint(painter: CheckPainter(_c.value)),
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.title, textAlign: TextAlign.center, style: AppText.serif(size: 28)),
            const SizedBox(height: 6),
            Text(
              widget.line1,
              textAlign: TextAlign.center,
              style: AppText.sans(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 4),
            if (widget.line2 != null)
              Text(
                widget.line2!,
                textAlign: TextAlign.center,
                style: AppText.sans(size: 12.5, color: AppColors.inkFaint, height: 1.45),
              ),
            const SizedBox(height: 18),
            GradButton(
              label: widget.button,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckPainter extends CustomPainter {
  final double t;
  CheckPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final circleT = Curves.elasticOut.transform((t / 0.45).clamp(0.0, 1.0).toDouble());
    final r = 44.0 * circleT;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = AppColors.gradBtn.createShader(Rect.fromCircle(center: c, radius: 44)),
    );

    // percikan
    final burstT = ((t - 0.3) / 0.7).clamp(0.0, 1.0).toDouble();
    if (burstT > 0) {
      const colors = [AppColors.pink, AppColors.mint, AppColors.butter, AppColors.lav2];
      for (var i = 0; i < 12; i++) {
        final ang = i * math.pi / 6;
        final dist = 48 + 16 * Curves.easeOutCubic.transform(burstT);
        final p = c + Offset(math.cos(ang), math.sin(ang)) * dist;
        canvas.drawCircle(
          p,
          4.5 * (1 - burstT) + 1,
          Paint()..color = colors[i % colors.length].o(1 - burstT * 0.7),
        );
      }
    }

    // centang
    final checkT = Curves.easeOutCubic.transform(((t - 0.35) / 0.4).clamp(0.0, 1.0).toDouble());
    if (checkT > 0) {
      final path = Path()
        ..moveTo(c.dx - 18, c.dy + 2)
        ..lineTo(c.dx - 5, c.dy + 15)
        ..lineTo(c.dx + 19, c.dy - 12);
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * checkT),
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CheckPainter old) => old.t != t;
}
