// Mengimpor pustaka utama material design dari Flutter
import 'package:flutter/material.dart';
// Mengimpor paket provider untuk mengakses state management
import 'package:provider/provider.dart';

// Mengimpor model data alamat
import '../models/address.dart';
// Mengimpor state provider khusus checkout/alamat
import '../providers/checkout_provider.dart';
// Mengimpor konfigurasi warna kustom aplikasi
import '../theme/app_colors.dart';
// Mengimpor konfigurasi gaya teks aplikasi
import '../theme/app_text.dart';
// Mengimpor kumpulan widget UI kit tambahan
import 'ui_kit.dart';

/// Bottom sheet untuk memilih, menambah, dan menghapus alamat pengiriman.
// Fungsi global untuk menampilkan modal bottom sheet pengelolaan alamat pengiriman
Future<void> showAddressSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true, // Memungkinkan bottom sheet menyesuaikan tinggi saat keyboard muncul
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)), // Sudut atas melengkung
    ),
    builder: (_) => const _AddressSheet(),
  );
}

// Widget utama pembungkus bottom sheet yang bersifat Stateful
class _AddressSheet extends StatefulWidget {
  const _AddressSheet();

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  // Status untuk menentukan apakah sedang berada di mode form tambah alamat atau daftar alamat.
  // Jika daftar alamat kosong, maka form tambah alamat otomatis dibuka.
  late bool _adding = context.read<CheckoutProvider>().addresses.isEmpty;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * .88; // Batas tinggi maksimal 88% dari layar
    final kb = MediaQuery.viewInsetsOf(context).bottom;     // Ukuran tinggi keyboard perangkat

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Padding(
        padding: EdgeInsets.only(bottom: kb), // Mengatur padding agar tidak tertutup keyboard
        child: SafeArea(
          top: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300), // Animasi transisi mulus antar form dan list
            child: _adding
                ? _AddressForm(
                    key: const ValueKey('form'),
                    canCancel: context.read<CheckoutProvider>().addresses.isNotEmpty,
                    onCancel: () => setState(() => _adding = false), // Kembali ke daftar alamat
                    onSaved: () => Navigator.of(context).pop(),      // Menutup sheet setelah disimpan
                  )
                : _AddressList(
                    key: const ValueKey('list'),
                    onAdd: () => setState(() => _adding = true),     // Beralih ke form tambah alamat
                  ),
          ),
        ),
      ),
    );
  }
}

// Widget indikator garis kecil (grabber) di bagian atas modal sheet
class _Grabber extends StatelessWidget {
  const _Grabber();
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 10, bottom: 6),
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

