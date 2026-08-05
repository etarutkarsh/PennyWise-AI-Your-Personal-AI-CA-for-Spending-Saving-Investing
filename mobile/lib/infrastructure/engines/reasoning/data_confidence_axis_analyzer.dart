import '../../../domain/reasoning/decision_axis.dart';
import '../../../domain/reasoning/financial_reasoning_context.dart';
import '../../../domain/shared/data_confidence_report.dart';

class DataConfidenceAxisAnalyzer {
  const DataConfidenceAxisAnalyzer();

  DecisionAxisResult analyze(FinancialReasoningContext ctx) {
    final report = ctx.dataConfidence;
    final cap = report.recommendationConfidenceCap;

    final signals = <String>[];

    if (report.hasSmsConnected) signals.add('SMS intelligence active');
    if (report.hasAaConnected) signals.add('Account Aggregator linked');
    if (!report.hasSmsConnected && !report.hasAaConnected) {
      signals.add('Manual data only — no automated sources connected');
    }
    if (report.merchantResolutionRate >= 0.80) {
      signals.add('${(report.merchantResolutionRate * 100).toStringAsFixed(0)}% of merchants resolved');
    }

    final gaps = report.missingDataGaps;
    final limitation = gaps.isNotEmpty
        ? 'Data gaps: ${gaps.map((g) => g.type.label).join(', ')}'
        : null;

    return DecisionAxisResult(
      axis: DecisionAxis.dataConfidence,
      score: cap,
      confidence: 1.0,
      signals: signals,
      limitation: limitation,
    );
  }
}
