import '../decision/decision_type.dart';
import 'match_result.dart';
import 'matching_context.dart';
import 'partner_program.dart';
import 'rejection_reason.dart';

/// Encapsulates recommendation rules for a specific financial goal type.
///
/// Each policy answers two questions:
/// 1. Should this program be rejected outright?  → [reject]
/// 2. If not rejected, how well does it fit?    → [evaluate]
///
/// Policies are composable — the engine dispatches to the policy whose
/// [targetGoals] contains [MatchingContext.primaryGoal].
///
/// Design rule: policies know products and goals. They do NOT know users
/// beyond what [MatchingContext] exposes. Deep user knowledge lives in the
/// Behavioral Engine and Digital Twin.
abstract class MatchingPolicy {
  /// The goal types this policy handles.
  Set<DecisionType> get targetGoals;

  /// Returns a [RejectionReason] if [program] should be excluded for [context],
  /// or null if it may proceed to evaluation.
  ///
  /// Rejection is a hard filter — rejected programs are never shown even if
  /// they would score highly. Use it for fiduciary exclusions:
  /// lock-in vs emergency fund, volatility vs short horizon, etc.
  RejectionReason? reject(PartnerProgram program, MatchingContext context);

  /// Evaluates the fit of [program] for [context] and returns a [MatchResult].
  ///
  /// Returns null if this policy cannot score this program (e.g. wrong
  /// instrument type). The engine will apply a default score in that case.
  MatchResult? evaluate(PartnerProgram program, MatchingContext context);
}
