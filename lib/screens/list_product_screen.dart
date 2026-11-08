import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/nav_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/grad_button.dart';
import '../widgets/hero_banner.dart';
import '../widgets/product_grid.dart';
import '../widgets/reveal.dart';
import '../widgets/skeleton_card.dart';

/// Beranda: banner, kategori, dan seluruh produk.
class ListProductScreen extends StatelessWidget {
  const ListProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    final products = prov.products;
    final bottomPad = 110 + MediaQuery.of(context).padding.bottom;

    return RefreshIndicator(
      color: AppColors.ink,
      backgroundColor: Colors.white,
      onRefresh: prov.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Reveal(
                    delayMs: 80,
                    dy: 26,
                    fromScale: 0.97,
                    child: HeroBanner(onShop: () => context.read<NavProvider>().go(1)),
                  ),
                  const SizedBox(height: 22),
                  Reveal(
                    delayMs: 200,
                    child: Text('Kategori', style: AppText.serif(size: 26)),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _chips(prov)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Reveal(
                delayMs: 300,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        prov.selectedCategory == null
                            ? 'Semua Produk'
                            : categoryLabel(prov.selectedCategory!),
                        style: AppText.serif(size: 26),
                      ),
                    ),
                    if (!prov.loading && prov.error == null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.lavender,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${products.length} item',
                          style: AppText.sans(size: 11.5, weight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (prov.loading && products.isEmpty)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.62,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => SkeletonCard(index: i),
                  childCount: 6,
                ),
              ),
            )
          else if (prov.error != null && products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _message(
                context,
                icon: Icons.cloud_off_rounded,
                title: 'Oops, gagal memuat',
                text: prov.error!,
                action: GradButton(
                  label: 'Coba lagi',
                  icon: Icons.refresh_rounded,
                  onTap: prov.refresh,
                ),
              ),
            )
          else if (products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _message(
                context,
                icon: Icons.inventory_2_outlined,
                title: 'Belum ada produk',
                text: 'Kategori ini masih kosong.',
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad),
              sliver: SliverProductGrid(products: products),
            ),
        ],
      ),
    );
  }

  Widget _chips(ProductProvider prov) {
    final cats = prov.categories;
    final items = <String?>[null, ...cats];
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final slug = items[i];
          final selected = prov.selectedCategory == slug;
          final tone = AppColors.toneFor(i);
          final chip = Pressable(
            onTap: () => prov.selectCategory(slug),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.ink : tone.bg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                slug == null ? 'Semua' : categoryLabel(slug),
                style: AppText.sans(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          );
          if (i > 7) return chip;
          return Reveal(
            key: ValueKey('chip-${slug ?? 'all'}'),
            delayMs: 240 + i * 60,
            dx: 18,
            dy: 0,
            child: chip,
          );
        },
      ),
    );
  }

  Widget _message(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String text,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Reveal(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: AppColors.lavender,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: AppColors.ink),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppText.serif(size: 24)),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppText.sans(color: AppColors.inkSoft, height: 1.5),
            ),
            if (action != null) ...[const SizedBox(height: 18), action],
          ],
        ),
      ),
    );
  }
}
