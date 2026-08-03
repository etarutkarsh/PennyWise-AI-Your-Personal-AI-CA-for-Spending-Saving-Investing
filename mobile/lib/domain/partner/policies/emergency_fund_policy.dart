import '../../decision/decision_type.dart';
import '../financial_instrument.dart';
import '../match_result.dart';
import '../matching_context.dart';
import '../matching_policy.dart';
import '../partner_program.dart';
import '../rejection_reason.dart';

/// Recommendation policy for building or growing an emergency fund.
///
/// Fiduciary principle: emergency fund money must be accessible when the
/// emergency happens. Liquidity and capital safety beat returns here.
/// Any product that locks money away is automatically rejected.
class EmergencyFundPolicy implements MatchingPolicy {
  const EmergencyFundPolicy();

  @override
  Set<DecisionType> get targetGoals => const {
        DecisionType.buildEmergencyFund,
        DecisionType.increaseSavingsRate,
      };

  @override
  RejectionReason? reject(PartnerProgram program, MatchingContext context) {
    // Emergency funds cannot be locked up.
    if (program.metadata.lockInDays > 30) {
      return RejectionReason(
        program: program,
        code: 'LOCK_IN_EXCEEDS_EMERGENCY_REQUIREMENT',
        explanation:
            '${program.productName} has a ${program.metadata.lockInMonths}-month '
            'lock-in — unavailable during an emergency',
      );
    }

    // Equity instruments are too volatile for emergency fund.
    if (program.instrument == FinancialInstrument.elssSip ||
        program.instrument == FinancialInstrument.indexFundSip) {
      return RejectionReason(
        program: program,
        code: 'INSTRUMENT_TOO_VOLATILE',
        explanation:
            '${program.productName} is equity-linked — value may fall '
            'exactly when you need it most',
      );
    }

    return null;
  }

  @override
  MatchResult? evaluate(PartnerProgram program, MatchingContext context) {
    final reasons = <String>[];
    final warnings = <String>[];
    final assumptions = <String>[];
    final limitations = <String>[];

    double score = 0.0;

    // Liquidity (40% weight) — most important for emergency fund.
    final liquidityScore = program.metadata.liquidityScore;
    score += liquidityScore * 0.40;
    if (liquidityScore >= 0.85) {
      reasons.add('Accessible within 1–2 business days');
    } else if (liquidityScore >= 0.60) {
      reasons.add('Money accessible with minimal notice period');
    } else {
      warnings.add('Redemption may take several days — verify with provider');
    }

    // Capital guarantee (30% weight).
    if (program.metadata.capitalGuarantee) {
      score += 0.30;
      reasons.add('Principal is fully protected — no market risk');
    } else {
      warnings.add('Returns are market-linked — principal is not guaranteed');
    }

    // Return rate (20% weight — important but secondary to safety).
    final returnRate = program.returnRate ?? 0.0;
    final returnContrib = (returnRate / 10.0).clamp(0.0, 0.20);
    score += returnContrib;
    if (returnRate > 6.5) {
      reasons.add(
          '${returnRate.toStringAsFixed(1)}% return — beats a typical savings account');
    } else if (returnRate > 0) {
      reasons.add('${returnRate.toStringAsFixed(1)}% return');
    }

    // Regulator trust (10% weight).
    if (program.metadata.regulator == 'RBI' ||
        program.metadata.regulator == 'SEBI') {
      score += 0.10;
      reasons.add('Regulated by ${program.metadata.regulator}');
    } else {
      assumptions.add(
          'Not RBI/SEBI regulated — verify regulatory status independently');
    }

    // Context-sensitive assumptions.
    if (context.emergencyFundMonths < 3) {
      assumptions.add(
          'Emergency fund not yet built — prioritising liquidity over returns');
    } else if (context.emergencyFundMonths < 6) {
      assumptions.add(
          '${context.emergencyFundMonths.toStringAsFixed(1)} months covered — target is 6 months');
    }

    if (context.monthlySurplus == 0) {
      limitations.add(
          'Monthly surplus unknown — connect Account Aggregator for precise amount');
    }

    return MatchResult(
      score: score.clamp(0.0, 1.0),
      reasons: reasons,
      warnings: warnings,
      assumptions: assumptions,
      limitations: limitations,
    );
  }
}
