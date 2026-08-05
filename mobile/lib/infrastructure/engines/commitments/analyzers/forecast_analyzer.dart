import '../../../../core/services/commitment_intelligence/commitment_engine.dart';
import '../../../../domain/commitments/forecast_result.dart';
import '../../../../domain/shared/analyzer_result.dart';

const Map<RecurrencePeriod, String> _periodLabel = {
  RecurrencePeriod.weekly: 'Weekly',
  RecurrencePeriod.biweekly: 'Biweekly',
  RecurrencePeriod.monthly: 'Monthly',
  RecurrencePeriod.quarterly: 'Quarterly',
  RecurrencePeriod.semiannual: 'Semi-Annual',
  RecurrencePeriod.annual: 'Annual',
  RecurrencePeriod.irregular: 'Irregular',
};

class ForecastAnalyzer {
  const ForecastAnalyzer();

  AnalyzerResult<ForecastResult> analyze(
    List<DetectedCommitment> commitments,
    double monthlyIncome,
  ) {
    final startedAt = DateTime.now();
    final now = DateTime.now();

    // Build 6-month forecast
    final monthForecasts = <MonthlyForecast>[];
    for (var i = 0; i < 6; i++) {
      final targetYear =
          DateTime(now.year, now.month + i).year;
      final targetMonth =
          DateTime(now.year, now.month + i).month;

      final monthStart = DateTime(targetYear, targetMonth, 1);
      final monthEnd = DateTime(targetYear, targetMonth + 1, 1)
          .subtract(const Duration(days: 1));

      var monthTotal = 0.0;
      var contributingCount = 0;
      final spikeReasons = <String>[];

      for (final c in commitments) {
        // Walk forward from lastCharge to find all charges in this month
        var checkDate = c.lastCharge;
        // Advance to first occurrence on or after monthStart
        while (checkDate.isBefore(monthStart)) {
          checkDate = checkDate.add(Duration(days: c.periodDays));
        }
        // Sum all charges within this month
        bool chargedThisMonth = false;
        while (!checkDate.isAfter(monthEnd)) {
          monthTotal += c.avgAmount;
          chargedThisMonth = true;
          checkDate = checkDate.add(Duration(days: c.periodDays));
        }
        if (chargedThisMonth) {
          contributingCount++;
          if (c.period == RecurrencePeriod.annual ||
              c.period == RecurrencePeriod.semiannual ||
              c.period == RecurrencePeriod.quarterly) {
            spikeReasons.add('${c.displayName} (${_periodLabel[c.period]})');
          }
        }
      }

      monthForecasts.add(MonthlyForecast(
        year: targetYear,
        month: targetMonth,
        expectedTotal: monthTotal,
        contributingCount: contributingCount,
        spikeReasons: spikeReasons,
        isSpike: false, // will update below
        cashReserveRequired: monthTotal * 1.1,
      ));
    }

    // Calculate average and mark spikes
    final avg = monthForecasts.isEmpty
        ? 0.0
        : monthForecasts.fold<double>(0, (s, m) => s + m.expectedTotal) /
            monthForecasts.length;

    final updatedForecasts = monthForecasts
        .map((m) => MonthlyForecast(
              year: m.year,
              month: m.month,
              expectedTotal: m.expectedTotal,
              contributingCount: m.contributingCount,
              spikeReasons: m.spikeReasons,
              isSpike: avg > 0 && m.expectedTotal > avg * 1.5,
              cashReserveRequired: m.cashReserveRequired,
            ))
        .toList();

    final peakMonth = updatedForecasts.isEmpty
        ? updatedForecasts.first
        : updatedForecasts.reduce(
            (a, b) => a.expectedTotal >= b.expectedTotal ? a : b);

    final stressWindows =
        updatedForecasts.where((m) => m.isSpike).toList();

    // Renewal alerts within 60 days
    final renewalAlerts = <RenewalAlert>[];
    for (final c in commitments) {
      if (c.period == RecurrencePeriod.annual ||
          c.period == RecurrencePeriod.quarterly ||
          c.period == RecurrencePeriod.semiannual) {
        final daysUntil = c.nextExpected.difference(now).inDays;
        if (daysUntil >= 0 && daysUntil <= 60) {
          renewalAlerts.add(RenewalAlert(
            merchantKey: c.merchantKey,
            merchantName: c.displayName,
            expectedDate: c.nextExpected,
            amount: c.avgAmount,
            recurrencePeriod: _periodLabel[c.period] ?? 'Unknown',
            daysUntil: daysUntil,
            isAnnual: c.period == RecurrencePeriod.annual,
          ));
        }
      }
    }
    renewalAlerts.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));

    final maxMonthly = updatedForecasts.isEmpty
        ? 0.0
        : updatedForecasts
            .map((m) => m.expectedTotal)
            .reduce((a, b) => a > b ? a : b);

    final annualProjection = avg * 12;

    final confidence = commitments.length >= 5
        ? 0.85
        : commitments.length >= 2
            ? 0.65
            : 0.40;

    final result = ForecastResult(
      monthlyForecasts: updatedForecasts,
      averageMonthly: avg,
      annualProjection: annualProjection,
      forecastConfidence: confidence,
      renewalTimeline: renewalAlerts,
      cashReserveProjection: maxMonthly * 1.1,
      peakMonth: peakMonth,
      stressWindows: stressWindows,
    );

    return AnalyzerResult.of(
      analyzerId: 'forecast_analyzer',
      result: result,
      confidence: confidence,
      startedAt: startedAt,
      limitations: commitments.isEmpty
          ? ['No commitments detected — forecast is empty']
          : [],
    );
  }
}
