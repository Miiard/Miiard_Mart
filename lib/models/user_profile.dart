// Kelas untuk merepresentasikan data profil pengguna
class UserProfile {
  final String name;      // Menyimpan nama lengkap pengguna
  final String firstName; // Menyimpan nama depan pengguna
  final String email;     // Menyimpan alamat email pengguna

  // Konstruktor konstan untuk menginisialisasi data wajib profil pengguna
  const UserProfile({
    required this.name,
    required this.firstName,
    required this.email,
  });
}

/// Pengguna contoh (sama seperti prototipe HTML).
// Membuat objek konstanta global 'kUser' berisi data sampel untuk keperluan uji coba atau tampilan awal aplikasi
const kUser = UserProfile(
  name: 'Nazhmi Putra Ardiyan',
  firstName: 'Nazhmi',
  email: 'nazhmi@miiardmart.com',
);