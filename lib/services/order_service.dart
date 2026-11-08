import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import 'api_exception.dart';
import 'http_client.dart';

/// Panggilan API pesanan: checkout, riwayat, batal, dan kelola admin.
class OrderService {
  final Dio _dio = buildDio(ApiConfig.backendUrl);

  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  List<ShopOrder> _list(dynamic data) =>
      ((data as Map<String, dynamic>)['orders'] as List? ?? [])
          .map((e) => ShopOrder.fromJson(e as Map<String, dynamic>))
          .toList();

  Future<ShopOrder> create({
    required List<CartItem> items,
    required String paymentMethod,
    required String name,
    required String phone,
    required String address,
  }) =>
      _run(() async {
        final res = await _dio.post('/orders', data: {
          'items': [
            for (final i in items) {'productId': i.product.id, 'quantity': i.quantity},
          ],
          'paymentMethod': paymentMethod,
          'shipName': name,
          'shipPhone': phone,
          'shipAddress': address,
        });
        return ShopOrder.fromJson(res.data as Map<String, dynamic>);
      });

  Future<List<ShopOrder>> mine() => _run(() async => _list((await _dio.get('/orders')).data));

  Future<ShopOrder> cancel(int id) => _run(() async {
        final res = await _dio.post('/orders/$id/cancel');
        return ShopOrder.fromJson(res.data as Map<String, dynamic>);
      });

  Future<List<ShopOrder>> adminAll() =>
      _run(() async => _list((await _dio.get('/admin/orders')).data));

  Future<ShopOrder> adminSetStatus(int id, String status) => _run(() async {
        final res = await _dio.patch('/admin/orders/$id', data: {'status': status});
        return ShopOrder.fromJson(res.data as Map<String, dynamic>);
      });
}
