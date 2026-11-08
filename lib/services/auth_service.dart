import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_exception.dart';
import 'http_client.dart';

class AuthResult {
  final String token;
  final AppUser user;
  const AuthResult(this.token, this.user);
}

/// Panggilan API untuk login, daftar, dan lupa password.
class AuthService {
  final Dio _dio = buildDio(ApiConfig.backendUrl);

  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  AuthResult _result(Map<String, dynamic> data) => AuthResult(
        data['token'] as String,
        AppUser.fromJson(data['user'] as Map<String, dynamic>),
      );

  Future<AuthResult> login(String email, String password) => _run(() async {
        final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
        return _result(res.data as Map<String, dynamic>);
      });

  Future<AuthResult> register(String name, String email, String password) => _run(() async {
        final res = await _dio.post(
          '/auth/register',
          data: {'name': name, 'email': email, 'password': password},
        );
        return _result(res.data as Map<String, dynamic>);
      });

  Future<AppUser> me() => _run(() async {
        final res = await _dio.get('/auth/me');
        return AppUser.fromJson((res.data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
      });

  /// Mengunggah foto profil (base64 JPEG/PNG/WEBP, maks 2 MB).
  Future<AppUser> setAvatar(String base64Image) => _run(() async {
        final res = await _dio.put('/auth/avatar', data: {'image': base64Image});
        return AppUser.fromJson((res.data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
      });

  Future<AppUser> removeAvatar() => _run(() async {
        final res = await _dio.delete('/auth/avatar');
        return AppUser.fromJson((res.data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
      });

  /// Mengembalikan kode reset hanya bila server berjalan dalam mode pengembangan.
  Future<String?> forgot(String email) => _run(() async {
        final res = await _dio.post('/auth/forgot', data: {'email': email});
        final data = res.data;
        return data is Map ? data['devCode'] as String? : null;
      });

  Future<void> reset(String email, String code, String newPassword) => _run(() async {
        await _dio.post(
          '/auth/reset',
          data: {'email': email, 'code': code, 'newPassword': newPassword},
        );
      });
}
