// Defines GoalImpact — the projected effect of a decision on a specific financial goal.

import 'package:flutter/foundation.dart';
import '../value_objects/ids.dart';

/// The projected impact of accepting a Decision on one financial goal.
@immutable
class GoalImpact {
  final GoalId goalId;
  final String goalName;

  /// Health score for this goal before the decision (0–100).
  final int currentHealthScore;

  /// Projected health score after accepting the decision (0–100).
  final int projectedHealthScore;

  /// Change in probability of achieving the goal on time (e.g. 0.12 = +12%).
  final double successProbabilityDelta;

  const GoalImpact({
    required this.goalId,
    required this.goalName,
    required this.currentHealthScore,
    required this.projectedHealthScore,
    required this.successProbabilityDelta,
  });

  /// Delta between projected and current health scores.
  int get healthScoreDelta => projectedHealthScore - currentHealthScore;

  GoalImpact copyWith({
    GoalId? goalId,
    String? goalName,
    int? currentHealthScore,
    int? projectedHealthScore,
    double? successProbabilityDelta,
  }) =>
      GoalImpact(
        goalId: goalId ?? this.goalId,
        goalName: goalName ?? this.goalName,
        currentHealthScore: currentHealthScore ?? this.currentHealthScore,
        projectedHealthScore: projectedHealthScore ?? this.projectedHealthScore,
        successProbabilityDelta: successProbabilityDelta ?? this.successProbabilityDelta,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalImpact &&
          other.goalId == goalId &&
          other.projectedHealthScore == projectedHealthScore);

  @override
  int get hashCode => Object.hash(goalId, projectedHealthScore);

  @override
  String toString() =>
      'GoalImpact(goal: $goalName, delta: ${healthScoreDelta > 0 ? '+' : ''}$healthScoreDelta)';
}
