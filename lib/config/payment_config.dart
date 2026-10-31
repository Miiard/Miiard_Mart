/// Pengaturan pembayaran toko. Ubah nilai di sini sesuai akunmu.
class PaymentConfig {
  static const merchantName = 'MIIARD.MART';

  /// GANTI dengan nomor DANA yang menerima pembayaran.
  static const danaNumber = '08xxxxxxxxxx';

  /// GANTI dengan nama yang terdaftar di akun DANA tersebut.
  static const danaAccountName = 'Nama Pemilik DANA';

  /// Harga produk dummyjson dalam dolar; dikonversi ke rupiah dengan kurs ini.
  static const usdToIdr = 16000;

  /// Batas waktu pembayaran sejak halaman pembayaran dibuka.
  static const paymentWindow = Duration(minutes: 15);

  /// Aset gambar QRIS toko.
  static const qrisAsset = 'assets/images/qris.png';
}
