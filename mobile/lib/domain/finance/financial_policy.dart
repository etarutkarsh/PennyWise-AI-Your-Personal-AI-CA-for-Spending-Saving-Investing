import 'package:flutter/foundation.dart';

/// Business rules that govern recommendation logic.
/// These values come from backend DecisionResponse in production.
/// The defaults here match the current hardcoded values in TodayDecisionService.java.
@immutable
class FinancialPolicy {
  /// Emergency fund target in months of expenses
  final double emergencyFundTargetMonths;

  /// Minimum savings rate before intervention is triggered
  final double minSavingsRate;

  /// Maximum first SIP as fraction of discretionary income (Fiduciary Manifesto rule)
  final double maxInitialSipFraction;

  /// Annual step-up rate for SIPs (Save More Tomorrow protocol)
  final double defaultSipStepUpRate;

  /// Annual return rate by horizon (months → rate)
  final Map<int, double> returnRateByHorizonMonths;

  /// Health score weights per dimension (must sum to 1.0)
  final Map<String, double> healthScoreWeights;

  const FinancialPolicy({
    this.emergencyFundTargetMonths = 6.0,
    this.minSavingsRate = 0.15,
    this.maxInitialSipFraction = 0.10,
    this.defaultSipStepUpRate = 0.10,
    this.returnRateByHorizonMonths = const {
      12: 0.07, // < 12 months → 7% (RD / Liquid Fund)
      36: 0.08, // 12-36 months → 8% (Debt/Hybrid)
      60: 0.10, // 36-60 months → 10% (Balanced)
      999: 0.12, // > 60 months → 12% (Equity SIP)
    },
    this.healthScoreWeights = const {
      'liquidity': 0.15,
      'debtQuality': 0.15,
      'savingsConsistency': 0.12,
      'goalFunding': 0.12,
      'insuranceCoverage': 0.12,
      'investmentDiversification': 0.10,
      'behavioralConsistency': 0.10,
      'incomeStability': 0.08,
      'financialAnxiety': 0.03,
      'taxEfficiency': 0.03,
    },
  });

  /// Returns the applicable annual return rate for the given horizon.
  double returnRateForMonths(int months) {
    final sortedKeys = returnRateByHorizonMonths.keys.toList()..sort();
    for (final threshold in sortedKeys) {
      if (months <= threshold) return returnRateByHorizonMonths[threshold]!;
    }
    return 0.12;
  }

  static const FinancialPolicy current = FinancialPolicy();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialPolicy &&
          emergencyFundTargetMonths == other.emergencyFundTargetMonths &&
          minSavingsRate == other.minSavingsRate;

  @override
  int get hashCode =>
      emergencyFundTargetMonths.hashCode ^ minSavingsRate.hashCode;
}
