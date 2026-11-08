import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Tab aktif pada bottom navigation: 0 Beranda, 1 Cari, 2 Keranjang, 3 Profil.
class NavProvider extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void go(int i) {
    if (i == _index) return;
    _index = i;
    notifyListeners();
  }
}

/// Membuka tab Keranjang dari mana saja (termasuk dari halaman detail).
void openCartTab(NavProvider nav, GoRouter router) {
  nav.go(2);
  router.go('/');
}
