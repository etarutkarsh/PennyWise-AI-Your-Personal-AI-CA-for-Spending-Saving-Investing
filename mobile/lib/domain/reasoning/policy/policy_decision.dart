import 'package:flutter/foundation.dart';

import 'decision_policy.dart';
import 'lifecycle_stage.dart';

/// The result type returned by [PolicySelector.select].
///
/// Returns the selected [DecisionPolicy] together with full explainability:
/// why this policy was chosen, which conditions matched, how confident the
/// selector is, and whether a fallback was used.
///
/// This object becomes part of [ReasoningMemory] — the full chain of reasoning
/// stored per pipeline execution.
@immutable
class PolicyDecision {
  const PolicyDecision({
    required this.policy,
    required this.policyId,
    required this.policyLabel,
    required this.reason,
    required this.matchedConditions,
    required this.confidence,
    required this.fallbackUsed,
    this.activeModifiers = const [],
    this.conflictingPolicies = const [],
    this.conflictResolution,
  });

  /// The selected policy carrying axis weights, thresholds, and evolution rules.
  final DecisionPolicy policy;

  /// The policy's unique identifier. Redundant with [policy.id] but surfaced
  /// at the top level for easy access in [DecisionConfidenceReport] fields.
  final String policyId;

  /// Human-readable label. e.g. 'Freelancer — Survive'
  final String policyLabel;

  /// Why this policy was selected. Full natural-language explanation.
  /// e.g. 'LifecycleStage.retirement overrides all other conditions (age 63)'
  final String reason;

  /// The specific conditions that were evaluated and matched.
  /// Each string describes one condition. Ordered by evaluation precedence.
  final List<String> matchedConditions;

  /// How confident the selector is in this policy selection. 0.0–1.0.
  /// Reduced when:
  /// - archetype was inferred (not set by user profile): -0.10
  /// - fallback was used: -0.15
  /// - multiple policies matched at the same priority level: -0.05
  final double confidence;

  /// True when the selector could not determine the precise correct policy and
  /// applied a conservative default ([salariedWithFamily] + [FinancialState.build]).
  /// A fallback always records an explanation in [reason].
  final bool fallbackUsed;

  /// Modifiers active on top of the selected policy (e.g. taxSeason, impulseWindow).
  final List<String> activeModifiers;

  /// Other policies that were evaluated and considered during selection.
  /// Included for explainability — "we also considered X, Y."
  final List<String> conflictingPolicies;

  /// If multiple policies matched at the same priority, how was conflict resolved?
  /// e.g. 'Retired policy overrides FreelancerBuild — lifecycle stage takes precedence'
  final String? conflictResolution;

  /// True when the policy selection reflects a retirement or pre-retirement
  /// lifecycle override (these always override archetype-based selection).
  bool get isLifecycleOverride =>
      policy.lifecycleStage == LifecycleStage.retirement ||
      policy.lifecycleStage == LifecycleStage.preRetirement;

  /// Summary suitable for inclusion in the explanation panel.
  String get explanationSummary {
    final modText = activeModifiers.isEmpty
        ? ''
        : ' Active modifiers: ${activeModifiers.join(', ')}.';
    final fallbackText = fallbackUsed ? ' (Conservative default applied.)' : '';
    return '$reason$modText$fallbackText';
  }
}
