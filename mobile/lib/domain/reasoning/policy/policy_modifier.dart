import 'package:flutter/foundation.dart';

/// A temporary or conditional overlay applied on top of a base [DecisionPolicy].
///
/// Modifiers adjust axis weights and thresholds without replacing the whole policy.
/// They are applied post-selection and revert automatically when the triggering
/// condition exits (e.g., impulseWindow, taxSeason).
///
/// Invariant: the sum of all [weightDeltas] must equal 0.0 (±0.001) — a modifier
/// redistributes weight, it does not add or remove it from the pool.
@immutable
class PolicyModifier {
  const PolicyModifier({
    required this.id,
    required this.name,
    required this.condition,
    required this.cashFlowDelta,
    required this.liquidityDelta,
    required this.goalImpactDelta,
    required this.behaviorDelta,
    required this.taxesDelta,
    required this.opportunityCostDelta,
    this.thresholdOverrides = const {},
  });

  final String id;
  final String name;

  /// Human-readable description of the condition that activated this modifier.
  /// e.g. "Impulse window detected — behavior weight elevated"
  final String condition;

  // Weight deltas — positive means more weight to this axis.
  final double cashFlowDelta;
  final double liquidityDelta;
  final double goalImpactDelta;
  final double behaviorDelta;
  final double taxesDelta;
  final double opportunityCostDelta;

  /// Optional threshold overrides — maps PolicyThresholds field name → new value.
  final Map<String, double> thresholdOverrides;

  double get deltaSum =>
      cashFlowDelta +
      liquidityDelta +
      goalImpactDelta +
      behaviorDelta +
      taxesDelta +
      opportunityCostDelta;

  /// True when modifier satisfies the zero-sum invariant (redistributes, not adds).
  bool get isZeroSum => deltaSum.abs() < 0.001;

  // ── Named modifiers (Section 7.3 of design spec) ──────────────────────────

  static const PolicyModifier impulseWindow = PolicyModifier(
    id: 'impulse_window',
    name: 'Impulse Window',
    condition: 'Impulse window detected — behaviour weight elevated',
    cashFlowDelta: 0.0,
    liquidityDelta: 0.0,
    goalImpactDelta: 0.0,
    behaviorDelta: 0.05,
    taxesDelta: 0.0,
    opportunityCostDelta: -0.05,
  );

  static const PolicyModifier highLiquidity = PolicyModifier(
    id: 'high_liquidity',
    name: 'High Liquidity',
    condition: 'Above-target liquidity — opportunity cost signal elevated',
    cashFlowDelta: 0.0,
    liquidityDelta: -0.03,
    goalImpactDelta: 0.0,
    behaviorDelta: 0.0,
    taxesDelta: 0.0,
    opportunityCostDelta: 0.03,
  );

  static const PolicyModifier taxSeason = PolicyModifier(
    id: 'tax_season',
    name: 'Tax Season (Feb–Mar)',
    condition: 'Tax season active — tax efficiency weight elevated for Q4 deadline',
    cashFlowDelta: -0.07,
    liquidityDelta: 0.0,
    goalImpactDelta: 0.0,
    behaviorDelta: 0.0,
    taxesDelta: 0.07,
    opportunityCostDelta: 0.0,
  );

  static const PolicyModifier festiveSeason = PolicyModifier(
    id: 'festive_season',
    name: 'Festive Season (Oct)',
    condition: 'Festive season active — cash flow monitoring elevated',
    cashFlowDelta: 0.04,
    liquidityDelta: 0.0,
    goalImpactDelta: 0.0,
    behaviorDelta: 0.0,
    taxesDelta: 0.0,
    opportunityCostDelta: -0.04,
  );

  static const PolicyModifier familyObligation = PolicyModifier(
    id: 'family_obligation',
    name: 'Family Obligation Overlay',
    condition: 'Significant family financial obligations detected',
    cashFlowDelta: 0.0,
    liquidityDelta: 0.0,
    goalImpactDelta: 0.05,
    behaviorDelta: 0.0,
    taxesDelta: 0.0,
    opportunityCostDelta: -0.05,
  );
}
