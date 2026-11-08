import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../services/api_exception.dart';
import '../services/upload_service.dart';
import '../theme/app_colors.dart';
import 'app_toast.dart';
import 'product_image.dart';

/// Form dipakai bersama oleh halaman Tambah dan Edit produk.
class ProductForm extends StatefulWidget {
  final Product? initial;
  final String submitLabel;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  const ProductForm({
    super.key,
    this.initial,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _brand;
  late final TextEditingController _description;
  late final TextEditingController _categoryText; // cadangan bila kategori gagal dimuat
  String? _category;
  bool _categoryError = false;
  bool _saving = false;

  // foto produk: dari galeri / file laptop (tidak lagi memakai URL)
  static const int _maxImageBytes = 5 * 1024 * 1024; // sama dengan batas server
  final _upload = UploadService();
  String _imageUrl = ''; // foto yang sudah tersimpan (saat edit)
  Uint8List? _pickedBytes; // foto baru yang baru dipilih, belum diunggah
  String? _uploadedUrl; // hasil unggah untuk _pickedBytes (supaya tidak diunggah dua kali)

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _title = TextEditingController(text: p?.title ?? '');
    _price = TextEditingController(text: p == null ? '' : p.price.toString());
    _stock = TextEditingController(text: p == null ? '' : p.stock.toString());
    _brand = TextEditingController(text: p?.brand ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _imageUrl = p?.thumbnail ?? '';
    _categoryText = TextEditingController(text: p?.category ?? '');
    _category = (p == null || p.category.isEmpty) ? null : p.category;
  }

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _stock.dispose();
    _brand.dispose();
    _description.dispose();
    _categoryText.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color c, [double w = 1.5]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: c, width: w),
      );

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

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file == null) return; // dibatalkan
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > _maxImageBytes) {
        showAppToast(
          context,
          message: 'Foto terlalu besar',
          subtitle: 'Ukuran maksimal 5 MB, pilih foto yang lebih kecil.',
          icon: Icons.error_outline_rounded,
          color: AppColors.pink,
        );
        return;
      }
      setState(() {
        _pickedBytes = bytes;
        _uploadedUrl = null;
      });
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        context,
        message: 'Tidak bisa membuka galeri',
        subtitle: 'Coba lagi, atau periksa izin aplikasi.',
        icon: Icons.error_outline_rounded,
        color: AppColors.pink,
      );
    }
  }

  void _removeImage() => setState(() {
        _pickedBytes = null;
        _uploadedUrl = null;
        _imageUrl = '';
      });

  Future<void> _save() async {
    final cats = context.read<ProductProvider>().categories;
    final category = cats.isEmpty ? _categoryText.text.trim() : (_category ?? '');

    final valid = _formKey.currentState!.validate();
    setState(() => _categoryError = category.isEmpty);
    if (!valid || category.isEmpty) return;

    setState(() => _saving = true);
    try {
      // foto baru dari galeri diunggah dulu; hasilnya berupa alamat foto di server
      final picked = _pickedBytes;
      if (picked != null && _uploadedUrl == null) {
        try {
          _uploadedUrl = await _upload.uploadProductImage(picked);
        } catch (e) {
          if (mounted) {
            showAppToast(
              context,
              message: 'Gagal mengunggah foto',
              subtitle: ApiException.from(e).message,
              icon: Icons.error_outline_rounded,
              color: AppColors.pink,
            );
          }
          return;
        }
      }
      final image = (picked != null ? _uploadedUrl : _imageUrl) ?? '';

      final data = <String, dynamic>{
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'category': category,
        'price': double.parse(_price.text.trim().replaceAll(',', '.')),
        'stock': int.parse(_stock.text.trim()),
        'brand': _brand.text.trim(),
        if (image.isNotEmpty) 'thumbnail': image,
        if (image.isNotEmpty) 'images': [image],
      };
      await widget.onSubmit(data);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.select<ProductProvider, List<String>>((p) => p.categories);
    final shown = [
      if (_category != null && cats.isNotEmpty && !cats.contains(_category)) _category!,
      ...cats,
    ];

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          TextFormField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('Judul produk', Icons.title_rounded),
            validator: _required,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _dec('Harga (\$)', Icons.attach_money_rounded),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                    if (n == null || n <= 0) return 'Harga tidak valid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  decoration: _dec('Stok', Icons.inventory_2_rounded),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null || n < 0) return 'Stok tidak valid';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _brand,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('Merek (opsional)', Icons.sell_rounded),
          ),
          const SizedBox(height: 18),
          const Text(
            'Kategori',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          if (cats.isEmpty)
            TextFormField(
              controller: _categoryText,
              decoration: _dec('Kategori', Icons.category_rounded, hint: 'contoh: beauty'),
              validator: _required,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < shown.length; i++) _categoryChip(shown[i], i),
              ],
            ),
          if (cats.isNotEmpty && _categoryError)
            const Padding(
              padding: EdgeInsets.only(top: 8, left: 4),
              child: Text(
                'Pilih salah satu kategori',
                style: TextStyle(color: AppColors.heart, fontSize: 12.5),
              ),
            ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _description,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('Deskripsi', Icons.notes_rounded),
            validator: _required,
          ),
          const SizedBox(height: 14),
          _imagePicker(),
          const SizedBox(height: 26),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            onPressed: _saving ? null : _save,
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

  Widget _imagePicker() {
    final hasImage = _pickedBytes != null || _imageUrl.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto produk (opsional)',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _saving ? null : _pickImage,
          child: Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.lavender, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: _pickedBytes != null
                ? Image.memory(_pickedBytes!, fit: BoxFit.contain)
                : _imageUrl.isNotEmpty
                    ? ProductImage(url: _imageUrl, iconSize: 48)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                              size: 44, color: AppColors.inkSoft.o(0.7)),
                          const SizedBox(height: 8),
                          const Text(
                            'Ketuk untuk pilih foto',
                            style: TextStyle(color: AppColors.inkSoft),
                          ),
                        ],
                      ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickImage,
              icon: const Icon(Icons.photo_library_rounded, size: 18),
              label: Text(hasImage ? 'Ganti foto' : 'Pilih dari galeri'),
            ),
            if (hasImage) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _saving ? null : _removeImage,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Hapus'),
              ),
            ],
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4, left: 2),
          child: Text(
            'JPG, PNG, atau WEBP · maksimal 5 MB',
            style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _categoryChip(String slug, int i) {
    final selected = _category == slug;
    final color = AppColors.pastels[i % AppColors.pastels.length];
    return GestureDetector(
      onTap: () => setState(() {
        _category = slug;
        _categoryError = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.ink.o(0.25) : color,
            width: 1.5,
          ),
        ),
        child: Text(
          prettyCategory(slug),
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.ink,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
