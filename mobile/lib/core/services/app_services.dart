import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ai_service.dart';
import 'network/api_client.dart';
import 'storage/token_storage.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/affordability_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/health_score_repository.dart';
import '../../data/repositories/investment_repository.dart';

/// Global service locator. Call [AppServices.init()] in main() before runApp.
/// Access everywhere via [AppServices.instance].
class AppServices {
  AppServices._();
  static final AppServices instance = AppServices._();

  late final TokenStorage tokenStorage;
  late final ApiClient apiClient;
  late final AuthRepository auth;
  late final TransactionRepository transactions;
  late final GoalRepository goals;
  late final BudgetRepository budgets;
  late final AffordabilityRepository affordability;
  late final CategoryRepository categories;
  late final HealthScoreRepository healthScore;
  late final InvestmentRepository investments;
  late final AiService ai;

  Future<void> init() async {
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    tokenStorage = TokenStorage(secureStorage);
    apiClient = ApiClient(tokenStorage);
    auth = AuthRepository(apiClient, tokenStorage);
    transactions = TransactionRepository(apiClient);
    goals = GoalRepository(apiClient);
    budgets = BudgetRepository(apiClient);
    affordability = AffordabilityRepository(apiClient);
    categories = CategoryRepository(apiClient);
    healthScore = HealthScoreRepository(apiClient);
    investments = InvestmentRepository(apiClient);
    ai = AiService(secureStorage);
  }
}

/// Helper — extracts a user-readable message from a DioException or any error.
String friendlyError(Object error) {
  // ignore: avoid_dynamic_calls
  try {
    final dynamic e = error;
    final dynamic resp = e.response;
    if (resp != null) {
      final dynamic data = resp.data;
      if (data is Map && data['message'] != null) {
        return data['message'] as String;
      }
      if (resp.statusCode == 401) return 'Invalid email or password.';
      if (resp.statusCode == 409) return 'An account with this email already exists.';
      if (resp.statusCode == 404) return 'Resource not found.';
      if (resp.statusCode != null && resp.statusCode! >= 500) {
        return 'Server error — please try again later.';
      }
    }
  } catch (_) {}
  return 'Something went wrong. Check your connection and try again.';
}
