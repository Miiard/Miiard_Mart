import 'package:dio/dio.dart';

/// Menyimpan token login di memori; otomatis ditempel ke setiap permintaan.
class TokenStore {
  static String? token;
}

Dio buildDio(String baseUrl, {bool withAuth = true}) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));
  if (withAuth) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final t = TokenStore.token;
        if (t != null) options.headers['Authorization'] = 'Bearer $t';
        handler.next(options);
      },
    ));
  }
  return dio;
}
