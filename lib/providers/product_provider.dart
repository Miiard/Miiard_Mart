// Mengimpor pustaka dasar Flutter untuk mendeteksi perubahan state (ChangeNotifier)
import 'package:flutter/foundation.dart';

// Mengimpor model data produk
import '../models/product_model.dart';
// Mengimpor layanan API produk untuk komunikasi data ke server
import '../services/api_service_products.dart';

// Enum untuk mendefinisikan opsi pengurutan (sorting) produk
enum SortOption { relevan, termurah, termahal, ratingTertinggi }

// Extension untuk memberikan label/teks tampilan pada setiap opsi pengurutan
extension SortOptionLabel on SortOption {
  String get label => switch (this) {
        SortOption.relevan => 'Rekomendasi',
        SortOption.termurah => 'Harga terendah',
        SortOption.termahal => 'Harga tertinggi',
        SortOption.ratingTertinggi => 'Rating tertinggi',
      };
}

// Kelas state management ProductProvider untuk mengelola data produk, pencarian, filter, dan favorit
class ProductProvider extends ChangeNotifier {
  final ApiServiceProducts _api = ApiServiceProducts(); // Inisialisasi layanan API produk

  List<Product> _raw = []; // Hasil gabungan dari API + perubahan lokal (mentah)
  List<Product> _view = []; // Daftar produk setelah melalui proses sort & filter favorit
  List<String> _categories = []; // Daftar kategori produk
  final Set<int> _favorites = {}; // Menyimpan ID produk yang ditandai sebagai favorit

  // dummyjson tidak menyimpan perubahan (hanya simulasi), jadi
  // tambah/edit/hapus dicatat di sini agar tetap terlihat di aplikasi.
  final List<Product> _added = []; // Menyimpan produk baru yang ditambahkan secara lokal
  final Map<int, Product> _edited = {}; // Menyimpan produk yang telah diedit secara lokal
  final Set<int> _deleted = {}; // Menyimpan ID produk yang telah dihapus secara lokal
  int _nextLocalId = 1000; // ID awal untuk produk buatan lokal (agar tidak bentrok dengan ID API)

  String _query = ''; // Kata kunci pencarian produk
  String? _category; // Kategori yang sedang dipilih dari API
  SortOption _sort = SortOption.relevan; // Opsi urutan produk aktif
  bool _onlyFavorites = false; // Status apakah hanya menampilkan produk favorit
  bool _loading = false; // Status apakah sedang memuat data dari server
  String? _error; // Pesan error jika gagal memuat data
  int _requestId = 0; // Token ID unik untuk mencegah hasil request lama menimpa request baru

  // Getter publik untuk mengakses state
  List<Product> get products => _view;
  List<String> get categories => _categories;
  String get query => _query;
  String? get selectedCategory => _category;
  SortOption get sort => _sort;
  bool get onlyFavorites => _onlyFavorites;
  int get favoritesCount => _favorites.length;
  bool get loading => _loading;
  String? get error => _error;

  // Fungsi untuk mengecek apakah suatu produk merupakan favorit
  bool isFavorite(int id) => _favorites.contains(id);

  // ---------- filter sisi klien (Beranda, Cari, Wishlist) ----------
  // Semua produk dimuat sekali, lalu disaring di perangkat seperti prototipe.

  String _filterCat = 'all'; // Filter kategori lokal ('all' untuk semua)
  String _filterQuery = ''; // Filter teks pencarian lokal

  String get filterCategory => _filterCat;
  String get filterQuery => _filterQuery;

  /// Semua produk yang sedang dimuat (tanpa filter).
  List<Product> get allProducts => List.unmodifiable(_raw);

  /// Kategori yang benar-benar ada di data, urut sesuai kemunculan.
  List<String> get productCategories {
    final seen = <String>{};
    for (final p in _raw) {
      if (p.category.isNotEmpty) seen.add(p.category);
    }
    return seen.toList();
  }

