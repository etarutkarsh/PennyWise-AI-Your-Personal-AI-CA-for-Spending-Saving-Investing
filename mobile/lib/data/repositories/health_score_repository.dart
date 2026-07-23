import '../../core/constants/api_constants.dart';
import '../../core/services/network/api_client.dart';

class HealthScoreModel {
  const HealthScoreModel({
    required this.score,
    required this.grade,
    required this.summary,
    required this.savingsScore,
    required this.budgetScore,
    required this.goalScore,
    required this.activityScore,
    required this.surplusScore,
  });

  final int score;
  final String grade;
  final String summary;
  final int savingsScore;
  final int budgetScore;
  final int goalScore;
  final int activityScore;
  final int surplusScore;

  factory HealthScoreModel.fromJson(Map<String, dynamic> json) =>
      HealthScoreModel(
        score: json['score'] as int? ?? 0,
        grade: json['grade'] as String? ?? 'Fair',
        summary: json['summary'] as String? ?? '',
        savingsScore: json['savingsScore'] as int? ?? 0,
        budgetScore: json['budgetScore'] as int? ?? 0,
        goalScore: json['goalScore'] as int? ?? 0,
        activityScore: json['activityScore'] as int? ?? 0,
        surplusScore: json['surplusScore'] as int? ?? 0,
      );
}

class HealthScoreRepository {
  const HealthScoreRepository(this._api);
  final ApiClient _api;

  Future<HealthScoreModel> get() async {
    final response = await _api.dio.get(ApiConstants.healthScore);
    return HealthScoreModel.fromJson(response.data as Map<String, dynamic>);
  }
}
