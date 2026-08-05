import '../../../domain/reasoning/decision_axis.dart';
import '../../../domain/reasoning/financial_reasoning_context.dart';

class TaxAxisAnalyzer {
  const TaxAxisAnalyzer();

  DecisionAxisResult analyze(FinancialReasoningContext ctx) {
    final taxFact = ctx.facts.taxEfficiency;

    if (taxFact == null) {
      return const DecisionAxisResult(
        axis: DecisionAxis.taxes,
        score: 0.50,
        confidence: 0.0,
        signals: ['Tax efficiency not computed'],
        limitation: 'Tax analysis requires investment data (ELSS, PPF, NPS, etc.)',
      );
    }

    final efficiency = taxFact.value.clamp(0.0, 1.0);
    final score = _taxScore(efficiency);
    final pct = (efficiency * 100).toStringAsFixed(0);

    final signals = [
      'Tax efficiency: $pct% of 80C capacity utilized',
      if (efficiency < 0.60) 'Opportunity: increase tax-saving investments to reduce liability',
      if (efficiency >= 0.90) 'Excellent — Section 80C limit fully utilized',
    ];

    return DecisionAxisResult(
      axis: DecisionAxis.taxes,
      score: score,
      confidence: taxFact.confidence.clamp(0.10, 1.0),
      signals: signals,
    );
  }

  double _taxScore(double efficiency) {
    if (efficiency >= 0.90) return 1.0;
    if (efficiency >= 0.70) return 0.85;
    if (efficiency >= 0.50) return 0.65;
    if (efficiency >= 0.30) return 0.45;
    return 0.25;
  }
}
