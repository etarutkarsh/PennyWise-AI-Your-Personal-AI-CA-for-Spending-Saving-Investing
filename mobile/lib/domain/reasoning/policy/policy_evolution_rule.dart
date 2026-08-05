import 'package:flutter/foundation.dart';

/// Comparison operator for [PolicyCondition].
enum ConditionOp {
  greaterThan,
  lessThan,
  greaterThanOrEqual,
  lessThanOrEqual,
  equals;

  bool evaluate(double actual, double threshold) => switch (this) {
        ConditionOp.greaterThan => actual > threshold,
        ConditionOp.lessThan => actual < threshold,
        ConditionOp.greaterThanOrEqual => actual >= threshold,
        ConditionOp.lessThanOrEqual => actual <= threshold,
        ConditionOp.equals => (actual - threshold).abs() < 0.001,
      };
}

/// Whether all conditions must be true or any one condition is sufficient.
enum EvolutionEvalMode { allConditions, anyCondition }

/// A single measurable condition on a named [FinancialFacts] fact.
///
/// [factKey] maps to a fact value accessor:
/// - `emergencyFundMonths` → FinancialFacts.emergencyFundMonthsValue
/// - `debtRatio`           → FinancialFacts.debtRatioValue
/// - `savingsRate`         → FinancialFacts.savingsRateValue
/// - `taxEfficiency`       → FinancialFacts.taxEfficiencyValue
/// - `healthScore`         → FinancialFacts.healthScoreValue
/// - `ageYears`            → FinancialFacts.ageYearsValue (as double)
@immutable
class PolicyCondition {
  const PolicyCondition({
    required this.factKey,
    required this.operator,
    required this.threshold,
    this.sustainedDays,
  });

  final String factKey;
  final ConditionOp operator;
  final double threshold;

  /// If set, the condition must be true for this many consecutive days before
  /// triggering. Prevents false promotions from a single good month.
  final int? sustainedDays;

  bool evaluate(double actualValue) => operator.evaluate(actualValue, threshold);

  String get humanReadable {
    final op = switch (operator) {
      ConditionOp.greaterThan => '>',
      ConditionOp.lessThan => '<',
      ConditionOp.greaterThanOrEqual => '≥',
      ConditionOp.lessThanOrEqual => '≤',
      ConditionOp.equals => '=',
    };
    final sustained =
        sustainedDays != null ? ' (sustained ${sustainedDays}d)' : '';
    return '$factKey $op $threshold$sustained';
  }
}

/// Defines when and how the policy engine automatically advances a user
/// to a better (or protective) policy.
///
/// Evolution is primarily forward (Survive → Stabilize → Build → Optimize).
/// Protective downgrades also use this type — they have no [sustainedDays]
/// requirement and fire immediately when conditions are met.
@immutable
class PolicyEvolutionRule {
  const PolicyEvolutionRule({
    required this.triggerId,
    required this.description,
    required this.fromPolicyId,
    required this.toPolicyId,
    required this.conditions,
    required this.evaluationMode,
    required this.graduationLabel,
    this.isProtectiveDowngrade = false,
  });

  /// Unique identifier for this rule. Used in [PolicyStateRecord] to record
  /// which rule triggered the last transition.
  final String triggerId;

  /// Human-readable description of the trigger (internal, not user-facing).
  final String description;

  final String fromPolicyId;
  final String toPolicyId;
  final List<PolicyCondition> conditions;
  final EvolutionEvalMode evaluationMode;

  /// User-facing message shown when this rule fires.
  /// e.g. "You've built a 3-month safety net. Now tackle high-interest debt."
  final String graduationLabel;

  /// True for protective downgrade rules (e.g. EF collapse, debt spike).
  /// Downgrade rules have no sustain requirement and fire immediately.
  final bool isProtectiveDowngrade;

  /// Evaluate whether this rule should fire given a map of fact values.
  /// [factValues] maps factKey → current value from FinancialFacts.
  bool shouldFire(Map<String, double> factValues) {
    final results = conditions.map((c) {
      final value = factValues[c.factKey];
      if (value == null) return false;
      return c.evaluate(value);
    }).toList();

    return switch (evaluationMode) {
      EvolutionEvalMode.allConditions => results.every((r) => r),
      EvolutionEvalMode.anyCondition => results.any((r) => r),
    };
  }
}
