// Defines the 10-dimension HealthScore model for financial wellness assessment.

import 'package:flutter/foundation.dart';

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
  taxEfficiency,
}

/// A score for one dimension of financial health.
@immutable
class DimensionScore {
  final HealthDimension dimension;

  /// Composite score from 0 to 100.
  final int score;

  /// Short label such as "Good" or "Needs work".
  final String label;

  /// One-line actionable insight for this dimension.
  final String insight;

  const DimensionScore({
    required this.dimension,
    required this.score,
    required this.label,
    required this.insight,
  }) : assert(score >= 0 && score <= 100, 'DimensionScore must be 0–100');

  DimensionScore copyWith({
    HealthDimension? dimension,
    int? score,
    String? label,
    String? insight,
  }) =>
      DimensionScore(
        dimension: dimension ?? this.dimension,
        score: score ?? this.score,
        label: label ?? this.label,
        insight: insight ?? this.insight,
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
  String toString() => 'DimensionScore(dimension: $dimension, score: $score, label: $label)';
}

/// Composite financial health score across all ten dimensions.
@immutable
class HealthScore {
  /// Composite score from 0 to 100.
  final int score;

  /// Per-dimension breakdown.
  final Map<HealthDimension, DimensionScore> dimensions;

  final DateTime computedAt;
  final String engineVersion;

  const HealthScore({
    required this.score,
    required this.dimensions,
    required this.computedAt,
    required this.engineVersion,
  }) : assert(score >= 0 && score <= 100, 'HealthScore must be 0–100');

  /// Returns a placeholder score of 82 — used until Health Engine V2 is built.
  factory HealthScore.placeholder() => HealthScore(
        score: 82,
        dimensions: const {},
        computedAt: DateTime(2026, 1, 1),
        engineVersion: 'placeholder-hardcoded',
      );

  bool get isPlaceholder => engineVersion == 'placeholder-hardcoded';

  HealthScore copyWith({
    int? score,
    Map<HealthDimension, DimensionScore>? dimensions,
    DateTime? computedAt,
    String? engineVersion,
  }) =>
      HealthScore(
        score: score ?? this.score,
        dimensions: dimensions ?? this.dimensions,
        computedAt: computedAt ?? this.computedAt,
        engineVersion: engineVersion ?? this.engineVersion,
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
  String toString() => 'HealthScore(score: $score, version: $engineVersion)';
}
