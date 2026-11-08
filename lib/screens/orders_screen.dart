import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_toast.dart';
import '../widgets/grad_button.dart';
import '../widgets/order_card.dart';
import '../widgets/qris_sheet.dart';
import '../widgets/reveal.dart';

/// Riwayat pesanan milik pengguna.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderProvider>().load();
    });
  }

  Future<void> _cancel(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Batalkan pesanan?', style: AppText.sans(size: 17, weight: FontWeight.w800)),
        content: Text('Stok barang akan dikembalikan.', style: AppText.sans(color: AppColors.inkSoft)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak', style: TextStyle(color: AppColors.ink)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.pink, foregroundColor: AppColors.ink),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final orders = context.read<OrderProvider>();
    final products = context.read<ProductProvider>();
    final done = await orders.cancel(id);
    if (!mounted) return;
    if (done) products.refresh();
    showAppToast(
      context,
      message: done ? 'Pesanan dibatalkan' : 'Gagal membatalkan',
      subtitle: done ? null : orders.error,
      icon: done ? Icons.check_circle_rounded : Icons.error_outline_rounded,
      color: done ? AppColors.mint : AppColors.rose,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OrderProvider>();

    Widget body;
    if (p.loading && p.orders.isEmpty) {
      body = const Center(child: CircularProgressIndicator(color: AppColors.ink));
    } else if (p.error != null && p.orders.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(p.error!, textAlign: TextAlign.center, style: AppText.sans(color: AppColors.inkSoft, height: 1.5)),
              const SizedBox(height: 14),
              GradButton(label: 'Coba lagi', icon: Icons.refresh_rounded, onTap: () => p.load()),
            ],
          ),
        ),
      );
    } else if (p.orders.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Reveal(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(gradient: AppColors.heroGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.local_shipping_outlined, size: 44, color: AppColors.ink),
                ),
                const SizedBox(height: 16),
                Text('Belum ada pesanan', style: AppText.serif(size: 26)),
                const SizedBox(height: 6),
                Text('Pesanan yang kamu buat akan muncul di sini.',
                    textAlign: TextAlign.center, style: AppText.sans(color: AppColors.inkSoft)),
                const SizedBox(height: 18),
                GradButton(label: 'Mulai belanja', icon: Icons.storefront_rounded, onTap: () => context.go('/')),
              ],
            ),
          ),
        ),
      );
    } else {
      body = RefreshIndicator(
        color: AppColors.ink,
        backgroundColor: Colors.white,
        onRefresh: () => p.load(),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          itemCount: p.orders.length,
          itemBuilder: (context, i) {
            final o = p.orders[i];
            final card = OrderCard(
              order: o,
              footer: o.canCancel
                  ? Column(
                      children: [
                        if (o.paymentMethod == 'qris') ...[
                          GradButton(
                            label: 'Bayar dengan QRIS',
                            icon: Icons.qr_code_2_rounded,
                            height: 46,
                            onTap: () => showQrisSheet(context, code: o.code, total: o.total, button: 'Tutup'),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Pressable(
                          onTap: () => _cancel(o.id),
                          child: Container(
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: AppColors.rose, borderRadius: BorderRadius.circular(21)),
                            child: Text('Batalkan pesanan', style: AppText.sans(size: 13, weight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    )
                  : null,
            );
            if (i >= 8) return card;
            return Reveal(key: ValueKey('order-${o.id}'), delayMs: i * 70, child: card);
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 20, 12),
              child: Reveal(
                dy: -12,
                child: Row(
                  children: [
                    Pressable(
                      scale: 0.88,
                      onTap: () => context.canPop() ? context.pop() : context.go('/'),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppColors.softShadow,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Pesanan Saya', style: AppText.serif(size: 30))),
                  ],
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
