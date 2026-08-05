import '../../../domain/reasoning/policy/policy_decision.dart';
import '../../../domain/reasoning/policy/policy_state_record.dart';
import '../../../domain/reasoning/policy/user_archetype.dart';
import '../../../domain/shared/financial_facts.dart';

/// Domain service that produces a [PolicyDecision] from user context.
///
/// Invariants:
/// - Always returns a non-null [PolicyDecision] — fallback to conservative default
///   when inputs are insufficient. Never throws on valid inputs.
/// - Given the same inputs, always returns the same [PolicyDecision] (deterministic).
/// - Does not persist state. [PolicyStateRepository] handles persistence separately.
/// - Does not call other engines. All inputs arrive as value objects.
abstract class PolicySelector {
  String get engineVersion;

  /// Select the best-matching [DecisionPolicy] for the given user context.
  ///
  /// [facts]            — current financial facts (income, EF, debt, age, etc.)
  /// [archetype]        — user's employment classification (from profile or inferred)
  /// [existingRecord]   — persisted policy state, if any; null on first selection
  ///
  /// Returns a [PolicyDecision] with the selected policy, full explainability,
  /// matched conditions, confidence score, and any active modifiers.
  PolicyDecision select({
    required FinancialFacts facts,
    required UserArchetype archetype,
    PolicyStateRecord? existingRecord,
  });

  /// All policy IDs known to this selector.
  /// Used by automated validation to verify evolution graph has no cycles.
  List<String> get allPolicyIds;

  /// All evolution rules known to this selector.
  /// Used by automated validation to verify the evolution graph.
  List<String> get evolutionEdges; // format: 'fromId -> toId'
}
