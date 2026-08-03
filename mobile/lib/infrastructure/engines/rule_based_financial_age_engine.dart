import '../../domain/engines/financial_age_engine.dart';
import '../../domain/finance/financial_age.dart';
import '../../domain/finance/health_score.dart';
import '../../domain/partner/matching_context.dart';

/// Rule-based Financial Age computation.
/// Maps health dimensions and behavioral context into an effective financial age.
///
/// Algorithm: start from chronological age, apply penalties and bonuses
/// based on measured financial behaviors. Each penalty/bonus is explainable.
class RuleBasedFinancialAgeEngine implements FinancialAgeEngine {
  const RuleBasedFinancialAgeEngine();

  static const _kVersion = 'financial-age-rule-v1';

  @override
  String get engineVersion => _kVersion;

  @override
  FinancialAge compute({
    required MatchingContext context,
    required HealthScore healthScore,
    required int chronologicalAge,
  }) {
    int financialAge = chronologicalAge;
    final drivers = <String>[];

    // Emergency fund: each missing month above 3 adds 0.5 years
    if (context.emergencyFundMonths < 1) {
      financialAge += 8;
      drivers.add('No emergency fund (+8 years)');
    } else if (context.emergencyFundMonths < 3) {
      financialAge += 4;
      drivers.add('Insufficient emergency fund (+4 years)');
    } else if (context.emergencyFundMonths >= 6) {
      financialAge -= 3;
      drivers.add('Fully funded emergency reserve (-3 years)');
    }

    // Debt quality
    final debtScore = healthScore.dimensions[HealthDimension.debtQuality]?.score ?? 50;
    if (debtScore < 25) {
      financialAge += 6;
      drivers.add('High debt burden (+6 years)');
    } else if (debtScore < 55) {
      financialAge += 2;
      drivers.add('Elevated debt-to-income (+2 years)');
    } else if (debtScore >= 80) {
      financialAge -= 2;
      drivers.add('Low debt burden (-2 years)');
    }

    // Savings consistency
    if (context.monthlySavingsRate >= 0.30) {
      financialAge -= 5;
      drivers.add('High savings rate ≥30% (-5 years)');
    } else if (context.monthlySavingsRate >= 0.20) {
      financialAge -= 2;
      drivers.add('Good savings rate ≥20% (-2 years)');
    } else if (context.monthlySavingsRate < 0.05) {
      financialAge += 5;
      drivers.add('Very low savings rate (+5 years)');
    }

    // Investment diversification
    final investScore = healthScore.dimensions[HealthDimension.investmentDiversification]?.score ?? 10;
    if (investScore >= 70) {
      financialAge -= 3;
      drivers.add('Strong investment portfolio (-3 years)');
    } else if (investScore < 15) {
      financialAge += 4;
      drivers.add('No investments detected (+4 years)');
    }

    // Age floor: financial age cannot go below 18
    financialAge = financialAge.clamp(18, 80);

    final gap = financialAge - chronologicalAge;
    final String insight;
    if (gap > 10) {
      insight = 'Your financial behaviors are significantly behind your age. '
          'Focus on ${drivers.isNotEmpty ? drivers.first.split('(').first.trim() : "building savings"} first.';
    } else if (gap > 0) {
      insight = 'You\'re slightly behind your financial age. Small consistent improvements will close the gap.';
    } else if (gap < -5) {
      insight = 'Your financial behaviors are well ahead of your age — excellent discipline.';
    } else {
      insight = 'Your financial behavior aligns well with your chronological age.';
    }

    return FinancialAge(
      chronologicalAge: chronologicalAge,
      financialAge: financialAge,
      drivers: drivers,
      insight: insight,
      engineVersion: _kVersion,
      computedAt: DateTime.now(),
    );
  }
}
