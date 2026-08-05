import '../../../domain/reasoning/decision_axis.dart';
import '../../../domain/reasoning/financial_reasoning_context.dart';

class OpportunityCostAxisAnalyzer {
  const OpportunityCostAxisAnalyzer();

  DecisionAxisResult analyze(FinancialReasoningContext ctx) {
    final investFact = ctx.facts.investmentRatio;
    final savFact = ctx.facts.savingsRate;

    if (investFact == null && savFact == null) {
      return const DecisionAxisResult(
        axis: DecisionAxis.opportunityCost,
        score: 0.30,
        confidence: 0.05,
        signals: ['Investment ratio not tracked'],
        limitation: 'Link investment accounts to compute opportunity cost',
      );
    }

    final investRate = investFact?.value ?? 0.0;
    final savRate = savFact?.value ?? 0.0;

    double score = _investScore(investRate);

    // Boost if savings rate is strong when investment tracking is unavailable
    if (investFact == null && savRate >= 0.20) {
      score = score.clamp(0.50, 1.0);
    }

    final signals = <String>[];
    if (investFact != null) {
      signals.add(
        'Investing ${(investRate * 100).toStringAsFixed(0)}% of income in growth assets',
      );
    }
    if (savFact != null) {
      signals.add(
        'Savings rate: ${(savRate * 100).toStringAsFixed(0)}% of income',
      );
    }
    if (investRate < 0.10 && investFact != null) {
      signals.add('Opportunity: redirect surplus to SIP/ELSS for compounding gains');
    }
    if (ctx.facts.existingInvestmentTotal != null) {
      signals.add(
        'Existing investments: ₹${(ctx.facts.existingInvestmentTotalValue / 1000).toStringAsFixed(0)}K',
      );
    }

    final confidence = (investFact?.confidence ?? savFact?.confidence ?? 0.10)
        .clamp(0.05, 1.0);

    return DecisionAxisResult(
      axis: DecisionAxis.opportunityCost,
      score: score.clamp(0.05, 1.0),
      confidence: confidence,
      signals: signals,
    );
  }

  double _investScore(double rate) {
    if (rate >= 0.20) return 1.0;
    if (rate >= 0.15) return 0.85;
    if (rate >= 0.10) return 0.70;
    if (rate >= 0.05) return 0.50;
    if (rate >= 0.02) return 0.30;
    return 0.15;
  }
}
