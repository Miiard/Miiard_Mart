import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/format.dart';
import 'grad_button.dart';

/// Lembar pembayaran QRIS: kode QR toko, nominal, dan langkah membayar.
/// Mengembalikan setelah ditutup.
Future<void> showQrisSheet(
  BuildContext context, {
  required String code,
  required double total,
  String button = 'Saya sudah bayar',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _QrisSheet(code: code, total: total, button: button),
  );
}

class _QrisSheet extends StatelessWidget {
  final String code;
  final double total;
  final String button;
  const _QrisSheet({required this.code, required this.total, required this.button});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: h * 0.92),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(height: 14),
              Text('Bayar dengan QRIS', style: AppText.serif(size: 28)),
              const SizedBox(height: 2),
              Text(code, style: AppText.sans(size: 12.5, color: AppColors.inkSoft, weight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(money(total), style: AppText.sans(size: 26, weight: FontWeight.w800)),
              Text(
                'Masukkan nominal persis sama saat membayar.',
                style: AppText.sans(size: 11.5, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.cardShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset('assets/images/qris.jpg', height: h * 0.46, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 14),
              _step('1', 'Buka aplikasi bank atau e-wallet, pilih Scan / Bayar.'),
              _step('2', 'Scan kode di atas, masukkan nominal sesuai total.'),
              _step('3', 'Selesaikan pembayaran. Admin akan memverifikasi pesananmu.'),
              const SizedBox(height: 16),
              GradButton(
                label: button,
                icon: Icons.check_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(String n, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
              child: Text(n, style: AppText.sans(size: 11.5, weight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: AppText.sans(size: 12.5, color: AppColors.inkSoft, height: 1.4)),
            ),
          ],
        ),
      );
}
