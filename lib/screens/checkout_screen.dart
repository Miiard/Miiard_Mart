// Mengimpor pustaka matematika untuk menghasilkan kode unik acak
import 'dart:math';

// Mengimpor pustaka utama material design dari Flutter
import 'package:flutter/material.dart';
// Mengimpor paket go_router untuk navigasi halaman
import 'package:go_router/go_router.dart';
// Mengimpor paket provider untuk mengakses state management
import 'package:provider/provider.dart';

// Mengimpor konfigurasi pembayaran (seperti kurs mata uang USD ke IDR)
import '../config/payment_config.dart';
// Mengimpor model data alamat pengiriman
import '../models/address.dart';
// Mengimpor model data metode pembayaran
import '../models/payment_method.dart';
// Mengimpor state provider keranjang belanja
import '../providers/cart_provider.dart';
// Mengimpor state provider proses checkout
import '../providers/checkout_provider.dart';
// Mengimpor konfigurasi warna kustom aplikasi
import '../theme/app_colors.dart';
// Mengimpor konfigurasi gaya teks aplikasi
import '../theme/app_text.dart';
// Mengimpor widget bottom sheet untuk pemilihan alamat
import '../widgets/address_sheet.dart';
// Mengimpor widget animasi kemunculan (reveal)
import '../widgets/reveal.dart';
// Mengimpor widget kartu bagian (section card)
import '../widgets/section_card.dart';
// Mengimpor kumpulan widget UI kit tambahan
import '../widgets/ui_kit.dart';

