// Defines the 10-dimension HealthScore model for financial wellness assessment.

import 'package:flutter/foundation.dart';

import '../decision/explanation.dart';

/// Score trend for a health dimension relative to the previous snapshot.
enum ScoreTrend {
  up,
  down,
  stable,
  /// No historical data to compare against.
  unknown,
}

/// The ten dimensions of financial health tracked by the Health Engine.
enum HealthDimension {
  liquidity,
  debtQuality,
  savingsConsistency,
  goalFunding,
  insuranceCoverage,
  investmentDiversification,
  behavioralConsistency,
  incomeStability,
  financialAnxiety,
  taxEfficiency;

  String get label => switch (this) {
        HealthDimension.liquidity => 'Liquidity',
        HealthDimension.debtQuality => 'Debt Quality',
        HealthDimension.savingsConsistency => 'Savings Consistency',
        HealthDimension.goalFunding => 'Goal Funding',
        HealthDimension.insuranceCoverage => 'Insurance Coverage',
        HealthDimension.investmentDiversification => 'Investment Diversification',
        HealthDimension.behavioralConsistency => 'Behavioral Consistency',
        HealthDimension.incomeStability => 'Income Stability',
        HealthDimension.financialAnxiety => 'Financial Anxiety',
        HealthDimension.taxEfficiency => 'Tax Efficiency',
      };

  /// Design weight in the composite health score (must sum to 1.0).
  double get weight => switch (this) {
        HealthDimension.liquidity => 0.25,
        HealthDimension.debtQuality => 0.15,
        HealthDimension.savingsConsistency => 0.15,
        HealthDimension.goalFunding => 0.10,
        HealthDimension.insuranceCoverage => 0.10,
        HealthDimension.investmentDiversification => 0.10,
        HealthDimension.behavioralConsistency => 0.05,
        HealthDimension.incomeStability => 0.05,
        HealthDimension.financialAnxiety => 0.03,
        HealthDimension.taxEfficiency => 0.02,
      };
}

/// A score for one dimension of financial health with full explainability.
///
/// Following the user-facing design: score + evidence + trend + target + recommendation.
/// Every dimension that cannot be computed from available data should return
/// an honest insight about what data is missing rather than silently returning 0.
@immutable
class DimensionScore {
  final HealthDimension dimension;

  /// Score 0–100 for this dimension.
  final int score;

  /// Target score to reach for this dimension (0–100).
  final int target;

  /// Short qualitative label: "Excellent" / "Good" / "Fair" / "Poor" / "Unknown".
  final String label;

  /// What the data shows for this dimension.
  final String insight;

  /// Actionable next step for this dimension.
  final String recommendation;

  /// Score direction relative to the previous snapshot.
  final ScoreTrend trend;

  /// Evidence items that drove this dimension's score.
  final List<EvidenceItem> evidence;

  const DimensionScore({
    required this.dimension,
    required this.score,
    required this.label,
    required this.insight,
    required this.recommendation,
    this.target = 80,
    this.trend = ScoreTrend.unknown,
    this.evidence = const [],
  }) : assert(score >= 0 && score <= 100, 'DimensionScore must be 0–100'),
       assert(target >= 0 && target <= 100, 'target must be 0–100');

  int get gap => (target - score).clamp(0, 100);
  bool get meetsTarget => score >= target;

  DimensionScore copyWith({
    HealthDimension? dimension,
    int? score,
    int? target,
    String? label,
    String? insight,
    String? recommendation,
    ScoreTrend? trend,
    List<EvidenceItem>? evidence,
  }) =>
      DimensionScore(
        dimension: dimension ?? this.dimension,
        score: score ?? this.score,
        target: target ?? this.target,
        label: label ?? this.label,
        insight: insight ?? this.insight,
        recommendation: recommendation ?? this.recommendation,
        trend: trend ?? this.trend,
        evidence: evidence ?? this.evidence,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DimensionScore &&
          other.dimension == dimension &&
          other.score == score);

  @override
  int get hashCode => Object.hash(dimension, score);

  @override
  String toString() =>
      'DimensionScore(${dimension.label}: $score/$target, trend: $trend)';
}

/// Composite financial health score across all ten dimensions.
///
/// The score itself is just a number. The explainability lives in [dimensions],
/// [topActions], and [dataCompleteness]. Every consumer should surface the
/// dimension breakdown — not just the composite number.
@immutable
class HealthScore {
  /// Composite weighted score from 0 to 100.
  final int score;

  /// Per-dimension breakdown with evidence, trend, and recommendation.
  final Map<HealthDimension, DimensionScore> dimensions;

  final DateTime computedAt;
  final String engineVersion;

  /// Fraction [0.0–1.0] of the 10 dimensions computed from real data.
  /// 0.3 = only 3 of 10 have real evidence; affects [Confidence.score] downstream.
  final double dataCompleteness;

  /// Top 3 actions sorted by highest potential score improvement.
  final List<String> topActions;

  const HealthScore({
    required this.score,
    required this.dimensions,
    required this.computedAt,
    required this.engineVersion,
    this.dataCompleteness = 0.0,
    this.topActions = const [],
  }) : assert(score >= 0 && score <= 100, 'HealthScore must be 0–100'),
       assert(dataCompleteness >= 0.0 && dataCompleteness <= 1.0);

  /// Placeholder — used until the Health Engine is wired with real data.
  factory HealthScore.placeholder() => HealthScore(
        score: 82,
        dimensions: const {},
        computedAt: DateTime(2026, 1, 1),
        engineVersion: 'placeholder-hardcoded',
        dataCompleteness: 0.0,
      );

  bool get isPlaceholder => engineVersion == 'placeholder-hardcoded';
  bool get hasFullData => dataCompleteness >= 0.9;
  String get grade {
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B+';
    if (score >= 60) return 'B';
    if (score >= 50) return 'C';
    return 'D';
  }

  HealthScore copyWith({
    int? score,
    Map<HealthDimension, DimensionScore>? dimensions,
    DateTime? computedAt,
    String? engineVersion,
    double? dataCompleteness,
    List<String>? topActions,
  }) =>
      HealthScore(
        score: score ?? this.score,
        dimensions: dimensions ?? this.dimensions,
        computedAt: computedAt ?? this.computedAt,
        engineVersion: engineVersion ?? this.engineVersion,
        dataCompleteness: dataCompleteness ?? this.dataCompleteness,
        topActions: topActions ?? this.topActions,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthScore &&
          other.score == score &&
          other.engineVersion == engineVersion);

  @override
  int get hashCode => Object.hash(score, engineVersion, computedAt);

  @override
  String toString() =>
      'HealthScore(score: $score, grade: $grade, completeness: $dataCompleteness, '
      'version: $engineVersion)';
}
