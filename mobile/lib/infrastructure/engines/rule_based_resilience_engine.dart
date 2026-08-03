import '../../domain/engines/resilience_engine.dart';
import '../../domain/finance/resilience_index.dart';
import '../../domain/partner/matching_context.dart';

/// Rule-based Resilience Index computation.
/// Measures shock-absorption capacity only — not wealth accumulation.
/// Distinct from HealthScore: a wealthy person with no insurance scores low here.
class RuleBasedResilienceEngine implements ResilienceEngine {
  const RuleBasedResilienceEngine();

  static const _kVersion = 'resilience-rule-v1';

  @override
  String get engineVersion => _kVersion;

  @override
  ResilienceIndex compute(MatchingContext context) {
    final dimensions = <ResilienceDimension, int>{};

    // ── Emergency Fund Depth (50% weight) ─────────────────────────────
    final efScore = _scoreEmergencyFund(context.emergencyFundMonths);
    dimensions[ResilienceDimension.emergencyFundDepth] = efScore;

    // ── Liquidity Coverage (30% weight) ───────────────────────────────
    // Proxy: surplus-to-commitment ratio. High surplus = more liquid buffer.
    final liquidityScore = _scoreLiquidity(context);
    dimensions[ResilienceDimension.liquidityCoverage] = liquidityScore;

    // ── Insurance Coverage (20% weight) — stub, no data yet ───────────
    // Conservative: 30 until insurance data is available.
    dimensions[ResilienceDimension.insuranceCoverage] = 30;

    // ── Composite ─────────────────────────────────────────────────────
    final composite = dimensions.entries.fold<double>(
      0.0,
      (sum, e) => sum + e.value * e.key.weight,
    ).round().clamp(0, 100);

    // ── Can absorb months: emergency fund + estimated liquid buffer ────
    final liquidBuffer = context.monthlySurplus > 0
        ? (context.monthlySurplus * 2) /
              (context.monthlySurplus + context.monthlyCommitmentsTotal + 1)
        : 0.0;
    final canAbsorb = context.emergencyFundMonths + liquidBuffer;

    final label = _label(composite);
    final insight = _insight(composite, canAbsorb);

    return ResilienceIndex(
      score: composite,
      label: label,
      canAbsorbMonths: canAbsorb.clamp(0.0, 36.0),
      dimensions: dimensions,
      insight: insight,
      engineVersion: _kVersion,
      computedAt: DateTime.now(),
    );
  }

  int _scoreEmergencyFund(double months) {
    if (months <= 0) return 0;
    if (months < 1) return 10;
    if (months < 3) return 35;
    if (months < 6) return 65;
    if (months < 9) return 85;
    return 100;
  }

  int _scoreLiquidity(MatchingContext context) {
    if (context.monthlySurplus <= 0) return 10;
    final total = context.monthlySurplus + context.monthlyCommitmentsTotal;
    final surplusRatio = total > 0 ? context.monthlySurplus / total : 0.0;
    if (surplusRatio >= 0.50) return 90;
    if (surplusRatio >= 0.30) return 65;
    if (surplusRatio >= 0.15) return 40;
    return 20;
  }

  String _label(int score) {
    if (score >= 80) return 'Fortified';
    if (score >= 65) return 'Resilient';
    if (score >= 45) return 'Stable';
    if (score >= 25) return 'Vulnerable';
    return 'Fragile';
  }

  String _insight(int score, double canAbsorb) {
    final months = canAbsorb < 1
        ? 'less than 1 month'
        : '${canAbsorb.toStringAsFixed(1)} months';
    if (score < 25) {
      return 'Critical: you can absorb $months without income. '
          'Build an emergency fund before any other financial goal.';
    }
    if (score < 45) {
      return 'You can absorb $months without income. '
          'Increase your emergency fund to 3 months as a priority.';
    }
    if (score < 65) {
      return 'You can absorb $months without income. '
          'A 6-month emergency fund would move you to Resilient.';
    }
    return 'You can absorb $months without income. Strong shock-absorption capacity.';
  }
}
