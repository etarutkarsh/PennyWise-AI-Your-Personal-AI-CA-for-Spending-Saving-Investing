import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;
    if (kIsWeb) return 'http://localhost:8080/api';
    // Android emulator maps 10.0.2.2 → host machine; iOS simulator uses localhost directly
    if (Platform.isIOS || Platform.isMacOS) return 'http://localhost:8080/api';
    return 'http://10.0.2.2:8080/api';
  }

  static const String auth = '/auth';
  static const String authRefresh = '/auth/refresh';
  static const String transactions = '/transactions';
  static const String categories = '/categories';
  static const String budgets = '/budgets';
  static const String goals = '/goals';
  static const String affordability = '/affordability';
  static const String healthScore = '/dashboard/health-score';
  static const String investments = '/investments';
  static const String chatHistory = '/ai/chat/history';
  static const String chat = '/ai/chat';

  static const String users = '/users';

  static const String accessTokenKey = 'pennywise_access_token';
  static const String refreshTokenKey = 'pennywise_refresh_token';
  static const String openAiKeyStorageKey = 'pennywise_openai_key';
}
