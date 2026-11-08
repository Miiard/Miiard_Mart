import 'package:dio/dio.dart';
import '../models/product_model.dart';

class ProductService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'));

  Future<List<Product>> getProducts() async {
    try {
      final response = await _dio.get('/products');
      final List data = response.data['products'];
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> getProductById(int id) async {
    try {
      final response = await _dio.get('/products/$id');
      return Product.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> addProduct(Map<String, dynamic> productData) async {
    try {
      final response = await _dio.post('/products/add', data: productData);
      return Product.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> updateProduct(int id, Map<String, dynamic> productData) async {
    try {
      final response = await _dio.put('/products/$id', data: productData);
      return Product.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _dio.delete('/products/$id');
    } catch (e) {
      rethrow;
    }
  }
}