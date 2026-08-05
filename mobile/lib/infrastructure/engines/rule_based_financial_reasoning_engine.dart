import '../../domain/engines/financial_reasoning_engine.dart';
import '../../domain/reasoning/decision_axis.dart';
import '../../domain/reasoning/decision_confidence_report.dart';
import '../../domain/reasoning/financial_reasoning_context.dart';
import '../../domain/reasoning/recommendation_strength.dart';
import 'reasoning/behavior_axis_analyzer.dart';
import 'reasoning/cash_flow_axis_analyzer.dart';
import 'reasoning/data_confidence_axis_analyzer.dart';
import 'reasoning/goal_impact_axis_analyzer.dart';
import 'reasoning/historical_accuracy_axis_analyzer.dart';
import 'reasoning/liquidity_axis_analyzer.dart';
import 'reasoning/opportunity_cost_axis_analyzer.dart';
import 'reasoning/tax_axis_analyzer.dart';

/// Rule-based implementation of [FinancialReasoningEngine].
///
/// Runs all 8 axis analyzers and applies the CTO compound formula:
///   compoundConfidence = dataConf × decisionConf × behaviorConf × historicalAcc
///
/// [decisionConfidenceFactor] is the confidence-weighted average of the 6
/// decision axes (cashFlow, liquidity, goalImpact, behavior, taxes, opportunityCost).
///
/// Architecture: pure computation, const constructor, zero external calls.
/// Upgrade path: replace weight constants with trained Bayesian weights once
/// [DecisionLearningEngine] accumulates sufficient outcome history.
class RuleBasedFinancialReasoningEngine implements FinancialReasoningEngine {
  const RuleBasedFinancialReasoningEngine({
    required CashFlowAxisAnalyzer cashFlowAnalyzer,
    required LiquidityAxisAnalyzer liquidityAnalyzer,
    required GoalImpactAxisAnalyzer goalImpactAnalyzer,
    required BehaviorAxisAnalyzer behaviorAnalyzer,
    required TaxAxisAnalyzer taxAnalyzer,
    required OpportunityCostAxisAnalyzer opportunityCostAnalyzer,
    required DataConfidenceAxisAnalyzer dataConfidenceAnalyzer,
    required HistoricalAccuracyAxisAnalyzer historicalAccuracyAnalyzer,
  })  : _cashFlowAnalyzer = cashFlowAnalyzer,
        _liquidityAnalyzer = liquidityAnalyzer,
        _goalImpactAnalyzer = goalImpactAnalyzer,
        _behaviorAnalyzer = behaviorAnalyzer,
        _taxAnalyzer = taxAnalyzer,
        _opportunityCostAnalyzer = opportunityCostAnalyzer,
        _dataConfidenceAnalyzer = dataConfidenceAnalyzer,
        _historicalAccuracyAnalyzer = historicalAccuracyAnalyzer;

  final CashFlowAxisAnalyzer _cashFlowAnalyzer;
  final LiquidityAxisAnalyzer _liquidityAnalyzer;
  final GoalImpactAxisAnalyzer _goalImpactAnalyzer;
  final BehaviorAxisAnalyzer _behaviorAnalyzer;
  final TaxAxisAnalyzer _taxAnalyzer;
  final OpportunityCostAxisAnalyzer _opportunityCostAnalyzer;
  final DataConfidenceAxisAnalyzer _dataConfidenceAnalyzer;
  final HistoricalAccuracyAxisAnalyzer _historicalAccuracyAnalyzer;

  static RuleBasedFinancialReasoningEngine withDefaults() =>
      const RuleBasedFinancialReasoningEngine(
        cashFlowAnalyzer: CashFlowAxisAnalyzer(),
        liquidityAnalyzer: LiquidityAxisAnalyzer(),
        goalImpactAnalyzer: GoalImpactAxisAnalyzer(),
        behaviorAnalyzer: BehaviorAxisAnalyzer(),
        taxAnalyzer: TaxAxisAnalyzer(),
        opportunityCostAnalyzer: OpportunityCostAxisAnalyzer(),
        dataConfidenceAnalyzer: DataConfidenceAxisAnalyzer(),
        historicalAccuracyAnalyzer: HistoricalAccuracyAxisAnalyzer(),
      );

  @override
  String get engineVersion => '10.0';

