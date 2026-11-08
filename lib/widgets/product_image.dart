import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../theme/app_colors.dart';

/// Foto yang diunggah dari galeri disimpan sebagai /uploads/product/{id}.
/// Host-nya diganti ke server yang sedang dipakai, jadi tetap muncul walau IP laptop berubah.
String resolveImageUrl(String url) {
  final u = url.trim();
  if (u.startsWith('/uploads/')) return '${ApiConfig.backendUrl}$u';
  if (u.startsWith('http')) {
    final uri = Uri.tryParse(u);
    if (uri != null && uri.path.startsWith('/uploads/product/')) {
      return '${ApiConfig.backendUrl}${uri.path}';
    }
  }
  return u;
}

/// Gambar produk yang aman: URL kosong, gagal muat, dan loading ditangani.
class ProductImage extends StatelessWidget {
  final String url;
  final double iconSize;
  final BoxFit fit;

  const ProductImage({
    super.key,
    required this.url,
    this.iconSize = 40,
    this.fit = BoxFit.contain,
  });

  Widget _placeholder(IconData icon) => Center(
        child: Icon(
          icon,
          size: iconSize,
          color: AppColors.inkSoft.o(0.7),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return _placeholder(Icons.image_rounded);

    return Image.network(
      resolveImageUrl(url),
      fit: fit,
      errorBuilder: (_, __, ___) => _placeholder(Icons.image_not_supported_rounded),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.ink,
                ),
              ),
            ),
    );
  }
}
