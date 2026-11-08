import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/nav_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/format.dart';
import '../widgets/app_toast.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/grad_button.dart';
import '../widgets/pay_logo.dart';
import '../widgets/qris_sheet.dart';
import '../widgets/reveal.dart';
import '../widgets/success_dialog.dart';

/// Checkout: alamat pengiriman, pilih metode pembayaran, bayar. Pesanan disimpan di MySQL.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: context.read<AuthProvider>().user?.name ?? '');
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String? _method;
  bool _busy = false;
  bool _methodError = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final cart = context.read<CartProvider>();
    if (cart.isEmpty) return;
    final okForm = _form.currentState?.validate() ?? false;
    if (_method == null) setState(() => _methodError = true);
    if (!okForm || _method == null) return;

    final orders = context.read<OrderProvider>();
    final products = context.read<ProductProvider>();
    final nav = context.read<NavProvider>();
    final router = GoRouter.of(context);

    setState(() => _busy = true);
    final order = await orders.place(
      items: cart.items,
      paymentMethod: _method!,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);

    if (order == null) {
      showAppToast(
        context,
        message: 'Pesanan gagal',
        subtitle: orders.error,
        icon: Icons.error_outline_rounded,
        color: AppColors.rose,
      );
      return;
    }

    final cod = order.paymentMethod == 'cod';
    cart.clear();
    products.refresh(); // stok di database sudah berkurang
    if (order.paymentMethod == 'qris') {
      await showQrisSheet(context, code: order.code, total: order.total, button: 'Lihat pesanan');
    } else {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => SuccessDialog(
        title: 'Pesanan berhasil!',
        line1: '${order.code} • ${money(order.total)}',
        line2: cod
            ? 'Siapkan uang pas saat kurir tiba.'
            : 'Selesaikan pembayaran via ${order.paymentLabel}. Admin akan memverifikasi dan memproses pesananmu.',
        button: 'Lihat pesanan',
        ),
      );
    }
    if (!mounted) return;
    nav.go(0);
    router.go('/');
    router.push('/orders');
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final bottom = 24 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 20, 4),
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
                    Expanded(child: Text('Checkout', style: AppText.serif(size: 30))),
                  ],
                ),
              ),
            ),
            Expanded(
              child: cart.isEmpty && !_busy
                  ? Center(
                      child: Text('Keranjang kosong.', style: AppText.sans(color: AppColors.inkSoft)),
                    )
                  : ListView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(20, 10, 20, bottom),
                      children: [
                        Reveal(delayMs: 60, child: _summary(cart)),
                        const SizedBox(height: 20),
                        Reveal(delayMs: 120, child: _sectionTitle('Alamat pengiriman')),
                        const SizedBox(height: 10),
                        Reveal(delayMs: 160, child: _addressForm()),
                        const SizedBox(height: 22),
                        Reveal(delayMs: 220, child: _sectionTitle('Metode pembayaran')),
                        if (_methodError && _method == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Pilih salah satu metode pembayaran.',
                              style: AppText.sans(size: 12, color: const Color(0xFFC0506E), weight: FontWeight.w700),
                            ),
                          ),
                        const SizedBox(height: 8),
                        ..._methods(),
                        const SizedBox(height: 18),
                        Reveal(
                          delayMs: 300,
                          child: GradButton(
                            label: 'Bayar ${money(cart.total)}',
                            icon: Icons.lock_rounded,
                            loading: _busy,
                            onTap: _pay,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: AppText.serif(size: 22));

  Widget _summary(CartProvider cart) {
    Widget row(String l, Widget v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(child: Text(l, style: AppText.sans(size: 13, color: AppColors.inkSoft))),
              v,
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          row('${cart.totalQuantity} barang', Text(money(cart.originalTotal), style: AppText.sans(weight: FontWeight.w700))),
          if (cart.savings > 0.005)
            row(
              'Hemat diskon',
              Text('- ${money(cart.savings)}',
                  style: AppText.sans(weight: FontWeight.w800, color: const Color(0xFF3FA27F))),
            ),
          row('Ongkir', Text('Gratis', style: AppText.sans(weight: FontWeight.w800, color: const Color(0xFF3FA27F)))),
          const Divider(height: 18, color: AppColors.lavender),
          Row(
            children: [
              Expanded(child: Text('Total', style: AppText.serif(size: 21))),
              Text(money(cart.total), style: AppText.sans(size: 19, weight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _addressForm() {
    return Form(
      key: _form,
      child: Column(
        children: [
          AuthField(
            controller: _name,
            label: 'Nama penerima',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().length < 2) ? 'Nama minimal 2 karakter' : null,
          ),
          const SizedBox(height: 12),
          AuthField(
            controller: _phone,
            label: 'Nomor telepon',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                RegExp(r'^[0-9+\-\s]{8,20}$').hasMatch((v ?? '').trim()) ? null : 'Nomor telepon tidak valid',
          ),
          const SizedBox(height: 12),
          AuthField(
            controller: _address,
            label: 'Alamat lengkap',
            icon: Icons.location_on_outlined,
            textInputAction: TextInputAction.done,
            validator: (v) => (v == null || v.trim().length < 10) ? 'Alamat minimal 10 karakter' : null,
          ),
        ],
      ),
    );
  }

  List<Widget> _methods() {
    final out = <Widget>[];
    String? group;
    var i = 0;
    for (final m in payMethods) {
      if (m.group != group) {
        group = m.group;
        out.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Text(
            m.group.toUpperCase(),
            style: AppText.sans(size: 10.5, weight: FontWeight.w800, color: AppColors.inkFaint, letterSpacing: 1.2),
          ),
        ));
      }
      out.add(Reveal(delayMs: 260 + i * 40, child: _methodTile(m)));
      i++;
    }
    return out;
  }

  Widget _methodTile(PayMethod m) {
    final selected = _method == m.code;
    return Pressable(
      scale: 0.98,
      onTap: () => setState(() {
        _method = m.code;
        _methodError = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.lavender.o(0.55) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.ink : Colors.transparent, width: 1.5),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            PayLogo(m, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.label, style: AppText.sans(size: 14, weight: FontWeight.w800)),
                  Text(m.hint, style: AppText.sans(size: 11.5, color: AppColors.inkSoft)),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(
                selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                key: ValueKey(selected),
                color: selected ? AppColors.ink : AppColors.inkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
