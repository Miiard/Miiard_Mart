// Mengimpor paket dio untuk melakukan permintaan HTTP (HTTP requests)
import 'package:dio/dio.dart';
// Mengimpor model data produk
import '../models/product_model.dart';

// Kelas ProductService untuk menangani komunikasi layanan API produk dengan server DummyJSON
class ProductService {
  // Inisialisasi instance Dio dengan pengaturan dasar (BaseOptions) menggunakan URL dasar DummyJSON
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'));

  // Fungsi asinkron untuk mengambil daftar semua produk dari server
  Future<List<Product>> getProducts() async {
    try {
      // Mengirim permintaan GET ke endpoint /products
      final response = await _dio.get('/products');
      // Mengambil daftar list data produk dari kunci 'products' pada respons JSON
      final List data = response.data['products'];
      // Memetakan (mapping) data JSON ke dalam bentuk objek model Product dan mengubahnya menjadi List
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      // Melempar ulang error jika terjadi kegagalan saat mengambil data
      rethrow;
    }
  }

  // Fungsi asinkron untuk mengambil detail data produk berdasarkan ID unik
  Future<Product> getProductById(int id) async {
    try {
      // Mengirim permintaan GET ke endpoint /products/{id}
      final response = await _dio.get('/products/$id');
      // Mengonversi data JSON respons ke dalam objek model Product
      return Product.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Fungsi asinkron untuk menambahkan data produk baru ke server
  Future<Product> addProduct(Map<String, dynamic> productData) async {
    try {
      // Mengirim permintaan POST dengan data payload ke endpoint /products/add
      final response = await _dio.post('/products/add', data: productData);
      // Mengonversi respons produk yang berhasil ditambahkan ke objek Product
      return Product.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Fungsi asinkron untuk memperbarui data produk berdasarkan ID
  Future<Product> updateProduct(int id, Map<String, dynamic> productData) async {
    try {
      // Mengirim permintaan PUT dengan data pembaruan ke endpoint /products/{id}
      final response = await _dio.put('/products/$id', data: productData);
      // Mengonversi hasil pembaruan ke objek Product
      return Product.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Fungsi asinkron untuk menghapus produk dari server berdasarkan ID
  Future<void> deleteProduct(int id) async {
    try {
      // Mengirim permintaan DELETE ke endpoint /products/{id}
      await _dio.delete('/products/$id');
    } catch (e) {
      rethrow;
    }
  }
}