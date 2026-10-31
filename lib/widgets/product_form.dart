// Mengimpor library bawaan Flutter untuk membuat UI
import 'package:flutter/material.dart';
// Mengimpor library provider untuk state management (mengambil data dari provider)
import 'package:provider/provider.dart';

// Mengimpor model, provider, dan warna tema yang digunakan dalam aplikasi
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';

/// Form dipakai bersama oleh halaman Tambah dan Edit produk.
// StatefulWidget digunakan karena halaman ini memiliki perubahan data (state) yang dinamis, seperti mengetik di text field.
class ProductForm extends StatefulWidget {
  // Variabel untuk menampung data produk jika sedang dalam mode 'Edit' (opsional)
  final Product? initial;
  // Label teks untuk tombol simpan (misalnya: "Tambah" atau "Simpan")
  final String submitLabel;
  // Fungsi callback (aksi) yang akan dieksekusi saat tombol simpan ditekan
  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  // Constructor untuk menginisialisasi parameter yang dibutuhkan widget ini
  const ProductForm({
    super.key,
    this.initial,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

// Kelas state yang mengelola perubahan data pada ProductForm
class _ProductFormState extends State<ProductForm> {
  // Kunci global untuk mengontrol dan memvalidasi form
  final _formKey = GlobalKey<FormState>();
  
  // Kumpulan controller untuk menangkap dan memanipulasi teks yang diinput oleh user
  late final TextEditingController _title;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _brand;
  late final TextEditingController _description;
  late final TextEditingController _image;
  late final TextEditingController _categoryText; // cadangan bila kategori gagal dimuat
  
  // Variabel untuk menyimpan kategori yang dipilih
  String? _category;
  // Penanda apakah ada error pada pemilihan kategori (belum dipilih)
  bool _categoryError = false;
  // Penanda apakah proses penyimpanan sedang berlangsung (untuk loading state)
  bool _saving = false;

  // initState dipanggil pertama kali saat widget dirender ke layar
  @override
  void initState() {
    super.initState();
    // Mengambil data awal jika ada (mode edit)
    final p = widget.initial;
    
    // Menginisialisasi nilai awal ke dalam masing-masing text controller
    // Jika 'p' (produk) tidak null, nilainya dimasukkan. Jika null, diisi teks kosong ('').
    _title = TextEditingController(text: p?.title ?? '');
    _price = TextEditingController(text: p == null ? '' : p.price.toString());
    _stock = TextEditingController(text: p == null ? '' : p.stock.toString());
    _brand = TextEditingController(text: p?.brand ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _image = TextEditingController(text: p?.thumbnail ?? '');
    _categoryText = TextEditingController(text: p?.category ?? '');
    _category = (p == null || p.category.isEmpty) ? null : p.category;
  }

  // dispose dipanggil saat widget dihancurkan (berpindah halaman)
  @override
  void dispose() {
    // Wajib menghapus controller dari memori untuk mencegah kebocoran memori (memory leak)
    _title.dispose();
    _price.dispose();
    _stock.dispose();
    _brand.dispose();
    _description.dispose();
    _image.dispose();
    _categoryText.dispose();
    super.dispose();
  }

  // Fungsi bantuan (helper) untuk membuat desain border pada form input
  OutlineInputBorder _border(Color c, [double w = 1.5]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: c, width: w),
      );

  // Fungsi bantuan (helper) untuk mengatur gaya dekorasi pada setiap TextFormField
  InputDecoration _dec(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.inkSoft),
      prefixIcon: Icon(icon, color: AppColors.ink),
      filled: true,
      fillColor: Colors.white,
      border: _border(AppColors.lavender),
      enabledBorder: _border(AppColors.lavender),
      focusedBorder: _border(AppColors.accent, 2),
      errorBorder: _border(AppColors.heart),
      focusedErrorBorder: _border(AppColors.heart, 2),
    );
  }

  // Fungsi untuk memvalidasi apakah kolom input diisi atau dibiarkan kosong
  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  // Fungsi asinkron yang dijalankan ketika user menekan tombol simpan
  Future<void> _save() async {
    // Mengambil daftar kategori dari provider
    final cats = context.read<ProductProvider>().categories;
    // Menentukan kategori: gunakan input teks jika list kosong, atau gunakan kategori yang dipilih dari list
    final category = cats.isEmpty ? _categoryText.text.trim() : (_category ?? '');

    // Memvalidasi seluruh input form berdasarkan aturan validator masing-masing kolom
    final valid = _formKey.currentState!.validate();
    // Mengatur state error jika kategori belum dipilih/diisi
    setState(() => _categoryError = category.isEmpty);
    
    // Jika form tidak valid atau kategori kosong, hentikan proses penyimpanan (return)
    if (!valid || category.isEmpty) return;

    final image = _image.text.trim();
    // Mengumpulkan semua data inputan ke dalam sebuah Map (dictionary)
    final data = <String, dynamic>{
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'category': category,
      'price': double.parse(_price.text.trim().replaceAll(',', '.')), // Konversi teks harga ke angka desimal
      'stock': int.parse(_stock.text.trim()), // Konversi teks stok ke bilangan bulat
      'brand': _brand.text.trim(),
      if (image.isNotEmpty) 'thumbnail': image, // Hanya tambahkan gambar jika URL tidak kosong
      if (image.isNotEmpty) 'images': [image],
    };

    // Mengubah state menjadi 'saving' (menampilkan loading)
    setState(() => _saving = true);
    try {
      // Memanggil fungsi onSubmit yang dikirimkan dari halaman induk dengan membawa data yang sudah dibungkus
      await widget.onSubmit(data);
    } finally {
      // Mematikan state loading jika widget masih aktif setelah proses selesai
      if (mounted) setState(() => _saving = false);
    }
  }

  // Metode wajib di Flutter untuk merender tampilan antarmuka
  @override
  Widget build(BuildContext context) {
    // Mengambil (mendengarkan/listen) daftar kategori langsung dari ProductProvider
    final cats = context.select<ProductProvider, List<String>>((p) => p.categories);
    
    // Membuat daftar kategori yang akan ditampilkan. Jika dalam mode edit ada kategori aneh (tidak ada di list), tetap ditambahkan.
    final shown = [
      if (_category != null && cats.isNotEmpty && !cats.contains(_category)) _category!,
      ...cats,
    ];

    // Membungkus seluruh halaman dengan widget Form agar bisa divalidasi
    return Form(
      key: _formKey, // Menyambungkan form UI dengan key validator
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        // Menutup keyboard secara otomatis ketika pengguna menggeser/scroll layar
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          // Input Teks: Judul Produk
          TextFormField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('Judul produk', Icons.title_rounded),
            validator: _required,
          ),
          const SizedBox(height: 14),
          
          // Row digunakan untuk menampilkan input Harga dan Stok secara berdampingan (sebelahan)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expanded membagi ruang yang adil untuk input harga (50% layar)
              Expanded(
                child: TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true), // Memunculkan keyboard angka
                  decoration: _dec('Harga (\$)', Icons.attach_money_rounded),
                  validator: (v) {
                    // Validasi khusus untuk harga: tidak boleh huruf, tidak boleh <= 0
                    final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                    if (n == null || n <= 0) return 'Harga tidak valid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Expanded membagi ruang yang adil untuk input stok (50% layar)
              Expanded(
                child: TextFormField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  decoration: _dec('Stok', Icons.inventory_2_rounded),
                  validator: (v) {
                    // Validasi khusus untuk stok: harus angka bulat dan tidak boleh minus
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null || n < 0) return 'Stok tidak valid';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // Input Teks: Merek Produk (Opsional, tidak butuh validasi 'required')
          TextFormField(
            controller: _brand,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('Merek (opsional)', Icons.sell_rounded),
          ),
          const SizedBox(height: 18),
          
          // Label Bagian Kategori
          const Text(
            'Kategori',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          
          // Kondisional: Jika API/Provider tidak memiliki kategori, tampilkan text input biasa
          if (cats.isEmpty)
            TextFormField(
              controller: _categoryText,
              decoration: _dec('Kategori', Icons.category_rounded, hint: 'contoh: beauty'),
              validator: _required,
            )
          // Jika list kategori tersedia, tampilkan widget kustom berupa 'Chip' (tombol pilihan)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Me-loop daftar kategori dan merendernya menjadi widget _categoryChip
                for (var i = 0; i < shown.length; i++) _categoryChip(shown[i], i),
              ],
            ),
            
          // Pesan error merah yang muncul jika pengguna mencoba menyimpan tanpa memilih kategori
          if (cats.isNotEmpty && _categoryError)
            const Padding(
              padding: EdgeInsets.only(top: 8, left: 4),
              child: Text(
                'Pilih salah satu kategori',
                style: TextStyle(color: AppColors.heart, fontSize: 12.5),
              ),
            ),
          const SizedBox(height: 18),
          
          // Input Teks: Deskripsi (menggunakan tinggi fleksibel min 3 baris - max 6 baris)
          TextFormField(
            controller: _description,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('Deskripsi', Icons.notes_rounded),
            validator: _required,
          ),
          const SizedBox(height: 14),
          
          // Input Teks: URL Gambar (Opsional)
          TextFormField(
            controller: _image,
            keyboardType: TextInputType.url,
            decoration: _dec('URL gambar (opsional)', Icons.image_rounded,
                hint: 'https://...'),
          ),
          const SizedBox(height: 26),
          
          // Tombol Submit (Simpan / Tambah)
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)), // Membuat tombol melebar penuh
            // Menonaktifkan tombol saat '_saving' bernilai true (mencegah klik ganda)
            onPressed: _saving ? null : _save, 
            // Mengubah icon menjadi animasi berputar (loading) saat sedang proses _save()
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }

