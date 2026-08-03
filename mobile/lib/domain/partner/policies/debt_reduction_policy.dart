import '../../decision/decision_type.dart';
import '../match_result.dart';
import '../matching_context.dart';
import '../matching_policy.dart';
import '../partner_program.dart';
import '../rejection_reason.dart';

/// Recommendation policy for reducing high-interest debt.
///
/// Stub implementation — Phase 4 will implement:
/// - Debt waterfall prioritisation (highest APR first)
/// - Debt consolidation feasibility check
/// - Reject any investment when debt APR > expected investment return
///   (e.g. 36% credit card APR > 12% equity SIP — pay debt first)
/// - Prepayment vs SIP opportunity cost comparison
class DebtReductionPolicy implements MatchingPolicy {
  const DebtReductionPolicy();

  @override
  Set<DecisionType> get targetGoals => const {DecisionType.reduceDebt};

  @override
  RejectionReason? reject(PartnerProgram program, MatchingContext context) =>
      null; // Stub

  @override
  MatchResult? evaluate(PartnerProgram program, MatchingContext context) {
    return const MatchResult(
      score: 0.50,
      reasons: [],
      warnings: [],
      assumptions: ['EMI burden and debt interest rates unknown'],
      limitations: [
        'Debt reduction engine not yet active — Phase 4',
        'Connect Account Aggregator to detect and prioritise your highest-cost debt',
      ],
    );
  }
}
