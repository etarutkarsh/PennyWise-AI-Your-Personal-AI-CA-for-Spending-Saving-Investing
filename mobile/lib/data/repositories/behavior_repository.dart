import '../../core/services/network/api_client.dart';

class BehaviorProfile {
  final String? discipline;
  final String? impulseControl;
  final String? goalCommitment;
  final String? savingsConsistency;
  final String? riskBehavior;
  final String? primaryBehavior;
  final String? secondaryBehavior;
  final int followRate;
  final int disciplineScore;
  final List<String> insights;
  final List<String> detectedPatterns;
  final int eventsAnalyzed;
  final int decisionsAnalyzed;
  final int monthsOfData;
  final String dataConfidence;

  const BehaviorProfile({
    this.discipline,
    this.impulseControl,
    this.goalCommitment,
    this.savingsConsistency,
    this.riskBehavior,
    this.primaryBehavior,
    this.secondaryBehavior,
    required this.followRate,
    required this.disciplineScore,
    required this.insights,
    required this.detectedPatterns,
    required this.eventsAnalyzed,
    required this.decisionsAnalyzed,
    required this.monthsOfData,
    required this.dataConfidence,
  });

  factory BehaviorProfile.fromJson(Map<String, dynamic> json) {
    return BehaviorProfile(
      discipline: json['discipline'] as String?,
      impulseControl: json['impulseControl'] as String?,
      goalCommitment: json['goalCommitment'] as String?,
      savingsConsistency: json['savingsConsistency'] as String?,
      riskBehavior: json['riskBehavior'] as String?,
      primaryBehavior: json['primaryBehavior'] as String?,
      secondaryBehavior: json['secondaryBehavior'] as String?,
      followRate: (json['followRate'] as num?)?.toInt() ?? 0,
      disciplineScore: (json['disciplineScore'] as num?)?.toInt() ?? 50,
      insights: (json['insights'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      detectedPatterns: (json['detectedPatterns'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      eventsAnalyzed: (json['eventsAnalyzed'] as num?)?.toInt() ?? 0,
      decisionsAnalyzed: (json['decisionsAnalyzed'] as num?)?.toInt() ?? 0,
      monthsOfData: (json['monthsOfData'] as num?)?.toInt() ?? 0,
      dataConfidence: json['dataConfidence'] as String? ?? 'LOW',
    );
  }

  bool get hasEnoughData => eventsAnalyzed >= 5 || decisionsAnalyzed >= 2;
}

class BehaviorRepository {
  BehaviorRepository(this._client);
  final ApiClient _client;

  Future<BehaviorProfile> getProfile() async {
    final res = await _client.dio.get('/behavior');
    return BehaviorProfile.fromJson(res.data as Map<String, dynamic>);
  }
}
