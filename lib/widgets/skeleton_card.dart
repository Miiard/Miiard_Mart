import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Kartu placeholder berdenyut saat data produk sedang dimuat.
class SkeletonCard extends StatefulWidget {
  final int index;
  const SkeletonCard({super.key, required this.index});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.ink.o(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.pastelFor(widget.index),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Icon(
                  Icons.image_rounded,
                  size: 44,
                  color: Colors.white.o(0.7),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: Colors.white.o(0.75),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(100, 12),
                  const SizedBox(height: 8),
                  _bar(60, 10),
                  const SizedBox(height: 12),
                  _bar(70, 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
