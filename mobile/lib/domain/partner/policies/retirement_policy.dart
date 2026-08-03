import '../../decision/decision_type.dart';
import '../match_result.dart';
import '../matching_context.dart';
import '../matching_policy.dart';
import '../partner_program.dart';
import '../rejection_reason.dart';

/// Recommendation policy for retirement planning (NPS, PPF, long-horizon SIPs).
///
/// Stub implementation — Phase 4 will implement full logic using:
/// - Human capital modelling (years to retirement × expected income growth)
/// - Asset allocation glide path (equity → debt as retirement approaches)
/// - NPS tier selection and annuity estimation
/// - EEE vs EET tax treatment comparison
class RetirementPolicy implements MatchingPolicy {
  const RetirementPolicy();

  @override
  Set<DecisionType> get targetGoals => const {DecisionType.rebalancePortfolio};

  @override
  RejectionReason? reject(PartnerProgram program, MatchingContext context) =>
      null; // Stub: no rejections yet

  @override
  MatchResult? evaluate(PartnerProgram program, MatchingContext context) {
    // Stub: return a baseline neutral score with honest limitations.
    return const MatchResult(
      score: 0.50,
      reasons: ['Available for retirement planning'],
      warnings: [],
      assumptions: [
        'Retirement goal horizon not yet specified',
        'Current asset allocation unknown',
      ],
      limitations: [
        'Retirement recommendation engine not yet active — Phase 4',
        'Connect Account Aggregator and specify retirement age for personalized advice',
      ],
    );
  }
}
