import '../../../../core/services/commitment_intelligence/commitment_engine.dart';
import '../../../../domain/commitments/timeline_month.dart';
import '../../../../domain/shared/analyzer_result.dart';

class TimelineAnalyzer {
  const TimelineAnalyzer();

  AnalyzerResult<List<TimelineMonth>> analyze(
    List<DetectedCommitment> commitments,
  ) {
    final startedAt = DateTime.now();
    final now = DateTime.now();

    // 6 months back, 6 months forward = 12 months total
    final months = <TimelineMonth>[];

    for (var offset = -6; offset < 6; offset++) {
      final targetDate = DateTime(now.year, now.month + offset);
      final targetYear = targetDate.year;
      final targetMonth = targetDate.month;
      final monthStart = DateTime(targetYear, targetMonth, 1);
      final monthEnd = DateTime(targetYear, targetMonth + 1, 1)
          .subtract(const Duration(days: 1));

      var monthTotal = 0.0;
      final spikeNames = <String>[];

      for (final c in commitments) {
        // Walk forward from lastCharge to find charges in this month
        var checkDate = c.lastCharge;
        // Go backward if needed for past months
        if (offset < 0) {
          // Walk backward from lastCharge
          var backDate = c.lastCharge;
          while (backDate.isAfter(monthEnd)) {
            backDate = backDate.subtract(Duration(days: c.periodDays));
          }
          // Now check if backDate falls in our month
          var fwdDate = backDate;
          while (!fwdDate.isAfter(monthEnd)) {
            if (!fwdDate.isBefore(monthStart)) {
              monthTotal += c.avgAmount;
              if (c.period == RecurrencePeriod.annual ||
                  c.period == RecurrencePeriod.quarterly ||
                  c.period == RecurrencePeriod.semiannual) {
                spikeNames.add(c.displayName);
              }
            }
            fwdDate = fwdDate.add(Duration(days: c.periodDays));
          }
        } else {
          // Future months — walk forward from lastCharge
          while (checkDate.isBefore(monthStart)) {
            checkDate = checkDate.add(Duration(days: c.periodDays));
          }
          while (!checkDate.isAfter(monthEnd)) {
            monthTotal += c.avgAmount;
            if (c.period == RecurrencePeriod.annual ||
                c.period == RecurrencePeriod.quarterly ||
                c.period == RecurrencePeriod.semiannual) {
              if (!spikeNames.contains(c.displayName)) {
                spikeNames.add(c.displayName);
              }
            }
            checkDate = checkDate.add(Duration(days: c.periodDays));
          }
        }
      }

      final isCurrentMonth =
          targetYear == now.year && targetMonth == now.month;
      final spikeLabel =
          spikeNames.isNotEmpty ? spikeNames.join(', ') : '';

      months.add(TimelineMonth(
        year: targetYear,
        month: targetMonth,
        totalAmount: monthTotal,
        spikeLabel: spikeLabel,
        isCurrentMonth: isCurrentMonth,
      ));
    }

    return AnalyzerResult.of(
      analyzerId: 'timeline_analyzer',
      result: months,
      confidence: commitments.isEmpty ? 0.30 : 0.85,
      startedAt: startedAt,
    );
  }
}
