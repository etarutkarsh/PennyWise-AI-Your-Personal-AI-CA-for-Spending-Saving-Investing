import 'package:flutter/foundation.dart';

@immutable
class RenewalAlert {
  const RenewalAlert({
    required this.merchantKey,
    required this.merchantName,
    required this.expectedDate,
    required this.amount,
    required this.recurrencePeriod,
    required this.daysUntil,
    required this.isAnnual,
  });

  final String merchantKey;
  final String merchantName;
  final DateTime expectedDate;
  final double amount;
  final String recurrencePeriod;
  final int daysUntil;
  final bool isAnnual;

  bool get isUrgent => daysUntil <= 14;
  bool get isSoon => daysUntil <= 30;
}

@immutable
class MonthlyForecast {
  const MonthlyForecast({
    required this.year,
    required this.month,
    required this.expectedTotal,
    required this.contributingCount,
    required this.spikeReasons,
    required this.isSpike,
    required this.cashReserveRequired,
  });

  final int year;
  final int month;
  final double expectedTotal;
  final int contributingCount;
  final List<String> spikeReasons;
  final bool isSpike;
  final double cashReserveRequired;

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
class ForecastResult {
  const ForecastResult({
    required this.monthlyForecasts,
    required this.averageMonthly,
    required this.annualProjection,
    required this.forecastConfidence,
    required this.renewalTimeline,
    required this.cashReserveProjection,
    required this.peakMonth,
    required this.stressWindows,
  });

  final List<MonthlyForecast> monthlyForecasts;
  final double averageMonthly;
  final double annualProjection;
  final double forecastConfidence;
  final List<RenewalAlert> renewalTimeline;
  final double cashReserveProjection;
  final MonthlyForecast peakMonth;
  final List<MonthlyForecast> stressWindows;
}