  // Getter untuk mengambil daftar produk yang masuk ke dalam daftar favorit
  List<Product> get favoriteProducts =>
      _raw.where((p) => _favorites.contains(p.id)).toList();

  // Fungsi untuk menyaring produk secara lokal di sisi klien berdasarkan kategori dan kata kunci
  List<Product> filteredProducts({bool withQuery = true}) {
    final q = withQuery ? _filterQuery.trim().toLowerCase() : '';
    return _raw.where((p) {
      if (_filterCat != 'all' && p.category != _filterCat) return false;
      if (q.isEmpty) return true;
      return [p.title, p.category, prettyCategory(p.category), p.brand]
          .any((s) => s.toLowerCase().contains(q));
    }).toList();
  }

  // Fungsi untuk mengubah filter kategori lokal
  void setFilterCategory(String c) {
    if (_filterCat == c) return;
    _filterCat = c;
    notifyListeners();
  }

  // Fungsi untuk mengubah filter teks pencarian lokal
  void setFilterQuery(String q) {
    if (_filterQuery == q) return;
    _filterQuery = q;
    notifyListeners();
  }

  // Fungsi untuk mereset seluruh filter lokal kembali ke kondisi awal
  void resetFilters() {
    _filterCat = 'all';
    _filterQuery = '';
    notifyListeners();
  }

  // Fungsi untuk mencari produk berdasarkan ID dari berbagai sumber lokal maupun server
  Product? byId(int id) {
    if (_deleted.contains(id)) return null;
    for (final p in _added) {
      if (p.id == id) return p;
    }
    final edited = _edited[id];
    if (edited != null) return edited;
    for (final p in _raw) {
      if (p.id == id) return p;
    }
    return null;
  }

  // Fungsi privat untuk mengecek apakah sebuah ID produk dibuat secara lokal
  bool _isLocal(int id) => _added.any((p) => p.id == id);

  // Inisialisasi awal untuk memuat kategori dan data produk secara bersamaan
  Future<void> init() async {
    await Future.wait([_loadCategories(), _loadProducts()]);
  }

  // Fungsi untuk memuat ulang data produk (refresh)
  Future<void> refresh() => _loadProducts();

  // Fungsi untuk melakukan pencarian produk berdasarkan kata kunci
  Future<void> search(String q) {
    _query = q.trim();
    return _loadProducts();
  }

  // Fungsi untuk memilih kategori produk tertentu
  Future<void> selectCategory(String? slug) {
    _category = slug;
    return _loadProducts();
  }

  // Fungsi untuk mengubah metode pengurutan (sorting)
  void setSort(SortOption option) {
    _sort = option;
    _rebuildView();
    notifyListeners();
  }

  // Fungsi untuk menambah atau menghapus produk dari daftar favorit (toggle)
  void toggleFavorite(int id) {
    if (!_favorites.remove(id)) _favorites.add(id);
    _rebuildView();
    notifyListeners();
  }

  // Fungsi untuk mengaktifkan atau menonaktifkan filter tampilan khusus favorit saja
  void toggleOnlyFavorites() {
    _onlyFavorites = !_onlyFavorites;
    _rebuildView();
    notifyListeners();
  }

  // ---------- tambah / edit / hapus ----------

