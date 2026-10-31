import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../lib/main.dart';
import '../lib/models/product_model.dart';
import '../lib/providers/cart_provider.dart';
import '../lib/providers/product_provider.dart';

Product _fakeProduct({int id = 1, int stock = 5}) => Product.fromJson({
      'id': id,
      'title': 'Produk Tes',
      'price': 100,
      'discountPercentage': 10,
      'stock': stock,
    });

void main() {
  testWidgets('Aplikasi berhasil dibangun tanpa crash',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          // tanpa ..init() supaya tidak memanggil API sungguhan saat tes
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
  });

  group('CartProvider', () {
    test('menambah produk dan menghitung total', () {
      final cart = CartProvider();
      final added = cart.add(_fakeProduct(), quantity: 2);

      expect(added, 2);
      expect(cart.totalQuantity, 2);
      expect(cart.total, closeTo(180, 0.001)); // 100 diskon 10% x 2
    });

    test('jumlah dibatasi oleh stok', () {
      final cart = CartProvider();
      final p = _fakeProduct(stock: 3);

      expect(cart.add(p, quantity: 10), 3);
      expect(cart.add(p), 0); // stok sudah habis di keranjang
      expect(cart.totalQuantity, 3);
    });

    test('hapus lalu urungkan mengembalikan item', () {
      final cart = CartProvider();
      cart.add(_fakeProduct());

      final removed = cart.remove(1)!;
      expect(cart.isEmpty, true);

      cart.restore(removed);
      expect(cart.totalQuantity, 1);
    });
  });
}