import '../../core/services/network/api_client.dart';
import '../../features/decisions/domain/entities/decision_memory_entity.dart';

class DecisionMemoryRepository {
  DecisionMemoryRepository(this._client);

  final ApiClient _client;

  /// GET /decision-memory/timeline — ordered list of all past decisions.
  Future<List<DecisionMemoryEntry>> timeline() async {
    final res = await _client.dio.get('/decision-memory/timeline');
    return (res.data as List<dynamic>)
        .map(
          (j) => DecisionMemoryEntry.fromTimelineJson(
            j as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// GET /decision-memory/insights — aggregate stats + observations.
  Future<DecisionInsights> insights() async {
    final res = await _client.dio.get('/decision-memory/insights');
    return DecisionInsights.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST /decision-memory/{id}/review — submit outcome review.
  ///
  /// [id] — UUID of the decision memory entry.
  /// [followed] — whether the user followed the recommendation.
  /// [currentHealthScore] — user's self-reported health score today (0–100).
  Future<DecisionMemoryEntry> submitReview(
    String id,
    bool followed,
    int currentHealthScore,
  ) async {
    final res = await _client.dio.post(
      '/decision-memory/$id/review',
      data: {
        'followedRecommendation': followed,
        'currentHealthScore': currentHealthScore,
      },
    );
    return DecisionMemoryEntry.fromJson(res.data as Map<String, dynamic>);
  }
}
