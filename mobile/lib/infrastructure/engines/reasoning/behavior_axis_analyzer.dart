import '../../../domain/behavioral/behavior_dimension.dart';
import '../../../domain/reasoning/decision_axis.dart';
import '../../../domain/reasoning/financial_reasoning_context.dart';

class BehaviorAxisAnalyzer {
  const BehaviorAxisAnalyzer();

  DecisionAxisResult analyze(FinancialReasoningContext ctx) {
    final behavior = ctx.behavior;

    if (behavior == null || !behavior.isCalibrated) {
      return DecisionAxisResult(
        axis: DecisionAxis.behavior,
        score: 0.50,
        confidence: behavior?.overallConfidence ?? 0.0,
        signals: const ['Behavioral engine not yet calibrated'],
        limitation: 'Connect transaction history to calibrate behavioral patterns',
      );
    }

    final dims = behavior.dimensions;

    // Positive dimensions (higher = better)
    final saving = _dimScore(dims, BehaviorDimensionType.savingDiscipline);
    final spending = _dimScore(dims, BehaviorDimensionType.spendingDiscipline);
    final investing = _dimScore(dims, BehaviorDimensionType.investmentDiscipline);
    final consistency = _dimScore(dims, BehaviorDimensionType.consistency);

    // Negative dimensions (lower = better — inverted)
    final impulsiveness = 1.0 - _dimScore(dims, BehaviorDimensionType.impulsiveness);
    final presentBias = 1.0 - _dimScore(dims, BehaviorDimensionType.presentBias);

    // Weighted composite — saving and spending discipline carry most weight
    final score = saving * 0.30 +
        spending * 0.30 +
        investing * 0.15 +
        consistency * 0.10 +
        impulsiveness * 0.10 +
        presentBias * 0.05;

    final signals = <String>[];
    if (saving >= 0.65) signals.add('Strong saving discipline');
    if (spending >= 0.65) signals.add('Controlled spending habits');
    if (investing >= 0.65) signals.add('Consistent investment behavior');
    if (impulsiveness < 0.40) signals.add('Impulse spending detected');
    if (signals.isEmpty) signals.add('Moderate behavioral discipline across dimensions');

    // Surface top intent if present
    final primary = behavior.primaryIntent;
    if (primary != null) signals.add('Primary intent: ${primary.type.label}');

    // Note contradictions as a limitation
    String? limitation;
    if (behavior.hasCriticalContradictions) {
      limitation = 'Critical behavioral contradictions detected — review Digital Twin';
    }

    return DecisionAxisResult(
      axis: DecisionAxis.behavior,
      score: score.clamp(0.05, 1.0),
      confidence: behavior.overallConfidence.clamp(0.05, 1.0),
      signals: signals,
      limitation: limitation,
    );
  }

  double _dimScore(
    Map<BehaviorDimensionType, dynamic> dims,
    BehaviorDimensionType type,
  ) {
    final d = dims[type];
    if (d == null) return 0.5;
    return (d.score as double) / 100.0;
  }
}
