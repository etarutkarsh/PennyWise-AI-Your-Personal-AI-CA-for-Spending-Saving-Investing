import 'package:flutter/foundation.dart';

/// Regulatory and suitability metadata for a financial product.
///
/// This is what matters to a fiduciary: not just returns, but
/// lock-in, liquidity, tax treatment, capital safety, and regulator.
/// Structured now so real AMC/bank data can be ingested without
/// schema changes when partner agreements are signed.
@immutable
class ProductMetadata {
  const ProductMetadata({
    required this.regulator,
    required this.taxTreatment,
    required this.lockInDays,
    required this.minHorizonMonths,
    this.maxHorizonMonths = 0,
    this.exitLoadPercent = 0.0,
    required this.liquidityScore,
    required this.capitalGuarantee,
    required this.returnType,
    required this.suitableForGoalTypes,
    this.notSuitableForGoalTypes = const [],
    required this.disclaimer,
  });

  /// Regulatory authority: 'SEBI', 'RBI', 'IRDAI', 'PFRDA', 'Self-regulated'.
  final String regulator;

  /// Tax treatment description for the user.
  /// e.g. 'Interest taxable as income', 'LTCG 10% after 1 year',
  /// 'Exempt under Section 80C (up to ₹1.5L)', 'EEE — fully tax-free'
  final String taxTreatment;

  /// Mandatory lock-in in days. 0 = no lock-in.
  final int lockInDays;

  /// Minimum suitable investment horizon in months.
  /// Recommending below this horizon is penalised.
  final int minHorizonMonths;

  /// Maximum suitable investment horizon in months. 0 = no upper limit.
  final int maxHorizonMonths;

  /// Exit load as a percentage (e.g. 1.0 = 1%). 0.0 = no exit load.
  final double exitLoadPercent;

  /// Liquidity score 0.0–1.0.
  /// 1.0 = T+1 redemption (liquid fund), 0.0 = fully locked (PPF, pension).
  final double liquidityScore;

  /// True if principal is protected by a regulated institution.
  final bool capitalGuarantee;

  /// 'Guaranteed', 'Market-linked', 'Inflation-linked'.
  final String returnType;

  /// DecisionType names this product is suitable for.
  /// e.g. ['buildEmergencyFund', 'increaseSavingsRate']
  final List<String> suitableForGoalTypes;

  /// DecisionType names this product is explicitly NOT suitable for.
  final List<String> notSuitableForGoalTypes;

  /// SEBI / AMFI mandated risk disclaimer to be shown with the product.
  final String disclaimer;

  /// Convenience: lock-in duration in months (rounded).
  int get lockInMonths => (lockInDays / 30).ceil();

  /// Convenience: is there a meaningful lock-in (more than 7 days)?
  bool get hasLockIn => lockInDays > 7;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductMetadata &&
          other.regulator == regulator &&
          other.lockInDays == lockInDays &&
          other.liquidityScore == liquidityScore);

  @override
  int get hashCode =>
      Object.hash(regulator, lockInDays, liquidityScore);
}
