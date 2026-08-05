import 'package:flutter/foundation.dart';

import 'axis_weight_profile.dart';
import 'lifecycle_stage.dart';
import 'policy_evolution_rule.dart';
import 'policy_modifier.dart';
import 'policy_thresholds.dart';
import 'user_archetype.dart';

/// The primary output of the Policy Engine. Carries the axis weight profile for
/// a specific user context plus the metadata explaining why this policy was selected.
///
/// [DecisionPolicy] is immutable. It is never mutated — evolution produces a
/// new policy via [PolicyEvolutionRule], never by updating an existing instance.
///
/// All instances are created by [RuleBasedPolicySelector] using the 14 named
/// factory configurations defined in that class.
@immutable
class DecisionPolicy {
  const DecisionPolicy({
    required this.id,
    required this.name,
    required this.archetype,
    required this.lifecycleStage,
    required this.weights,
    required this.thresholds,
    required this.evolutionRules,
    required this.selectionReason,
    required this.schemaVersion,
    required this.effectiveAt,
    required this.priority,
    required this.activationCriteria,
    this.appliedModifiers = const [],
  });

  /// Unique identifier. Format: '{archetype}_{state}_v{n}' e.g. 'freelancer_survive_v1'.
  final String id;

  /// Human-readable name. e.g. 'Freelancer — Survive'
  final String name;

  final UserArchetype archetype;
  final LifecycleStage lifecycleStage;

  /// Axis weights for this policy. Invariant: weights.sum ≈ 1.0.
  final AxisWeightProfile weights;

  /// Numerical thresholds for axis health checks (EF target, debt limits, etc.).
  final PolicyThresholds thresholds;

  /// Rules that trigger graduation to a new policy. Must be non-empty.
  final List<PolicyEvolutionRule> evolutionRules;

  /// Explainability string: why this policy was selected.
  /// e.g. 'Selected because: irregular income detected, FinancialState.survive'
  final String selectionReason;

  final String schemaVersion;

  /// When this policy became effective for the current user context.
  final DateTime effectiveAt;

  /// Priority for deterministic resolution when multiple policies match.
  /// Higher value wins. Emergency/crisis policies carry the highest priority.
  /// See [RuleBasedPolicySelector] for the full priority table.
  final int priority;

  /// Declarative description of when this policy activates, exits, and evolves.
  final PolicyActivationCriteria activationCriteria;

  /// Active modifiers applied on top of the base weights (e.g. impulseWindow, taxSeason).
  /// Empty list means base policy weights are in effect unchanged.
  final List<PolicyModifier> appliedModifiers;

  /// Returns this policy with the given [modifier] applied.
  /// The resulting [weights] reflect the modifier's deltas.
  /// Throws [PolicyWeightViolation] if the modifier violates weight invariants.
  DecisionPolicy withModifier(PolicyModifier modifier) {
    return DecisionPolicy(
      id: id,
      name: name,
      archetype: archetype,
      lifecycleStage: lifecycleStage,
      weights: weights.applyDeltas(
        cashFlowDelta: modifier.cashFlowDelta,
        liquidityDelta: modifier.liquidityDelta,
        goalImpactDelta: modifier.goalImpactDelta,
        behaviorDelta: modifier.behaviorDelta,
        taxesDelta: modifier.taxesDelta,
        opportunityCostDelta: modifier.opportunityCostDelta,
      ),
      thresholds: thresholds,
      evolutionRules: evolutionRules,
      selectionReason: selectionReason,
      schemaVersion: schemaVersion,
      effectiveAt: effectiveAt,
      priority: priority,
      activationCriteria: activationCriteria,
      appliedModifiers: [...appliedModifiers, modifier],
    );
  }

  /// Evaluate all evolution rules against current fact values.
  /// Returns the first matching rule, or null if none match.
  PolicyEvolutionRule? checkEvolution(Map<String, double> factValues) {
    for (final rule in evolutionRules) {
      if (rule.shouldFire(factValues)) return rule;
    }
    return null;
  }

  @override
  String toString() => 'DecisionPolicy($id, priority=$priority)';
}

/// Declarative description of a policy's activation lifecycle.
/// Powers explainability: "This policy activates when..." and "exits when..."
@immutable
class PolicyActivationCriteria {
  const PolicyActivationCriteria({
    required this.eligibilityDescription,
    required this.activationDescription,
    required this.exitDescription,
    required this.evolutionDescription,
  });

  /// When is a user eligible for this policy?
  /// e.g. 'Salaried employee in the Survive financial state'
  final String eligibilityDescription;

  /// What triggers activation?
  /// e.g. 'emergencyFundMonths < 6.0 and no high-interest debt cleared'
  final String activationDescription;

  /// What causes this policy to exit (graduate to next)?
  /// e.g. 'emergencyFundMonths >= 6.0 sustained for 30 days and debtRatio <= 0.30'
  final String exitDescription;

  /// What does the next policy look like?
  /// e.g. 'Graduates to SalariedBuild when foundation requirements are met'
  final String evolutionDescription;
}
