import 'dart:convert';

import '../../core/services/network/api_client.dart';
import '../../core/services/storage/token_storage.dart';

class AuthRepository {
  AuthRepository(this._client, this._storage);

  final ApiClient _client;
  final TokenStorage _storage;

  Future<void> login(String email, String password) async {
    final res = await _client.dio.post('/auth/login', data: {
      'email': email.trim(),
      'password': password.trim(),
    });
    await _storage.saveTokens(
      accessToken: res.data['accessToken'] as String,
      refreshToken: res.data['refreshToken'] as String,
    );
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String userType,
  }) async {
    final res = await _client.dio.post('/auth/register', data: {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'password': password.trim(),
      'userType': userType,
    });
    await _storage.saveTokens(
      accessToken: res.data['accessToken'] as String,
      refreshToken: res.data['refreshToken'] as String,
    );
  }

  /// Returns true if a saved, non-expired access token exists.
  Future<bool> hasSession() async {
    final token = await _storage.accessToken;
    if (token == null || token.isEmpty) return false;
    return !_isTokenExpired(token);
  }

  /// Decodes the JWT payload and checks the [exp] claim without a library.
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = json.decode(decoded) as Map<String, dynamic>;
      final exp = map['exp'] as int?;
      if (exp == null) return true;
      return DateTime.now().isAfter(
        DateTime.fromMillisecondsSinceEpoch(exp * 1000),
      );
    } catch (_) {
      return true;
    }
  }

  /// Sends a 6-digit OTP to the phone number (must include +91 prefix).
  /// Returns `devOtp` string in dev-mode (no SMS key configured), null in production.
  Future<String?> sendOtp(String phone) async {
    final res = await _client.dio.post('/auth/send-otp', data: {'phone': phone});
    return res.data['devOtp'] as String?;
  }

  /// Verifies OTP and stores JWT tokens on success.
  Future<void> verifyOtp(String phone, String otp) async {
    final res = await _client.dio.post('/auth/verify-otp', data: {
      'phone': phone,
      'otp': otp,
    });
    await _storage.saveTokens(
      accessToken: res.data['accessToken'] as String,
      refreshToken: res.data['refreshToken'] as String,
    );
  }

  Future<void> logout() async {
    await _storage.clear();
  }
}