  // Widget custom untuk menampilkan kotak pilihan (chip) kategori satuan
  Widget _categoryChip(String slug, int i) {
    // Mengecek apakah chip ini adalah kategori yang saat ini sedang dipilih
    final selected = _category == slug;
    // Mengambil warna dari daftar palet pastel berdasarkan urutan indeksnya (looping warna)
    final color = AppColors.pastels[i % AppColors.pastels.length];
    
    return GestureDetector(
      // Aksi saat chip ditekan: ubah state kategori terpilih dan hilangkan error
      onTap: () => setState(() {
        _category = slug;
        _categoryError = false;
      }),
      // AnimatedContainer memberikan efek transisi halus saat warna chip berubah (terpilih/tidak)
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          // Jika dipilih warnanya dari pastel, jika tidak dipilih warnanya putih
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            // Gaya border yang menyesuaikan apakah kategori sedang terpilih atau belum
            color: selected ? AppColors.ink.withValues(alpha: 0.25) : color,
            width: 1.5,
          ),
        ),
        // Menampilkan teks kategori dengan pemformatan khusus (asumsi dari fungsi prettyCategory bawaan proyek)
        child: Text(
          prettyCategory(slug),
          style: TextStyle(
            // Menebalkan teks jika kategori ini sedang dipilih
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.ink,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}