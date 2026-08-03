// Defines SIPCalculation for Step-Up SIP projections using horizon-based return rates.

import 'package:flutter/foundation.dart';
import '../value_objects/money.dart';
import '../value_objects/time_horizon.dart';

/// A Step-Up SIP projection result including FV and optional Monte Carlo band.
@immutable
class SIPCalculation {
  /// Initial monthly SIP amount (should be ≤ 10% of discretionary income).
  final Money m0;

  /// Annual step-up rate as a fraction (default 0.10 = 10%).
  final double stepUpRate;

  final TimeHorizon horizon;

  /// Expected annualised return rate (horizon-based, see [returnRateForHorizon]).
  final double expectedReturn;

  /// Projected future value using the Step-Up SIP formula.
  final Money projectedFV;

  /// 85th-percentile Monte Carlo future value. Null until Monte Carlo engine is built.
  final Money? monteCarlo85;

  const SIPCalculation({
    required this.m0,
    required this.stepUpRate,
    required this.horizon,
    required this.expectedReturn,
    required this.projectedFV,
    this.monteCarlo85,
  });

  /// Returns the horizon-based expected annual return rate.
  /// < 12 months → 7%, 12–36 months → 8%, 36–60 months → 10%, > 60 months → 12%.
  static double returnRateForHorizon(TimeHorizon horizon) {
    if (horizon.months < 12) return 0.07;
    if (horizon.months <= 36) return 0.08;
    if (horizon.months <= 60) return 0.10;
    return 0.12;
  }

  SIPCalculation copyWith({
    Money? m0,
    double? stepUpRate,
    TimeHorizon? horizon,
    double? expectedReturn,
    Money? projectedFV,
    Money? monteCarlo85,
  }) =>
      SIPCalculation(
        m0: m0 ?? this.m0,
        stepUpRate: stepUpRate ?? this.stepUpRate,
        horizon: horizon ?? this.horizon,
        expectedReturn: expectedReturn ?? this.expectedReturn,
        projectedFV: projectedFV ?? this.projectedFV,
        monteCarlo85: monteCarlo85 ?? this.monteCarlo85,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SIPCalculation &&
          other.m0 == m0 &&
          other.stepUpRate == stepUpRate &&
          other.horizon == horizon &&
          other.expectedReturn == expectedReturn &&
          other.projectedFV == projectedFV);

  @override
  int get hashCode => Object.hash(m0, stepUpRate, horizon, expectedReturn, projectedFV);

  @override
  String toString() =>
      'SIPCalculation(m0: $m0, stepUpRate: ${(stepUpRate * 100).toStringAsFixed(0)}%, '
      'horizon: ${horizon.label}, projectedFV: $projectedFV)';
}
