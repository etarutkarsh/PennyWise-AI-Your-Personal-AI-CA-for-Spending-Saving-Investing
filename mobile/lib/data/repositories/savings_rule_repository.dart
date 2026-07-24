import '../models/savings_rule_model.dart';
import '../../core/services/network/api_client.dart';

class SavingsRuleRepository {
  SavingsRuleRepository(this._client);

  final ApiClient _client;

  Future<List<SavingsRuleModel>> getAll() async {
    final res = await _client.dio.get('/savings-rules');
    return (res.data as List)
        .map((j) => SavingsRuleModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<SavingsRuleModel> create({
    required String triggerType,
    String? categoryId,
    required Map<String, dynamic> config,
  }) async {
    final res = await _client.dio.post('/savings-rules', data: {
      'triggerType': triggerType,
      if (categoryId != null) 'categoryId': categoryId,
      'config': config,
    });
    return SavingsRuleModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SavingsRuleModel> toggleActive(String id) async {
    final res = await _client.dio.patch('/savings-rules/$id/toggle');
    return SavingsRuleModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.dio.delete('/savings-rules/$id');
  }
}
