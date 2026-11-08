import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product_model.dart';

/// Hasil menghapus item, dipakai untuk fitur "Urungkan".
class RemovedCartItem {
  final CartItem item;
  final int index;
  const RemovedCartItem(this.item, this.index);
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get totalQuantity => _items.fold(0, (sum, i) => sum + i.quantity);
  double get originalTotal => _items.fold(0.0, (sum, i) => sum + i.lineOriginal);
  double get total => _items.fold(0.0, (sum, i) => sum + i.lineTotal);
  double get savings => originalTotal - total;

  int _indexOf(int id) => _items.indexWhere((i) => i.product.id == id);

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
    if (added <= 0) return 0;

    final i = _indexOf(p.id);
    if (i < 0) {
      _items.add(CartItem(product: p, quantity: added));
    } else {
      _items[i] = _items[i].copyWith(product: p, quantity: _items[i].quantity + added);
    }
    notifyListeners();
    return added;
  }

  void increment(int id) {
    final i = _indexOf(id);
    if (i < 0) return;
    final item = _items[i];
    if (item.quantity >= item.product.stock) return;
    _items[i] = item.copyWith(quantity: item.quantity + 1);
    notifyListeners();
  }

  void decrement(int id) {
    final i = _indexOf(id);
    if (i < 0) return;
    final item = _items[i];
    if (item.quantity <= 1) return;
    _items[i] = item.copyWith(quantity: item.quantity - 1);
    notifyListeners();
  }

  RemovedCartItem? remove(int id) {
    final i = _indexOf(id);
    if (i < 0) return null;
    final item = _items.removeAt(i);
    notifyListeners();
    return RemovedCartItem(item, i);
  }

  void restore(RemovedCartItem removed) {
    if (_indexOf(removed.item.product.id) >= 0) return;
    final at = removed.index > _items.length ? _items.length : removed.index;
    _items.insert(at, removed.item);
    notifyListeners();
  }

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
      _items.removeAt(i);
    } else {
      final q = _items[i].quantity;
      _items[i] = _items[i].copyWith(product: p, quantity: q > p.stock ? p.stock : q);
    }
    notifyListeners();
  }
}
