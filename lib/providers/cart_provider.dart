// Mengimpor pustaka dasar Flutter untuk mendeteksi perubahan state (ChangeNotifier)
import 'package:flutter/foundation.dart';

// Mengimpor model item keranjang belanja
import '../models/cart_item.dart';
// Mengimpor model produk
import '../models/product_model.dart';

/// Hasil menghapus item, dipakai untuk fitur "Urungkan".
// Kelas sederhana untuk menyimpan data item keranjang yang baru saja dihapus beserta posisi indeksnya
class RemovedCartItem {
  final CartItem item;    // Objek item keranjang yang dihapus
  final int index;        // Posisi indeks awal item tersebut di dalam list
  const RemovedCartItem(this.item, this.index);
}

// Kelas state management CartProvider yang mewarisi ChangeNotifier untuk mengelola keranjang belanja
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = []; // List privat untuk menyimpan daftar barang di keranjang
  int _orders = 0;                  // Variabel privat untuk melacak jumlah pesanan

  /// Jumlah pesanan yang sudah di-checkout (ditampilkan di Profil).
  int get orders => _orders;

  // Getter publik untuk mengembalikan list item keranjang yang tidak dapat diubah secara langsung dari luar
  List<CartItem> get items => List.unmodifiable(_items);
  // Getter untuk mengecek apakah keranjang kosong
  bool get isEmpty => _items.isEmpty;
  // Getter untuk menghitung total keseluruhan kuantitas barang di keranjang
  int get totalQuantity => _items.fold(0, (sum, i) => sum + i.quantity);
  // Getter untuk menghitung total harga asli sebelum diskon dari semua item
  double get originalTotal => _items.fold(0.0, (sum, i) => sum + i.lineOriginal);
  // Getter untuk menghitung total harga akhir setelah diskon
  double get total => _items.fold(0.0, (sum, i) => sum + i.lineTotal);
  // Getter untuk menghitung total penghematan (total diskon yang didapat)
  double get savings => originalTotal - total;

  // Fungsi helper privat untuk mencari indeks produk di keranjang berdasarkan ID produk
  int _indexOf(int id) => _items.indexWhere((i) => i.product.id == id);

  // Fungsi untuk mendapatkan jumlah kuantitas suatu produk tertentu di dalam keranjang
  int quantityOf(int id) {
    final i = _indexOf(id);
    return i < 0 ? 0 : _items[i].quantity;
  }

  /// Sisa jumlah yang masih boleh ditambahkan (berdasarkan stok).
  int remainingFor(Product p) {
    final r = p.stock - quantityOf(p.id);
    return r < 0 ? 0 : r;
  }

  /// Menambah produk. Mengembalikan jumlah yang benar-benar masuk (0 bila stok habis).
  int add(Product p, {int quantity = 1}) {
    final room = remainingFor(p);
    final added = quantity < room ? quantity : room;
    if (added <= 0) return 0; // Jika stok tidak mencukupi, batalkan penambahan

    final i = _indexOf(p.id);
    if (i < 0) {
      // Jika produk belum ada di keranjang, tambahkan sebagai item baru
      _items.add(CartItem(product: p, quantity: added));
    } else {
      // Jika produk sudah ada, perbarui jumlah kuantitasnya
      _items[i] = _items[i].copyWith(product: p, quantity: _items[i].quantity + added);
    }
    notifyListeners(); // Beritahu UI bahwa data keranjang telah berubah
    return added;
  }

  // Fungsi untuk menambah jumlah kuantitas suatu produk di keranjang (tombol plus)
  void increment(int id) {
    final i = _indexOf(id);
    if (i < 0) return;
    final item = _items[i];
    if (item.quantity >= item.product.stock) return; // Batasi agar tidak melebihi stok
    _items[i] = item.copyWith(quantity: item.quantity + 1);
    notifyListeners();
  }

  // Fungsi untuk mengurangi jumlah kuantitas suatu produk di keranjang (tombol minus)
  void decrement(int id) {
    final i = _indexOf(id);
    if (i < 0) return;
    final item = _items[i];
    if (item.quantity <= 1) return; // Batasi minimal kuantitas adalah 1
    _items[i] = item.copyWith(quantity: item.quantity - 1);
    notifyListeners();
  }

  // Fungsi untuk menghapus item dari keranjang dan mengembalikan data item yang dihapus (untuk fitur undo)
  RemovedCartItem? remove(int id) {
    final i = _indexOf(id);
    if (i < 0) return null;
    final item = _items.removeAt(i);
    notifyListeners();
    return RemovedCartItem(item, i);
  }

  // Fungsi untuk mengembalikan (undo) item yang sebelumnya terhapus ke dalam keranjang
  void restore(RemovedCartItem removed) {
    if (_indexOf(removed.item.product.id) >= 0) return;
    final at = removed.index > _items.length ? _items.length : removed.index;
    _items.insert(at, removed.item);
    notifyListeners();
  }

  /// Checkout: mengosongkan keranjang dan menambah hitungan pesanan.
  void checkout() {
    if (_items.isEmpty) return;
    _orders++;       // Menambahkan jumlah total pesanan berhasil
    _items.clear();  // Mengosongkan keranjang belanja
    notifyListeners();
  }

  // Fungsi untuk mengosongkan seluruh isi keranjang
  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }

  /// Samakan data produk di keranjang setelah produk diedit.
  void syncProduct(Product p) {
    final i = _indexOf(p.id);
    if (i < 0) return;
    if (p.stock <= 0) {
      // Jika stok habis setelah diedit, hapus dari keranjang
      _items.removeAt(i);
    } else {
      // Perbarui data produk dan pastikan kuantitas tidak melebihi stok baru
      final q = _items[i].quantity;
      _items[i] = _items[i].copyWith(product: p, quantity: q > p.stock ? p.stock : q);
    }
    notifyListeners();
  }
}