  // Fungsi untuk menambahkan produk baru secara lokal dan simulasi ke API
  Future<bool> addProduct(Map<String, dynamic> data) async {
    try {
      await _api.addProduct(data); // simulasi POST ke dummyjson
      final stock = (data['stock'] as num?)?.toInt() ?? 0;
      final product = Product.fromJson({
        ...data,
        'id': _nextLocalId++,
        'availabilityStatus': stock > 0 ? 'In Stock' : 'Out of Stock',
      });
      _added.insert(0, product);
      if (_matches(product)) _raw = [product, ..._raw];
      _rebuildView();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Fungsi untuk memperbarui data produk (edit)
  Future<bool> updateProduct(int id, Product updated) async {
    try {
      final local = _isLocal(id);
      if (!local) await _api.updateProduct(id, updated.toJson()); // simulasi PUT
      if (local) {
        final i = _added.indexWhere((p) => p.id == id);
        if (i >= 0) _added[i] = updated;
      } else {
        _edited[id] = updated;
      }
      final i = _raw.indexWhere((p) => p.id == id);
      if (i >= 0) _raw[i] = updated;
      _rebuildView();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // Fungsi untuk menghapus produk berdasarkan ID
  Future<bool> deleteProduct(int id) async {
    try {
      if (_isLocal(id)) {
        _added.removeWhere((p) => p.id == id);
      } else {
        await _api.deleteProduct(id); // simulasi DELETE
        _deleted.add(id);
        _edited.remove(id);
      }
      _raw.removeWhere((p) => p.id == id);
      _favorites.remove(id);
      _rebuildView();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------- internal ----------

  // Fungsi helper untuk mengecek apakah suatu produk sesuai dengan kriteria kategori dan query pencarian aktif
  bool _matches(Product p) {
    final cat = _category;
    if (cat != null && p.category != cat) return false;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      final hit = p.title.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
      if (!hit) return false;
    }
    return true;
  }

  // Fungsi untuk menyusun ulang tampilan list produk (_view) berdasarkan filter favorit dan aturan sorting aktif
  void _rebuildView() {
    var list = List<Product>.of(_raw);
    if (_onlyFavorites) {
      list = list.where((p) => _favorites.contains(p.id)).toList();
    }
    switch (_sort) {
      case SortOption.relevan:
        break;
      case SortOption.termurah:
        list.sort((a, b) => a.discountedPrice.compareTo(b.discountedPrice));
      case SortOption.termahal:
        list.sort((a, b) => b.discountedPrice.compareTo(a.discountedPrice));
      case SortOption.ratingTertinggi:
        list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    _view = list;
  }

  // Fungsi privat untuk memuat daftar kategori dari API
  Future<void> _loadCategories() async {
    try {
      _categories = await _api.getCategoryList();
      notifyListeners();
    } catch (_) {
      // kategori hanya pelengkap, abaikan jika gagal
    }
  }

  // Fungsi utama untuk memuat data produk dari API berdasarkan query atau kategori yang dipilih
  Future<void> _loadProducts() async {
    final id = ++_requestId;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final cat = _category;
      final ProductsResponse res;
      if (_query.isNotEmpty) {
        res = await _api.searchProducts(_query);
      } else if (cat != null) {
        res = await _api.getProductsByCategory(cat);
      } else {
        res = await _api.getAllProducts();
      }

      var list = res.products;

      // search + kategori dipakai bersamaan -> saring di sisi klien
      if (_query.isNotEmpty && cat != null) {
        list = list.where((p) => p.category == cat).toList();
      }

      // terapkan perubahan lokal (hapus / edit), lalu tambahkan produk baru
      list = list
          .where((p) => !_deleted.contains(p.id))
          .map((p) => _edited[p.id] ?? p)
          .where((p) => !_edited.containsKey(p.id) || _matches(p))
          .toList();
      final extras = _added.where(_matches).toList();

      if (id != _requestId) return;
      _raw = [...extras, ...list];
      _rebuildView();
    } catch (_) {
      if (id != _requestId) return;
      _raw = [];
      _rebuildView();
      _error = 'Gagal memuat produk. Periksa koneksi internet kamu.';
    } finally {
      if (id == _requestId) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  // Fungsi untuk mengambil detail data sebuah produk berdasarkan string ID
  Future<Product> fetchProduct(String id) async {
    final pid = int.tryParse(id);
    if (pid == null) throw Exception('ID produk tidak valid');
    if (_deleted.contains(pid)) throw Exception('Produk sudah dihapus');
    final local = byId(pid);
    if (local != null) return local;
    return _api.getProduct(pid);
  }
}