/// Alamat server API Miiard.Mart (PHP di Docker milikmu).
///
/// Format: http://ALAMAT:PORT
///   - PORT = angka kiri pada `ports:` service web/Caddy di docker-compose.yml
///            (contoh "8080:80" berarti PORT = 8080)
///   - Emulator Android : 10.0.2.2  (bawaan di bawah)
///   - HP asli (satu Wi-Fi dengan laptop): IP laptop, contoh 192.168.1.10
///
/// Cara mengganti tanpa mengedit kode:
///   flutter run --dart-define=API_URL=http://192.168.1.10:8080
class ApiConfig {
  static const String backendUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// Cadangan baca-saja bila server sendiri belum menyala.
  static const String dummyUrl = 'https://dummyjson.com';
}
