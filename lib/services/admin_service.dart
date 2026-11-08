import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import 'api_exception.dart';
import 'http_client.dart';

/// Panggilan API khusus admin: statistik dan kelola pengguna.
class AdminService {
  final Dio _dio = buildDio(ApiConfig.backendUrl);

  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<AdminStats> stats() => _run(() async {
        final res = await _dio.get('/admin/stats');
        return AdminStats.fromJson(res.data as Map<String, dynamic>);
      });

  Future<List<AppUser>> users() => _run(() async {
        final res = await _dio.get('/admin/users');
        final list = (res.data as Map<String, dynamic>)['users'] as List? ?? [];
        return list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<void> setRole(int id, String role) => _run(() async {
        await _dio.patch('/admin/users/$id', data: {'role': role});
      });

  Future<void> deleteUser(int id) => _run(() async {
        await _dio.delete('/admin/users/$id');
      });

  Future<List<ShopOrder>> orders() => _run(() async {
        final res = await _dio.get('/admin/orders');
        final list = (res.data as Map<String, dynamic>)['orders'] as List? ?? [];
        return list.map((e) => ShopOrder.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<ShopOrder> setOrderStatus(int id, String status) => _run(() async {
        final res = await _dio.patch('/admin/orders/$id', data: {'status': status});
        return ShopOrder.fromJson(res.data as Map<String, dynamic>);
      });
}
