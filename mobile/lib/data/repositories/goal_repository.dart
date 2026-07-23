import '../../core/services/network/api_client.dart';
import '../../features/goals/domain/entities/goal_entity.dart';

class GoalRepository {
  GoalRepository(this._client);

  final ApiClient _client;

  Future<List<GoalEntity>> getAll() async {
    final res = await _client.dio.get('/goals');
    return (res.data as List)
        .map((j) => GoalEntity.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<GoalEntity> create({
    required String name,
    required String goalType,
    required double targetAmount,
    required DateTime deadline,
    String priority = 'MEDIUM',
  }) async {
    final res = await _client.dio.post('/goals', data: {
      'name': name,
      'goalType': goalType.toUpperCase(),
      'targetAmount': targetAmount,
      'deadline': '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}',
      'priority': priority,
    });
    return GoalEntity.fromJson(res.data as Map<String, dynamic>);
  }

  Future<GoalEntity> updateSavedAmount(String id, double amount) async {
    final res = await _client.dio.patch('/goals/$id/saved-amount', data: {
      'amount': amount,
    });
    return GoalEntity.fromJson(res.data as Map<String, dynamic>);
  }
}
