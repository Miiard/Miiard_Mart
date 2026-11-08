import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Logo Miiard.Mart (huruf M dalam karangan daun) berbentuk lingkaran.
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: AppColors.softShadow,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo_mark.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Text(
              'M',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
