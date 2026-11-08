import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/product_model.dart';
import '../services/api_exception.dart';
import '../services/api_service_products.dart';

class ProductProvider extends ChangeNotifier {
  // server sendiri (Docker + MySQL); dummyjson hanya cadangan baca-saja
  final ApiServiceProducts _api = ApiServiceProducts();
  final ApiServiceProducts _backup = ApiServiceProducts(baseUrl: ApiConfig.dummyUrl);

  List<Product> _catalog = []; // semua produk
  List<Product> _view = []; // katalog setelah filter kategori (Beranda)
  List<String> _categories = [];
  final Set<int> _favorites = {};
  bool _offline = false; // true bila server sendiri tidak terjangkau

  // beranda
  String? _category;
  bool _loading = false;
  String? _error;
  int _requestId = 0;

  // pencarian
  String _query = '';
  String? _searchCategory;
  List<Product> _searchApi = [];
  bool _searching = false;
  int _searchId = 0;

  // pesan error terakhir dari tambah / ubah / hapus
  String? _actionError;

  List<Product> get products => _view;
  List<Product> get allProducts => _catalog;
  List<String> get categories => _categories;
  String? get selectedCategory => _category;
  bool get loading => _loading;
  String? get error => _error;
  bool get offline => _offline;
  String? get actionError => _actionError;

  String get query => _query;
  String? get searchCategory => _searchCategory;
  bool get searching => _searching;

  int get favoritesCount => _favorites.length;
  bool isFavorite(int id) => _favorites.contains(id);
  List<Product> get favoriteProducts =>
      _catalog.where((p) => _favorites.contains(p.id)).toList();

  /// Hasil pencarian: kata kunci (lewat API) + filter kategori.
  List<Product> get searchResults {
    Iterable<Product> list = _query.isEmpty ? _catalog : _searchApi;
    final cat = _searchCategory;
    if (cat != null) list = list.where((p) => p.category == cat);
    return list.toList();
  }

  Product? byId(int id) {
    for (final p in _catalog) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> init() async {
    await Future.wait([_loadCategories(), _loadProducts()]);
  }

  Future<void> refresh() => init();

  /// Membaca dari server sendiri; bila gagal, dari dummyjson (mode offline).
  Future<T> _read<T>(Future<T> Function(ApiServiceProducts api) call) async {
    try {
      final r = await call(_api);
      _offline = false;
      return r;
    } catch (_) {
      final r = await call(_backup);
      _offline = true;
      return r;
    }
  }

  // ---------- beranda ----------

  void selectCategory(String? slug) {
    _category = slug;
    _rebuild();
    notifyListeners();
  }

  // ---------- pencarian ----------

  void selectSearchCategory(String? slug) {
    _searchCategory = slug;
    notifyListeners();
  }

  Future<void> search(String q) async {
    _query = q.trim();
    final id = ++_searchId;

    if (_query.isEmpty) {
      _searching = false;
      notifyListeners();
      return;
    }

    _searching = true;
    notifyListeners();
    try {
      final res = await _read((api) => api.searchProducts(_query));
      if (id != _searchId) return;
      _searchApi = res.products;
    } catch (_) {
      if (id != _searchId) return;
      // tanpa koneksi sama sekali: cari di katalog yang sudah dimuat
      _searchApi = _catalog.where((p) => _matches(p, _query)).toList();
    }
    _searching = false;
    notifyListeners();
  }

  bool _matches(Product p, String q) {
    final k = q.toLowerCase();
    return p.title.toLowerCase().contains(k) ||
        p.brand.toLowerCase().contains(k) ||
        p.category.toLowerCase().contains(k) ||
        p.description.toLowerCase().contains(k);
  }

  // ---------- favorit ----------

  void toggleFavorite(int id) {
    if (!_favorites.remove(id)) _favorites.add(id);
    notifyListeners();
  }

  // ---------- tambah / ubah / hapus (khusus admin, disimpan di MySQL) ----------

  Future<bool> addProduct(Map<String, dynamic> data) =>
      _write(() async => _api.addProduct(data));

  Future<bool> updateProduct(int id, Product updated) =>
      _write(() async => _api.updateProduct(id, updated.toJson()));

  Future<bool> deleteProduct(int id) async {
    final ok = await _write(() async => _api.deleteProduct(id));
    if (ok) {
      _favorites.remove(id);
      notifyListeners();
    }
    return ok;
  }

  Future<bool> _write(Future<void> Function() action) async {
    _actionError = null;
    if (_offline) {
      _actionError = 'Server belum terhubung, jadi data tidak bisa diubah. Nyalakan Docker lalu tarik layar beranda untuk memuat ulang.';
      return false;
    }
    try {
      await action();
      await _reloadQuietly();
      return true;
    } catch (e) {
      _actionError = ApiException.from(e).message;
      return false;
    }
  }

  /// Memuat ulang katalog tanpa menampilkan layar loading.
  Future<void> _reloadQuietly() async {
    try {
      final res = await _api.getAllProducts();
      _catalog = res.products;
      _rebuild();
      // pencarian aktif ikut disegarkan supaya hasilnya tidak basi
      if (_query.isNotEmpty) {
        final s = await _api.searchProducts(_query);
        _searchApi = s.products;
      }
    } catch (_) {
      // data lama tetap dipakai; akan tersegarkan saat refresh berikutnya
    }
    notifyListeners();
  }

  // ---------- internal ----------

  void _rebuild() {
    final cat = _category;
    _view = cat == null
        ? List<Product>.of(_catalog)
        : _catalog.where((p) => p.category == cat).toList();
  }

  Future<void> _loadCategories() async {
    try {
      _categories = await _read((api) => api.getCategoryList());
      notifyListeners();
    } catch (_) {
      // kategori hanya pelengkap, abaikan jika gagal
    }
  }

  Future<void> _loadProducts() async {
    final id = ++_requestId;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _read((api) => api.getAllProducts()); // limit 0 = semua produk
      if (id != _requestId) return;
      _catalog = res.products;
      _rebuild();
    } catch (_) {
      if (id != _requestId) return;
      _error = 'Gagal memuat produk. Periksa koneksi internet dan server kamu.';
    } finally {
      if (id == _requestId) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<Product> fetchProduct(String id) async {
    final pid = int.tryParse(id);
    if (pid == null) throw Exception('ID produk tidak valid');
    final local = byId(pid);
    if (local != null) return local;
    return _read((api) => api.getProduct(pid));
  }
}
