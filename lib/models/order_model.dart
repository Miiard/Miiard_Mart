class OrderItem {
  final int productId;
  final String title;
  final String thumbnail;
  final double price; // harga satuan setelah diskon saat dipesan
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.title,
    required this.thumbnail,
    required this.price,
    required this.quantity,
  });

  double get lineTotal => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        productId: (j['productId'] as num).toInt(),
        title: j['title'] as String? ?? '',
        thumbnail: j['thumbnail'] as String? ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0,
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      );
}

/// Pesanan (checkout) yang tersimpan di database.
class ShopOrder {
  final int id;
  final String code;
  final int userId;
  final String userName;
  final String userEmail;
  final String status; // menunggu, diproses, dikirim, selesai, dibatalkan
  final String paymentMethod;
  final String paymentLabel;
  final double total;
  final double originalTotal;
  final String shipName;
  final String shipPhone;
  final String shipAddress;
  final String createdAt;
  final List<OrderItem> items;

  const ShopOrder({
    required this.id,
    required this.code,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.status,
    required this.paymentMethod,
    required this.paymentLabel,
    required this.total,
    required this.originalTotal,
    required this.shipName,
    required this.shipPhone,
    required this.shipAddress,
    required this.createdAt,
    required this.items,
  });

  static const statuses = ['menunggu', 'diproses', 'dikirim', 'selesai', 'dibatalkan'];

  static String statusLabel(String s) {
    switch (s) {
      case 'menunggu':
        return 'Menunggu pembayaran';
      case 'diproses':
        return 'Diproses';
      case 'dikirim':
        return 'Dikirim';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return s;
    }
  }

  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);
  bool get canCancel => status == 'menunggu';

  /// "2026-11-08 08:12:00" -> "08/11/2026 08:12"
  String get dateLabel {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})').firstMatch(createdAt);
    if (m == null) return createdAt;
    return '${m[3]}/${m[2]}/${m[1]} ${m[4]}:${m[5]}';
  }

  factory ShopOrder.fromJson(Map<String, dynamic> j) => ShopOrder(
        id: (j['id'] as num).toInt(),
        code: j['code'] as String? ?? '',
        userId: (j['userId'] as num?)?.toInt() ?? 0,
        userName: j['userName'] as String? ?? '',
        userEmail: j['userEmail'] as String? ?? '',
        status: j['status'] as String? ?? 'menunggu',
        paymentMethod: j['paymentMethod'] as String? ?? '',
        paymentLabel: j['paymentLabel'] as String? ?? '',
        total: (j['total'] as num?)?.toDouble() ?? 0,
        originalTotal: (j['originalTotal'] as num?)?.toDouble() ?? 0,
        shipName: j['shipName'] as String? ?? '',
        shipPhone: j['shipPhone'] as String? ?? '',
        shipAddress: j['shipAddress'] as String? ?? '',
        createdAt: j['createdAt'] as String? ?? '',
        items: ((j['items'] as List?) ?? [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Pilihan metode pembayaran. [code] harus sama dengan yang diterima server.
class PayMethod {
  final String code;
  final String label;
  final String group;
  final String hint;
  final String badge; // singkatan di lencana logo
  final int color; // warna latar lencana (ARGB)
  const PayMethod(this.code, this.label, this.group, this.hint, this.badge, this.color);

  bool get isQris => code == 'qris';
}

const payMethods = <PayMethod>[
  PayMethod('qris', 'QRIS', 'Scan QR', 'Scan dengan aplikasi bank atau e-wallet apa pun', 'QRIS', 0xFFFFD6DE),
  PayMethod('bca', 'Transfer BCA', 'Transfer Bank', 'Bayar lewat m-banking / ATM', 'BCA', 0xFFD4E7FF),
  PayMethod('mandiri', 'Transfer Mandiri', 'Transfer Bank', 'Bayar lewat Livin / ATM', 'MDR', 0xFFFFF3BF),
  PayMethod('bni', 'Transfer BNI', 'Transfer Bank', 'Bayar lewat BNI Mobile / ATM', 'BNI', 0xFFFFE2CC),
  PayMethod('gopay', 'GoPay', 'E-Wallet', 'Bayar lewat aplikasi Gojek', 'GP', 0xFFCFF3E2),
  PayMethod('ovo', 'OVO', 'E-Wallet', 'Bayar lewat aplikasi OVO', 'OVO', 0xFFE6D9FF),
  PayMethod('dana', 'DANA', 'E-Wallet', 'Bayar lewat aplikasi DANA', 'DANA', 0xFFD4E7FF),
  PayMethod('cod', 'Bayar di tempat (COD)', 'Tunai', 'Bayar ke kurir saat barang tiba', 'COD', 0xFFFFF3BF),
];

PayMethod? payMethodByCode(String code) {
  for (final m in payMethods) {
    if (m.code == code) return m;
  }
  return null;
}
