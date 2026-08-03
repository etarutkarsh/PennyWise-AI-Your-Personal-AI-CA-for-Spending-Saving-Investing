import 'package:flutter/foundation.dart';
import '../value_objects/ids.dart';

/// The direction of outcome vs prediction.
enum OutcomeType {
  better,
  worse,
  asExpected,
  noData,
}

/// Multi-dimensional outcome evaluation observed ~60 days after execution.
/// Each dimension represents a measurable financial signal.
@immutable
class DecisionOutcome {
  final DecisionId decisionId;
  final UserId userId;
  final DateTime observedAt;
  final OutcomeType overallOutcome;

  /// DEV = realized - predicted. Positive = better than expected.
  final double decisionExpectationVariance;

  /// Health score at the time the decision was generated.
  final int? baselineHealthScore;

  /// Health score 60 days post-execution.
  final int? observedHealthScore;

  /// Emergency fund change in months.
  final double? emergencyFundDelta;

  /// Savings rate change (0.05 = 5pp improvement).
  final double? savingsRateDelta;

  /// Commitment-to-income ratio change.
  final double? debtRatioDelta;

  /// Goal progress delta (0.0–1.0 scale).
  final double? goalProgressDelta;

  /// Whether the user self-reported reduced financial stress.
  final bool? stressReduced;

  /// SIP or investment continued for full 60 days.
  final bool? investmentConsistency;

  /// Confidence that this outcome is attributable to the decision (0.0–1.0).
  final double attributionConfidence;

  const DecisionOutcome({
    required this.decisionId,
    required this.userId,
    required this.observedAt,
    required this.overallOutcome,
    required this.decisionExpectationVariance,
    this.baselineHealthScore,
    this.observedHealthScore,
    this.emergencyFundDelta,
    this.savingsRateDelta,
    this.debtRatioDelta,
    this.goalProgressDelta,
    this.stressReduced,
    this.investmentConsistency,
    this.attributionConfidence = 0.5,
  }) : assert(attributionConfidence >= 0.0 && attributionConfidence <= 1.0);

  /// True if the outcome is meaningful enough to learn from.
  bool get isSignificant =>
      decisionExpectationVariance.abs() > 5.0 &&
      attributionConfidence >= 0.40;

  int? get healthDelta =>
      (baselineHealthScore != null && observedHealthScore != null)
          ? observedHealthScore! - baselineHealthScore!
          : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DecisionOutcome && other.decisionId == decisionId);

  @override
  int get hashCode => decisionId.hashCode;

  @override
  String toString() =>
      'DecisionOutcome(decision: $decisionId, outcome: $overallOutcome, '
      'DEV: $decisionExpectationVariance, health: $healthDelta)';
}
