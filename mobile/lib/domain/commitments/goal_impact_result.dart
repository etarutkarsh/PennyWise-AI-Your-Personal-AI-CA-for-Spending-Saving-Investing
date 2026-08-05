import 'package:flutter/foundation.dart';

/// Impact of a single commitment on a single goal.
@immutable
class GoalImpactEntry {
  const GoalImpactEntry({
    required this.goalId,
    required this.goalName,
    required this.goalType,
    required this.monthsToGoalCurrent,
    required this.monthsToGoalIfChanged,
    required this.monthsDelta,
    required this.isPositive,
    required this.insight,
  });

  final String goalId;
  final String goalName;
  final String goalType;

  /// Months to goal at the current contribution rate.
  final int monthsToGoalCurrent;

  /// Months to goal if this commitment were eliminated (subscriptions)
  /// or removed from the budget (investments).
  final int monthsToGoalIfChanged;

  /// Positive = this change would accelerate the goal.
  /// Negative = this change would delay the goal.
  final int monthsDelta;

  /// True if the commitment itself is net-positive for the goal
  /// (e.g., a SIP directly funding it).
  final bool isPositive;

  /// One-line human-readable insight for the card.
  final String insight;

  int get daysDelta => monthsDelta * 30;
  bool get hasMeaningfulImpact => monthsDelta.abs() >= 1;
}

/// The full goal impact profile for one DetectedCommitment.
@immutable
class GoalImpactResult {
  const GoalImpactResult({
    required this.merchantKey,
    required this.displayName,
    required this.monthlyAmount,
    required this.impacts,
    required this.primaryInsight,
    required this.confidence,
  });

  final String merchantKey;
  final String displayName;
  final double monthlyAmount;

  /// One entry per active goal with a meaningful impact.
  final List<GoalImpactEntry> impacts;

  /// Top-line insight string surfaced directly on the commitment card.
  final String primaryInsight;

  final double confidence;

  bool get hasImpact => impacts.any((e) => e.hasMeaningfulImpact);

  GoalImpactEntry? get primaryImpact => impacts.isEmpty
      ? null
      : impacts.reduce(
          (a, b) => a.monthsDelta.abs() >= b.monthsDelta.abs() ? a : b,
        );
}
