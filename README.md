# Miiard.Mart

Aplikasi toko online berbasis **Flutter** dengan backend **PHP + MySQL** yang berjalan di **Docker**.
Dibuat sebagai tugas mata kuliah Pemrograman Perangkat Bergerak.

**Pembuat:** Nazhmi Putra Ardiyan (IF 24 A)

---

## Fitur

**Pengguna**
- Daftar, login, dan lupa password
- Katalog produk, pencarian, filter kategori, dan favorit
- Detail produk, keranjang, dan checkout
- Pembayaran dengan QRIS
- Riwayat pesanan dan pembatalan pesanan
- Foto profil dari galeri atau kamera

**Admin**
- Tambah, edit, dan hapus produk
- Foto produk dipilih dari galeri atau file laptop, bukan URL
- Statistik toko, daftar pengguna, dan pengaturan role
- Mengubah status pesanan

---

## Teknologi

| Bagian | Teknologi |
|---|---|
| Aplikasi | Flutter, Provider, go_router, Dio, google_fonts, shared_preferences, image_picker, url_launcher |
| Backend | PHP (REST API), JWT |
| Database | MySQL |
| Antrean | RabbitMQ (`worker.php`) |
| Infrastruktur | Docker |

---

## Struktur folder

```
miiard_mart/
├── backend/htdocs/
│   ├── index.php              # pintu masuk API
│   ├── Rest.php               # helper respond() dan fail()
│   ├── worker.php             # pemroses antrean RabbitMQ
│   ├── routes/api.php         # semua rute API
│   ├── controller/            # Product, UserAuth, Admin, Order, Upload
│   ├── models/UserStore.php   # akses database dan pembuatan tabel
│   └── support/               # Jwt, Guard, RabbitMq, AppSettings
└── flutter/
    ├── assets/images/         # logo dan QRIS
    └── lib/
        ├── config/            # alamat server (api_config.dart)
        ├── models/            # Product, User, Order, CartItem
        ├── providers/         # state aplikasi
        ├── services/          # panggilan API
        ├── screens/           # halaman
        ├── widgets/           # komponen
        ├── theme/             # warna dan teks
        └── utils/
```

---

## Cara pasang

### 1. Backend

1. Salin isi `backend/htdocs` ke folder `htdocs` milikmu. Pilih **Replace the files in the destination**.
2. Nyalakan Docker (`docker compose up -d`).
3. Buka `http://localhost:8080/health`. Kalau muncul `{"status":"ok"...}`, server sudah hidup.

Semua tabel dibuat otomatis saat request pertama: `users`, `orders`, `order_items`, `product_images`, dan lainnya.

> Angka port (8080) mengikuti `ports:` pada `docker-compose.yml` milikmu. Sesuaikan kalau berbeda.

**Akun admin pertama**

```
email    : admin@miiard.mart
password : Admin123!
```

Ganti password ini sebelum aplikasi dipakai di luar keperluan tugas.

### 2. Flutter

1. Ganti folder `lib/` dan `assets/` proyek Flutter-mu dengan yang ada di `flutter/`.
2. Pastikan `pubspec.yaml` berisi:

```yaml
dependencies:
  provider: ^6.1.2
  go_router: ^14.0.0
  dio: ^5.4.0
  google_fonts: ^6.2.1
  url_launcher: ^6.3.0
  shared_preferences: ^2.2.3
  image_picker: ^1.0.7

flutter:
  assets:
    - assets/images/
```

3. Jalankan `flutter pub get`.
4. Khusus iOS, tambahkan di `ios/Runner/Info.plist`:
   - `NSPhotoLibraryUsageDescription`: "Pilih foto"
   - `NSCameraUsageDescription`: "Ambil foto"

---

## Menjalankan aplikasi

Alamat server diatur lewat `--dart-define=API_URL=...`, tanpa mengedit kode.

| Dijalankan di | Perintah |
|---|---|
| Emulator Android | `flutter run` (bawaan `http://10.0.2.2:8080`) |
| Chrome | `flutter run -d chrome --dart-define=API_URL=http://localhost:8080` |
| Windows | `flutter run -d windows --dart-define=API_URL=http://localhost:8080` |
| HP asli (satu Wi-Fi) | `flutter run --dart-define=API_URL=http://IP_LAPTOP:8080` |

---

## Foto produk dari galeri

Di halaman Tambah atau Edit Produk, ketuk kotak foto atau tombol **Pilih dari galeri**.

- Format JPG, PNG, atau WEBP, maksimal 5 MB.
- Foto diunggah saat tombol Simpan atau Perbarui ditekan, lalu disimpan di MySQL (tabel `product_images`).
- Di Windows, macOS, Linux, dan Chrome, yang terbuka adalah dialog file laptop.
- Di emulator Android, yang terbuka adalah galeri emulator. Seret fotonya dari laptop ke jendela emulator lebih dulu.

---

## Daftar endpoint

| Metode | Rute | Keterangan |
|---|---|---|
| POST | `/auth/register`, `/auth/login` | Daftar dan login |
| GET / PUT | `/auth/me` | Data akun |
| PUT / DELETE | `/auth/avatar` | Foto profil |
| POST | `/auth/forgot`, `/auth/reset` | Lupa password |
| GET | `/products`, `/products/{id}`, `/products/search` | Katalog dan pencarian |
| GET | `/products/categories`, `/products/category-list` | Kategori |
| POST / PUT / DELETE | `/products`, `/products/{id}` | Kelola produk (admin) |
| POST | `/uploads/product` | Unggah foto produk (admin) |
| GET | `/uploads/product/{id}` | Menampilkan foto produk |
| POST / GET | `/orders`, `/orders/{id}` | Checkout dan riwayat |
| POST | `/orders/{id}/cancel` | Batalkan pesanan |
| GET | `/admin/stats`, `/admin/users`, `/admin/orders` | Data admin |
| PATCH | `/admin/users/{id}`, `/admin/orders/{id}` | Ubah role dan status pesanan |

---

## Pemecahan masalah

**"Gagal menambahkan produk. Server belum terhubung..."**
Aplikasi tidak bisa menghubungi server dan beralih ke data cadangan dummyjson yang hanya bisa dibaca.
1. Pastikan Docker menyala dan `http://localhost:8080/health` terbuka di browser.
2. Jalankan aplikasi dengan `API_URL` yang sesuai (lihat tabel di atas).
3. Tarik layar beranda ke bawah untuk memuat ulang.

**Foto produk tidak muncul**
Cek bahwa server hidup dan `API_URL` benar. Alamat foto otomatis mengikuti `API_URL` yang sedang dipakai.

**Gagal unggah foto**
Biasanya ukuran lebih dari 5 MB atau formatnya bukan JPG, PNG, atau WEBP. Akun yang dipakai juga harus berrole admin.

**`flutter pub get` meminta Developer Mode (Windows)**
Aktifkan Developer Mode di Pengaturan Windows, lalu ulangi.

---

## Catatan

- Data produk bawaan berasal dari [dummyjson.com](https://dummyjson.com) dan dipakai sebagai cadangan baca-saja.
- Harga ditampilkan dalam dolar (`$`).
