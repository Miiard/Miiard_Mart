double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;

String prettyCategory(String slug) => slug
    .split('-')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

class Review {
  final int rating;
  final String comment;
  final String reviewerName;

  Review({
    required this.rating,
    required this.comment,
    required this.reviewerName,
  });

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        rating: (j['rating'] as num?)?.toInt() ?? 0,
        comment: j['comment'] as String? ?? '',
        reviewerName: j['reviewerName'] as String? ?? 'Anonim',
      );
}

/// Item dari endpoint /products/categories.
class Category {
  final String slug;
  final String name;
  final String url;

  Category({required this.slug, required this.name, required this.url});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        slug: j['slug'] as String? ?? '',
        name: j['name'] as String? ?? '',
        url: j['url'] as String? ?? '',
      );
}

/// Bungkus respons list produk: { products, total, skip, limit }.
class ProductsResponse {
  final List<Product> products;
  final int total;
  final int skip;
  final int limit;

  ProductsResponse({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory ProductsResponse.fromJson(Map<String, dynamic> j) => ProductsResponse(
        products: (j['products'] as List? ?? [])
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (j['total'] as num?)?.toInt() ?? 0,
        skip: (j['skip'] as num?)?.toInt() ?? 0,
        limit: (j['limit'] as num?)?.toInt() ?? 0,
      );
}

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

  double get discountedPrice => price * (1 - discountPercentage / 100);

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
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category,
        'price': price,
        'stock': stock,
        'brand': brand,
        'thumbnail': thumbnail,
        'images': images,
      };

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
      images: imgs.isEmpty ? [thumb] : imgs,
      tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      warrantyInformation: j['warrantyInformation'] as String? ?? '-',
      shippingInformation: j['shippingInformation'] as String? ?? '-',
      availabilityStatus: j['availabilityStatus'] as String? ?? '-',
      returnPolicy: j['returnPolicy'] as String? ?? '-',
      reviews: (j['reviews'] as List?)
              ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Label kategori berbahasa Indonesia untuk tampilan (slug asli tetap dipakai untuk API).
String categoryLabel(String slug) {
  const map = {
    'beauty': 'Kecantikan',
    'fragrances': 'Parfum',
    'furniture': 'Perabot',
    'groceries': 'Kebutuhan',
    'home-decoration': 'Dekorasi',
    'kitchen-accessories': 'Dapur',
    'laptops': 'Laptop',
    'mens-shirts': 'Kemeja Pria',
    'mens-shoes': 'Sepatu Pria',
    'mens-watches': 'Jam Pria',
    'mobile-accessories': 'Aksesori HP',
    'motorcycle': 'Motor',
    'skin-care': 'Perawatan Kulit',
    'smartphones': 'Ponsel',
    'sports-accessories': 'Olahraga',
    'sunglasses': 'Kacamata',
    'tablets': 'Tablet',
    'tops': 'Atasan',
    'vehicle': 'Kendaraan',
    'womens-bags': 'Tas Wanita',
    'womens-dresses': 'Gaun',
    'womens-jewellery': 'Perhiasan',
    'womens-shoes': 'Sepatu Wanita',
    'womens-watches': 'Jam Wanita',
  };
  return map[slug] ?? prettyCategory(slug);
}
