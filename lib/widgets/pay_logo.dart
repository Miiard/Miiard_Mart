import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Gambar kecil metode pembayaran: logo QRIS asli milikmu, atau lencana berwarna pastel.
class PayLogo extends StatelessWidget {
  final PayMethod method;
  final double size;
  const PayLogo(this.method, {super.key, this.size = 46});

  @override
  Widget build(BuildContext context) {
    if (method.isQris) {
      return Container(
        width: size * 1.5,
        height: size,
        padding: EdgeInsets.all(size * 0.14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.32),
          border: Border.all(color: AppColors.lavender, width: 1.2),
        ),
        child: Image.asset('assets/images/qris_logo.png', fit: BoxFit.contain),
      );
    }
    return Container(
      width: size * 1.5,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color(method.color),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Text(
        method.badge,
        style: AppText.sans(
          size: method.badge.length > 3 ? size * 0.27 : size * 0.33,
          weight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
