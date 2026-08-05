import 'package:flutter/foundation.dart';

/// Stub — blocked on Goals repository integration (Group C sprint).
@immutable
class GoalImpactEstimate {
  const GoalImpactEstimate({
    required this.goalId,
    required this.goalName,
    required this.monthlyImpact,
    required this.daysDelayIfCommitmentAdded,
    required this.opportunityCostLabel,
  });

  final String goalId;
  final String goalName;
  final double monthlyImpact;
  final int daysDelayIfCommitmentAdded;
  final String opportunityCostLabel;
}

abstract interface class GoalImpactAnalyzer {
  Future<Map<String, List<GoalImpactEstimate>>> analyzeImpact(
    List<String> merchantKeys,
    // List<GoalEntity> goals — added when Goals integrated
  );
}
