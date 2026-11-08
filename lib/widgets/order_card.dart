import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/format.dart';
import 'product_image.dart';
import 'reveal.dart';

Color statusColor(String s) {
  switch (s) {
    case 'menunggu':
      return AppColors.butter;
    case 'diproses':
      return AppColors.sky;
    case 'dikirim':
      return AppColors.lavender;
    case 'selesai':
      return AppColors.mint;
    default:
      return AppColors.rose;
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: statusColor(status), borderRadius: BorderRadius.circular(10)),
      child: Text(
        ShopOrder.statusLabel(status),
        style: AppText.sans(size: 10.5, weight: FontWeight.w800),
      ),
    );
  }
}

/// Kartu pesanan yang bisa dibuka untuk melihat rincian. [footer] untuk tombol aksi.
class OrderCard extends StatefulWidget {
  final ShopOrder order;
  final bool showUser;
  final Widget? footer;
  final Widget? trailing;

  const OrderCard({
    super.key,
    required this.order,
    this.showUser = false,
    this.footer,
    this.trailing,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _open = false;

  Widget _info(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.inkSoft),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: AppText.sans(size: 12, color: AppColors.inkSoft, height: 1.4)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Pressable(
            scale: 0.99,
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(o.code, style: AppText.sans(size: 14, weight: FontWeight.w800)),
                      ),
                      StatusChip(o.status),
                      if (widget.trailing != null) widget.trailing!,
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.showUser ? '${o.userName} • ${o.dateLabel}' : o.dateLabel,
                    style: AppText.sans(size: 11.5, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(
                        height: 40,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final it in o.items.take(3))
                              Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.toneFor(it.productId).bg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ProductImage(url: it.thumbnail, iconSize: 16),
                              ),
                            if (o.items.length > 3)
                              Text(
                                '+${o.items.length - 3}',
                                style: AppText.sans(size: 12, weight: FontWeight.w800),
                              ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(money(o.total), style: AppText.sans(size: 15, weight: FontWeight.w800)),
                          Text(
                            '${o.totalQuantity} barang • ${o.paymentLabel}',
                            style: AppText.sans(size: 11, color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 8, color: AppColors.lavender),
                        for (final it in o.items)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${it.quantity}× ${it.title}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.sans(size: 12.5, weight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(money(it.lineTotal), style: AppText.sans(size: 12.5, weight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        const Divider(height: 14, color: AppColors.lavender),
                        _info(Icons.person_outline_rounded, '${o.shipName} • ${o.shipPhone}'),
                        _info(Icons.location_on_outlined, o.shipAddress),
                        _info(Icons.payments_outlined, o.paymentLabel),
                        if (widget.showUser) _info(Icons.alternate_email_rounded, o.userEmail),
                        if (widget.footer != null) ...[
                          const SizedBox(height: 12),
                          widget.footer!,
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
