import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'api_exception.dart';
import 'http_client.dart';

/// Mengunggah foto produk (dari galeri / file laptop) ke server sendiri.
class UploadService {
  final Dio _dio = buildDio(ApiConfig.backendUrl);

  /// Mengembalikan URL foto yang sudah tersimpan di server.
  Future<String> uploadProductImage(Uint8List bytes) async {
    try {
      final res = await _dio.post(
        '/uploads/product',
        data: {'image': base64Encode(bytes)},
        options: Options(sendTimeout: const Duration(seconds: 60)),
      );
      final url = (res.data as Map)['url'];
      if (url is! String || url.isEmpty) {
        throw ApiException('Server tidak mengembalikan alamat foto.');
      }
      return url;
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
