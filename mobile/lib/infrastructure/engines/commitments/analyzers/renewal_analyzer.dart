import '../../../../core/services/commitment_intelligence/commitment_engine.dart';
import '../../../../domain/commitments/forecast_result.dart';
import '../../../../domain/shared/analyzer_result.dart';

const Map<RecurrencePeriod, String> _renewalPeriodLabel = {
  RecurrencePeriod.weekly: 'Weekly',
  RecurrencePeriod.biweekly: 'Biweekly',
  RecurrencePeriod.monthly: 'Monthly',
  RecurrencePeriod.quarterly: 'Quarterly',
  RecurrencePeriod.semiannual: 'Semi-Annual',
  RecurrencePeriod.annual: 'Annual',
  RecurrencePeriod.irregular: 'Irregular',
};

class RenewalAnalyzer {
  const RenewalAnalyzer();

  AnalyzerResult<List<RenewalAlert>> analyze(
    List<DetectedCommitment> commitments,
  ) {
    final startedAt = DateTime.now();
    final now = DateTime.now();
    final alerts = <RenewalAlert>[];

    for (final c in commitments) {
      if (c.period == RecurrencePeriod.annual ||
          c.period == RecurrencePeriod.quarterly ||
          c.period == RecurrencePeriod.semiannual) {
        final daysUntil = c.nextExpected.difference(now).inDays;
        if (daysUntil >= 0 && daysUntil <= 60) {
          alerts.add(RenewalAlert(
            merchantKey: c.merchantKey,
            merchantName: c.displayName,
            expectedDate: c.nextExpected,
            amount: c.avgAmount,
            recurrencePeriod: _renewalPeriodLabel[c.period] ?? 'Unknown',
            daysUntil: daysUntil,
            isAnnual: c.period == RecurrencePeriod.annual,
          ));
        }
      }
    }

    alerts.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));

    return AnalyzerResult.of(
      analyzerId: 'renewal_analyzer',
      result: alerts,
      confidence: alerts.isNotEmpty ? 0.90 : 0.70,
      startedAt: startedAt,
    );
  }
}
