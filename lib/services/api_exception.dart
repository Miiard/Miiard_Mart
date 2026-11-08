import 'package:dio/dio.dart';

/// Error yang pesannya sudah ramah untuk ditampilkan ke pengguna.
class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);

  factory ApiException.from(Object e) {
    if (e is ApiException) return e;
    if (e is DioException) {
      final data = e.response?.data;
      final code = e.response?.statusCode;
      if (data is Map && data['message'] is String) {
        return ApiException(data['message'] as String, code);
      }
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return ApiException(
            'Tidak bisa terhubung ke server. Pastikan Docker menyala dan alamat API benar.',
          );
        default:
          return ApiException('Terjadi kesalahan jaringan (${code ?? '-'}).', code);
      }
    }
    return ApiException('Terjadi kesalahan. Coba lagi.');
  }

  @override
  String toString() => message;
}
