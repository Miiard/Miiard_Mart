// Mengimpor pustaka asynchronous Dart untuk fitur timer/penghitung waktu mundur
import 'dart:async';

// Mengimpor pustaka dasar Flutter untuk mendeteksi mode debug (kDebugMode)
import 'package:flutter/foundation.dart' show kDebugMode;
// Mengimpor pustaka utama material design dari Flutter
import 'package:flutter/material.dart';
// Mengimpor layanan sistem untuk fungsi clipboard (salin teks)
import 'package:flutter/services.dart';
// Mengimpor paket go_router untuk navigasi halaman
import 'package:go_router/go_router.dart';
// Mengimpor paket provider untuk mengakses state management
import 'package:provider/provider.dart';
// Mengimpor paket url_launcher untuk membuka tautan atau aplikasi eksternal (seperti DANA)
import 'package:url_launcher/url_launcher.dart';

// Mengimpor file konfigurasi pembayaran
import '../config/payment_config.dart';
// Mengimpor model data metode pembayaran
import '../models/payment_method.dart';
// Mengimpor state provider keranjang belanja
import '../providers/cart_provider.dart';
// Mengimpor konfigurasi warna kustom aplikasi
import '../theme/app_colors.dart';
// Mengimpor konfigurasi gaya teks aplikasi
import '../theme/app_text.dart';
// Mengimpor widget kustom untuk notifikasi toast
import '../widgets/app_toast.dart';
// Mengimpor dialog sukses pesanan
import '../widgets/order_success_dialog.dart';
// Mengimpor widget animasi kemunculan (reveal)
import '../widgets/reveal.dart';
// Mengimpor widget kartu bagian (section card)
import '../widgets/section_card.dart';
// Mengimpor kumpulan widget UI kit tambahan
import '../widgets/ui_kit.dart';

// Kelas PaymentScreen berupa StatefulWidget untuk mengelola halaman pembayaran pesanan
class PaymentScreen extends StatefulWidget {
  final PaymentArgs args; // Menyimpan data argumen pembayaran yang dibawa dari layar checkout
  const PaymentScreen({super.key, required this.args});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Duration _left = PaymentConfig.paymentWindow; // Durasi waktu mundur pembayaran aktif
  Timer? _timer;                                // Timer berkala untuk menghitung mundur waktu pembayaran

  PaymentArgs get a => widget.args;
  bool get _expired => _left <= Duration.zero;    // Getter untuk mengecek apakah waktu pembayaran sudah habis
  bool get _isQris => a.method == PaymentMethod.qris; // Getter untuk mengecek apakah metode pembayaran QRIS

