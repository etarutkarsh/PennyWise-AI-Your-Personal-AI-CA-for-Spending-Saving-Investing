import '../../../domain/reasoning/decision_axis.dart';
import '../../../domain/reasoning/financial_reasoning_context.dart';

class LiquidityAxisAnalyzer {
  const LiquidityAxisAnalyzer();

  DecisionAxisResult analyze(FinancialReasoningContext ctx) {
    final efFact = ctx.facts.emergencyFundMonths;
    if (efFact == null) {
      return const DecisionAxisResult(
        axis: DecisionAxis.liquidity,
        score: 0.10,
        confidence: 0.05,
        signals: ['Emergency fund not tracked'],
        limitation: 'Liquidity analysis requires emergency fund data',
      );
    }

    final months = efFact.value;
    final score = _efScore(months);
    final signals = [
      'Emergency fund: ${months.toStringAsFixed(1)} months coverage',
      if (months < 3) 'Target: 6 months — currently ${(months / 6 * 100).toStringAsFixed(0)}% funded',
      if (months >= 6) 'Emergency fund meets the 6-month safety target',
    ];

    return DecisionAxisResult(
      axis: DecisionAxis.liquidity,
      score: score,
      confidence: (efFact.confidence).clamp(0.10, 1.0),
      signals: signals,
      limitation: months < 1 ? 'Emergency fund critically low — liquidity risk is high' : null,
    );
  }

  double _efScore(double months) {
    if (months >= 6.0) return 1.0;
    if (months >= 4.0) return 0.80;
    if (months >= 2.0) return 0.55;
    if (months >= 1.0) return 0.30;
    return 0.10;
  }
}
