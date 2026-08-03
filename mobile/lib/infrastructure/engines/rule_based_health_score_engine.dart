import '../../domain/decision/explanation.dart';
import '../../domain/engines/health_score_engine.dart';
import '../../domain/finance/health_score.dart';
import '../../domain/partner/matching_context.dart';
import '../../domain/shared/data_source.dart';
import '../../domain/shared/financial_fact.dart';
import '../../domain/shared/result.dart';

/// Local, synchronous implementation of [HealthScoreEngine].
///
/// Computes all 10 health dimensions from the [MatchingContext] — no network,
/// no database. Dimensions backed by real data (LIQUIDITY, DEBT_QUALITY,
/// SAVINGS_CONSISTENCY) produce accurate scores. Dimensions without data
/// (GOAL_FUNDING, INSURANCE_COVERAGE, etc.) return conservative estimates
/// with honest limitations and evidence explaining what's missing.
///
/// [HealthScore.dataCompleteness] reflects the fraction of dimensions
/// computed from real data — this directly degrades [Confidence.score]
/// in the Decision Engine.
///
/// Phase 6: replaced by [RestHealthScoreEngine] that calls the backend
/// 8-dimension engine which has transaction history and goal data.
class RuleBasedHealthScoreEngine implements HealthScoreEngine {
  const RuleBasedHealthScoreEngine();

  static const _kVersion = 'rule-based-v1';
  static final _kNow = DateTime(2026, 8, 3);

  @override
  String get engineVersion => _kVersion;

  @override
  HealthScore computeFrom(MatchingContext context) {
    final dimensions = <HealthDimension, DimensionScore>{};

    // Track which dimensions have real data (not stubs) for dataCompleteness
    int realDataCount = 0;

    // ── 1. LIQUIDITY (weight 25%) ─────────────────────────────────────
    final liquidity = _scoreLiquidity(context);
    dimensions[HealthDimension.liquidity] = liquidity;
    if (context.emergencyFundMonths > 0) realDataCount++;

    // ── 2. DEBT_QUALITY (weight 15%) ──────────────────────────────────
    final debt = _scoreDebtQuality(context);
    dimensions[HealthDimension.debtQuality] = debt;
    if (context.monthlyCommitmentsTotal > 0 || context.monthlySurplus > 0) realDataCount++;

    // ── 3. SAVINGS_CONSISTENCY (weight 15%) ───────────────────────────
    final savings = _scoreSavingsConsistency(context);
    dimensions[HealthDimension.savingsConsistency] = savings;
    if (context.monthlySavingsRate > 0) realDataCount++;

    // ── 4. GOAL_FUNDING (weight 10%) — no goal data in context ────────
    dimensions[HealthDimension.goalFunding] = _stubDimension(
      HealthDimension.goalFunding,
      score: 50,
      insight: 'Goal contribution data is not available in the current context.',
      recommendation: 'Open the Goals screen and set active monthly contributions.',
      limitation: 'Connect to the backend to compute goal funding from real goal data.',
    );

    // ── 5. INSURANCE_COVERAGE (weight 10%) — no insurance data ────────
    dimensions[HealthDimension.insuranceCoverage] = _stubDimension(
      HealthDimension.insuranceCoverage,
      score: 30,
      insight: 'Insurance coverage data has not been linked.',
      recommendation: 'Ensure term life (10× annual income) and health cover (₹10L minimum).',
      limitation: 'Add insurance policies to unlock this dimension.',
    );

    // ── 6. INVESTMENT_DIVERSIFICATION (weight 10%) ────────────────────
    final invest = _scoreInvestmentDiversification(context);
    dimensions[HealthDimension.investmentDiversification] = invest;
    if (context.existingInvestmentTotal > 0) realDataCount++;

    // ── 7. BEHAVIORAL_CONSISTENCY (weight 5%) ─────────────────────────
    dimensions[HealthDimension.behavioralConsistency] = _stubDimension(
      HealthDimension.behavioralConsistency,
      score: 50,
      insight: 'Behavioral Engine is not yet calibrated.',
      recommendation: 'Use PennyWise daily — the Behavioral Engine learns from your patterns.',
      limitation: 'Requires 90+ days of transaction history for calibration.',
    );

    // ── 8. INCOME_STABILITY (weight 5%) ───────────────────────────────
    dimensions[HealthDimension.incomeStability] = _stubDimension(
      HealthDimension.incomeStability,
      score: 60,
      insight: 'Assuming stable single income source (default until verified).',
      recommendation: 'Connect Account Aggregator to verify income consistency.',
      limitation: 'Income stability computation requires SMS intelligence or AA data.',
    );

    // ── 9. FINANCIAL_ANXIETY (weight 3%) ──────────────────────────────
    dimensions[HealthDimension.financialAnxiety] = _stubDimension(
      HealthDimension.financialAnxiety,
      score: 50,
      insight: 'Financial Anxiety Metric (FAM) requires behavioral transaction data.',
      recommendation: 'FAM activates after 90 days of transaction history.',
      limitation: 'Requires 3+ months of behaviorally-tagged transaction data.',
    );

    // ── 10. TAX_EFFICIENCY (weight 2%) ────────────────────────────────
    dimensions[HealthDimension.taxEfficiency] = _stubDimension(
      HealthDimension.taxEfficiency,
      score: 50,
      insight: 'Tax optimization analysis coming in Phase 2.',
      recommendation:
          'Maximise 80C (₹1.5L), NPS 80CCD(1B) (₹50K extra), and health insurance 80D.',
      limitation: 'Tax efficiency computation requires Form 16 or ITR data.',
    );

    // ── Composite score (weighted) ────────────────────────────────────
    final composite = _computeComposite(dimensions);
    final dataCompleteness = realDataCount / HealthDimension.values.length;

    final topActions = _topActions(dimensions);

    return HealthScore(
      score: composite,
      dimensions: dimensions,
      computedAt: _kNow,
      engineVersion: _kVersion,
      dataCompleteness: dataCompleteness,
      topActions: topActions,
    );
  }

