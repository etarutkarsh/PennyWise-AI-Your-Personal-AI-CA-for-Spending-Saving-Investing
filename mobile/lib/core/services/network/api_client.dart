import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../constants/api_constants.dart';
import '../storage/token_storage.dart';

/// Thin wrapper around Dio: attaches the JWT bearer token to every request
/// and auto-refreshes using the 30-day refresh token when a 401 is received.
class ApiClient {
  ApiClient(this._tokenStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            try {
              final newAccess = await _refreshAccessToken();
              if (newAccess != null) {
                // Retry original request with the fresh token.
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccess';
                final response = await dio.fetch(opts);
                return handler.resolve(response);
              }
            } catch (_) {
              // Refresh failed — fall through and surface the original 401.
            }
          }
          handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(requestBody: true, responseBody: true, error: true),
      );
    }
  }

  final TokenStorage _tokenStorage;
  late final Dio dio;

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await _tokenStorage.refreshToken;
    if (refreshToken == null) return null;

    // Use a plain Dio (no interceptors) to avoid infinite retry loops.
    final plainDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
    final response = await plainDio.post(
      ApiConstants.authRefresh,
      data: {'refreshToken': refreshToken},
    );

    final newAccess = response.data['accessToken'] as String?;
    final newRefresh = response.data['refreshToken'] as String?;
    if (newAccess != null && newRefresh != null) {
      await _tokenStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      return newAccess;
    }
    return null;
  }
}
