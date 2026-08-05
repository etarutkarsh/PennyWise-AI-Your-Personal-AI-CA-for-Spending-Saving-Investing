import 'package:flutter/foundation.dart';

import 'decision_axis.dart';
import 'recommendation_strength.dart';

/// The canonical confidence report for any financial recommendation.
///
/// Captures the CTO compound formula:
///   compoundConfidence = dataConfidence × decisionConfidence
///                        × behaviorConfidence × historicalAccuracy
///
/// This is SEPARATE from [DataConfidenceReport]:
/// - DataConfidenceReport: "How good is the raw input data?"
/// - DecisionConfidenceReport: "How good is the reasoning about the decision?"
///
/// Both must be high for a high-confidence recommendation.
/// Example: excellent data (0.85) + risky decision logic (0.45) = moderate (0.38).
///
/// Produced by [FinancialReasoningEngine].
/// Consumed by: Dashboard, Affordability screen, Digital Twin, Explanation panel.
@immutable
class DecisionConfidenceReport {
  const DecisionConfidenceReport({
    required this.axes,
    required this.dataConfidenceFactor,
    required this.decisionConfidenceFactor,
    required this.behaviorConfidenceFactor,
    required this.historicalAccuracyFactor,
    required this.compoundConfidence,
    required this.strength,
    required this.topFactors,
    required this.limitations,
    required this.computedAt,
  });

  /// Full per-axis evaluation. All 8 axes are always present.
  final Map<DecisionAxis, DecisionAxisResult> axes;

  /// Factor 1 — data quality cap from [DataConfidenceReport.recommendationConfidenceCap].
  /// Range: 0.10 (no sources connected) → 1.0 (full AA + SMS coverage).
  final double dataConfidenceFactor;

  /// Factor 2 — weighted average of the 6 decision axes.
  /// Range: 0.0 → 1.0. Reflects the financial health across cash flow, liquidity,
  /// goals, behavior, taxes, and opportunity cost.
  final double decisionConfidenceFactor;

  /// Factor 3 — from [BehaviorInterpretation.overallConfidence].
  /// Range: 0.05 (uncalibrated new user) → 1.0 (well-calibrated).
  /// Floor: 0.50 when behavioral engine has never been run.
  final double behaviorConfidenceFactor;

  /// Factor 4 — from [LearningSnapshot.maturity].
  /// Range: 0.50 (neutral prior, no history) → 1.0 (excellent track record).
  /// Floor: 0.50 since "no decision history" ≠ "bad recommendation track record".
  final double historicalAccuracyFactor;

  /// The compound: dataConf × decisionConf × behaviorConf × historicalAcc.
  /// Typically 0.00–0.45. High value requires all four factors to be strong.
  final double compoundConfidence;

  /// Qualitative strength derived from [compoundConfidence].
  final RecommendationStrength strength;

  /// Top factors (positive or constraining) that shaped this report.
  /// Shown in the "Why this confidence?" panel.
  final List<String> topFactors;

  /// Why this confidence is limited — data gaps, uncalibrated behavior, etc.
  final List<String> limitations;

  final DateTime computedAt;

  // ─── Convenience accessors ─────────────────────────────────────────────────

  DecisionAxisResult? axisResult(DecisionAxis axis) => axes[axis];

  List<DecisionAxisResult> get decisionAxes => axes.entries
      .where((e) => e.key.isDecisionAxis)
      .map((e) => e.value)
      .toList();

  /// True when all four compound factors are meaningful (≥ 0.50).
  bool get isWellCalibrated =>
      dataConfidenceFactor >= 0.50 &&
      decisionConfidenceFactor >= 0.50 &&
      behaviorConfidenceFactor >= 0.50 &&
      historicalAccuracyFactor >= 0.50;

  String get strengthLabel => strength.label;
  String get strengthDescription => strength.userLabel;

  /// The weakest of the four factors — the primary bottleneck.
  String get bottleneckLabel {
    final factors = {
      'Data Quality': dataConfidenceFactor,
      'Decision Analysis': decisionConfidenceFactor,
      'Behavioral Calibration': behaviorConfidenceFactor,
      'Recommendation History': historicalAccuracyFactor,
    };
    final weakest = factors.entries.reduce(
      (a, b) => a.value <= b.value ? a : b,
    );
    return weakest.key;
  }
}
