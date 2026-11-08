import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'models/product_model.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/nav_provider.dart';
import 'providers/order_provider.dart';
import 'providers/product_provider.dart';
import 'screens/add_product_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/detail_product_screen.dart';
import 'screens/edit_product_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/wishlist_screen.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  final auth = AuthProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => ProductProvider()..init()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MyApp(auth: auth),
    ),
  );
}

/// Transisi halus: muncul perlahan + naik sedikit.
CustomTransitionPage<void> _softPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class MyApp extends StatefulWidget {
  final AuthProvider auth;
  const MyApp({super.key, required this.auth});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router = _buildRouter(widget.auth);

  static const _authPages = ['/login', '/register', '/forgot'];

  /// Penjaga halaman: belum login -> /login; halaman admin hanya untuk admin.
  static GoRouter _buildRouter(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final loc = state.matchedLocation;
        if (loc == '/splash') return null;
        if (!auth.ready) return '/splash';

        final onAuthPage = _authPages.contains(loc);
        if (!auth.isLoggedIn) return onAuthPage ? null : '/login';
        if (onAuthPage) return '/';

        final adminOnly = loc == '/admin' || loc == '/add' || loc.startsWith('/edit/');
        if (adminOnly && !auth.isAdmin) return '/';
        return null;
      },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const HomeShell(),
          transitionDuration: const Duration(milliseconds: 700),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        ),
      ),
      GoRoute(
        path: '/detail/:id',
        pageBuilder: (context, state) => _softPage(
          state,
          DetailProductScreen(
            id: state.pathParameters['id']!,
            product: state.extra is Product ? state.extra as Product : null,
          ),
        ),
      ),
      GoRoute(
        path: '/edit/:id',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final product = extra is Product
              ? extra
              : context
                  .read<ProductProvider>()
                  .byId(int.tryParse(state.pathParameters['id']!) ?? -1);
          return _softPage(
            state,
            product == null
                ? const HomeShell()
                : EditProductScreen(product: product),
          );
        },
      ),
      GoRoute(
        path: '/add',
        pageBuilder: (context, state) =>
            _softPage(state, const AddProductScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _softPage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _softPage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/forgot',
        pageBuilder: (context, state) =>
            _softPage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => _softPage(state, const AdminScreen()),
      ),
      GoRoute(
        path: '/checkout',
        pageBuilder: (context, state) => _softPage(state, const CheckoutScreen()),
      ),
      GoRoute(
        path: '/orders',
        pageBuilder: (context, state) => _softPage(state, const OrdersScreen()),
      ),
      GoRoute(
        path: '/wishlist',
        pageBuilder: (context, state) =>
            _softPage(state, const WishlistScreen()),
      ),
    ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: AppColors.accent,
      scaffoldBackgroundColor: AppColors.background,
    );

    return MaterialApp.router(
      title: 'Miiard.Mart',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        ),
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(color: AppColors.ink),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.ink,
            disabledBackgroundColor: AppColors.lavender.o(0.6),
            disabledForegroundColor: AppColors.inkSoft,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.ink,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      routerConfig: _router,
    );
  }
}