  @override
  DecisionConfidenceReport reason(FinancialReasoningContext ctx) {
    // 1. Run all 8 axes
    final axes = <DecisionAxis, DecisionAxisResult>{
      DecisionAxis.cashFlow: _cashFlowAnalyzer.analyze(ctx),
      DecisionAxis.liquidity: _liquidityAnalyzer.analyze(ctx),
      DecisionAxis.goalImpact: _goalImpactAnalyzer.analyze(ctx),
      DecisionAxis.behavior: _behaviorAnalyzer.analyze(ctx),
      DecisionAxis.taxes: _taxAnalyzer.analyze(ctx),
      DecisionAxis.opportunityCost: _opportunityCostAnalyzer.analyze(ctx),
      DecisionAxis.dataConfidence: _dataConfidenceAnalyzer.analyze(ctx),
      DecisionAxis.historicalAccuracy: _historicalAccuracyAnalyzer.analyze(ctx),
    };

    // 2. Decision confidence = confidence-weighted average of 6 decision axes
    double weightedSum = 0;
    double totalWeight = 0;
    for (final axis in DecisionAxis.values.where((a) => a.isDecisionAxis)) {
      final result = axes[axis]!;
      final effectiveWeight = axis.weight * result.confidence;
      weightedSum += result.score * effectiveWeight;
      totalWeight += effectiveWeight;
    }
    final decisionConf = totalWeight > 0 ? (weightedSum / totalWeight) : 0.50;

    // 3. External multiplier factors
    final dataFactor = ctx.dataConfidence.recommendationConfidenceCap;
    final behaviorFactor = (ctx.behavior?.overallConfidence ?? 0.50)
        .clamp(0.0, 1.0);
    final historicalFactor = axes[DecisionAxis.historicalAccuracy]!.score;

    // 4. Compound formula (CTO):
    //    Recommendation Confidence = Data × Decision × Behavior × Historical
    final compound = (dataFactor * decisionConf * behaviorFactor * historicalFactor)
        .clamp(0.0, 1.0);

    // 5. Aggregate signals into top factors and limitations
    final topFactors = _buildTopFactors(axes, dataFactor, behaviorFactor, historicalFactor);
    final limitations = _buildLimitations(axes, ctx);

    return DecisionConfidenceReport(
      axes: axes,
      dataConfidenceFactor: dataFactor,
      decisionConfidenceFactor: decisionConf,
      behaviorConfidenceFactor: behaviorFactor,
      historicalAccuracyFactor: historicalFactor,
      compoundConfidence: compound,
      strength: RecommendationStrength.fromCompound(compound),
      topFactors: topFactors,
      limitations: limitations,
      computedAt: DateTime.now(),
    );
  }

  List<String> _buildTopFactors(
    Map<DecisionAxis, DecisionAxisResult> axes,
    double dataFactor,
    double behaviorFactor,
    double historicalFactor,
  ) {
    final factors = <String>[];

    // Strongest decision axis
    final decisionAxes = axes.entries.where((e) => e.key.isDecisionAxis).toList()
      ..sort((a, b) => b.value.score.compareTo(a.value.score));
    if (decisionAxes.isNotEmpty && decisionAxes.first.value.score >= 0.70) {
      final best = decisionAxes.first;
      factors.add('${best.key.label}: ${(best.value.score * 100).toStringAsFixed(0)}% (strong)');
    }

    if (dataFactor >= 0.70) factors.add('Data quality: good coverage from connected sources');
    if (behaviorFactor >= 0.60) factors.add('Behavioral patterns calibrated');
    if (historicalFactor >= 0.70) factors.add('Strong recommendation history');

    // Weakest axis (main bottleneck)
    if (decisionAxes.isNotEmpty && decisionAxes.last.value.score < 0.40) {
      final worst = decisionAxes.last;
      factors.add('${worst.key.label}: ${(worst.value.score * 100).toStringAsFixed(0)}% — needs attention');
    }

    return factors;
  }

  List<String> _buildLimitations(
    Map<DecisionAxis, DecisionAxisResult> axes,
    FinancialReasoningContext ctx,
  ) {
    final limitations = <String>[];

    for (final entry in axes.entries) {
      final limitation = entry.value.limitation;
      if (limitation != null) limitations.add(limitation);
    }

    if (ctx.behavior == null) {
      limitations.add('Behavioral engine not run — using neutral prior for behavior confidence');
    }
    if (ctx.learningSnapshot == null ||
        ctx.learningSnapshot!.completedCycles == 0) {
      limitations.add('No recommendation history — using neutral prior for historical accuracy');
    }

    return limitations;
  }
}
