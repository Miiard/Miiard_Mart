// Mengimpor pustaka dasar Flutter untuk mendeteksi perubahan state (ChangeNotifier)
import 'package:flutter/foundation.dart';

// Mengimpor model data alamat pengiriman
import '../models/address.dart';
// Mengimpor model data metode pembayaran
import '../models/payment_method.dart';

/// Alamat pengiriman dan metode pembayaran yang dipilih saat checkout.
// Kelas state management CheckoutProvider untuk mengelola data alamat dan metode pembayaran saat proses checkout
class CheckoutProvider extends ChangeNotifier {
  final List<Address> _addresses = []; // List privat untuk menyimpan daftar alamat pengiriman
  String? _selectedId;                 // Menyimpan ID alamat yang sedang dipilih (nullable)
  PaymentMethod? _method;              // Menyimpan metode pembayaran yang sedang dipilih (nullable)

  // Getter publik untuk mengambil daftar alamat yang tidak bisa diubah langsung dari luar
  List<Address> get addresses => List.unmodifiable(_addresses);
  // Getter publik untuk mengambil metode pembayaran yang dipilih
  PaymentMethod? get method => _method;
  // Getter publik untuk mengambil ID alamat yang dipilih
  String? get selectedId => _selectedId;

  // Getter untuk mengembalikan objek Address lengkap yang sedang dipilih berdasarkan ID-nya
  Address? get selectedAddress {
    for (final a in _addresses) {
      if (a.id == _selectedId) return a;
    }
    return null;
  }

  // Fungsi untuk memilih alamat pengiriman berdasarkan ID
  void selectAddress(String id) {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners(); // Beritahu UI bahwa alamat yang dipilih telah berubah
  }

  // Fungsi untuk menambahkan alamat baru ke daftar dan otomatis memilihnya
  void addAddress(Address a) {
    _addresses.insert(0, a); // Masukkan alamat baru di urutan paling atas (index 0)
    _selectedId = a.id;      // Otomatis jadikan alamat yang baru ditambahkan sebagai pilihan aktif
    notifyListeners();
  }

  // Fungsi untuk menghapus alamat berdasarkan ID
  void removeAddress(String id) {
    _addresses.removeWhere((a) => a.id == id);
    // Jika alamat yang dihapus adalah alamat yang sedang aktif dipilih,
    // pindahkan pilihan ke alamat pertama (jika masih ada), atau set null jika kosong.
    if (_selectedId == id) {
      _selectedId = _addresses.isEmpty ? null : _addresses.first.id;
    }
    notifyListeners();
  }

  // Fungsi untuk memilih metode pembayaran
  void selectMethod(PaymentMethod m) {
    if (_method == m) return;
    _method = m;
    notifyListeners(); // Beritahu UI bahwa metode pembayaran telah berubah
  }
}