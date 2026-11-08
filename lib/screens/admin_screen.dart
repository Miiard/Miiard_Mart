import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../services/admin_service.dart';
import '../services/api_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/format.dart';
import '../widgets/app_toast.dart';
import '../widgets/grad_button.dart';
import '../widgets/order_card.dart';
import '../widgets/product_image.dart';
import '../widgets/reveal.dart';

/// Panel admin: ringkasan, kelola produk (tambah / ubah / hapus), kelola pengguna.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  final AdminService _service = AdminService();
  late final TabController _tab = TabController(length: 3, vsync: this);

  AdminStats _stats = const AdminStats();
  List<AppUser> _users = [];
  List<ShopOrder> _orders = [];
  bool _ordersLoading = true;
  String? _ordersError;
  bool _usersLoading = true;
  String? _usersError;
  final _search = TextEditingController();
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _tab.addListener(() {
      if (mounted) setState(() {});
    });
    _loadStats();
    _loadUsers();
    _loadOrders();
  }

  @override
  void dispose() {
    _tab.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final s = await _service.stats();
      if (mounted) setState(() => _stats = s);
    } catch (_) {
      // ringkasan hanya pelengkap
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _usersLoading = true;
      _usersError = null;
    });
    try {
      final list = await _service.users();
      if (mounted) setState(() => _users = list);
    } catch (e) {
      if (mounted) setState(() => _usersError = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _usersLoading = false);
    }
  }

  // ---------- pesanan ----------

  Future<void> _loadOrders() async {
    setState(() {
      _ordersLoading = true;
      _ordersError = null;
    });
    try {
      final list = await _service.orders();
      if (mounted) setState(() => _orders = list);
    } catch (e) {
      if (mounted) setState(() => _ordersError = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _ordersLoading = false);
    }
  }

  Future<void> _setOrderStatus(ShopOrder o, String status) async {
    final products = context.read<ProductProvider>();
    try {
      final updated = await _service.setOrderStatus(o.id, status);
      if (!mounted) return;
      setState(() => _orders = [for (final x in _orders) x.id == o.id ? updated : x]);
      if (status == 'dibatalkan') products.refresh(); // stok dikembalikan
      showAppToast(
        context,
        message: 'Status diperbarui',
        subtitle: '${o.code} • ${ShopOrder.statusLabel(status)}',
        icon: Icons.local_shipping_rounded,
        color: statusColor(status),
      );
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: 'Gagal mengubah status',
        subtitle: ApiException.from(e).message,
        icon: Icons.error_outline_rounded,
        color: AppColors.rose,
      );
    }
  }

  // ---------- produk ----------

  Future<void> _openForm(String path, {Product? product}) async {
    await context.push(path, extra: product);
    _loadStats();
  }

  Future<void> _deleteProduct(Product p) async {
    final ok = await _confirm(
      title: 'Hapus produk?',
      message: '"${p.title}" akan dihapus permanen dari database.',
    );
    if (ok != true || !mounted) return;

    final cart = context.read<CartProvider>();
    final provider = context.read<ProductProvider>();
    final done = await provider.deleteProduct(p.id);
    if (!mounted) return;
    if (done) cart.remove(p.id);
    showAppToast(
      context,
      message: done ? 'Produk dihapus' : 'Gagal menghapus produk',
      subtitle: done ? p.title : provider.actionError,
      icon: done ? Icons.delete_outline_rounded : Icons.error_outline_rounded,
      color: AppColors.rose,
    );
    if (done) _loadStats();
  }

  // ---------- pengguna ----------

  Future<void> _changeRole(AppUser u) async {
    final newRole = u.isAdmin ? 'user' : 'admin';
    try {
      await _service.setRole(u.id, newRole);
      if (!mounted) return;
      showAppToast(
        context,
        message: newRole == 'admin' ? 'Dijadikan admin' : 'Dijadikan pengguna biasa',
        subtitle: u.name,
        icon: Icons.verified_user_rounded,
        color: AppColors.lavender,
      );
      _loadUsers();
      _loadStats();
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: 'Gagal mengubah role',
        subtitle: ApiException.from(e).message,
        icon: Icons.error_outline_rounded,
        color: AppColors.rose,
      );
    }
  }

  Future<void> _deleteUser(AppUser u) async {
    final ok = await _confirm(
      title: 'Hapus pengguna?',
      message: 'Akun ${u.name} (${u.email}) akan dihapus permanen.',
    );
    if (ok != true || !mounted) return;
    try {
      await _service.deleteUser(u.id);
      if (!mounted) return;
      showAppToast(
        context,
        message: 'Pengguna dihapus',
        subtitle: u.name,
        icon: Icons.person_remove_rounded,
        color: AppColors.rose,
      );
      _loadUsers();
      _loadStats();
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: 'Gagal menghapus pengguna',
        subtitle: ApiException.from(e).message,
        icon: Icons.error_outline_rounded,
        color: AppColors.rose,
      );
    }
  }

  Future<bool?> _confirm({required String title, required String message}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(title, style: AppText.sans(size: 17, weight: FontWeight.w800)),
        content: Text(message, style: AppText.sans(color: AppColors.inkSoft, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.ink)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.pink,
              foregroundColor: AppColors.ink,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ---------- tampilan ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _tab.index == 0
          ? GradButton(
              label: 'Tambah produk',
              icon: Icons.add_rounded,
              onTap: () => _openForm('/add'),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
              child: Reveal(
                dy: -12,
                child: Row(
                  children: [
                    Pressable(
                      scale: 0.88,
                      onTap: () => context.canPop() ? context.pop() : context.go('/'),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppColors.softShadow,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 19,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Panel Admin', style: AppText.serif(size: 30))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.lavender,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'ADMIN',
                        style: AppText.sans(size: 10.5, weight: FontWeight.w800, letterSpacing: 1.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _statsRow(),
            const SizedBox(height: 14),
            _tabBar(),
            const SizedBox(height: 6),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [_productsTab(), _ordersTab(), _usersTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsRow() {
    Widget card(String label, int value, IconData icon, Color bg, int delay) => Expanded(
          child: Reveal(
            delayMs: delay,
            fromScale: 0.92,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: AppColors.ink),
                  const SizedBox(height: 8),
                  CountUpText(
                    value: value.toDouble(),
                    format: (v) => v.round().toString(),
                    style: AppText.serif(size: 28, height: 1),
                  ),
                  Text(label, style: AppText.sans(size: 10.5, weight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          card('Produk', _stats.products, Icons.inventory_2_rounded, AppColors.peach, 100),
          const SizedBox(width: 10),
          card('Pengguna', _stats.users, Icons.people_alt_rounded, AppColors.lavender, 160),
          const SizedBox(width: 10),
          card(
            'Stok menipis',
            _stats.lowStock + _stats.outOfStock,
            Icons.warning_amber_rounded,
            AppColors.butter,
            220,
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: AppColors.softShadow,
        ),
        child: TabBar(
          controller: _tab,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          splashFactory: NoSplash.splashFactory,
          labelColor: AppColors.ink,
          unselectedLabelColor: AppColors.inkFaint,
          labelStyle: AppText.sans(size: 13, weight: FontWeight.w800),
          unselectedLabelStyle: AppText.sans(size: 13, weight: FontWeight.w700),
          indicator: BoxDecoration(
            gradient: AppColors.gradBtn,
            borderRadius: BorderRadius.circular(22),
          ),
          tabs: const [
            Tab(height: 40, text: 'Produk'),
            Tab(height: 40, text: 'Pesanan'),
            Tab(height: 40, text: 'Pengguna'),
          ],
        ),
      ),
    );
  }

  // ---------- tab produk ----------

  Widget _productsTab() {
    final all = context.watch<ProductProvider>().allProducts;
    final key = _filter.toLowerCase();
    final list = key.isEmpty
        ? all
        : all
            .where((p) =>
                p.title.toLowerCase().contains(key) ||
                p.brand.toLowerCase().contains(key) ||
                p.category.toLowerCase().contains(key))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.inkSoft, size: 21),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _filter = v.trim()),
                    cursorColor: AppColors.ink,
                    style: AppText.sans(size: 13.5, weight: FontWeight.w600),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Cari produk di database…',
                      hintStyle: AppText.sans(size: 13, color: AppColors.inkFaint),
                    ),
                  ),
                ),
                Text('${list.length}', style: AppText.sans(size: 12, color: AppColors.inkSoft)),
              ],
            ),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text(
                    all.isEmpty ? 'Belum ada produk.' : 'Tidak ada yang cocok.',
                    style: AppText.sans(color: AppColors.inkSoft),
                  ),
                )
              : ListView.builder(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final tile = _productTile(list[i]);
                    if (i >= 8) return tile;
                    return Reveal(
                      key: ValueKey('admin-p-${list[i].id}'),
                      delayMs: i * 60,
                      child: tile,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _productTile(Product p) {
    final tone = AppColors.toneFor(p.id);
    final low = p.stock <= 5;

    Widget action(IconData icon, Color bg, VoidCallback onTap) => Pressable(
          scale: 0.85,
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: AppColors.ink),
          ),
        );

    return Pressable(
      scale: 0.98,
      onTap: () => context.push('/detail/${p.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(16)),
              child: ProductImage(url: p.thumbnail, iconSize: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 13.5, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${categoryLabel(p.category)} • ${money(p.price)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 11.5, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: p.stock <= 0
                          ? AppColors.rose
                          : low
                              ? AppColors.butter
                              : AppColors.mint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.stock <= 0 ? 'Habis' : 'Stok ${p.stock}',
                      style: AppText.sans(size: 10.5, weight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            action(Icons.edit_rounded, AppColors.lavender, () => _openForm('/edit/${p.id}', product: p)),
            const SizedBox(width: 6),
            action(Icons.delete_outline_rounded, AppColors.rose, () => _deleteProduct(p)),
          ],
        ),
      ),
    );
  }

  // ---------- tab pesanan ----------

  Widget _ordersTab() {
    if (_ordersLoading && _orders.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.ink));
    }
    if (_ordersError != null && _orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_ordersError!,
                  textAlign: TextAlign.center, style: AppText.sans(color: AppColors.inkSoft, height: 1.5)),
              const SizedBox(height: 14),
              GradButton(label: 'Coba lagi', icon: Icons.refresh_rounded, onTap: _loadOrders),
            ],
          ),
        ),
      );
    }
    if (_orders.isEmpty) {
      return Center(child: Text('Belum ada pesanan.', style: AppText.sans(color: AppColors.inkSoft)));
    }
    return RefreshIndicator(
      color: AppColors.ink,
      backgroundColor: Colors.white,
      onRefresh: _loadOrders,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        itemCount: _orders.length,
        itemBuilder: (context, i) {
          final o = _orders[i];
          final cancelled = o.status == 'dibatalkan';
          final card = OrderCard(
            order: o,
            showUser: true,
            footer: cancelled
                ? null
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in ShopOrder.statuses)
                        if (s != o.status)
                          Pressable(
                            scale: 0.94,
                            onTap: () => _setOrderStatus(o, s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: statusColor(s),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '→ ${ShopOrder.statusLabel(s)}',
                                style: AppText.sans(size: 11.5, weight: FontWeight.w800),
                              ),
                            ),
                          ),
                    ],
                  ),
          );
          if (i >= 8) return card;
          return Reveal(key: ValueKey('admin-o-${o.id}'), delayMs: i * 60, child: card);
        },
      ),
    );
  }

  // ---------- tab pengguna ----------

  Widget _usersTab() {
    if (_usersLoading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.ink));
    }
    if (_usersError != null && _users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _usersError!,
                textAlign: TextAlign.center,
                style: AppText.sans(color: AppColors.inkSoft, height: 1.5),
              ),
              const SizedBox(height: 14),
              GradButton(label: 'Coba lagi', icon: Icons.refresh_rounded, onTap: _loadUsers),
            ],
          ),
        ),
      );
    }

    final me = context.read<AuthProvider>().user;
    return RefreshIndicator(
      color: AppColors.ink,
      backgroundColor: Colors.white,
      onRefresh: () async {
        await _loadUsers();
        await _loadStats();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        itemCount: _users.length,
        itemBuilder: (context, i) {
          final u = _users[i];
          final tone = AppColors.toneFor(u.id);
          final isMe = me?.id == u.id;
          final tile = Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: tone.bg, shape: BoxShape.circle),
                  child: Text(u.initial, style: AppText.serif(size: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMe ? '${u.name} (kamu)' : u.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(size: 13.5, weight: FontWeight.w800),
                      ),
                      Text(
                        u.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(size: 11.5, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: u.isAdmin ? AppColors.lavender : AppColors.mint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    u.isAdmin ? 'Admin' : 'User',
                    style: AppText.sans(size: 10.5, weight: FontWeight.w800),
                  ),
                ),
                if (!isMe)
                  PopupMenuButton<String>(
                    color: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    icon: const Icon(Icons.more_vert_rounded, color: AppColors.inkSoft),
                    onSelected: (v) {
                      if (v == 'role') _changeRole(u);
                      if (v == 'delete') _deleteUser(u);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'role',
                        child: Text(u.isAdmin ? 'Jadikan user biasa' : 'Jadikan admin'),
                      ),
                      const PopupMenuItem(value: 'delete', child: Text('Hapus akun')),
                    ],
                  )
                else
                  const SizedBox(width: 12),
              ],
            ),
          );
          if (i >= 8) return tile;
          return Reveal(key: ValueKey('admin-u-${u.id}'), delayMs: i * 60, child: tile);
        },
      ),
    );
  }
}
