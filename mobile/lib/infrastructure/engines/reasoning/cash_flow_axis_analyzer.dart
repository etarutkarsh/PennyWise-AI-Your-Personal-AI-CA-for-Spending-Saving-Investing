import '../../../domain/reasoning/decision_axis.dart';
import '../../../domain/reasoning/financial_reasoning_context.dart';

class CashFlowAxisAnalyzer {
  const CashFlowAxisAnalyzer();

  DecisionAxisResult analyze(FinancialReasoningContext ctx) {
    final income = ctx.facts.monthlyIncomeValue;
    if (income <= 0) {
      return const DecisionAxisResult(
        axis: DecisionAxis.cashFlow,
        score: 0.10,
        confidence: 0.05,
        signals: ['Monthly income not detected'],
        limitation: 'Cash flow analysis requires income data — connect SMS or Account Aggregator',
      );
    }

    final surplus = ctx.facts.monthlySurplus;
    final surplusRatio = (surplus / income).clamp(0.0, 1.0);
    final debtRatio = ctx.facts.debtRatio?.value ?? 0.0;

    double score = _surplusScore(surplusRatio);

    // Penalize high debt burden
    if (debtRatio >= 0.50) {
      score = (score - 0.35).clamp(0.05, score);
    } else if (debtRatio >= 0.40) {
      score = (score - 0.20).clamp(0.05, score);
    } else if (debtRatio >= 0.30) {
      score = (score - 0.08).clamp(0.05, score);
    }

    final signals = <String>[
      'Monthly surplus ₹${surplus.round()} (${(surplusRatio * 100).toStringAsFixed(0)}% of income)',
    ];
    if (debtRatio > 0) {
      signals.add('Debt-to-income ratio: ${(debtRatio * 100).toStringAsFixed(0)}%');
    }
    if (ctx.facts.recurringCommitmentsTotal != null) {
      signals.add(
        'Recurring commitments ₹${ctx.facts.recurringCommitmentsTotalValue.round()}/mo',
      );
    }

    final confidence = (ctx.facts.monthlyIncome?.confidence ?? 0.30)
        .clamp(0.10, 1.0);

    return DecisionAxisResult(
      axis: DecisionAxis.cashFlow,
      score: score.clamp(0.05, 1.0),
      confidence: confidence,
      signals: signals,
    );
  }

  double _surplusScore(double ratio) {
    if (ratio >= 0.40) return 0.95;
    if (ratio >= 0.30) return 0.80;
    if (ratio >= 0.20) return 0.65;
    if (ratio >= 0.10) return 0.45;
    if (ratio >= 0.02) return 0.25;
    return 0.10;
  }
}
