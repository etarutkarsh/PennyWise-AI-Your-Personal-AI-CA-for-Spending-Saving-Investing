import '../../decision/decision_type.dart';
import '../financial_instrument.dart';
import '../match_result.dart';
import '../matching_context.dart';
import '../matching_policy.dart';
import '../partner_program.dart';
import '../rejection_reason.dart';

/// Recommendation policy for long-term wealth creation via SIP.
///
/// Prioritises return potential and goal alignment. Liquidity is less
/// important here — the user is committing capital over years.
/// Short-horizon requests are rejected from equity instruments.
class WealthCreationPolicy implements MatchingPolicy {
  const WealthCreationPolicy();

  @override
  Set<DecisionType> get targetGoals => const {
        DecisionType.startGoalSip,
        DecisionType.stepUpSip,
        DecisionType.rebalancePortfolio,
      };

  @override
  RejectionReason? reject(PartnerProgram program, MatchingContext context) {
    // Equity needs a minimum horizon — reject if too short.
    final isEquity = program.instrument == FinancialInstrument.indexFundSip ||
        program.instrument == FinancialInstrument.elssSip;
    if (isEquity && context.horizonMonths < program.metadata.minHorizonMonths) {
      return RejectionReason(
        program: program,
        code: 'HORIZON_TOO_SHORT_FOR_EQUITY',
        explanation:
            '${program.productName} needs at least '
            '${program.metadata.minHorizonMonths} months — '
            'your goal horizon is ${context.horizonMonths} months',
      );
    }

    // Guaranteed instruments return less than inflation over long horizons —
    // reject for aggressive long-horizon goals.
    if (context.isAggressive &&
        context.horizonMonths > 60 &&
        program.metadata.capitalGuarantee &&
        program.instrument == FinancialInstrument.recurringDeposit) {
      return RejectionReason(
        program: program,
        code: 'GUARANTEED_INSTRUMENT_SUB_OPTIMAL_FOR_AGGRESSIVE_LONG_HORIZON',
        explanation:
            '${program.productName} returns may not beat inflation '
            'over a ${context.horizonMonths}-month horizon for your risk profile',
      );
    }

    return null;
  }

  @override
  MatchResult? evaluate(PartnerProgram program, MatchingContext context) {
    // Only evaluate SIP-compatible instruments.
    final isSipCompatible =
        program.instrument == FinancialInstrument.indexFundSip ||
            program.instrument == FinancialInstrument.elssSip ||
            program.instrument == FinancialInstrument.digitalGold ||
            program.instrument == FinancialInstrument.ppf ||
            program.instrument == FinancialInstrument.nps;
    if (!isSipCompatible) return null;

    final reasons = <String>[];
    final warnings = <String>[];
    final assumptions = <String>[];
    final limitations = <String>[];

    double score = 0.0;

    // Return potential (40% weight).
    final returnRate = program.returnRate ?? 0.0;
    final returnContrib = (returnRate / 15.0).clamp(0.0, 0.40);
    score += returnContrib;
    if (returnRate > 10.0) {
      reasons.add(
          'Historical ${returnRate.toStringAsFixed(1)}% CAGR — strong long-term growth potential');
    } else if (returnRate > 7.0) {
      reasons.add(
          '${returnRate.toStringAsFixed(1)}% return beats inflation over time');
    }

    // Goal horizon alignment (30% weight).
    final horizonFit = context.horizonMonths >= program.metadata.minHorizonMonths
        ? 1.0
        : (context.horizonMonths / program.metadata.minHorizonMonths).clamp(0.0, 1.0);
    score += horizonFit * 0.30;
    if (horizonFit == 1.0) {
      reasons.add('Horizon of ${context.horizonMonths} months aligns with this instrument');
    }

    // Risk match (20% weight).
    double riskScore;
    if (context.isConservative && program.metadata.capitalGuarantee) {
      riskScore = 1.0;
      reasons.add('Capital-protected — matches your conservative risk profile');
    } else if (context.isModerate &&
        !program.metadata.capitalGuarantee &&
        program.metadata.liquidityScore >= 0.7) {
      riskScore = 0.9;
      reasons.add('Balanced risk — matches your moderate profile');
    } else if (context.isAggressive && !program.metadata.capitalGuarantee) {
      riskScore = 1.0;
      reasons.add('Market-linked growth — matches your aggressive profile');
    } else {
      riskScore = 0.5;
      warnings.add('Risk level may not perfectly match your profile');
    }
    score += riskScore * 0.20;

    // Minimum amount feasibility (10% weight).
    final minAmount = program.minAmount.amount;
    if (context.monthlySurplus > 0 && minAmount <= context.monthlySurplus * 0.20) {
      score += 0.10;
      reasons.add('Minimum investment fits within your estimated surplus');
    } else if (context.monthlySurplus == 0) {
      limitations.add('Monthly surplus unknown — verify affordability before starting');
    }

    // Context-sensitive assumptions.
    assumptions.add(
        'Risk profile: ${context.riskProfile} — update in Settings for better fit');
    if (context.goalAmountTarget > 0) {
      assumptions.add(
          'Goal target: ₹${(context.goalAmountTarget / 100000).toStringAsFixed(1)}L over '
          '${context.horizonMonths} months');
    }

    limitations.add(
        'Past CAGR is not a guarantee of future returns');
    if (context.existingInvestmentTotal == 0) {
      limitations.add(
          'Existing investments unknown — connect Account Aggregator to check for duplicate exposure');
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
