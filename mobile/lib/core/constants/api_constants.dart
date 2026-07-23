/// Central place for backend endpoint configuration.
/// Point [baseUrl] at your local Spring Boot instance during development
/// (see backend/src/main/resources/application.yml for the port/context-path).
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api',
  );

  static const String auth = '/auth';
  static const String transactions = '/transactions';
  static const String categories = '/categories';
  static const String budgets = '/budgets';
  static const String goals = '/goals';
  static const String affordability = '/affordability';
  static const String healthScore = '/dashboard/health-score';

  static const String accessTokenKey = 'pennywise_access_token';
  static const String refreshTokenKey = 'pennywise_refresh_token';
  static const String openAiKeyStorageKey = 'pennywise_openai_key';
}
