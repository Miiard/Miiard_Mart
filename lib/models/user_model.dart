import '../config/api_config.dart';

class AppUser {
  final int id;
  final String name;
  final String email;
  final String role; // 'user' atau 'admin'
  final String? avatarUrl; // path dari server, mis. /users/3/avatar?v=2

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  /// Alamat lengkap foto profil (null bila belum punya foto).
  String? get avatarFullUrl => avatarUrl == null ? null : '${ApiConfig.backendUrl}$avatarUrl';

  bool get isAdmin => role == 'admin';

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'teman' : parts.first;
  }

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: j['role'] as String? ?? 'user',
        avatarUrl: j['avatarUrl'] as String?,
      );
}

class AdminStats {
  final int users;
  final int admins;
  final int products;
  final int outOfStock;
  final int lowStock;

  const AdminStats({
    this.users = 0,
    this.admins = 0,
    this.products = 0,
    this.outOfStock = 0,
    this.lowStock = 0,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        users: (j['users'] as num?)?.toInt() ?? 0,
        admins: (j['admins'] as num?)?.toInt() ?? 0,
        products: (j['products'] as num?)?.toInt() ?? 0,
        outOfStock: (j['outOfStock'] as num?)?.toInt() ?? 0,
        lowStock: (j['lowStock'] as num?)?.toInt() ?? 0,
      );
}