// Widget untuk menampilkan daftar alamat yang sudah tersimpan
class _AddressList extends StatelessWidget {
  final VoidCallback onAdd;
  const _AddressList({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final co = context.watch<CheckoutProvider>(); // Memantau state data alamat via provider
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Grabber(),
          const SizedBox(height: 8),
          Text('Pilih Alamat', style: AppText.serif(26)),
          const SizedBox(height: 12),
          // Looping daftar alamat pengiriman yang tersedia
          for (final a in co.addresses)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Pressable(
                scale: .98,
                onTap: () {
                  co.selectAddress(a.id);           // Memilih alamat aktif berdasarkan ID
                  Navigator.of(context).pop();     // Menutup bottom sheet setelah dipilih
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    // Border aksen khusus untuk alamat yang sedang dipilih (selected)
                    border: Border.all(
                      color: a.id == co.selectedId ? AppColors.accent : Colors.transparent,
                      width: 1.8,
                    ),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              InfoTag(a.label, color: AppColors.lavender), // Label alamat (Rumah/Kantor/Lainnya)
                              const SizedBox(width: 8),
                              // Menampilkan ikon centang jika alamat ini sedang aktif dipilih
                              if (a.id == co.selectedId)
                                const Icon(Icons.check_circle_rounded,
                                    size: 16, color: AppColors.mintDeep),
                            ]),
                            const SizedBox(height: 8),
                            Text('${a.recipient}   ·   ${a.phone}',
                                style: AppText.sans(12.5, w: FontWeight.w800)),
                            const SizedBox(height: 3),
                            Text(a.fullLine,
                                style: AppText.sans(12, color: AppColors.inkSoft, height: 1.45)),
                            // Menampilkan catatan kurir jika ada isinya
                            if (a.note.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text('Catatan: ${a.note}',
                                    style: AppText.sans(11, color: AppColors.ink3)),
                              ),
                          ],
                        ),
                      ),
                      // Tombol ikon untuk menghapus alamat
                      Pressable(
                        scale: .8,
                        onTap: () => co.removeAddress(a.id),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.delete_outline_rounded,
                              size: 19, color: AppColors.ink3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          // Tombol untuk menambah alamat baru
          GradientButton(
            label: 'Tambah Alamat Baru',
            icon: Icons.add_rounded,
            expand: true,
            padding: const EdgeInsets.symmetric(vertical: 15),
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

// Widget form input untuk menambahkan alamat baru
class _AddressForm extends StatefulWidget {
  final bool canCancel;
  final VoidCallback onCancel;
  final VoidCallback onSaved;
  const _AddressForm({
    super.key,
    required this.canCancel,
    required this.onCancel,
    required this.onSaved,
  });

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _key = GlobalKey<FormState>(); // GlobalKey untuk validasi form
  final _recipient = TextEditingController();
  final _phone = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _postal = TextEditingController();
  final _note = TextEditingController();
  String _label = 'Rumah'; // Label default alamat baru

  @override
  void dispose() {
    // Membersihkan semua controller input saat widget dihancurkan
    for (final c in [_recipient, _phone, _street, _city, _postal, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  // Fungsi helper untuk mendesain border input form
  OutlineInputBorder _border(Color c, [double w = 1.5]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: c, width: w),
      );

  // Fungsi helper untuk dekorasi input field (TextField / TextFormField)
  InputDecoration _dec(String label, IconData icon, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppText.sans(13, color: AppColors.inkSoft),
        prefixIcon: Icon(icon, color: AppColors.ink, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: _border(AppColors.lavender),
        enabledBorder: _border(AppColors.lavender),
        focusedBorder: _border(AppColors.accent, 2),
        errorBorder: _border(AppColors.heart),
        focusedErrorBorder: _border(AppColors.heart, 2),
      );

  // Aturan validasi wajib diisi
  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  // Aturan validasi nomor telepon (panjang digit 9 sampai 15)
  String? _phoneRule(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9 || digits.length > 15) return 'Nomor telepon tidak valid';
    return null;
  }

  // Fungsi untuk menyimpan alamat baru ke dalam provider
  void _save() {
    if (!_key.currentState!.validate()) return; // Cek validasi form
    context.read<CheckoutProvider>().addAddress(
          Address(
            id: DateTime.now().microsecondsSinceEpoch.toString(), // Membuat ID unik berdasarkan waktu
            label: _label,
            recipient: _recipient.text.trim(),
            phone: _phone.text.trim(),
            street: _street.text.trim(),
            city: _city.text.trim(),
            postalCode: _postal.text.trim(),
            note: _note.text.trim(),
          ),
        );
    widget.onSaved(); // Panggil callback setelah berhasil disimpan
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Form(
        key: _key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Grabber(),
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.canCancel) ...[
                  RoundIconButton(
                      icon: Icons.arrow_back_rounded, size: 38, onTap: widget.onCancel),
                  const SizedBox(width: 10),
                ],
                Text('Alamat Baru', style: AppText.serif(26)),
              ],
            ),
            const SizedBox(height: 14),
            // Pilihan label alamat (Rumah, Kantor, Lainnya)
            Wrap(
              spacing: 8,
              children: [
                for (final l in const ['Rumah', 'Kantor', 'Lainnya'])
                  Pressable(
                    onTap: () => setState(() => _label = l),
                    scale: .94,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: _label == l ? AppColors.gradient : null,
                        color: _label == l ? null : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: _label == l ? Colors.transparent : AppColors.line),
                      ),
                      child: Text(l,
                          style: AppText.sans(12,
                              w: FontWeight.w700,
                              color: _label == l ? AppColors.ink : AppColors.inkSoft)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // Input nama penerima
            TextFormField(
              controller: _recipient,
              textCapitalization: TextCapitalization.words,
              decoration: _dec('Nama penerima', Icons.person_outline_rounded),
              validator: _required,
            ),
            const SizedBox(height: 12),
            // Input nomor telepon
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: _dec('Nomor telepon', Icons.phone_outlined, hint: '08xxxxxxxxxx'),
              validator: _phoneRule,
            ),
            const SizedBox(height: 12),
            // Input alamat lengkap
            TextFormField(
              controller: _street,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _dec('Alamat lengkap', Icons.place_outlined,
                  hint: 'Jalan, nomor, RT/RW, kelurahan'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            // Row untuk Kota dan Kode Pos
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    decoration: _dec('Kota/Kabupaten', Icons.location_city_outlined),
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _postal,
                    keyboardType: TextInputType.number,
                    decoration: _dec('Kode pos', Icons.markunread_mailbox_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Input catatan kurir opsional
            TextFormField(
              controller: _note,
              decoration: _dec('Catatan kurir (opsional)', Icons.sticky_note_2_outlined),
            ),
            const SizedBox(height: 18),
            // Tombol simpan alamat
            GradientButton(
              label: 'Simpan Alamat',
              icon: Icons.check_rounded,
              expand: true,
              padding: const EdgeInsets.symmetric(vertical: 15),
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}