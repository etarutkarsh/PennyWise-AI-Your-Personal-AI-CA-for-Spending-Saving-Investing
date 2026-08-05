import 'package:flutter/foundation.dart';

/// Numerical parameters that accompany a [DecisionPolicy].
///
/// Different policies use different threshold values for the same facts — a
/// freelancer's "acceptable" emergency fund is 9 months, not 6. These thresholds
/// override hardcoded values in the axis analyzers.
///
/// All thresholds are positive. Rationale per field is documented inline.
@immutable
class PolicyThresholds {
  const PolicyThresholds({
    required this.emergencyFundTargetMonths,
    required this.minSavingsRate,
    required this.safeDebtRatio,
    required this.criticalDebtRatio,
    required this.taxEfficiencyTarget,
    required this.minOpportunityCostRate,
    required this.behaviorMinimumConsistency,
  });

  /// EF coverage that scores 1.0 on the liquidity axis.
  /// Student=3.0, Salaried=6.0, Freelancer/Business=9.0, Retired=24.0
  final double emergencyFundTargetMonths;

  /// Savings rate below which the cash flow axis signals a penalty.
  /// Retired=0.0 (distribution phase), Student=0.05, Optimize=0.20+
  final double minSavingsRate;

  /// EMI/income ratio above which the debt component activates a penalty.
  final double safeDebtRatio;

  /// EMI/income ratio above which the liquidity axis signals a blocking condition.
  /// Must be > [safeDebtRatio].
  final double criticalDebtRatio;

  /// 80C utilisation rate that scores 1.0 on the tax axis.
  /// Student=0.30 (80C barely relevant), Optimize=0.90+
  final double taxEfficiencyTarget;

  /// Minimum investment ratio to avoid opportunity cost penalty.
  final double minOpportunityCostRate;

  /// Behavioral consistency score below which the behavior axis signals a warning.
  final double behaviorMinimumConsistency;

  /// Convenience: true when debt is approaching the critical threshold.
  bool isDebtCritical(double debtRatio) => debtRatio >= criticalDebtRatio;

  /// Convenience: true when EF is below the safe floor (< 1 month).
  bool isEmergencyFundCritical(double efMonths) => efMonths < 1.0;

  @override
  String toString() =>
      'PolicyThresholds(EF=${emergencyFundTargetMonths}mo, '
      'minSR=$minSavingsRate, safeDebt=$safeDebtRatio, '
      'critDebt=$criticalDebtRatio, taxTarget=$taxEfficiencyTarget)';
}