  @override
  Future<Result<HealthScore>> fetchFromBackend() async {
    return Result.failure('RuleBasedHealthScoreEngine does not call the backend. '
        'Use RestHealthScoreEngine for backend data.');
  }

  // ── Dimension: Liquidity ───────────────────────────────────────────

  DimensionScore _scoreLiquidity(MatchingContext context) {
    final months = context.emergencyFundMonths;
    final fact = FinancialFact<double>(
      value: months,
      source: DataSource.goalData,
      confidence: months > 0 ? 0.75 : 0.40,
      timestamp: _kNow,
      unit: 'months',
      engineVersion: _kVersion,
    );

    int score;
    String label;
    String insight;
    String recommendation;

    if (months <= 0) {
      score = 0; label = 'Poor';
      insight = 'No emergency fund detected. Financial safety net is critical.';
      recommendation = 'Start an emergency fund goal — target 6 months of expenses.';
    } else if (months < 1) {
      score = 10; label = 'Poor';
      insight = 'Emergency fund covers less than 1 month. Build this first.';
      recommendation = 'Pause all investments until you have 1 month of expenses saved.';
    } else if (months < 3) {
      score = 30; label = 'Fair';
      insight = 'Emergency fund covers ${months.toStringAsFixed(1)} months. Target is 6.';
      recommendation = 'Prioritise building emergency fund to 3 months before investing.';
    } else if (months < 6) {
      score = 65; label = 'Good';
      insight = 'Emergency fund covers ${months.toStringAsFixed(1)} months. Target is 6.';
      recommendation = 'Keep adding to reach 6 months — then shift focus to investing.';
    } else {
      score = 100; label = 'Excellent';
      insight = 'Emergency fund covers ${months.toStringAsFixed(1)} months. Excellent.';
      recommendation = 'Emergency fund is solid. Redirect surplus into long-term investments.';
    }

    return DimensionScore(
      dimension: HealthDimension.liquidity,
      score: score,
      target: 80,
      label: label,
      insight: insight,
      recommendation: recommendation,
      evidence: [fact.toEvidence(label: 'Emergency fund coverage')],
    );
  }

  // ── Dimension: Debt Quality ────────────────────────────────────────

  DimensionScore _scoreDebtQuality(MatchingContext context) {
    final totalInflow = context.monthlySurplus + context.monthlyCommitmentsTotal;
    final emiRatio = totalInflow > 0
        ? context.monthlyCommitmentsTotal / totalInflow
        : 0.0;

    final fact = FinancialFact<double>(
      value: emiRatio * 100,
      source: DataSource.manual,
      confidence: 0.60,
      timestamp: _kNow,
      unit: '% of income',
      engineVersion: _kVersion,
    );

    int score;
    String label;
    String insight;
    String recommendation;

    if (context.monthlyCommitmentsTotal <= 0) {
      score = 90; label = 'Excellent';
      insight = 'No recurring commitments detected. Excellent flexibility.';
      recommendation = 'Stay debt-free. If taking a home loan, keep EMI below 40% of take-home.';
    } else if (emiRatio < 0.20) {
      score = 80; label = 'Good';
      insight = 'Commitments are ${(emiRatio * 100).toStringAsFixed(0)}% of income — manageable.';
      recommendation = 'Debt load is low. Consider accelerating repayment to free up cash flow.';
    } else if (emiRatio < 0.35) {
      score = 55; label = 'Fair';
      insight = 'Commitments are ${(emiRatio * 100).toStringAsFixed(0)}% of income — elevated.';
      recommendation = 'Prioritise repayment of high-interest debt (credit cards, personal loans).';
    } else if (emiRatio < 0.50) {
      score = 25; label = 'Poor';
      insight = 'Commitments are ${(emiRatio * 100).toStringAsFixed(0)}% of income — high.';
      recommendation = 'Stop new debt. Aggressively pay down existing high-interest balances.';
    } else {
      score = 5; label = 'Poor';
      insight = 'Commitments exceed 50% of income — urgent action needed.';
      recommendation = 'Seek debt restructuring. Consolidate high-interest debt immediately.';
    }

    return DimensionScore(
      dimension: HealthDimension.debtQuality,
      score: score,
      target: 75,
      label: label,
      insight: insight,
      recommendation: recommendation,
      evidence: [fact.toEvidence(label: 'Commitment-to-income ratio')],
    );
  }

