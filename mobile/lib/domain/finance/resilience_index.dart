import 'package:flutter/foundation.dart';

/// Resilience Index — distinct from Health Score.
/// Answers: "If something bad happens tomorrow, how long can you survive?"
/// Composite of liquidity coverage, insurance coverage, and emergency fund depth.
/// Does not measure wealth accumulation — only shock absorption capacity.
@immutable
class ResilienceIndex {
  /// Composite resilience score (0–100).
  final int score;

  /// Human-readable label: 'Fragile', 'Vulnerable', 'Stable', 'Resilient', 'Fortified'.
  final String label;

  /// How many months the user can survive without income, based on:
  /// emergency fund + liquid savings / monthly expenses.
  final double canAbsorbMonths;

  /// Sub-dimension scores (0–100 each).
  final Map<ResilienceDimension, int> dimensions;

  /// Insight text for Financial Journal display.
  final String insight;

  final String engineVersion;
  final DateTime computedAt;

  const ResilienceIndex({
    required this.score,
    required this.label,
    required this.canAbsorbMonths,
    required this.dimensions,
    required this.insight,
    required this.engineVersion,
    required this.computedAt,
  });

  String get survivalLabel {
    if (canAbsorbMonths < 1) return 'Less than 1 month';
    if (canAbsorbMonths < 3) return '${canAbsorbMonths.toStringAsFixed(1)} months';
    return '${canAbsorbMonths.toStringAsFixed(0)} months';
  }

  @override
  String toString() =>
      'ResilienceIndex(score: $score, label: $label, absorb: $survivalLabel)';
}

enum ResilienceDimension {
  /// Cash + liquid savings / monthly burn rate.
  liquidityCoverage,

  /// Term life + health insurance adequacy.
  insuranceCoverage,

  /// Emergency fund vs 6-month target.
  emergencyFundDepth,
}

extension ResilienceDimensionExtension on ResilienceDimension {
  double get weight {
    switch (this) {
      case ResilienceDimension.emergencyFundDepth:
        return 0.50;
      case ResilienceDimension.liquidityCoverage:
        return 0.30;
      case ResilienceDimension.insuranceCoverage:
        return 0.20;
    }
  }

  String get label {
    switch (this) {
      case ResilienceDimension.emergencyFundDepth:
        return 'Emergency Fund';
      case ResilienceDimension.liquidityCoverage:
        return 'Liquidity Coverage';
      case ResilienceDimension.insuranceCoverage:
        return 'Insurance Coverage';
    }
  }
}
