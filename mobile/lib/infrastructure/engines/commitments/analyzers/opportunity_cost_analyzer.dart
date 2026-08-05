import 'dart:math' as math;

import '../../../../core/services/commitment_intelligence/commitment_engine.dart';
import '../../../../domain/commitments/opportunity_cost.dart';
import '../../../../domain/shared/analyzer_result.dart';

class OpportunityCostAnalyzer {
  const OpportunityCostAnalyzer();

  static const double _equityCagr = 0.12;
  static const String _returnLabel = '12% equity CAGR (Indian market avg)';

  AnalyzerResult<Map<String, OpportunityCostSimulation>> analyze(
    List<DetectedCommitment> subscriptions,
  ) {
    final startedAt = DateTime.now();
    final simulations = <String, OpportunityCostSimulation>{};

    final discretionary = subscriptions
        .where((c) =>
            c.type == CommitmentType.subscription ||
            c.type == CommitmentType.membership)
        .toList();

    for (final c in discretionary) {
      final monthly = c.monthlyEquivalent;
      final annual = monthly * 12;

      simulations[c.merchantKey] = OpportunityCostSimulation(
        merchantKey: c.merchantKey,
        displayName: c.displayName,
        monthlyAmount: monthly,
        annualAmount: annual,
        fiveYear: _project(monthly, 5),
        tenYear: _project(monthly, 10),
        twentyYear: _project(monthly, 20),
        thirtyYear: _project(monthly, 30),
        returnAssumption: _equityCagr,
        returnAssumptionLabel: _returnLabel,
      );
    }

    return AnalyzerResult.of(
      analyzerId: 'opportunity_cost_analyzer',
      result: simulations,
      confidence: 0.80,
      startedAt: startedAt,
    );
  }

  /// Future value of monthly PMT = PMT × [((1+r/12)^(n*12) - 1) / (r/12)]
  OpportunityCostProjection _project(double monthlyPmt, int years) {
    final r = _equityCagr;
    final n = years;
    final monthlyRate = r / 12;
    final periods = n * 12;

    final investedValue =
        monthlyPmt * ((math.pow(1 + monthlyRate, periods) - 1) / monthlyRate);
    final totalSpent = monthlyPmt * 12 * years;
    final opportunityCost = investedValue - totalSpent;

    return OpportunityCostProjection(
      years: years,
      totalSpent: totalSpent,
      investedValue: investedValue,
      opportunityCost: opportunityCost,
      returnAssumption: _equityCagr,
    );
  }
}