  // ── Dimension: Savings Consistency ────────────────────────────────

  DimensionScore _scoreSavingsConsistency(MatchingContext context) {
    final rate = context.monthlySavingsRate;

    final fact = FinancialFact<double>(
      value: rate * 100,
      source: DataSource.transactionHistory,
      confidence: 0.65,
      timestamp: _kNow,
      unit: '% of income saved',
      engineVersion: _kVersion,
    );

    int score;
    String label;
    String insight;
    String recommendation;

    if (rate >= 0.30) {
      score = 100; label = 'Excellent';
      insight = 'Savings rate is ${(rate * 100).toStringAsFixed(0)}% — far above 20% target.';
      recommendation = 'Excellent discipline. Consider increasing equity allocation for long-term growth.';
    } else if (rate >= 0.20) {
      score = 80; label = 'Good';
      insight = 'Savings rate is ${(rate * 100).toStringAsFixed(0)}% — meets the 20% target.';
      recommendation = 'On track. Try the 1% step-up: increase savings by 1% each month.';
    } else if (rate >= 0.10) {
      score = 50; label = 'Fair';
      insight = 'Savings rate is ${(rate * 100).toStringAsFixed(0)}% — below the 20% target.';
      recommendation = 'Cut one expense category by 5% to improve your savings rate.';
    } else if (rate > 0) {
      score = 20; label = 'Poor';
      insight = 'Savings rate is only ${(rate * 100).toStringAsFixed(0)}%.';
      recommendation = 'Start a recurring deposit for even ₹500/month — the habit matters most.';
    } else {
      score = 0; label = 'Poor';
      insight = 'No savings detected this month.';
      recommendation = 'Add your salary to unlock accurate savings tracking.';
    }

    return DimensionScore(
      dimension: HealthDimension.savingsConsistency,
      score: score,
      target: 80,
      label: label,
      insight: insight,
      recommendation: recommendation,
      evidence: [fact.toEvidence(label: 'Monthly savings rate')],
    );
  }

  // ── Dimension: Investment Diversification ─────────────────────────

  DimensionScore _scoreInvestmentDiversification(MatchingContext context) {
    final totalInvested = context.existingInvestmentTotal;

    final fact = FinancialFact<double>(
      value: totalInvested,
      source: DataSource.manual,
      confidence: 0.50,
      timestamp: _kNow,
      unit: 'INR',
      engineVersion: _kVersion,
    );

    int score;
    String label;
    String insight;
    String recommendation;

    if (totalInvested <= 0) {
      score = 10; label = 'Poor';
      insight = 'No existing investments detected.';
      recommendation = 'Start a Nifty 50 Index SIP — even ₹500/month grows significantly over time.';
    } else {
      // We know investments exist but not their breakdown — conservative score
      score = 45; label = 'Fair';
      insight = 'Investments of ₹${totalInvested.toStringAsFixed(0)} detected. Breakdown unknown.';
      recommendation = 'Connect Account Aggregator to get a full diversification analysis.';
    }

    return DimensionScore(
      dimension: HealthDimension.investmentDiversification,
      score: score,
      target: 70,
      label: label,
      insight: insight,
      recommendation: recommendation,
      evidence: [fact.toEvidence(label: 'Total investments')],
    );
  }

  // ── Stub for data-unavailable dimensions ──────────────────────────

  DimensionScore _stubDimension(
    HealthDimension dimension, {
    required int score,
    required String insight,
    required String recommendation,
    required String limitation,
  }) =>
      DimensionScore(
        dimension: dimension,
        score: score,
        label: 'Unknown',
        insight: insight,
        recommendation: recommendation,
        evidence: [
          EvidenceItem(
            label: 'Data availability',
            value: 'Not available',
            source: DataSource.manual.id,
            freshness: _kNow,
            confidence: 0.0,
            engineVersion: _kVersion,
          ),
        ],
      );

  // ── Composite weighted score ───────────────────────────────────────

  int _computeComposite(Map<HealthDimension, DimensionScore> dimensions) {
    double weighted = 0.0;
    for (final dim in HealthDimension.values) {
      final d = dimensions[dim];
      if (d != null) {
        weighted += d.score * dim.weight;
      }
    }
    return weighted.round().clamp(0, 100);
  }

  // ── Top 3 actions sorted by potential score improvement ───────────

  List<String> _topActions(Map<HealthDimension, DimensionScore> dimensions) {
    final withGap = dimensions.values
        .where((d) => d.label != 'Unknown' && d.gap > 0)
        .toList()
      ..sort((a, b) {
        // Sort by (gap × weight) descending — biggest weighted improvement first
        final aImpact = a.gap * a.dimension.weight;
        final bImpact = b.gap * b.dimension.weight;
        return bImpact.compareTo(aImpact);
      });

    return withGap.take(3).map((d) => d.recommendation).toList();
  }
}
