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
      'userType': userType.toUpperCase(),
    });
    await _storage.saveTokens(
      accessToken: res.data['accessToken'] as String,
      refreshToken: res.data['refreshToken'] as String,
    );
  }

  /// Returns true if a saved access token exists (session may still be expired).
  Future<bool> hasSession() async {
    final token = await _storage.accessToken;
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _storage.clear();
  }
}
