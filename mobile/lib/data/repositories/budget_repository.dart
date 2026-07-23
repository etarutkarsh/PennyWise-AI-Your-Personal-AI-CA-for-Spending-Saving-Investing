import '../../core/services/network/api_client.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  BudgetRepository(this._client);

  final ApiClient _client;

  Future<List<BudgetModel>> getCurrentPeriod() async {
    final res = await _client.dio.get('/budgets');
    return (res.data as List)
        .map((j) => BudgetModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<BudgetModel> create({
    required String categoryId,
    required double monthlyLimit,
  }) async {
    final res = await _client.dio.post('/budgets', data: {
      'categoryId': categoryId,
      'monthlyLimit': monthlyLimit,
    });
    return BudgetModel.fromJson(res.data as Map<String, dynamic>);
  }
}
