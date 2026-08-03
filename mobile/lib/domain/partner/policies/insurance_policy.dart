import '../../decision/decision_type.dart';
import '../match_result.dart';
import '../matching_context.dart';
import '../matching_policy.dart';
import '../partner_program.dart';
import '../rejection_reason.dart';

/// Recommendation policy for life and health insurance adequacy.
///
/// Stub implementation — Phase 4 will implement logic using:
/// - Human Life Value (HLV) calculation (income × multiplier − assets)
/// - Existing insurance gap detection
/// - Term insurance vs ULIP fiduciary filtering (ULIPs almost always inferior)
/// - Critical illness and health floater sizing
///
/// Currently no insurance products are in the catalog — this policy
/// activates when partners (PolicyBazaar, Ditto, Digit) are onboarded.
class InsurancePolicy implements MatchingPolicy {
  const InsurancePolicy();

  @override
  Set<DecisionType> get targetGoals => const {DecisionType.getInsurance};

  @override
  RejectionReason? reject(PartnerProgram program, MatchingContext context) =>
      null; // Stub

  @override
  MatchResult? evaluate(PartnerProgram program, MatchingContext context) {
    return const MatchResult(
      score: 0.50,
      reasons: [],
      warnings: [],
      assumptions: ['Insurance gap unknown — requires income and dependent data'],
      limitations: [
        'Insurance recommendation engine not yet active — Phase 4',
        'Provide income, dependents, and existing coverage for personalised advice',
      ],
    );
  }
}
