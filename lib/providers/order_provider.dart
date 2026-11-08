import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../services/api_exception.dart';
import '../services/order_service.dart';

/// Riwayat pesanan milik pengguna yang sedang login (disimpan di MySQL).
class OrderProvider extends ChangeNotifier {
  final OrderService _service = OrderService();

  List<ShopOrder> _orders = [];
  bool _loading = false;
  String? _error;

  List<ShopOrder> get orders => _orders;
  bool get loading => _loading;
  String? get error => _error;

  /// Pesanan yang tidak dibatalkan.
  int get activeCount => _orders.where((o) => o.status != 'dibatalkan').length;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _orders = await _service.mine();
    } catch (e) {
      _error = ApiException.from(e).message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Membuat pesanan. Mengembalikan pesanan, atau null bila gagal ([error] berisi alasannya).
  Future<ShopOrder?> place({
    required List<CartItem> items,
    required String paymentMethod,
    required String name,
    required String phone,
    required String address,
  }) async {
    _error = null;
    try {
      final order = await _service.create(
        items: items,
        paymentMethod: paymentMethod,
        name: name,
        phone: phone,
        address: address,
      );
      _orders = [order, ..._orders];
      notifyListeners();
      return order;
    } catch (e) {
      _error = ApiException.from(e).message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancel(int id) async {
    _error = null;
    try {
      final updated = await _service.cancel(id);
      _orders = [for (final o in _orders) o.id == id ? updated : o];
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiException.from(e).message;
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _orders = [];
    _error = null;
    notifyListeners();
  }
}
