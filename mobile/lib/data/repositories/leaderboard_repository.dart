import '../models/leaderboard_model.dart';
import '../../core/services/network/api_client.dart';

class LeaderboardRepository {
  LeaderboardRepository(this._client);

  final ApiClient _client;

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final res = await _client.dio.get('/leaderboard');
    return (res.data as List)
        .map((j) => LeaderboardEntry.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
