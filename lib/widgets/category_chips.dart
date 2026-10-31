import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'reveal.dart';
import 'ui_kit.dart';

/// Baris chip kategori (dipakai Beranda dan Cari, kategori terpilih dibagi).
class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    final cats = ['all', ...prov.productCategories];
    final active = prov.filterCategory;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 8),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = cats[i];
          final on = c == active;
          return Reveal(
            key: ValueKey(c),
            delay: Duration(milliseconds: 320 + i * 55),
            duration: const Duration(milliseconds: 700),
            offset: const Offset(22, 0),
            scaleFrom: .92,
            child: Pressable(
              onTap: () => context.read<ProductProvider>().setFilterCategory(c),
              scale: .94,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: on ? AppColors.gradient : null,
                  color: on ? null : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: on ? Colors.transparent : AppColors.line),
                  boxShadow: on ? AppColors.softShadow : null,
                ),
                child: Text(
                  c == 'all' ? 'Semua' : prettyCategory(c),
                  style: AppText.sans(12,
                      w: FontWeight.w700,
                      color: on ? AppColors.ink : AppColors.inkSoft),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
