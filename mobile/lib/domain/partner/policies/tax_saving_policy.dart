import '../../decision/decision_type.dart';
import '../match_result.dart';
import '../matching_context.dart';
import '../matching_policy.dart';
import '../partner_program.dart';
import '../rejection_reason.dart';

/// Recommendation policy for Section 80C tax optimization.
///
/// Products without a tax benefit are immediately rejected here.
/// Lock-in is acceptable — users expect it for tax instruments.
class TaxSavingPolicy implements MatchingPolicy {
  const TaxSavingPolicy();

  /// Section 80C limit in INR.
  static const double _section80cLimit = 150000;

  /// Peak tax saving at 30% slab.
  static const double _maxTaxSaving = _section80cLimit * 0.30;

  @override
  Set<DecisionType> get targetGoals => const {DecisionType.optimizeTax};

  @override
  RejectionReason? reject(PartnerProgram program, MatchingContext context) {
    // Non-tax-benefit products have no place in a tax-saving recommendation.
    if (!program.taxBenefit) {
      return RejectionReason(
        program: program,
        code: 'NO_TAX_BENEFIT',
        explanation:
            '${program.productName} does not qualify for Section 80C deduction',
      );
    }
    return null;
  }

  @override
  MatchResult? evaluate(PartnerProgram program, MatchingContext context) {
    if (!program.taxBenefit) return null;

    final reasons = <String>[];
    final warnings = <String>[];
    final assumptions = <String>[];
    final limitations = <String>[];

    double score = 0.0;

    // Tax saving potential (50% weight) — core purpose of this policy.
    score += 0.50;
    reasons.add(
        'Qualifies for Section 80C deduction — save up to ₹${(_maxTaxSaving / 1000).toStringAsFixed(0)}K in tax');

    // Return rate (30% weight) — ELSS beats PPF/traditional at long horizon.
    final returnRate = program.returnRate ?? 0.0;
    final returnContrib = (returnRate / 15.0).clamp(0.0, 0.30);
    score += returnContrib;
    if (returnRate > 10.0) {
      reasons.add(
          'Historical ${returnRate.toStringAsFixed(1)}% CAGR — tax saving + wealth creation combined');
    } else if (returnRate > 6.0) {
      reasons.add('${returnRate.toStringAsFixed(1)}% return on top of tax saving');
    }

    // Lock-in appropriateness (20% weight) — shorter lock-in wins for flexibility.
    final lockInMonths = program.metadata.lockInMonths;
    if (lockInMonths <= 36) {
      score += 0.20;
      reasons.add('Shortest 80C lock-in available at $lockInMonths months');
    } else if (lockInMonths <= 60) {
      score += 0.10;
      warnings.add('$lockInMonths-month lock-in — plan for it in your cash flow');
    } else {
      warnings.add(
          '$lockInMonths-month lock-in — only invest what you will not need during this period');
    }

    // Assumptions.
    assumptions.add('Assumes you have not yet exhausted your ₹1.5L 80C limit this financial year');
    if (program.metadata.regulator == 'SEBI') {
      assumptions.add('Market-linked — tax benefit is certain, returns are not');
    }

    limitations.add(
        'Section 80C limit (₹1.5L) and tax slabs change each Budget — verify current year');
    limitations.add(
        'Full optimisation requires knowing your other 80C contributions (PF, insurance premium, home loan principal)');

    return MatchResult(
      score: score.clamp(0.0, 1.0),
      reasons: reasons,
      warnings: warnings,
      assumptions: assumptions,
      limitations: limitations,
    );
  }
}
