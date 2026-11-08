import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/http_client.dart';

/// Hasil permintaan kode reset.
class ResetRequest {
  final String? error;
  final String? devCode; // hanya ada bila server dalam mode pengembangan
  const ResetRequest({this.error, this.devCode});
  bool get ok => error == null;
}

class AuthProvider extends ChangeNotifier {
  static const _tokenKey = 'auth_token';

  final AuthService _service = AuthService();
  AppUser? _user;
  bool _ready = false;
  Future<void>? _restoring;

  AppUser? get user => _user;
  bool get ready => _ready;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  /// Memulihkan sesi dari token tersimpan. Aman dipanggil berkali-kali.
  Future<void> restore() => _restoring ??= _restore();

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token != null) {
        TokenStore.token = token;
        try {
          _user = await _service.me();
        } on ApiException catch (e) {
          TokenStore.token = null;
          if (e.status == 401) await prefs.remove(_tokenKey); // token kedaluwarsa
        }
      }
    } catch (_) {
      TokenStore.token = null;
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _saveSession(AuthResult r) async {
    TokenStore.token = r.token;
    _user = r.user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, r.token);
    } catch (_) {
      // gagal menyimpan token hanya berarti harus login lagi saat aplikasi dibuka ulang
    }
    notifyListeners(); // router otomatis memindahkan ke beranda
  }

  /// Mengembalikan pesan error, atau null bila berhasil.
  Future<String?> login(String email, String password) async {
    try {
      await _saveSession(await _service.login(email.trim(), password));
      return null;
    } catch (e) {
      return ApiException.from(e).message;
    }
  }

  Future<String?> register(String name, String email, String password) async {
    try {
      await _saveSession(await _service.register(name.trim(), email.trim(), password));
      return null;
    } catch (e) {
      return ApiException.from(e).message;
    }
  }

  Future<ResetRequest> requestReset(String email) async {
    try {
      final code = await _service.forgot(email.trim());
      return ResetRequest(devCode: code);
    } catch (e) {
      return ResetRequest(error: ApiException.from(e).message);
    }
  }

  Future<String?> resetPassword(String email, String code, String newPassword) async {
    try {
      await _service.reset(email.trim(), code.trim(), newPassword);
      return null;
    } catch (e) {
      return ApiException.from(e).message;
    }
  }

  /// Mengganti foto profil. Mengembalikan pesan error, atau null bila berhasil.
  Future<String?> changeAvatar(Uint8List bytes) async {
    try {
      _user = await _service.setAvatar(base64Encode(bytes));
      notifyListeners();
      return null;
    } catch (e) {
      return ApiException.from(e).message;
    }
  }

  Future<String?> removeAvatar() async {
    try {
      _user = await _service.removeAvatar();
      notifyListeners();
      return null;
    } catch (e) {
      return ApiException.from(e).message;
    }
  }

  Future<void> logout() async {
    TokenStore.token = null;
    _user = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (_) {}
    notifyListeners();
  }
}
