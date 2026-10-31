// Kelas untuk merepresentasikan data alamat pengiriman pengguna
class Address {
  final String id;          // ID unik untuk mengidentifikasi setiap alamat
  final String label;       // Label alamat, contoh: Rumah / Kantor / Lainnya
  final String recipient;   // Nama penerima paket di alamat tersebut
  final String phone;       // Nomor telepon penerima yang dapat dihubungi
  final String street;      // Nama jalan, nomor rumah, atau detail lokasi
  final String city;        // Nama kota tempat pengiriman
  final String postalCode;  // Kode pos wilayah (opsional, default kosong)
  final String note;        // Catatan tambahan untuk kurir (opsional, default kosong)

  // Konstruktor konstan untuk menginisialisasi objek Address
  const Address({
    required this.id,
    required this.label,
    required this.recipient,
    required this.phone,
    required this.street,
    required this.city,
    this.postalCode = '',
    this.note = '',
  });

  // Getter untuk menggabungkan seluruh komponen alamat menjadi satu baris teks yang rapi dan lengkap
  String get fullLine =>
      '$street, $city${postalCode.isEmpty ? '' : ' $postalCode'}';
}