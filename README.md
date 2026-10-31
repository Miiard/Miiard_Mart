# Miiard.Mart

Aplikasi katalog produk berbasis **Flutter** dengan tema warna **pastel**. Data produk diambil dari API [DummyJSON Products](https://dummyjson.com/docs/products). Aplikasi dijalankan di handphone (Android/iOS), bukan di browser.

> Tugas mata kuliah **[Praktikum Pemograman Bergerak]**
> Nama: **[Nama Lengkap]** | NIM: **[230102095]** | Kelas: **[IF 24A]**

## Video Penjelasan dan Demo

**[Tonton di YouTube](https://youtu.be/ITff3ohcfyM?si=B0KVQk8aHi40k1nF)**

Video berisi penjelasan kode dan demo aplikasi di handphone (permission: Public).



## Ketentuan Tugas dan Pemenuhannya

| Ketentuan | Status | Keterangan |
|---|:---:|---|
| Memakai API DummyJSON Products | Ya | Service di `lib/services/api_service_products.dart` |
| Halaman depan menampilkan seluruh produk, tema pastel | Ya | `lib/screens/home_screen.dart` (grid semua produk, `limit=0`) |
| Halaman detail produk, tema pastel, dibuka dari halaman depan | Ya | `lib/screens/detail_product_screen.dart` |
| Tombol search yang berfungsi | Ya | `lib/screens/search_screen.dart` |


## Fitur

**Sesuai ketentuan tugas**
- **Halaman depan:** banner, chip kategori, dan grid seluruh produk dengan foto, nama, kategori, harga setelah diskon, rating, dan badge diskon. Tarik ke bawah untuk memuat ulang.
- **Detail produk:** foto besar, kategori, merek, status stok, harga asli dan harga diskon, rating, deskripsi, serta informasi garansi, pengiriman, dan pengembalian.
- **Pencarian:** menyaring produk berdasarkan nama, kategori, dan merek secara langsung saat mengetik, bisa digabung dengan filter kategori. Ada tampilan khusus saat hasil kosong.
- **Skema warna pastel:** lavender, pink, peach, mint, kuning, dan sky blue di atas latar krem.
- **Penanganan status:** skeleton saat memuat, pesan error dengan tombol coba lagi, dan placeholder bila foto gagal dimuat.

**Fitur tambahan**
- Keranjang belanja (ubah jumlah, hapus dengan Urungkan, batas stok)
- Wishlist
- Tambah, edit, dan hapus produk (disimulasikan oleh DummyJSON, perubahan dicatat lokal)
- Checkout dengan pilihan alamat pengiriman
- Pembayaran **QRIS** dan **DANA** dengan konfirmasi manual

## Teknologi

| Kebutuhan | Package |
|---|---|
| Framework | Flutter (Dart 3) |
| HTTP client | [`dio`](https://pub.dev/packages/dio) |
| State management | [`provider`](https://pub.dev/packages/provider) |
| Navigasi | [`go_router`](https://pub.dev/packages/go_router) |
| Font | [`google_fonts`](https://pub.dev/packages/google_fonts) (Cormorant Garamond, Plus Jakarta Sans) |
| Membuka aplikasi DANA | [`url_launcher`](https://pub.dev/packages/url_launcher) |

## Endpoint API yang Dipakai

Base URL: `https://dummyjson.com`

| Method | Endpoint | Kegunaan |
|---|---|---|
| GET | `/products?limit=0` | Seluruh produk untuk halaman depan |
| GET | `/products/{id}` | Detail satu produk |
| GET | `/products/search?q=` | Tersedia di service untuk pencarian lewat API |
| GET | `/products/category-list` | Daftar kategori (form tambah/edit) |
| GET | `/products/category/{slug}` | Produk per kategori |
| POST | `/products/add` | Menambah produk (simulasi) |
| PUT | `/products/{id}` | Mengubah produk (simulasi) |
| DELETE | `/products/{id}` | Menghapus produk (simulasi) |

Catatan: DummyJSON hanya mensimulasikan POST, PUT, dan DELETE tanpa menyimpannya di server. Karena itu perubahan dicatat di sisi aplikasi (`ProductProvider`) agar tetap terlihat.
Pencarian di aplikasi menyaring seluruh data yang sudah dimuat di perangkat, sehingga hasilnya muncul seketika tanpa menunggu jaringan.

## Struktur Proyek

```
lib/
├── main.dart                    # Provider, tema, dan rute (go_router)
├── config/
│   └── payment_config.dart      # Nomor DANA, kurs USD-IDR, batas waktu bayar
├── models/
│   ├── product_model.dart       # Product, Review, Category, fromJson
│   ├── cart_item.dart
│   ├── address.dart
│   ├── payment_method.dart
│   └── user_profile.dart
├── services/
│   ├── api_service_products.dart  # Pemanggilan API dengan dio
│   └── product_service.dart
├── providers/
│   ├── product_provider.dart    # Daftar produk, loading, error, filter, favorit
│   ├── cart_provider.dart       # Keranjang dan checkout
│   └── checkout_provider.dart   # Alamat dan metode pembayaran
├── screens/
│   ├── splash_screen.dart
│   ├── shell_screen.dart        # Header dan navigasi bawah
│   ├── home_screen.dart         # Halaman depan
│   ├── search_screen.dart       # Pencarian
│   ├── detail_product_screen.dart
│   ├── cart_screen.dart
│   ├── checkout_screen.dart
│   ├── payment_screen.dart
│   ├── wishlist_screen.dart
│   ├── profile_screen.dart
│   ├── add_product_screen.dart
│   └── edit_product_screen.dart
├── theme/
│   ├── app_colors.dart          # Palet pastel
│   └── app_text.dart            # Gaya teks
└── widgets/                     # Komponen UI yang dipakai ulang
assets/images/                   # Logo, latar splash, gambar QRIS
```

## Alur Data

```
DummyJSON API
     │  dio (GET /products?limit=0)
     ▼
ApiServiceProducts ──► Product.fromJson ──► ProductProvider (state)
                                               │ notifyListeners
                                               ▼
                           HomeScreen / SearchScreen / DetailProductScreen
```

## Cara Menjalankan

**Prasyarat:** Flutter SDK 3.27 atau lebih baru, dan handphone dengan USB debugging aktif (atau emulator).

```bash
git clone https://github.com/[username]/[nama-repo].git
cd [nama-repo]
flutter pub get
flutter devices          # pastikan HP terdeteksi
flutter run
```

Aplikasi membutuhkan koneksi internet untuk memuat data produk dan font.

### Pengaturan pembayaran (opsional)

Buka `lib/config/payment_config.dart`, lalu isi:
- `danaNumber` dan `danaAccountName` dengan akun DANA penerima
- `usdToIdr` bila ingin mengubah kurs (harga dari API dalam dolar)

Gambar QRIS toko ada di `assets/images/qris.png`.

**Catatan pembayaran:** QRIS bersifat statis, jadi pembeli mengetik nominal sendiri, dan ditambahkan kode unik 3 digit untuk mempermudah pencocokan. Aplikasi ini belum memverifikasi pembayaran secara otomatis; tombol "Saya sudah bayar" hanya konfirmasi dari pembeli. Verifikasi otomatis memerlukan payment gateway dan server.

## Keterbatasan

- Keranjang, wishlist, dan alamat disimpan di memori, sehingga hilang saat aplikasi ditutup.
- Perubahan produk (tambah, edit, hapus) hanya simulasi dan tidak permanen di server.
- Data pengguna di halaman Profil adalah contoh tetap.

## Penggunaan AI

[Isi sesuai kenyataan pengerjaanmu, misalnya: "Bantuan AI hanya digunakan untuk bagian tampilan (UI) sesuai ketentuan tugas. Logika (model, service, provider, dan pencarian) dikerjakan secara manual."]

## Referensi

- [DummyJSON Products](https://dummyjson.com/docs/products)
- [Referensi palet pastel (Vecteezy)](https://www.vecteezy.com/vector-art/27338494-collection-of-pastel-color-palette)
- [Dokumentasi Flutter](https://docs.flutter.dev)
