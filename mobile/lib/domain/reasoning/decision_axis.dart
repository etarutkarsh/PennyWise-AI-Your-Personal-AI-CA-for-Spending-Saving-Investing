import 'package:flutter/foundation.dart';

/// The 8 axes evaluated by [FinancialReasoningEngine].
///
/// Six axes form the "decision confidence pool" (weight > 0) — their
/// weighted average is the [DecisionConfidenceReport.decisionConfidenceFactor].
/// Two axes are external multipliers ([dataConfidence], [historicalAccuracy])
/// that modify the final compound confidence from outside the decision logic.
enum DecisionAxis {
  cashFlow,
  liquidity,
  goalImpact,
  behavior,
  taxes,
  opportunityCost,
  dataConfidence,
  historicalAccuracy;

  String get label => switch (this) {
        DecisionAxis.cashFlow => 'Cash Flow',
        DecisionAxis.liquidity => 'Liquidity',
        DecisionAxis.goalImpact => 'Goal Impact',
        DecisionAxis.behavior => 'Behavioral Pattern',
        DecisionAxis.taxes => 'Tax Efficiency',
        DecisionAxis.opportunityCost => 'Opportunity Cost',
        DecisionAxis.dataConfidence => 'Data Quality',
        DecisionAxis.historicalAccuracy => 'Historical Accuracy',
      };

  String get description => switch (this) {
        DecisionAxis.cashFlow =>
          'Monthly surplus, debt-to-income ratio, commitment burden',
        DecisionAxis.liquidity =>
          'Emergency fund coverage vs 6-month target',
        DecisionAxis.goalImpact =>
          'Fraction of active goals currently on track',
        DecisionAxis.behavior =>
          'Saving, spending, and investment discipline from behavioral engine',
        DecisionAxis.taxes =>
          'Tax-saving investment efficiency relative to 80C capacity',
        DecisionAxis.opportunityCost =>
          'Fraction of income invested in growth assets',
        DecisionAxis.dataConfidence =>
          'Data quality cap from connected sources (SMS, AA, manual)',
        DecisionAxis.historicalAccuracy =>
          'Accuracy of past recommendations from Decision Learning Loop',
      };

  /// Weight in the decision confidence pool (axes weighted sum → decisionConfidenceFactor).
  /// dataConfidence and historicalAccuracy are external multipliers — weight = 0.
  /// Weights across decision axes sum to 1.0.
  double get weight => switch (this) {
        DecisionAxis.cashFlow => 0.30,
        DecisionAxis.liquidity => 0.25,
        DecisionAxis.goalImpact => 0.20,
        DecisionAxis.behavior => 0.10,
        DecisionAxis.taxes => 0.05,
        DecisionAxis.opportunityCost => 0.10,
        DecisionAxis.dataConfidence => 0.0,
        DecisionAxis.historicalAccuracy => 0.0,
      };

  /// True if this axis participates in the decision confidence pool.
  bool get isDecisionAxis => weight > 0;
}

/// The result of evaluating a single reasoning axis.
@immutable
class DecisionAxisResult {
  const DecisionAxisResult({
    required this.axis,
    required this.score,
    required this.confidence,
    required this.signals,
    this.limitation,
  })  : assert(score >= 0.0 && score <= 1.0,
            'score must be 0.0–1.0, got $score'),
        assert(confidence >= 0.0 && confidence <= 1.0,
            'confidence must be 0.0–1.0, got $confidence');

  final DecisionAxis axis;

  /// Axis health score: 0.0 = worst financial position, 1.0 = best.
  final double score;

  /// How confident the analyzer is in this score (0.0–1.0).
  /// Low when input data is sparse or missing.
  final double confidence;

  /// Human-readable signals that drove this score (shown in explanation).
  final List<String> signals;

  /// Why this axis is incomplete, capped, or not computed.
  final String? limitation;

  bool get hasLimitation => limitation != null;

  /// Effective contribution = score weighted by how confident we are in it.
  double get confidenceWeightedScore => score * confidence;
}
