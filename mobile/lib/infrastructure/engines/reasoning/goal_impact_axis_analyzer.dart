import '../../../domain/reasoning/decision_axis.dart';
import '../../../domain/reasoning/financial_reasoning_context.dart';

class GoalImpactAxisAnalyzer {
  const GoalImpactAxisAnalyzer();

  DecisionAxisResult analyze(FinancialReasoningContext ctx) {
    final goals = ctx.goals;

    if (goals.isEmpty) {
      return const DecisionAxisResult(
        axis: DecisionAxis.goalImpact,
        score: 0.50,
        confidence: 0.0,
        signals: ['No goals configured'],
        limitation: 'Add financial goals to enable goal impact analysis',
      );
    }

    final active = goals.where((g) => !g.isComplete && g.hasContribution).toList();
    if (active.isEmpty) {
      return const DecisionAxisResult(
        axis: DecisionAxis.goalImpact,
        score: 0.50,
        confidence: 0.10,
        signals: ['No active goals with monthly contributions'],
        limitation: 'Goals exist but none have monthly contributions set',
      );
    }

    final onTrack = active.where((g) => g.isOnTrack).length;
    final trackRate = onTrack / active.length;
    final score = _trackScore(trackRate);

    final signals = [
      '$onTrack of ${active.length} active goal${active.length == 1 ? '' : 's'} on track',
      if (onTrack < active.length)
        '${active.length - onTrack} goal${active.length - onTrack == 1 ? '' : 's'} behind schedule',
    ];

    return DecisionAxisResult(
      axis: DecisionAxis.goalImpact,
      score: score,
      confidence: 0.75,
      signals: signals,
    );
  }

  double _trackScore(double trackRate) {
    if (trackRate >= 0.90) return 0.95;
    if (trackRate >= 0.70) return 0.80;
    if (trackRate >= 0.50) return 0.65;
    if (trackRate >= 0.30) return 0.50;
    if (trackRate >= 0.10) return 0.35;
    return 0.20;
  }
}
