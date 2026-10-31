// Mengimpor library standar dari Flutter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Mengimpor package pihak ketiga
import 'package:go_router/go_router.dart'; // Untuk navigasi rute (routing) aplikasi
import 'package:google_fonts/google_fonts.dart'; // Untuk menggunakan font kustom dari Google
import 'package:provider/provider.dart'; // Untuk manajemen state aplikasi

// Mengimpor model data yang digunakan di seluruh aplikasi
import 'models/payment_method.dart';
import 'models/product_model.dart';

// Mengimpor semua Provider (pengelola state/data) yang digunakan
import 'providers/cart_provider.dart';
import 'providers/checkout_provider.dart';
import 'providers/product_provider.dart';

// Mengimpor semua layar (screens) yang ada di dalam aplikasi
import 'screens/add_product_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/detail_product_screen.dart';
import 'screens/edit_product_screen.dart';
import 'screens/home_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/search_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/wishlist_screen.dart';

// Mengimpor tema warna aplikasi
import 'theme/app_colors.dart';

// Titik masuk utama aplikasi (entry point)
void main() {
  // Memastikan jembatan antara framework Flutter dan mesin core sudah terinisialisasi
  // Wajib dipanggil jika ada eksekusi sebelum runApp()
  WidgetsFlutterBinding.ensureInitialized();
  
  // Mengatur warna status bar (di atas) dan navigation bar (di bawah layar HP)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Latar status bar transparan
    statusBarIconBrightness: Brightness.dark, // Ikon status bar (jam, sinyal) berwarna gelap
    systemNavigationBarColor: Colors.white, // Latar navigation bar bawah berwarna putih
    systemNavigationBarIconBrightness: Brightness.dark, // Ikon navigation bar berwarna gelap
  ));

  // Menjalankan aplikasi utama dengan membungkusnya dalam MultiProvider
  runApp(
    MultiProvider(
      providers: [
        // Provider untuk manajemen data produk. Langsung memanggil fungsi init() saat dibuat
        ChangeNotifierProvider(create: (_) => ProductProvider()..init()),
        // Provider untuk manajemen keranjang belanja
        ChangeNotifierProvider(create: (_) => CartProvider()),
        // Provider untuk manajemen proses checkout pesanan
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// Key global untuk mengontrol navigasi utama (root navigator)
// Berguna agar halaman detail atau layar penuh menimpa/menutupi bottom navigation bar
final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Halaman yang bergeser pelan dari kanan sambil memudar.
// Fungsi bantuan untuk membuat animasi transisi kustom saat pindah halaman
CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 420), // Durasi halaman masuk
    reverseTransitionDuration: const Duration(milliseconds: 300), // Durasi halaman keluar (back)
    // Membuat dan mengatur transisi animasi
    transitionsBuilder: (context, animation, secondary, child) {
      // Mengatur kelenturan pergerakan animasi (curve)
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic, // Animasi masuk: melambat di akhir
        reverseCurve: Curves.easeInCubic, // Animasi keluar: perlahan lalu cepat
      );
      // Menggabungkan efek Fade (transparansi) dan Slide (geser posisi)
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          // Posisi awal dari sedikit di sebelah kanan (x = 0.08) menuju ke titik 0 (tengah)
          position: Tween<Offset>(begin: const Offset(.08, 0), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// Widget utama (akar) aplikasi yang mengatur konfigurasi tema dan rute
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Mengatur semua rute halaman menggunakan GoRouter
  static final GoRouter _router = GoRouter(
    navigatorKey: _rootKey, // Menyambungkan router dengan key root
    initialLocation: '/', // Halaman pertama yang dibuka saat aplikasi berjalan
    routes: [
      // Rute awal: Menampilkan layar Splash (animasi pembuka)
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

      // empat tab dengan header + navigasi bawah (ShellRoute)
      // StatefulShellRoute menjaga state/posisi masing-masing tab saat pengguna berpindah-pindah tab
      StatefulShellRoute.indexedStack(
        // ShellScreen adalah kerangka utama yang berisi BottomNavigationBar
        builder: (context, state, shell) => ShellScreen(shell: shell),
        branches: [
          // Cabang Tab 1: Beranda (Home)
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          ]),
          // Cabang Tab 2: Pencarian (Search)
          StatefulShellBranch(routes: [
            GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
          ]),
          // Cabang Tab 3: Keranjang (Cart)
          StatefulShellBranch(routes: [
            GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
          ]),
          // Cabang Tab 4: Profil (Profile)
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),

      // layar penuh di atas tab (menggunakan parentNavigatorKey agar menimpa navigasi bawah)
      
      // Rute Halaman Detail Produk (menerima parameter dinamis ':id')
      GoRoute(
        path: '/detail/:id',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => _slide(
          state,
          DetailProductScreen(
            id: state.pathParameters['id']!, // Mengambil ID dari URL
            // Mengambil objek Produk lengkap jika dilempar melalui ekstra (optimasi performa)
            product: state.extra is Product ? state.extra as Product : null,
          ),
        ),
      ),
      // Rute Halaman Checkout
      GoRoute(
        path: '/checkout',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => _slide(state, const CheckoutScreen()),
      ),
      // Rute Halaman Pembayaran
      GoRoute(
        path: '/payment',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) {
          // Menangkap argument atau data yang dilempar dari layar sebelumnya
          final args = state.extra;
          return _slide(
            state,
            // Jika data sesuai (PaymentArgs), tampilkan layar pembayaran. Jika tidak, tampilkan error.
            args is PaymentArgs
                ? PaymentScreen(args: args)
                : const Scaffold(body: Center(child: Text('Data pembayaran tidak ditemukan'))),
          );
        },
      ),
      // Rute Halaman Wishlist (Favorit)
      GoRoute(
        path: '/wishlist',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => _slide(state, const WishlistScreen()),
      ),
      // Rute Halaman Tambah Produk Baru
      GoRoute(
        path: '/add',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) => _slide(state, const AddProductScreen()),
      ),
      // Rute Halaman Edit Produk (menerima parameter dinamis ':id')
      GoRoute(
        path: '/edit/:id',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) {
          final extra = state.extra;
          // Mencoba mendapatkan produk dari state extra, jika tidak ada cari melalui ProductProvider berdasarkan ID
          final product = extra is Product
              ? extra
              : context
                  .read<ProductProvider>()
                  .byId(int.tryParse(state.pathParameters['id']!) ?? -1);
                  
          return _slide(
            state,
            // Jika produk tidak ditemukan di provider, tampilkan pesan error
            product == null
                ? const Scaffold(body: Center(child: Text('Produk tidak ditemukan')))
                : EditProductScreen(product: product),
          );
        },
      ),
    ],
  );

  // Method wajib untuk menggambar antarmuka (UI) aplikasi
  @override
  Widget build(BuildContext context) {
    // Membuat dasar tema menggunakan Material 3
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: AppColors.accent, // Warna dasar acuan
      scaffoldBackgroundColor: AppColors.background, // Warna latar belakang seluruh halaman
    );
    
    // Mengembalikan widget MaterialApp khusus router
    return MaterialApp.router(
      title: 'Miiard.Mart', // Nama aplikasi (terlihat di task manager HP)
      debugShowCheckedModeBanner: false, // Menghilangkan pita merah "DEBUG" di pojok layar
      // Menggabungkan tema dasar dengan konfigurasi teks dan tombol kustom
      theme: base.copyWith(
        // Menerapkan font Google Plus Jakarta Sans ke seluruh teks dalam aplikasi
        textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
            .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
        // Mewarnai animasi loading default
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.ink),
        
        // tombol FilledButton (form Tambah/Edit, dialog) memakai pastel ungu
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary, // Warna utama tombol
            foregroundColor: AppColors.ink, // Warna teks dalam tombol
            // Warna latar saat tombol disable/tidak bisa ditekan (transparan 60%)
            disabledBackgroundColor: AppColors.lavender.withValues(alpha: .6), 
            disabledForegroundColor: AppColors.inkSoft, // Warna teks saat disable
            elevation: 0, // Menghilangkan bayangan tombol standar Material
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), // Melengkungkan tombol
            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15), // Gaya teks tombol
          ),
        ),
        
        // Tema untuk menu pop-up (contoh: menu titik tiga)
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white, // Latar belakang menu pop-up
          surfaceTintColor: Colors.transparent, // Menghilangkan efek tint dari Material 3
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), // Melengkungkan menu pop-up
        ),
      ),
      // Menyambungkan MaterialApp dengan konfigurasi _router yang sudah dibuat di atas
      routerConfig: _router,
    );
  }
}