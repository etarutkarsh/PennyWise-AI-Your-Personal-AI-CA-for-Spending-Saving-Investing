import 'package:flutter/foundation.dart';

enum FinancialCalendarEventType {
  salary,
  subscription,
  emi,
  sip,
  insurance,
  utilityBill,
  tax,
  investmentMaturity,
  goalMilestone,
  creditCardDue,
  reminder;

  bool get isCommitment => switch (this) {
        FinancialCalendarEventType.salary ||
        FinancialCalendarEventType.goalMilestone ||
        FinancialCalendarEventType.reminder =>
          false,
        _ => true,
      };
}

@immutable
class FinancialCalendarEvent {
  const FinancialCalendarEvent({
    required this.date,
    required this.title,
    required this.amount,
    required this.type,
    required this.isConfirmed,
    this.merchantKey,
    this.recurrenceLabel,
    this.notes,
  });

  final DateTime date;
  final String title;
  final double amount;
  final FinancialCalendarEventType type;
  final bool isConfirmed;
  final String? merchantKey;
  final String? recurrenceLabel;
  final String? notes;
}

@immutable
class FinancialCalendarWeek {
  const FinancialCalendarWeek({
    required this.weekStart,
    required this.events,
  });

  final DateTime weekStart;
  final List<FinancialCalendarEvent> events;

  double get totalDue => events.fold(0, (s, e) => s + e.amount);
  int get eventCount => events.length;
}

@immutable
class FinancialCalendarMonth {
  const FinancialCalendarMonth({
    required this.year,
    required this.month,
    required this.events,
    required this.weeks,
  });

  final int year;
  final int month;
  final List<FinancialCalendarEvent> events;
  final List<FinancialCalendarWeek> weeks;

  double get totalDue => events.fold(0, (s, e) => s + e.amount);
  double get confirmedTotal =>
      events.where((e) => e.isConfirmed).fold(0, (s, e) => s + e.amount);
  int get eventCount => events.length;

  FinancialCalendarEvent? get largestPayment => events.isEmpty
      ? null
      : events.reduce((a, b) => a.amount >= b.amount ? a : b);

  String get label {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[month - 1]} $year';
  }
}

@immutable
class FinancialCalendar {
  const FinancialCalendar({
    required this.months,
    required this.totalDueThisWeek,
    required this.totalDueThisMonth,
    required this.upcomingCount,
    this.currentMonth,
    this.next7Days = const [],
    this.next30Days = const [],
    this.largestUpcoming,
  });

  final List<FinancialCalendarMonth> months;
  final FinancialCalendarMonth? currentMonth;
  final List<FinancialCalendarEvent> next7Days;
  final List<FinancialCalendarEvent> next30Days;
  final double totalDueThisWeek;
  final double totalDueThisMonth;
  final FinancialCalendarEvent? largestUpcoming;
  final int upcomingCount;
}
