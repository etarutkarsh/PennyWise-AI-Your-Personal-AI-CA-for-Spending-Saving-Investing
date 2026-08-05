import 'package:flutter/foundation.dart';

/// A lightweight, immutable snapshot of a goal's current state, used as
/// input to the Recurring Commitments Intelligence Platform.
///
/// Keeps the commitments domain decoupled from GoalEntity (features layer).
/// The use case / screen maps GoalEntity → GoalSnapshot before passing context.
@immutable
class GoalSnapshot {
  const GoalSnapshot({
    required this.id,
    required this.name,
    required this.goalType,
    required this.targetAmount,
    required this.currentSaved,
    required this.monthlyContribution,
    required this.deadline,
  });

  final String id;
  final String name;
  final String goalType;
  final double targetAmount;
  final double currentSaved;
  final double monthlyContribution;
  final DateTime deadline;

  double get remaining =>
      (targetAmount - currentSaved).clamp(0.0, double.infinity);

  bool get isComplete => remaining <= 0;
  bool get hasContribution => monthlyContribution > 0;

  /// Months to reach goal at the current contribution rate.
  int get monthsToGoal {
    if (isComplete) return 0;
    if (!hasContribution) return 9999;
    return (remaining / monthlyContribution).ceil();
  }

  /// Months to reach goal if [extra] additional monthly amount is redirected here.
  int monthsToGoalWithExtra(double extra) {
    if (isComplete) return 0;
    final effective = monthlyContribution + extra;
    if (effective <= 0) return 9999;
    return (remaining / effective).ceil();
  }

  int get monthsUntilDeadline =>
      deadline.difference(DateTime.now()).inDays ~/ 30;

  bool get isOnTrack => monthsToGoal <= monthsUntilDeadline;
}
