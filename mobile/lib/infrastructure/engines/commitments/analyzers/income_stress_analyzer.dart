import '../../../../core/services/commitment_intelligence/commitment_engine.dart';
import '../../../../domain/commitments/income_stress_analysis.dart';
import '../../../../domain/shared/analyzer_result.dart';

class IncomeStressAnalyzer {
  const IncomeStressAnalyzer();

  AnalyzerResult<IncomeStressAnalysis> analyze(
    CommitmentSummary summary,
    Map<CommitmentCategory, List<DetectedCommitment>> mandatesByCategory,
  ) {
    final startedAt = DateTime.now();

    if (summary.monthlyIncome <= 0) {
      // Income not configured — all scenarios appear safe
      final safeScenarios = StressScenario.values
          .map((scenario) => StressScenarioResult(
                scenario: scenario,
                reducedIncome: 0,
                essentialCoverage: true,
                investmentCoverage: true,
                surplusOrShortfall: 0,
                affordability: StressAffordability.safe,
                assessmentLabel: 'Safe',
                recommendations: [
                  'Configure your monthly income for accurate stress analysis'
                ],
              ))
          .toList();

      return AnalyzerResult.of(
        analyzerId: 'income_stress_analyzer',
        result: IncomeStressAnalysis(
          scenarios: safeScenarios,
          worstAffordableScenario: StressScenario.jobLoss,
          minimumViableIncome: 0,
          hasIncomeConfigured: false,
        ),
        confidence: 0.30,
        startedAt: startedAt,
        limitations: ['Monthly income not configured — stress analysis is approximate'],
      );
    }

    final essentialMonthly =
        (mandatesByCategory[CommitmentCategory.critical] ?? [])
            .fold<double>(0, (s, c) => s + c.monthlyEquivalent);
    final investmentMonthly =
        (mandatesByCategory[CommitmentCategory.investment] ?? [])
            .fold<double>(0, (s, c) => s + c.monthlyEquivalent);
    final minimumViableIncome = essentialMonthly + investmentMonthly;

    final scenarios = <StressScenarioResult>[];
    StressScenario? worstAffordable;

    for (final scenario in StressScenario.values) {
      final reducedIncome =
          summary.monthlyIncome * (1 - scenario.dropFraction);
      final surplusOrShortfall =
          reducedIncome - summary.totalMonthlyCommitted;
      final essentialCoverage = reducedIncome >= essentialMonthly;
      final investmentCoverage =
          reducedIncome >= essentialMonthly + investmentMonthly;

      final StressAffordability affordability;
      final String assessmentLabel;

      if (surplusOrShortfall >= 0) {
        affordability = StressAffordability.safe;
        assessmentLabel = 'Safe';
      } else if (essentialCoverage && investmentCoverage) {
        affordability = StressAffordability.manageable;
        assessmentLabel = 'Manageable';
      } else if (essentialCoverage && !investmentCoverage) {
        affordability = StressAffordability.atRisk;
        assessmentLabel = 'At Risk';
      } else {
        affordability = StressAffordability.critical;
        assessmentLabel = 'Critical';
      }

      final recommendations = _buildRecommendations(
          scenario, affordability, essentialCoverage, investmentCoverage);

      if (essentialCoverage) {
        worstAffordable = scenario;
      }

      scenarios.add(StressScenarioResult(
        scenario: scenario,
        reducedIncome: reducedIncome,
        essentialCoverage: essentialCoverage,
        investmentCoverage: investmentCoverage,
        surplusOrShortfall: surplusOrShortfall,
        affordability: affordability,
        assessmentLabel: assessmentLabel,
        recommendations: recommendations,
      ));
    }

    return AnalyzerResult.of(
      analyzerId: 'income_stress_analyzer',
      result: IncomeStressAnalysis(
        scenarios: scenarios,
        worstAffordableScenario: worstAffordable,
        minimumViableIncome: minimumViableIncome,
        hasIncomeConfigured: true,
      ),
      confidence: 0.85,
      startedAt: startedAt,
    );
  }

  List<String> _buildRecommendations(
    StressScenario scenario,
    StressAffordability affordability,
    bool essentialCoverage,
    bool investmentCoverage,
  ) {
    switch (affordability) {
      case StressAffordability.safe:
        return [
          'Your commitments are manageable even with a ${scenario.label}.',
          'Consider building a 6-month emergency fund as an additional buffer.',
        ];
      case StressAffordability.manageable:
        return [
          'Essential commitments are safe, but discretionary spending would need to stop.',
          'Review optional subscriptions to improve resilience.',
        ];
      case StressAffordability.atRisk:
        return [
          'Investment commitments would need to be paused.',
          'Prioritize building an emergency fund of at least 3 months of expenses.',
        ];
      case StressAffordability.critical:
        return [
          'Essential obligations like EMIs may be at risk.',
          'Immediate action needed — reduce discretionary commitments now.',
        ];
    }
  }
}
