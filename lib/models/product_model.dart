// Fungsi helper untuk mengubah nilai dinamis (dynamic) menjadi tipe data double (angka desimal).
// Jika nilai null atau bukan angka, maka akan mengembalikan nilai default 0.
double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;

// Peta konstanta (Map) untuk menerjemahkan kategori produk dari bahasa Inggris ke bahasa Indonesia.
const _categoryLabels = {
  'beauty': 'Kecantikan',
  'fragrances': 'Parfum',
  'furniture': 'Perabot',
  'groceries': 'Kebutuhan',
  'home-decoration': 'Dekorasi',
  'kitchen-accessories': 'Dapur',
  'skin-care': 'Perawatan Kulit',
  'laptops': 'Laptop',
  'smartphones': 'Ponsel',
};

// Fungsi untuk mempercantik nama kategori produk (slug).
// Jika ada di peta _categoryLabels akan diterjemahkan, 
// jika tidak, teks dengan tanda hubung (-) akan diubah menjadi huruf kapital di setiap kata awalnya.
String prettyCategory(String slug) =>
    _categoryLabels[slug] ??
    slug
        .split('-')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

// Kelas untuk merepresentasikan data ulasan (review) dari produk.
class Review {
  final int rating;             // Rating atau penilaian berupa angka (1-5)
  final String comment;         // Komentar atau teks ulasan dari pembeli
  final String reviewerName;    // Nama orang yang memberikan ulasan

  // Konstruktor untuk inisialisasi objek Review
  Review({
    required this.rating,
    required this.comment,
    required this.reviewerName,
  });

  // Factory constructor untuk mengubah data JSON (Map) menjadi objek Review
  factory Review.fromJson(Map<String, dynamic> j) => Review(
        rating: (j['rating'] as num?)?.toInt() ?? 0,
        comment: j['comment'] as String? ?? '',
        reviewerName: j['reviewerName'] as String? ?? 'Anonim',
      );
}

/// Item dari endpoint /products/categories.
class Category {
  final String slug;    // Kode unik kategori (misal: 'smartphones')
  final String name;    // Nama asli kategori
  final String url;     // URL endpoint API untuk kategori tersebut

  // Konstruktor untuk inisialisasi objek Category
  Category({required this.slug, required this.name, required this.url});

  // Factory constructor untuk memetakan data JSON ke dalam objek Category
  factory Category.fromJson(Map<String, dynamic> j) => Category(
        slug: j['slug'] as String? ?? '',
        name: j['name'] as String? ?? '',
        url: j['url'] as String? ?? '',
      );
}

/// Bungkus respons list produk: { products, total, skip, limit }.
class ProductsResponse {
  final List<Product> products; // Daftar list produk
  final int total;              // Total keseluruhan produk yang tersedia di server
  final int skip;               // Jumlah data yang dilewati (untuk pagination)
  final int limit;              // Batasan jumlah produk per halaman

  // Konstruktor untuk inisialisasi respons produk
  ProductsResponse({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  // Factory constructor untuk memparsing respons JSON API ke objek ProductsResponse
  factory ProductsResponse.fromJson(Map<String, dynamic> j) => ProductsResponse(
        products: (j['products'] as List? ?? [])
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (j['total'] as num?)?.toInt() ?? 0,
        skip: (j['skip'] as num?)?.toInt() ?? 0,
        limit: (j['limit'] as num?)?.toInt() ?? 0,
      );
}

// Kelas utama untuk merepresentasikan data sebuah produk
class Product {
  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String brand;
  final String thumbnail;
  final List<String> images;
  final List<String> tags;
  final String warrantyInformation;
  final String shippingInformation;
  final String availabilityStatus;
  final String returnPolicy;
  final List<Review> reviews;

  // Konstruktor untuk inisialisasi objek Product
  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.brand,
    required this.thumbnail,
    required this.images,
    required this.tags,
    required this.warrantyInformation,
    required this.shippingInformation,
    required this.availabilityStatus,
    required this.returnPolicy,
    required this.reviews,
  });

  // Getter untuk menghitung harga setelah mendapatkan potongan diskon
  double get discountedPrice => price * (1 - discountPercentage / 100);

  // Fungsi copyWith untuk menduplikasi objek Product dengan opsi mengubah beberapa nilai tertentu saja
  Product copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    double? price,
    double? discountPercentage,
    double? rating,
    int? stock,
    String? brand,
    String? thumbnail,
    List<String>? images,
    List<String>? tags,
    String? warrantyInformation,
    String? shippingInformation,
    String? availabilityStatus,
    String? returnPolicy,
    List<Review>? reviews,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      rating: rating ?? this.rating,
      stock: stock ?? this.stock,
      brand: brand ?? this.brand,
      thumbnail: thumbnail ?? this.thumbnail,
      images: images ?? this.images,
      tags: tags ?? this.tags,
      warrantyInformation: warrantyInformation ?? this.warrantyInformation,
      shippingInformation: shippingInformation ?? this.shippingInformation,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      reviews: reviews ?? this.reviews,
    );
  }

  /// Body untuk POST/PUT ke dummyjson.
  /// Mengubah objek Product kembali menjadi format Map (JSON) untuk dikirim ke API.
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category,
        'price': price,
        'stock': stock,
        'brand': brand,
      };

  // Factory constructor untuk memetakan data JSON dari API ke dalam objek Product
  factory Product.fromJson(Map<String, dynamic> j) {
    final thumb = j['thumbnail'] as String? ?? '';
    final imgs = (j['images'] as List?)?.map((e) => e.toString()).toList() ?? [];
    return Product(
      id: (j['id'] as num).toInt(),
      title: j['title'] as String? ?? '-',
      description: j['description'] as String? ?? '',
      category: j['category'] as String? ?? '',
      price: _d(j['price']),
      discountPercentage: _d(j['discountPercentage']),
      rating: _d(j['rating']),
      stock: (j['stock'] as num?)?.toInt() ?? 0,
      brand: j['brand'] as String? ?? '',
      thumbnail: thumb,
      // Jika list gambar kosong, gunakan thumbnail sebagai satu-satunya gambar
      images: imgs.isEmpty ? [thumb] : imgs,
      tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      warrantyInformation: j['warrantyInformation'] as String? ?? '-',
      shippingInformation: j['shippingInformation'] as String? ?? '-',
      availabilityStatus: j['availabilityStatus'] as String? ?? '-',
      returnPolicy: j['returnPolicy'] as String? ?? '-',
      // Memetakan list JSON review menjadi objek Review
      reviews: (j['reviews'] as List?)
              ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}