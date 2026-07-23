import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../constants/api_constants.dart';

/// Wraps the platform Keychain (iOS) / Keystore (Android) for JWT storage,
/// per Section 18 - Security ("Secure token storage using Keychain/Keystore").
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: ApiConstants.accessTokenKey, value: accessToken);
    await _storage.write(key: ApiConstants.refreshTokenKey, value: refreshToken);
  }

  Future<String?> get accessToken => _storage.read(key: ApiConstants.accessTokenKey);

  Future<String?> get refreshToken => _storage.read(key: ApiConstants.refreshTokenKey);

  Future<void> clear() async {
    await _storage.delete(key: ApiConstants.accessTokenKey);
    await _storage.delete(key: ApiConstants.refreshTokenKey);
  }
}
