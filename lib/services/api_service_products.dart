import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/product_model.dart';
import 'http_client.dart';

class ApiServiceProducts {
  final Dio _dio;

  /// Tanpa [baseUrl] memakai server sendiri (Docker) lengkap dengan token login.
  /// Dengan [baseUrl] (misalnya dummyjson.com) dipakai sebagai sumber cadangan baca-saja.
  ApiServiceProducts({String? baseUrl})
      : _dio = buildDio(baseUrl ?? ApiConfig.backendUrl, withAuth: baseUrl == null);

  /// limit = 0 -> dummyjson mengembalikan SEMUA produk.
  Future<ProductsResponse> getAllProducts({int limit = 0, int skip = 0}) async {
    final res = await _dio.get('/products', queryParameters: {'limit': limit, 'skip': skip});
    return ProductsResponse.fromJson(res.data);
  }

  Future<Product> getProduct(int id) async {
    final res = await _dio.get('/products/$id');
    return Product.fromJson(res.data);
  }

  Future<ProductsResponse> searchProducts(String query, {int limit = 0}) async {
    final res = await _dio.get('/products/search', queryParameters: {'q': query, 'limit': limit});
    return ProductsResponse.fromJson(res.data);
  }

  Future<ProductsResponse> getProductsPaginated({int limit = 10, int skip = 0, String? select}) async {
    Map<String, dynamic> params = {'limit': limit, 'skip': skip};
    if (select != null) params['select'] = select;
    final res = await _dio.get('/products', queryParameters: params);
    return ProductsResponse.fromJson(res.data);
  }

  Future<ProductsResponse> sortProducts(String sortBy, String order) async {
    final res = await _dio.get('/products', queryParameters: {'sortBy': sortBy, 'order': order});
    return ProductsResponse.fromJson(res.data);
  }

  Future<List<Category>> getCategories() async {
    final res = await _dio.get('/products/categories');
    return (res.data as List).map((e) => Category.fromJson(e)).toList();
  }

  Future<List<String>> getCategoryList() async {
    final res = await _dio.get('/products/category-list');
    return (res.data as List).map((e) => e.toString()).toList();
  }

  Future<ProductsResponse> getProductsByCategory(String category, {int limit = 0}) async {
    final res = await _dio.get('/products/category/$category', queryParameters: {'limit': limit});
    return ProductsResponse.fromJson(res.data);
  }

  Future<Product> addProduct(Map<String, dynamic> data) async {
    final res = await _dio.post('/products/add', data: data);
    return Product.fromJson(res.data);
  }

  Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('/products/$id', data: data);
    return Product.fromJson(res.data);
  }

  Future<Product> patchProduct(int id, Map<String, dynamic> partialData) async {
    final res = await _dio.patch('/products/$id', data: partialData);
    return Product.fromJson(res.data);
  }

  Future<Product> deleteProduct(int id) async {
    final res = await _dio.delete('/products/$id');
    return Product.fromJson(res.data);
  }
}