// Kelas CheckoutScreen berupa StatefulWidget untuk mengelola halaman checkout pembayaran
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  /// Kode unik 3 digit yang ditambahkan ke nominal agar pembayaran mudah dicocokkan.
  final int _code = 100 + Random().nextInt(900); // Menghasilkan angka acak 3 digit antara 100 - 999

  // Fungsi helper untuk mengonversi nominal harga USD ke Rupiah (IDR) dan dibulatkan
  int _idr(double usdAmount) => (usdAmount * PaymentConfig.usdToIdr).round();

  @override
  Widget build(BuildContext context) {
    // Memantau perubahan state dari CartProvider dan CheckoutProvider
    final cart = context.watch<CartProvider>();
    final co = context.watch<CheckoutProvider>();

    // Menghitung berbagai rincian nominal harga dalam Rupiah
    final baseIdr = _idr(cart.total);
    final originalIdr = _idr(cart.originalTotal);
    final saveIdr = originalIdr - baseIdr;
    final totalIdr = baseIdr + _code; // Total pembayaran ditambah kode unik 3 digit

    // Mengambil data alamat terpilih, metode pembayaran terpilih, dan status kesiapan checkout
    final address = co.selectedAddress;
    final method = co.method;
    final ready = address != null && method != null && !cart.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: PastelBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Bagian Header (Tombol kembali dan judul halaman)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: Row(
                  children: [
                    RoundIconButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'Selesaikan '),
                          TextSpan(
                            text: 'Pesanan',
                            style: AppText.serif(30,
                                w: FontWeight.w600,
                                style: FontStyle.italic,
                                color: AppColors.purpleText,
                                height: 1.05),
                          ),
                        ]),
                        style: AppText.serif(30, w: FontWeight.w600, height: 1.05),
                      ),
                    ),
                  ],
                ),
              ),
              // Bagian Konten Utama (Kondisi keranjang kosong atau menampilkan detail checkout)
              Expanded(
                child: cart.isEmpty
                    ? ListView(children: [
                        EmptyState(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Keranjang kosong',
                          text: 'Tambahkan produk dulu sebelum checkout.',
                          buttonLabel: 'Mulai Belanja',
                          onButton: () => context.go('/home'),
                        ),
                      ])
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                        children: [
                          Reveal(child: _addressSection(context, co, address)), // Bagian Alamat Pengiriman
                          Reveal(
                            delay: const Duration(milliseconds: 80),
                            child: _methodSection(co, method), // Bagian Metode Pembayaran
                          ),
                          Reveal(
                            delay: const Duration(milliseconds: 160),
                            child: _summarySection(cart, saveIdr, originalIdr, totalIdr), // Bagian Ringkasan Pesanan
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      // Tombol bar bawah (Bottom Navigation Bar) untuk aksi pembayaran
      bottomNavigationBar: _bottomBar(context, cart, address, method, ready, baseIdr, totalIdr),
    );
  }

  // ---------- alamat ----------

  // Widget untuk menampilkan bagian pemilihan alamat pengiriman
  Widget _addressSection(BuildContext context, CheckoutProvider co, Address? a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'Alamat Pengiriman',
          trailing: a == null
              ? null
              : GestureDetector(
                  onTap: () => showAddressSheet(context), // Membuka sheet ganti alamat
                  child: Text('Ganti',
                      style: AppText.sans(12, w: FontWeight.w700, color: AppColors.link)),
                ),
        ),
        if (a == null)
          Pressable(
            scale: .98,
            onTap: () => showAddressSheet(context), // Membuka sheet tambah alamat jika belum ada
            child: SectionCard(
              color: Colors.white.withValues(alpha: .7),
              border: Border.all(color: AppColors.accent, width: 1.5),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: AppColors.lavender, shape: BoxShape.circle),
                    child: const Icon(Icons.add_location_alt_outlined,
                        size: 20, color: AppColors.ink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tambah alamat pengiriman',
                            style: AppText.sans(13, w: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('Wajib diisi sebelum membayar',
                            style: AppText.sans(11.5, color: AppColors.inkSoft)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.ink3),
                ],
              ),
            ),
          )
        else
          SectionCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
                  child: const Icon(Icons.place_rounded, size: 20, color: AppColors.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        InfoTag(a.label),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(a.recipient,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.sans(13, w: FontWeight.w800)),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(a.phone, style: AppText.sans(12, color: AppColors.inkSoft)),
                      const SizedBox(height: 2),
                      Text(a.fullLine,
                          style: AppText.sans(12, color: AppColors.inkSoft, height: 1.45)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ---------- metode pembayaran ----------

  // Widget untuk menampilkan daftar pilihan metode pembayaran
  Widget _methodSection(CheckoutProvider co, PaymentMethod? selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Metode Pembayaran'),
        for (final m in PaymentMethod.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MethodTile(
              method: m,
              selected: selected == m,
              onTap: () => co.selectMethod(m), // Memilih metode pembayaran lewat provider
            ),
          ),
      ],
    );
  }

  // ---------- ringkasan ----------

  // Fungsi helper untuk merender baris teks rincian biaya
  Widget _line(String l, String r, {Color? rc, bool bold = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: AppText.sans(12.5, w: FontWeight.w600, color: AppColors.inkSoft)),
            Text(r,
                style: AppText.sans(12.5,
                    w: bold ? FontWeight.w800 : FontWeight.w700, color: rc ?? AppColors.ink)),
          ],
        ),
      );

  // Widget untuk menampilkan ringkasan item produk dan kalkulasi total harga
  Widget _summarySection(CartProvider cart, int saveIdr, int originalIdr, int totalIdr) {
    final items = cart.items;
    final shown = items.take(3).toList(); // Hanya menampilkan maksimal 3 item pertama di ringkasan
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Ringkasan'),
        SectionCard(
          child: Column(
            children: [
              for (final i in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text('${i.quantity}× ${i.product.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sans(12.5, w: FontWeight.w700)),
                      ),
                      const SizedBox(width: 10),
                      Text(rupiah(_idr(i.lineTotal)),
                          style: AppText.sans(12.5, w: FontWeight.w700)),
                    ],
                  ),
                ),
              if (items.length > shown.length)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('dan ${items.length - shown.length} produk lainnya',
                        style: AppText.sans(11.5, color: AppColors.ink3)),
                  ),
                ),
              const Divider(color: AppColors.line, height: 18),
              _line('Total Belanja', rupiah(originalIdr)),
              if (saveIdr > 0)
                _line('Hemat', '-${rupiah(saveIdr)}', rc: AppColors.mintDeep, bold: true),
              _line('Biaya Pengiriman', 'Gratis', rc: AppColors.mintDeep, bold: true),
              _line('Kode Unik', rupiah(_code)),
              const Divider(color: AppColors.line, height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Pembayaran', style: AppText.serif(19)),
                  Text(rupiah(totalIdr), style: AppText.serif(26, height: 1)),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
          child: Text(
            'Harga dalam dolar dikonversi dengan kurs 1 USD = ${rupiah(PaymentConfig.usdToIdr)}. '
            'Kode unik membantu penjual mencocokkan pembayaranmu.',
            style: AppText.sans(11, color: AppColors.ink3, height: 1.5),
          ),
        ),
      ],
    );
  }

  // ---------- bar bawah ----------

  // Widget untuk membuat panel navigasi bawah (bottom navigation bar) tombol aksi pembayaran
  Widget _bottomBar(BuildContext context, CartProvider cart, Address? address,
      PaymentMethod? method, bool ready, int baseIdr, int totalIdr) {
    // Menyesuaikan teks label tombol berdasarkan kelengkapan data checkout
    final label = address == null
        ? 'Pilih alamat dulu'
        : method == null
            ? 'Pilih metode pembayaran'
            : 'Bayar dengan ${method.label}';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF7FFFAF6),
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total', style: AppText.sans(11, color: AppColors.inkSoft)),
                  Text(rupiah(totalIdr), style: AppText.serif(24, height: 1.05)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GradientButton(
                  label: label,
                  expand: true,
                  radius: 18,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  // Jika data siap (ready), arahkan ke halaman pembayaran (/payment) dengan membawa argumen lengkap
                  onTap: ready
                      ? () => context.push(
                            '/payment',
                            extra: PaymentArgs(
                              method: method!,
                              address: address!,
                              itemCount: cart.totalQuantity,
                              baseIdr: baseIdr,
                              uniqueCode: _code,
                            ),
                          )
                      : null, // Tombol disable jika belum lengkap
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget privat _MethodTile untuk mendesain kartu pilihan metode pembayaran
class _MethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;
  const _MethodTile({required this.method, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: .98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.transparent,
            width: 1.8,
          ),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: method.color,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(method.icon, size: 24, color: AppColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.label, style: AppText.sans(14, w: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(method.subtitle,
                      style: AppText.sans(11.5, color: AppColors.inkSoft, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected ? AppColors.gradient : null,
                border: selected ? null : Border.all(color: AppColors.ink3, width: 1.5),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 14, color: AppColors.ink)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}