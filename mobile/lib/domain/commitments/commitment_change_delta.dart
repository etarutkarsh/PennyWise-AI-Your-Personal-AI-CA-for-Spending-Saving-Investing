import 'package:flutter/foundation.dart';

@immutable
class CommitmentPriceChange {
  const CommitmentPriceChange({
    required this.merchantKey,
    required this.displayName,
    required this.previousAmount,
    required this.currentAmount,
  });

  final String merchantKey;
  final String displayName;
  final double previousAmount;
  final double currentAmount;

  double get changeAmount => currentAmount - previousAmount;
  double get changePercent => previousAmount > 0
      ? ((currentAmount - previousAmount) / previousAmount) * 100
      : 0.0;
  bool get isIncrease => currentAmount > previousAmount;
}

@immutable
class CommitmentChangeDelta {
  const CommitmentChangeDelta({
    required this.newCommitmentNames,
    required this.removedCommitmentNames,
    required this.priceChanges,
    required this.netMonthlyChange,
    required this.annualChangeImpact,
    required this.detectedAt,
    this.healthGradeChanged = false,
  });

  final List<String> newCommitmentNames;
  final List<String> removedCommitmentNames;
  final List<CommitmentPriceChange> priceChanges;
  final double netMonthlyChange;
  final double annualChangeImpact;
  final DateTime detectedAt;
  final bool healthGradeChanged;

  bool get hasChanges =>
      newCommitmentNames.isNotEmpty ||
      removedCommitmentNames.isNotEmpty ||
      priceChanges.isNotEmpty;

  bool get isNetPositive => netMonthlyChange < 0;
}
