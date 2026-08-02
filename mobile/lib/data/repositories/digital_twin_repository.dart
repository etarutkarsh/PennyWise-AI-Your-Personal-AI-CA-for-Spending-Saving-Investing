import 'package:flutter/material.dart';
import '../../core/services/network/api_client.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class ProjectionPoint {
  final int monthsFromNow;
  final double netWorth;
  final double cumulativeSavings;

  const ProjectionPoint({
    required this.monthsFromNow,
    required this.netWorth,
    required this.cumulativeSavings,
  });

  factory ProjectionPoint.fromJson(Map<String, dynamic> json) {
    return ProjectionPoint(
      monthsFromNow: (json['monthsFromNow'] as num?)?.toInt() ?? 0,
      netWorth: (json['netWorth'] as num?)?.toDouble() ?? 0.0,
      cumulativeSavings: (json['cumulativeSavings'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GoalTrajectory {
  final String goalId;
  final String goalName;
  final double targetAmount;
  final double currentSaved;
  final String? deadline;
  final String? deadlineFormatted;
  final double completionProbability;
  final int monthsToCompletion;
  final bool onTrack;

  /// ON_TRACK | AT_RISK | OFF_TRACK | ACHIEVED
  final String status;

  const GoalTrajectory({
    required this.goalId,
    required this.goalName,
    required this.targetAmount,
    required this.currentSaved,
    this.deadline,
    this.deadlineFormatted,
    required this.completionProbability,
    required this.monthsToCompletion,
    required this.onTrack,
    required this.status,
  });

  factory GoalTrajectory.fromJson(Map<String, dynamic> json) {
    return GoalTrajectory(
      goalId: json['goalId']?.toString() ?? '',
      goalName: json['goalName']?.toString() ?? 'Goal',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentSaved: (json['currentSaved'] as num?)?.toDouble() ?? 0.0,
      deadline: json['deadline'] as String?,
      deadlineFormatted: json['deadlineFormatted'] as String?,
      completionProbability:
          (json['completionProbability'] as num?)?.toDouble() ?? 0.0,
      monthsToCompletion:
          (json['monthsToCompletion'] as num?)?.toInt() ?? 0,
      onTrack: (json['onTrack'] as bool?) ?? false,
      status: json['status']?.toString() ?? 'OFF_TRACK',
    );
  }

  Color get statusColor {
    switch (status) {
      case 'ON_TRACK':
        return const Color(0xFF22C55E);
      case 'AT_RISK':
        return const Color(0xFFFFB830);
      case 'ACHIEVED':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFEF4444);
    }
  }
}

class DigitalTwin {
  final int twinScore;
  final double? netWorth;
  final double? totalAssets;
  final double? totalLiabilities;
  final double? monthlyIncome;
  final double? monthlyExpenses;
  final double? monthlySurplus;
  final double? efCoverageMonths;
  final double? dtiRatio;
  final double? behaviorFactor;
  final double? projection12m;
  final double? projection3yr;
  final double? projection5yr;
  final double? projection10yr;
  final List<GoalTrajectory> goalTrajectories;
  final List<ProjectionPoint> projectionSeries;

  /// BASIC | GOOD | COMPLETE
  final String dataQuality;

  const DigitalTwin({
    required this.twinScore,
    this.netWorth,
    this.totalAssets,
    this.totalLiabilities,
    this.monthlyIncome,
    this.monthlyExpenses,
    this.monthlySurplus,
    this.efCoverageMonths,
    this.dtiRatio,
    this.behaviorFactor,
    this.projection12m,
    this.projection3yr,
    this.projection5yr,
    this.projection10yr,
    required this.goalTrajectories,
    required this.projectionSeries,
    required this.dataQuality,
  });

  factory DigitalTwin.fromJson(Map<String, dynamic> json) {
    final goals = (json['goalTrajectories'] as List?)
            ?.map((e) => GoalTrajectory.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final series = (json['projectionSeries'] as List?)
            ?.map((e) => ProjectionPoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return DigitalTwin(
      twinScore: (json['twinScore'] as num?)?.toInt() ?? 0,
      netWorth: (json['netWorth'] as num?)?.toDouble(),
      totalAssets: (json['totalAssets'] as num?)?.toDouble(),
      totalLiabilities: (json['totalLiabilities'] as num?)?.toDouble(),
      monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble(),
      monthlyExpenses: (json['monthlyExpenses'] as num?)?.toDouble(),
      monthlySurplus: (json['monthlySurplus'] as num?)?.toDouble(),
      efCoverageMonths: (json['efCoverageMonths'] as num?)?.toDouble(),
      dtiRatio: (json['dtiRatio'] as num?)?.toDouble(),
      behaviorFactor: (json['behaviorFactor'] as num?)?.toDouble(),
      projection12m: (json['projection12m'] as num?)?.toDouble(),
      projection3yr: (json['projection3yr'] as num?)?.toDouble(),
      projection5yr: (json['projection5yr'] as num?)?.toDouble(),
      projection10yr: (json['projection10yr'] as num?)?.toDouble(),
      goalTrajectories: goals,
      projectionSeries: series,
      dataQuality: json['dataQuality']?.toString() ?? 'BASIC',
    );
  }

  // ── Helper getters ────────────────────────────────────────────────────────

  String get twinScoreLabel {
    if (twinScore >= 80) return 'Complete';
    if (twinScore >= 50) return 'Building';
    return 'Starting';
  }

  Color get twinScoreColor {
    if (twinScore >= 80) return const Color(0xFF22C55E);
    if (twinScore >= 50) return const Color(0xFFFFB830);
    return const Color(0xFF4A4F62);
  }

  String get netWorthFormatted {
    final nw = netWorth ?? 0;
    final abs = nw.abs();
    final prefix = nw < 0 ? '-' : '';
    if (abs >= 10000000) return '${prefix}₹${(abs / 10000000).toStringAsFixed(1)}Cr';
    if (abs >= 100000)   return '${prefix}₹${(abs / 100000).toStringAsFixed(1)}L';
    if (abs >= 1000)     return '${prefix}₹${(abs / 1000).toStringAsFixed(1)}K';
    return '${prefix}₹${abs.toStringAsFixed(0)}';
  }

  bool get isNetWorthPositive => (netWorth ?? 0) >= 0;

  String get efLabel {
    if (efCoverageMonths == null) return '–';
    return '${efCoverageMonths!.toStringAsFixed(1)}mo';
  }

  String get dtiLabel {
    if (dtiRatio == null) return '–';
    return '${(dtiRatio! * 100).toStringAsFixed(0)}%';
  }

  String _formatAmount(double? value) {
    if (value == null) return '–';
    final abs = value.abs();
    final prefix = value < 0 ? '-' : '';
    if (abs >= 10000000) return '${prefix}₹${(abs / 10000000).toStringAsFixed(1)}Cr';
    if (abs >= 100000)   return '${prefix}₹${(abs / 100000).toStringAsFixed(1)}L';
    if (abs >= 1000)     return '${prefix}₹${(abs / 1000).toStringAsFixed(1)}K';
    return '${prefix}₹${abs.toStringAsFixed(0)}';
  }

  String get projection12mFormatted  => _formatAmount(projection12m);
  String get projection3yrFormatted  => _formatAmount(projection3yr);
  String get projection5yrFormatted  => _formatAmount(projection5yr);
  String get projection10yrFormatted => _formatAmount(projection10yr);
  String get assetsFormatted         => _formatAmount(totalAssets);
  String get liabilitiesFormatted    => _formatAmount(totalLiabilities);
  String get surplusFormatted        => _formatAmount(monthlySurplus);
}

// ─── Repository ───────────────────────────────────────────────────────────────

class DigitalTwinRepository {
  DigitalTwinRepository(this._client);
  final ApiClient _client;

  Future<DigitalTwin> getTwin() async {
    final res = await _client.dio.get('/twin');
    return DigitalTwin.fromJson(res.data as Map<String, dynamic>);
  }

  Future<DigitalTwin> refresh() async {
    final res = await _client.dio.post('/twin/refresh');
    return DigitalTwin.fromJson(res.data as Map<String, dynamic>);
  }
}
