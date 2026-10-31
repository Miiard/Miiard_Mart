// Mengimpor model data produk
import 'product_model.dart';

// Kelas untuk merepresentasikan satu item barang di dalam keranjang belanja
class CartItem {
  final Product product;    // Menyimpan objek data produk yang dibeli
  final int quantity;       // Menyimpan jumlah kuantitas produk tersebut

  // Konstruktor konstan untuk menginisialisasi objek CartItem
  const CartItem({required this.product, required this.quantity});

  // Fungsi copyWith untuk menduplikasi objek CartItem dengan opsi memperbarui produk atau kuantitasnya
  CartItem copyWith({Product? product, int? quantity}) => CartItem(
        product: product ?? this.product,
        quantity: quantity ?? this.quantity,
      );

  // Getter untuk menghitung total harga item setelah dikurangi diskon (harga diskon dikali kuantitas)
  double get lineTotal => product.discountedPrice * quantity;
  // Getter untuk menghitung total harga asli item sebelum diskon (harga normal dikali kuantitas)
  double get lineOriginal => product.price * quantity;
}