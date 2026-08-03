import 'package:flutter/foundation.dart';

/// Represents the gap between chronological age and financial behavior age.
/// Financial Age answers: "How old does your money behavior make you?"
/// A 28-year-old with no emergency fund, high debt, and no investments may
/// have a Financial Age of 41. A 35-year-old with high savings and diversified
/// portfolio may have a Financial Age of 26.
@immutable
class FinancialAge {
  final int chronologicalAge;
  final int financialAge;

  /// The behaviors/dimensions that explain the gap.
  final List<String> drivers;

  /// Human-readable message explaining the gap.
  final String insight;

  final String engineVersion;
  final DateTime computedAt;

  const FinancialAge({
    required this.chronologicalAge,
    required this.financialAge,
    required this.drivers,
    required this.insight,
    required this.engineVersion,
    required this.computedAt,
  });

  /// Positive = financially older than chronological (bad).
  /// Negative = financially younger than chronological (good).
  int get gap => financialAge - chronologicalAge;

  bool get isOlderThanAge => gap > 0;
  bool get isYoungerThanAge => gap < 0;
  bool get isAligned => gap == 0;

  String get gapLabel {
    final abs = gap.abs();
    if (abs == 0) return 'On Track';
    if (isOlderThanAge) return '+$abs years behind';
    return '${abs} years ahead';
  }

  String get displayLabel =>
      'Age $chronologicalAge / Financial Age $financialAge';

  @override
  String toString() =>
      'FinancialAge(chrono: $chronologicalAge, financial: $financialAge, gap: $gap)';
}
