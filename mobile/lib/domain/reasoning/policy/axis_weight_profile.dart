import 'package:flutter/foundation.dart';

/// Typed exception for axis weight invariant violations.
@immutable
class PolicyWeightViolation implements Exception {
  const PolicyWeightViolation(this.message);
  final String message;
  @override
  String toString() => 'PolicyWeightViolation: $message';
}

/// Per-axis weight configuration for the 6 decision axes.
///
/// Replaces the compile-time constant [DecisionAxis.weight] with a runtime
/// value object that varies by user archetype and financial maturity state.
///
/// Invariants (enforced by [AxisWeightProfile.validated]):
/// - All six weights ∈ [0.02, 0.55]
/// - Sum of all six weights == 1.0 (±0.001 floating-point tolerance)
/// - No duplicate axes (structural — Dart named fields prevent this)
///
/// The 0.02 floor is a fiduciary safeguard: every axis must contribute signal
/// even when its domain concern is minimal for the user archetype. Silencing
/// an axis entirely removes its explainability contribution.
///
/// The 0.55 ceiling prevents degenerate single-axis collapse where one axis
/// drowns out all others.
@immutable
class AxisWeightProfile {
  const AxisWeightProfile._({
    required this.cashFlow,
    required this.liquidity,
    required this.goalImpact,
    required this.behavior,
    required this.taxes,
    required this.opportunityCost,
  });

  final double cashFlow;
  final double liquidity;
  final double goalImpact;
  final double behavior;
  final double taxes;
  final double opportunityCost;

  static const double _minWeight = 0.02;
  static const double _maxWeight = 0.55;
  static const double _sumTarget = 1.0;
  static const double _sumTolerance = 0.001;

  /// Validated constructor — throws [PolicyWeightViolation] on any invariant breach.
  factory AxisWeightProfile.validated({
    required double cashFlow,
    required double liquidity,
    required double goalImpact,
    required double behavior,
    required double taxes,
    required double opportunityCost,
  }) {
    final weights = {
      'cashFlow': cashFlow,
      'liquidity': liquidity,
      'goalImpact': goalImpact,
      'behavior': behavior,
      'taxes': taxes,
      'opportunityCost': opportunityCost,
    };

    for (final entry in weights.entries) {
      if (entry.value < _minWeight) {
        throw PolicyWeightViolation(
          '${entry.key} weight ${entry.value} is below minimum floor $_minWeight',
        );
      }
      if (entry.value > _maxWeight) {
        throw PolicyWeightViolation(
          '${entry.key} weight ${entry.value} exceeds maximum ceiling $_maxWeight',
        );
      }
    }

    final sum = cashFlow + liquidity + goalImpact + behavior + taxes + opportunityCost;
    if ((sum - _sumTarget).abs() > _sumTolerance) {
      throw PolicyWeightViolation(
        'Weights sum to ${sum.toStringAsFixed(4)}, expected 1.0 (±$_sumTolerance). '
        'Values: CF=$cashFlow LQ=$liquidity GI=$goalImpact BH=$behavior TX=$taxes OC=$opportunityCost',
      );
    }

    return AxisWeightProfile._(
      cashFlow: cashFlow,
      liquidity: liquidity,
      goalImpact: goalImpact,
      behavior: behavior,
      taxes: taxes,
      opportunityCost: opportunityCost,
    );
  }

  double get sum => cashFlow + liquidity + goalImpact + behavior + taxes + opportunityCost;

  /// True when the profile satisfies all invariants (sum ≈ 1.0, all within bounds).
  bool get isValid {
    final allInBounds = [cashFlow, liquidity, goalImpact, behavior, taxes, opportunityCost]
        .every((w) => w >= _minWeight && w <= _maxWeight);
    return allInBounds && (sum - _sumTarget).abs() <= _sumTolerance;
  }

  /// Apply a [PolicyModifier]'s weight deltas. Returns a new validated profile.
  /// Throws [PolicyWeightViolation] if the result violates invariants.
  AxisWeightProfile applyDeltas({
    double cashFlowDelta = 0.0,
    double liquidityDelta = 0.0,
    double goalImpactDelta = 0.0,
    double behaviorDelta = 0.0,
    double taxesDelta = 0.0,
    double opportunityCostDelta = 0.0,
  }) {
    return AxisWeightProfile.validated(
      cashFlow: cashFlow + cashFlowDelta,
      liquidity: liquidity + liquidityDelta,
      goalImpact: goalImpact + goalImpactDelta,
      behavior: behavior + behaviorDelta,
      taxes: taxes + taxesDelta,
      opportunityCost: opportunityCost + opportunityCostDelta,
    );
  }

  Map<String, double> toMap() => {
        'cashFlow': cashFlow,
        'liquidity': liquidity,
        'goalImpact': goalImpact,
        'behavior': behavior,
        'taxes': taxes,
        'opportunityCost': opportunityCost,
      };

  @override
  String toString() =>
      'AxisWeightProfile(CF=$cashFlow, LQ=$liquidity, GI=$goalImpact, '
      'BH=$behavior, TX=$taxes, OC=$opportunityCost, sum=${sum.toStringAsFixed(3)})';
}