  @override
  void initState() {
    super.initState();
    // Memulai timer periodik yang berjalan setiap 1 detik untuk mengurangi sisa waktu pembayaran
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _left -= const Duration(seconds: 1);
        if (_left <= Duration.zero) {
          _left = Duration.zero;
          _timer?.cancel(); // Batalkan timer jika waktu habis
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Pastikan timer dibersihkan saat widget dihancurkan
    super.dispose();
  }

  // Getter untuk memformat sisa waktu menjadi teks jam/menit:detik (MM:SS)
  String get _clock {
    final m = _left.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _left.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // Fungsi asinkron untuk menyalin teks ke clipboard perangkat dan menampilkan toast
  Future<void> _copy(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showAppToast(context,
        message: message,
        icon: Icons.copy_rounded,
        duration: const Duration(milliseconds: 1500));
  }

  // Fungsi asinkron untuk membuka aplikasi DANA menggunakan deep link atau web link
  Future<void> _openDana() async {
    var ok = false;
    try {
      ok = await launchUrl(Uri.parse('danaid://'), mode: LaunchMode.externalApplication);
      if (!ok) {
        ok = await launchUrl(Uri.parse('https://link.dana.id'),
            mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      ok = false;
    }
    // Tampilkan pesan error jika gagal membuka aplikasi DANA
    if (!ok && mounted) {
      showAppToast(context,
          message: 'Tidak bisa membuka DANA. Buka aplikasinya secara manual.',
          icon: Icons.close_rounded);
    }
  }

  // Fungsi untuk menampilkan QR code dalam mode layar penuh (zoom)
  void _zoomQr() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.white,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.asset(PaymentConfig.qrisAsset, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(ctx).top + 10,
              right: 14,
              child: RoundIconButton(
                icon: Icons.close_rounded,
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi asinkron untuk konfirmasi pembayaran setelah pengguna menekan tombol "Saya sudah bayar"
  Future<void> _confirm() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Sudah membayar?', style: AppText.serif(24)),
        content: Text(
          'Pastikan pembayaran ${rupiah(a.totalIdr)} lewat ${a.method.label} sudah berhasil '
          'sebelum melanjutkan.',
          style: AppText.sans(13, color: AppColors.inkSoft, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Belum',
                style: AppText.sans(13, w: FontWeight.w700, color: AppColors.inkSoft)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, sudah'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    _timer?.cancel();
    context.read<CartProvider>().checkout(); // Kosongkan keranjang dan catat pesanan berhasil
    await showOrderSuccess(
      context,
      count: a.itemCount,
      total: 0,
      totalLabel: rupiah(a.totalIdr),
    );
    if (mounted) context.go('/home'); // Kembali ke halaman utama setelah sukses
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PastelBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Bagian Header (Tombol kembali dan judul halaman pembayaran)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: Row(
                  children: [
                    RoundIconButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'Bayar via '),
                          TextSpan(
                            text: a.method.label,
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
              // Bagian Konten Utama (Daftar kartu instruksi pembayaran)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  children: [
                    Reveal(child: _totalCard()), // Kartu informasi total nominal dan timer
                    const SizedBox(height: 14),
                    Reveal(
                      delay: const Duration(milliseconds: 80),
                      child: _isQris ? _qrisCard() : _danaCard(), // Kartu QRIS atau DANA sesuai metode terpilih
                    ),
                    const SizedBox(height: 14),
                    Reveal(
                      delay: const Duration(milliseconds: 160),
                      child: _shipCard(), // Kartu informasi alamat pengiriman
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Tombol bar bawah (Bottom Navigation Bar) untuk aksi konfirmasi pembayaran
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xF7FFFAF6),
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: _expired
                ? GradientButton(
                    label: 'Waktu habis, kembali',
                    expand: true,
                    radius: 18,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    onTap: () => context.pop(),
                  )
                : GradientButton(
                    label: 'Saya sudah bayar',
                    icon: Icons.check_rounded,
                    expand: true,
                    radius: 18,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    onTap: _confirm,
                  ),
          ),
        ),
      ),
    );
  }

  // ---------- kartu total ----------

  // Widget untuk menampilkan kartu total tagihan dan timer hitung mundur
  Widget _totalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lavender.withValues(alpha: .9),
            AppColors.pink.withValues(alpha: .8),
          ],
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total yang dibayar',
                  style: AppText.sans(12, w: FontWeight.w700, color: AppColors.inkSoft)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _expired ? AppColors.pink : AppColors.yellow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_expired ? Icons.timer_off_outlined : Icons.timer_outlined,
                        size: 13, color: AppColors.ink),
                    const SizedBox(width: 5),
                    Text(_expired ? 'Waktu habis' : _clock,
                        style: AppText.sans(11.5, w: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(rupiah(a.totalIdr), style: AppText.serif(40, height: 1)),
                ),
              ),
              const SizedBox(width: 8),
              Pressable(
                scale: .88,
                onTap: () => _copy('${a.totalIdr}', 'Nominal disalin'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .85),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy_rounded, size: 14, color: AppColors.ink),
                      const SizedBox(width: 5),
                      Text('Salin', style: AppText.sans(11.5, w: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sudah termasuk kode unik ${rupiah(a.uniqueCode)}. Bayar sesuai nominal ini, jangan dibulatkan.',
            style: AppText.sans(11.5, color: AppColors.inkSoft, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ---------- QRIS ----------

  // Widget untuk menampilkan kartu instruksi pembayaran QRIS
  Widget _qrisCard() {
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scan QRIS', style: AppText.serif(22)),
          const SizedBox(height: 10),
          Pressable(
            scale: .98,
            onTap: _zoomQr, // Membuka gambar QR code dalam mode zoom saat diketuk
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  Container(
                    color: Colors.white,
                    child: Image.asset(PaymentConfig.qrisAsset, fit: BoxFit.fitWidth),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(alpha: .85),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.zoom_out_map_rounded, size: 13, color: Colors.white),
                          const SizedBox(width: 5),
                          Text('Perbesar',
                              style: AppText.sans(10.5, w: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Steps([
            'Buka m-banking atau e-wallet yang mendukung QRIS (DANA, GoPay, OVO, ShopeePay, dan lainnya).',
            'Scan kode QR di atas. Ketuk gambar untuk memperbesar bila sulit terbaca.',
            'Ini QRIS statis, jadi ketik nominal ${rupiah(a.totalIdr)} secara manual.',
            'Selesaikan pembayaran, lalu tekan "Saya sudah bayar".',
          ]),
        ],
      ),
    );
  }

  // ---------- DANA ----------

  // Widget untuk menampilkan kartu instruksi transfer DANA
  Widget _danaCard() {
    final unset = PaymentConfig.danaNumber.toLowerCase().contains('x');
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transfer ke DANA', style: AppText.serif(22)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.sky.withValues(alpha: .6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nomor DANA',
                          style: AppText.sans(11, w: FontWeight.w700, color: AppColors.inkSoft)),
                      const SizedBox(height: 3),
                      Text(PaymentConfig.danaNumber,
                          style: AppText.sans(20, w: FontWeight.w800, letterSpacing: .6)),
                      const SizedBox(height: 2),
                      Text('a.n. ${PaymentConfig.danaAccountName}',
                          style: AppText.sans(12, color: AppColors.inkSoft)),
                    ],
                  ),
                ),
                Pressable(
                  scale: .88,
                  onTap: () => _copy(PaymentConfig.danaNumber, 'Nomor DANA disalin'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_rounded, size: 14, color: AppColors.ink),
                        const SizedBox(width: 5),
                        Text('Salin', style: AppText.sans(11.5, w: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (unset && kDebugMode)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Catatan pengembang: nomor DANA masih contoh. Isi di config/payment_config.dart.',
                style: AppText.sans(11, color: AppColors.heart, height: 1.4),
              ),
            ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Buka aplikasi DANA',
            icon: Icons.open_in_new_rounded,
            expand: true,
            padding: const EdgeInsets.symmetric(vertical: 14),
            onTap: _openDana, // Membuka aplikasi DANA saat ditekan
          ),
          const SizedBox(height: 14),
          _Steps([
            'Salin nomor DANA dan nominal ${rupiah(a.totalIdr)} di atas.',
            'Buka DANA, pilih Kirim, lalu Ke Sesama DANA, dan tempel nomornya.',
            'Masukkan nominal persis sama, lalu konfirmasi pengiriman.',
            'Kembali ke sini dan tekan "Saya sudah bayar".',
          ]),
        ],
      ),
    );
  }

  // ---------- alamat ----------

  // Widget untuk menampilkan informasi alamat tujuan pengiriman
  Widget _shipCard() {
    final ad = a.address;
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
            child: const Icon(Icons.local_shipping_outlined, size: 19, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dikirim ke ${ad.recipient}',
                    style: AppText.sans(12.5, w: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(ad.fullLine,
                    style: AppText.sans(12, color: AppColors.inkSoft, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pendukung _Steps untuk menampilkan daftar langkah-langkah instruksi bernomor
class _Steps extends StatelessWidget {
  final List<String> steps;
  const _Steps(this.steps);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: AppColors.lavender, shape: BoxShape.circle),
                  child: Text('${i + 1}', style: AppText.sans(11, w: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(steps[i],
                        style: AppText.sans(12.5, color: const Color(0xFF6B5D7C), height: 1.5)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}