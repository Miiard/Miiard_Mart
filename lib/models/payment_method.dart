// Mengimpor pustaka utama material design dari Flutter
import 'package:flutter/material.dart';

// Mengimpor file model alamat dari file 'address.dart'
import 'address.dart';

// Enum untuk mendefinisikan pilihan metode pembayaran yang tersedia (QRIS dan DANA)
enum PaymentMethod { qris, dana }

// Extension untuk menambahkan properti pendukung (getter) pada enum PaymentMethod
extension PaymentMethodX on PaymentMethod {
  
  // Getter untuk mendapatkan teks label atau nama metode pembayaran
  String get label => switch (this) {
        PaymentMethod.qris => 'QRIS',
        PaymentMethod.dana => 'DANA',
      };

  // Getter untuk mendapatkan teks deskripsi/subjudul dari metode pembayaran
  String get subtitle => switch (this) {
        PaymentMethod.qris => 'Scan dengan m-banking atau e-wallet apa pun',
        PaymentMethod.dana => 'Bayar lewat transfer ke akun DANA toko',
      };

  // Getter untuk menentukan ikon Material Design yang sesuai untuk setiap metode
  IconData get icon => switch (this) {
        PaymentMethod.qris => Icons.qr_code_2_rounded,
        PaymentMethod.dana => Icons.account_balance_wallet_rounded,
      };

  // Getter untuk menentukan warna latar belakang khusus untuk setiap metode pembayaran
  Color get color => switch (this) {
        PaymentMethod.qris => const Color(0xFFFBDDE7),
        PaymentMethod.dana => const Color(0xFFD4E7FF),
      };
}

/// Data yang dibawa dari layar Checkout ke layar Pembayaran.
// Kelas untuk membungkus data argumen yang dikirim dari halaman Checkout ke halaman Pembayaran
class PaymentArgs {
  final PaymentMethod method; // Menyimpan metode pembayaran yang dipilih
  final Address address;      // Menyimpan data alamat pengiriman
  final int itemCount;        // Menyimpan jumlah total item barang
  final int baseIdr; // total belanja dalam rupiah
  final int uniqueCode; // kode unik 3 digit untuk mencocokkan pembayaran

  // Konstruktor konstan dengan parameter wajib untuk menginisialisasi data
  const PaymentArgs({
    required this.method,
    required this.address,
    required this.itemCount,
    required this.baseIdr,
    required this.uniqueCode,
  });

  // Getter untuk menghitung total keseluruhan pembayaran (total belanja dasar + kode unik)
  int get totalIdr => baseIdr + uniqueCode;
}