import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/product_grid.dart';
import '../widgets/reveal.dart';

/// Pencarian fungsional: mengetik → tunggu 400 ms → panggil API /products/search.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _ctrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: context.read<ProductProvider>().query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) context.read<ProductProvider>().search(v);
    });
  }

  void _clear() {
    _ctrl.clear();
    _debounce?.cancel();
    context.read<ProductProvider>().search('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    final results = prov.searchResults;
    final bottomPad = 110 + MediaQuery.of(context).padding.bottom;
    final hasQuery = prov.query.isNotEmpty;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Reveal(child: Text('Cari produk', style: AppText.serif(size: 30))),
                const SizedBox(height: 12),
                Reveal(
                  delayMs: 100,
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(27),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppColors.inkSoft),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            onChanged: _onChanged,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (v) {
                              _debounce?.cancel();
                              context.read<ProductProvider>().search(v);
                            },
                            style: AppText.sans(size: 14.5, weight: FontWeight.w600),
                            cursorColor: AppColors.ink,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Cari parfum, laptop, sepatu…',
                              hintStyle: AppText.sans(size: 14, color: AppColors.inkFaint),
                            ),
                          ),
                        ),
                        if (_ctrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: _clear,
                            child: const Icon(Icons.close_rounded, color: AppColors.inkSoft),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _chips(prov)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasQuery ? 'Hasil untuk "${prov.query}"' : 'Semua produk',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 14, weight: FontWeight.w800),
                  ),
                ),
                if (prov.searching)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
                  )
                else
                  Text(
                    '${results.length} produk',
                    style: AppText.sans(size: 12, color: AppColors.inkSoft),
                  ),
              ],
            ),
          ),
        ),
        if (results.isEmpty && !prov.searching)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Reveal(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        color: AppColors.rose,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search_off_rounded, size: 38, color: AppColors.ink),
                    ),
                    const SizedBox(height: 16),
                    Text('Tidak ditemukan', style: AppText.serif(size: 24)),
                    const SizedBox(height: 6),
                    Text(
                      'Coba kata kunci lain atau ganti kategori.',
                      textAlign: TextAlign.center,
                      style: AppText.sans(color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad),
            sliver: SliverProductGrid(
              key: ValueKey('${prov.query}-${prov.searchCategory}'),
              products: results,
            ),
          ),
      ],
    );
  }

  Widget _chips(ProductProvider prov) {
    final items = <String?>[null, ...prov.categories];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final slug = items[i];
          final selected = prov.searchCategory == slug;
          return Pressable(
            onTap: () => prov.selectSearchCategory(slug),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.ink : AppColors.lavender,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                slug == null ? 'Semua' : categoryLabel(slug),
                style: AppText.sans(
                  size: 12,
                  weight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
