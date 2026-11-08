final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

String? validateName(String? v) {
  final s = (v ?? '').trim();
  if (s.length < 2) return 'Nama minimal 2 karakter';
  if (s.length > 100) return 'Nama terlalu panjang';
  return null;
}

String? validateEmail(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Email wajib diisi';
  if (!_email.hasMatch(s)) return 'Format email tidak valid';
  return null;
}

String? validatePassword(String? v) {
  final s = v ?? '';
  if (s.length < 6) return 'Minimal 6 karakter';
  if (s.length > 72) return 'Maksimal 72 karakter';
  if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) {
    return 'Harus mengandung huruf dan angka';
  }
  return null;
}
