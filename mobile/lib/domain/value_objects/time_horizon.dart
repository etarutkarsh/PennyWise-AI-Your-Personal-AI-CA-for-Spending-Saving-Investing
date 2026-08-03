// Defines the TimeHorizon value object for goal and investment durations.

import 'package:flutter/foundation.dart';

/// An immutable investment or goal time horizon measured in months.
@immutable
class TimeHorizon {
  final int months;

  const TimeHorizon._(this.months) : assert(months > 0, 'TimeHorizon months must be positive');

  /// Creates a TimeHorizon from a number of months.
  factory TimeHorizon.months(int months) => TimeHorizon._(months);

  /// Creates a TimeHorizon from a number of years (converted to months).
  factory TimeHorizon.years(int years) => TimeHorizon._(years * 12);

  /// Parses a human-readable label such as "24 months", "3 years", or "P24M".
  /// Falls back to 24 months if no valid number is found.
  factory TimeHorizon.fromLabel(String label) {
    final match = RegExp(r'(\d+)').firstMatch(label);
    if (match != null) {
      final n = int.parse(match.group(1)!);
      if (n <= 0) return TimeHorizon._(24);
      if (label.toLowerCase().contains('year')) return TimeHorizon._(n * 12);
      return TimeHorizon._(n);
    }
    return TimeHorizon._(24);
  }

  double get inYears => months / 12.0;

  /// Human-readable label: "2 years", "18 months", "1 year".
  String get label {
    if (months < 12) return '$months month${months == 1 ? '' : 's'}';
    if (months % 12 == 0) {
      final y = months ~/ 12;
      return '$y year${y == 1 ? '' : 's'}';
    }
    final y = months ~/ 12;
    final m = months % 12;
    return '$y year${y == 1 ? '' : 's'} $m month${m == 1 ? '' : 's'}';
  }

  /// Less than 12 months.
  bool get isShortTerm => months < 12;

  /// 12 to 60 months (inclusive).
  bool get isMediumTerm => months >= 12 && months <= 60;

  /// More than 60 months.
  bool get isLongTerm => months > 60;

  TimeHorizon copyWith({int? months}) => TimeHorizon._(months ?? this.months);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TimeHorizon && other.months == months);

  @override
  int get hashCode => months.hashCode;

  @override
  String toString() => 'TimeHorizon($label)';
}
