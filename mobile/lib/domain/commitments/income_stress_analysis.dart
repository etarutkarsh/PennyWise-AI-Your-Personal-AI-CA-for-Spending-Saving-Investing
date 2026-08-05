import 'package:flutter/foundation.dart';

enum StressScenario {
  dropTen,
  dropTwenty,
  dropThirty,
  jobLoss;

  String get label => switch (this) {
        StressScenario.dropTen => '10% income drop',
        StressScenario.dropTwenty => '20% income drop',
        StressScenario.dropThirty => '30% income drop',
        StressScenario.jobLoss => 'Job loss',
      };

  double get dropFraction => switch (this) {
        StressScenario.dropTen => 0.10,
        StressScenario.dropTwenty => 0.20,
        StressScenario.dropThirty => 0.30,
        StressScenario.jobLoss => 1.00,
      };
}

enum StressAffordability { safe, manageable, atRisk, critical }

@immutable
class StressScenarioResult {
  const StressScenarioResult({
    required this.scenario,
    required this.reducedIncome,
    required this.essentialCoverage,
    required this.investmentCoverage,
    required this.surplusOrShortfall,
    required this.affordability,
    required this.assessmentLabel,
    required this.recommendations,
  });

  final StressScenario scenario;
  final double reducedIncome;
  final bool essentialCoverage;
  final bool investmentCoverage;
  final double surplusOrShortfall;
  final StressAffordability affordability;
  final String assessmentLabel;
  final List<String> recommendations;
}

@immutable
class IncomeStressAnalysis {
  const IncomeStressAnalysis({
    required this.scenarios,
    required this.worstAffordableScenario,
    required this.minimumViableIncome,
    required this.hasIncomeConfigured,
  });

  final List<StressScenarioResult> scenarios;

  /// The worst scenario where essentials can still be covered.
  final StressScenario? worstAffordableScenario;

  /// Income needed to cover all essential + investment commitments.
  final double minimumViableIncome;
  final bool hasIncomeConfigured;

  StressScenarioResult? get twentyPercentDrop =>
      scenarios
          .where((s) => s.scenario == StressScenario.dropTwenty)
          .firstOrNull;
}
