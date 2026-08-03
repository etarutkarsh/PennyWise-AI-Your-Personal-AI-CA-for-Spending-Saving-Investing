import '../../core/services/network/api_client.dart';
import '../../features/decisions/data/models/today_decision_model.dart';

class TodayDecisionRepository {
  const TodayDecisionRepository(this._api);
  final ApiClient _api;

  Future<TodayDecisionModel> getToday() async {
    final response = await _api.dio.get('/decisions/today');
    return TodayDecisionModel.fromJson(response.data as Map<String, dynamic>);
  }
}
