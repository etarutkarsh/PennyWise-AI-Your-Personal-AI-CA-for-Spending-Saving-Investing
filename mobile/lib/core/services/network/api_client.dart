import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../constants/api_constants.dart';
import '../storage/token_storage.dart';

/// Thin wrapper around Dio: attaches the JWT bearer token to every request
/// and centralizes base URL / interceptor configuration.
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
        onError: (error, handler) {
          // TODO: on 401, attempt a refresh-token flow before propagating the error.
          handler.next(error);
        },
      ),
    );

    dio.interceptors.add(
      PrettyDioLogger(requestBody: true, responseBody: true, error: true),
    );
  }

  final TokenStorage _tokenStorage;
  late final Dio dio;
}
