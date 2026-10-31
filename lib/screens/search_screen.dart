// Mengimpor pustaka utama material design dari Flutter
import 'package:flutter/material.dart';
// Mengimpor paket provider untuk mengakses state management
import 'package:provider/provider.dart';

// Mengimpor state provider produk
import '../providers/product_provider.dart';
// Mengimpor konfigurasi warna kustom aplikasi
import '../theme/app_colors.dart';
// Mengimpor konfigurasi gaya teks aplikasi
import '../theme/app_text.dart';
// Mengimpor widget kategori pilihan (chips)
import '../widgets/category_chips.dart';
// Mengimpor widget grid produk
import '../widgets/product_grid.dart';
// Mengimpor widget animasi kemunculan (reveal)
import '../widgets/reveal.dart';
// Mengimpor kumpulan widget UI kit tambahan
import '../widgets/ui_kit.dart';

// Kelas SearchScreen berupa StatefulWidget untuk mengelola halaman pencarian produk
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _ctrl; // Controller untuk mengontrol teks pada input pencarian
  final FocusNode _focus = FocusNode();   // FocusNode untuk memantau status fokus pada input pencarian

  @override
  void initState() {
    super.initState();
    // Menginisialisasi controller teks dengan query filter yang sedang aktif dari provider
    _ctrl = TextEditingController(text: context.read<ProductProvider>().filterQuery);
    // Menambahkan listener untuk memperbarui state saat fokus input berubah
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();  // Membersihkan controller teks
    _focus.dispose(); // Membersihkan focus node
    super.dispose();
  }

  // Fungsi untuk menghapus teks pencarian dan mereset filter produk
  void _clear() {
    _ctrl.clear();
    final prov = context.read<ProductProvider>();
    prov.resetFilters();
    _focus.requestFocus(); // Mengembalikan fokus ke input pencarian
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    final list = prov.filteredProducts(); // Mendapatkan daftar produk yang sudah difilter
    final q = prov.filterQuery.trim();    // Mengambil teks query pencarian yang sudah dibersihkan spasi
    final focused = _focus.hasFocus;      // Mengecek apakah input pencarian sedang aktif/fokus
    final kb = MediaQuery.viewInsetsOf(context).bottom; // Mendapatkan tinggi keyboard untuk padding dinamis

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, // Menutup keyboard saat digeser
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Bagian Header dan Input Kolom Pencarian
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Reveal(
                  child: Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Cari Produk '),
                      TextSpan(
                        text: 'Impianmu',
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
                const SizedBox(height: 14),
                Reveal(
                  delay: const Duration(milliseconds: 75),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: focused ? AppColors.accent : Colors.transparent, // Warna border berubah saat fokus
                        width: 1.5,
                      ),
                      boxShadow: [
                        if (focused)
                          const BoxShadow(color: Color(0x47C9B8F2), spreadRadius: 5), // Efek bayangan saat fokus
                        ...AppColors.softShadow,
                      ],
                    ),
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      textInputAction: TextInputAction.search,
                      cursorColor: AppColors.ink,
                      style: AppText.sans(13, w: FontWeight.w600),
                      onChanged: (v) => prov.setFilterQuery(v), // Memperbarui query pencarian di provider saat teks berubah
                      decoration: InputDecoration(
                        hintText: 'Cari nama produk, kategori, merek...',
                        hintStyle: AppText.sans(13, color: AppColors.ink3),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.ink3),
                        // Tombol silang (clear) hanya muncul jika teks pencarian tidak kosong
                        suffixIcon: _ctrl.text.isEmpty
                            ? null
                            : Padding(
                                padding: const EdgeInsets.all(8),
                                child: Pressable(
                                  onTap: _clear,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: AppColors.lavender,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded,
                                        size: 14, color: AppColors.ink),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        // Bagian Deretan Chip Kategori
        const SliverToBoxAdapter(child: CategoryChips()),
        // Bagian Informasi Jumlah Hasil Pencarian
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Text(
              q.isEmpty ? '${list.length} produk' : '${list.length} hasil untuk "$q"',
              style: AppText.sans(12, w: FontWeight.w600, color: AppColors.ink3),
            ),
          ),
        ),
        // Pengkondisian tampilan berdasarkan status data (Loading, Kosong, atau Menampilkan Grid Produk)
        if (prov.loading && prov.allProducts.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 26),
            sliver: SliverSkeletonGrid(), // Menampilkan kerangka loading (skeleton)
          )
        else if (list.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.search_rounded,
              title: 'Produk tidak ditemukan',
              text: 'Coba kata kunci lain atau pilih kategori yang berbeda.',
              buttonLabel: 'Reset pencarian',
              onButton: _clear,
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 26 + kb), // Padding bawah otomatis menyesuaikan tinggi keyboard
            sliver: SliverProductGrid(products: list),         // Menampilkan grid produk hasil pencarian
          ),
      ],
    );
  }
}