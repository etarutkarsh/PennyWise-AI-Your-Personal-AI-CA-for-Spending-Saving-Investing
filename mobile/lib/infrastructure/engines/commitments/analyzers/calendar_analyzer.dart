import '../../../../core/services/commitment_intelligence/commitment_engine.dart';
import '../../../../domain/commitments/financial_calendar.dart';
import '../../../../domain/shared/analyzer_result.dart';

FinancialCalendarEventType _mapCommitmentType(CommitmentType type) =>
    switch (type) {
      CommitmentType.emi => FinancialCalendarEventType.emi,
      CommitmentType.subscription => FinancialCalendarEventType.subscription,
      CommitmentType.investment => FinancialCalendarEventType.sip,
      CommitmentType.savings => FinancialCalendarEventType.sip,
      CommitmentType.insurance => FinancialCalendarEventType.insurance,
      CommitmentType.utility => FinancialCalendarEventType.utilityBill,
      CommitmentType.tax => FinancialCalendarEventType.tax,
      CommitmentType.rent => FinancialCalendarEventType.creditCardDue,
      CommitmentType.education => FinancialCalendarEventType.subscription,
      CommitmentType.membership => FinancialCalendarEventType.subscription,
      CommitmentType.other => FinancialCalendarEventType.subscription,
    };

String _recurrenceLabel(RecurrencePeriod period) => switch (period) {
      RecurrencePeriod.weekly => 'Weekly',
      RecurrencePeriod.biweekly => 'Biweekly',
      RecurrencePeriod.monthly => 'Monthly',
      RecurrencePeriod.quarterly => 'Quarterly',
      RecurrencePeriod.semiannual => 'Semi-Annual',
      RecurrencePeriod.annual => 'Annual',
      RecurrencePeriod.irregular => 'Irregular',
    };

class CalendarAnalyzer {
  const CalendarAnalyzer();

  AnalyzerResult<FinancialCalendar> analyze(
    List<DetectedCommitment> commitments, {
    int months = 3,
  }) {
    final startedAt = DateTime.now();
    final now = DateTime.now();
    final allEvents = <FinancialCalendarEvent>[];

    for (final c in commitments) {
      final endDate = DateTime(now.year, now.month + months, now.day);
      var checkDate = c.lastCharge;

      // advance to first future charge
      while (!checkDate.isAfter(now)) {
        checkDate = checkDate.add(Duration(days: c.periodDays));
      }

      while (checkDate.isBefore(endDate)) {
        allEvents.add(FinancialCalendarEvent(
          date: checkDate,
          title: c.displayName,
          amount: c.avgAmount,
          type: _mapCommitmentType(c.type),
          isConfirmed: c.confidence > 0.80,
          merchantKey: c.merchantKey,
          recurrenceLabel: _recurrenceLabel(c.period),
        ));
        checkDate = checkDate.add(Duration(days: c.periodDays));
      }
    }

    allEvents.sort((a, b) => a.date.compareTo(b.date));

    // Group by month
    final monthMap = <String, List<FinancialCalendarEvent>>{};
    for (final e in allEvents) {
      final key = '${e.date.year}-${e.date.month}';
      monthMap.putIfAbsent(key, () => []).add(e);
    }

    final calendarMonths = <FinancialCalendarMonth>[];
    for (var i = 0; i < months; i++) {
      final targetDate = DateTime(now.year, now.month + i);
      final key = '${targetDate.year}-${targetDate.month}';
      final monthEvents = monthMap[key] ?? [];

      // Group by week within month
      final weekMap = <DateTime, List<FinancialCalendarEvent>>{};
      for (final e in monthEvents) {
        final weekStart =
            e.date.subtract(Duration(days: e.date.weekday - 1));
        final normalizedWeekStart =
            DateTime(weekStart.year, weekStart.month, weekStart.day);
        weekMap.putIfAbsent(normalizedWeekStart, () => []).add(e);
      }

      final weeks = weekMap.entries
          .map((entry) => FinancialCalendarWeek(
                weekStart: entry.key,
                events: entry.value,
              ))
          .toList()
        ..sort((a, b) => a.weekStart.compareTo(b.weekStart));

      calendarMonths.add(FinancialCalendarMonth(
        year: targetDate.year,
        month: targetDate.month,
        events: monthEvents,
        weeks: weeks,
      ));
    }

    final next7Cutoff = now.add(const Duration(days: 7));
    final next30Cutoff = now.add(const Duration(days: 30));

    final next7Days =
        allEvents.where((e) => e.date.isBefore(next7Cutoff)).toList();
    final next30Days =
        allEvents.where((e) => e.date.isBefore(next30Cutoff)).toList();

    final currentMonth = calendarMonths.isNotEmpty ? calendarMonths.first : null;

    final largestUpcoming = next30Days.isEmpty
        ? null
        : next30Days.reduce((a, b) => a.amount >= b.amount ? a : b);

    final totalDueThisWeek =
        next7Days.fold<double>(0, (s, e) => s + e.amount);
    final totalDueThisMonth =
        (currentMonth?.events ?? []).fold<double>(0, (s, e) => s + e.amount);

    final calendar = FinancialCalendar(
      months: calendarMonths,
      currentMonth: currentMonth,
      next7Days: next7Days,
      next30Days: next30Days,
      totalDueThisWeek: totalDueThisWeek,
      totalDueThisMonth: totalDueThisMonth,
      largestUpcoming: largestUpcoming,
      upcomingCount: next30Days.length,
    );

    return AnalyzerResult.of(
      analyzerId: 'calendar_analyzer',
      result: calendar,
      confidence: commitments.isEmpty ? 0.30 : 0.85,
      startedAt: startedAt,
    );
  }
}
