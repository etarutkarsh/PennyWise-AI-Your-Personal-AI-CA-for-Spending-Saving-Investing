import '../../../../core/services/commitment_intelligence/commitment_engine.dart';
import '../../../../domain/commitments/goal_impact_result.dart';
import '../../../../domain/commitments/goal_snapshot.dart';
import '../../../../domain/shared/analyzer_result.dart';

/// Computes the impact of each commitment on the user's active goals.
///
/// For subscription/lifestyle commitments: "freeing ₹X/mo could reach Goal Y
/// N months sooner."
/// For investment commitments: "removing this would delay Goal Y by N months."
///
/// Architecture invariant: pure computation — accepts only DetectedCommitments
/// + GoalSnapshots, returns GoalImpactResults. No UI, no repositories.
class GoalImpactAnalyzer {
  const GoalImpactAnalyzer();

  AnalyzerResult<Map<String, GoalImpactResult>> analyze(
    List<DetectedCommitment> commitments,
    List<GoalSnapshot> goals,
  ) {
    final start = DateTime.now();

    final activeGoals = goals
        .where((g) => !g.isComplete && g.hasContribution)
        .toList();

    if (activeGoals.isEmpty) {
      return AnalyzerResult.of(
        analyzerId: 'GoalImpactAnalyzer',
        result: const {},
        confidence: 0.0,
        startedAt: start,
        limitations: goals.isEmpty
            ? ['No goals configured — add goals to see commitment impact']
            : ['No active goals with monthly contributions found'],
      );
    }

    final results = <String, GoalImpactResult>{};

    for (final commitment in commitments) {
      final impacts = <GoalImpactEntry>[];

      for (final goal in activeGoals) {
        final entry = _computeEntry(commitment, goal);
        if (entry != null) impacts.add(entry);
      }

      if (impacts.isEmpty) continue;

      // Largest absolute impact first
      impacts.sort(
        (a, b) => b.monthsDelta.abs().compareTo(a.monthsDelta.abs()),
      );

      results[commitment.merchantKey] = GoalImpactResult(
        merchantKey: commitment.merchantKey,
        displayName: commitment.displayName,
        monthlyAmount: commitment.monthlyEquivalent,
        impacts: impacts,
        primaryInsight: _buildInsight(commitment, impacts.first),
        confidence: 0.75,
      );
    }

    return AnalyzerResult.of(
      analyzerId: 'GoalImpactAnalyzer',
      result: results,
      confidence: results.isNotEmpty ? 0.75 : 0.0,
      startedAt: start,
    );
  }

  GoalImpactEntry? _computeEntry(DetectedCommitment c, GoalSnapshot goal) {
    if (!goal.hasContribution || goal.isComplete) return null;

    final monthly = c.monthlyEquivalent;
    if (monthly <= 0) return null;

    final isInvestment = c.type == CommitmentType.investment ||
        c.type == CommitmentType.savings;

    final currentMonths = goal.monthsToGoal;

    if (isInvestment) {
      // Model: removing this commitment reduces the user's savings capacity
      // by its monthly equivalent, slowing goal achievement.
      final reducedGoal = GoalSnapshot(
        id: goal.id,
        name: goal.name,
        goalType: goal.goalType,
        targetAmount: goal.targetAmount,
        currentSaved: goal.currentSaved,
        monthlyContribution: (goal.monthlyContribution - monthly).clamp(0.0, double.infinity),
        deadline: goal.deadline,
      );
      final monthsWithout = reducedGoal.monthsToGoal;
      final costMonths = (monthsWithout - currentMonths).clamp(0, 9999);

      if (costMonths < 1) return null;

      return GoalImpactEntry(
        goalId: goal.id,
        goalName: goal.name,
        goalType: goal.goalType,
        monthsToGoalCurrent: currentMonths,
        monthsToGoalIfChanged: monthsWithout,
        monthsDelta: -costMonths,
        isPositive: true,
        insight:
            'Removing this would delay ${goal.name} by $costMonths month${costMonths == 1 ? '' : 's'}',
      );
    } else {
      // Model: freeing this commitment amount each month accelerates goal.
      final fasterMonths = goal.monthsToGoalWithExtra(monthly);
      final savedMonths = (currentMonths - fasterMonths).clamp(0, 9999);

      if (savedMonths < 1) return null;

      return GoalImpactEntry(
        goalId: goal.id,
        goalName: goal.name,
        goalType: goal.goalType,
        monthsToGoalCurrent: currentMonths,
        monthsToGoalIfChanged: fasterMonths,
        monthsDelta: savedMonths,
        isPositive: false,
        insight:
            'Freeing ₹${monthly.toInt()}/mo could reach ${goal.name} $savedMonths month${savedMonths == 1 ? '' : 's'} sooner',
      );
    }
  }

  String _buildInsight(DetectedCommitment c, GoalImpactEntry primary) {
    final months = primary.monthsDelta.abs();
    final suffix = months == 1 ? 'month' : 'months';
    if (primary.isPositive) {
      return 'Removing this would delay ${primary.goalName} by $months $suffix';
    } else {
      return 'Freeing ₹${c.monthlyEquivalent.toInt()}/mo → ${primary.goalName} $months $suffix sooner';
    }
  }
}
