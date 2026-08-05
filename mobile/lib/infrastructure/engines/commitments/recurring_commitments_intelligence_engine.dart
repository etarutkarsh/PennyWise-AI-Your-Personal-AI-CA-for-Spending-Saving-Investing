import '../../../core/services/commitment_intelligence/commitment_engine.dart';
import '../../../domain/commitments/commitment_platform_event.dart';
import '../../../domain/commitments/goal_snapshot.dart';
import '../../../domain/commitments/income_stress_analysis.dart';
import '../../../domain/commitments/recurring_commitments_intelligence.dart';
import 'analyzers/calendar_analyzer.dart';
import 'analyzers/cash_flow_analyzer.dart';
import 'analyzers/change_delta_analyzer.dart';
import 'analyzers/commitment_score_analyzer.dart';
import 'analyzers/duplicate_analyzer.dart';
import 'analyzers/forecast_analyzer.dart';
import 'analyzers/goal_impact_analyzer.dart';
import 'analyzers/income_stress_analyzer.dart';
import 'analyzers/monthly_report_analyzer.dart';
import 'analyzers/opportunity_cost_analyzer.dart';
import 'analyzers/renewal_analyzer.dart';
import 'analyzers/timeline_analyzer.dart';

class RecurringCommitmentsIntelligenceEngine {
  const RecurringCommitmentsIntelligenceEngine({
    required ForecastAnalyzer forecastAnalyzer,
    required CalendarAnalyzer calendarAnalyzer,
    required CashFlowAnalyzer cashFlowAnalyzer,
    required CommitmentScoreAnalyzer scoreAnalyzer,
    required RenewalAnalyzer renewalAnalyzer,
    required DuplicateAnalyzer duplicateAnalyzer,
    required OpportunityCostAnalyzer opportunityCostAnalyzer,
    required IncomeStressAnalyzer incomeStressAnalyzer,
    required MonthlyReportAnalyzer monthlyReportAnalyzer,
    required TimelineAnalyzer timelineAnalyzer,
    required ChangeDeltaAnalyzer changeDeltaAnalyzer,
    required GoalImpactAnalyzer goalImpactAnalyzer,
  })  : _forecastAnalyzer = forecastAnalyzer,
        _calendarAnalyzer = calendarAnalyzer,
        _cashFlowAnalyzer = cashFlowAnalyzer,
        _scoreAnalyzer = scoreAnalyzer,
        _renewalAnalyzer = renewalAnalyzer,
        _duplicateAnalyzer = duplicateAnalyzer,
        _opportunityCostAnalyzer = opportunityCostAnalyzer,
        _incomeStressAnalyzer = incomeStressAnalyzer,
        _monthlyReportAnalyzer = monthlyReportAnalyzer,
        _timelineAnalyzer = timelineAnalyzer,
        _changeDeltaAnalyzer = changeDeltaAnalyzer,
        _goalImpactAnalyzer = goalImpactAnalyzer;

  static const engineVersion = 'commitments-rule-v1';

  final ForecastAnalyzer _forecastAnalyzer;
  final CalendarAnalyzer _calendarAnalyzer;
  final CashFlowAnalyzer _cashFlowAnalyzer;
  final CommitmentScoreAnalyzer _scoreAnalyzer;
  final RenewalAnalyzer _renewalAnalyzer;
  final DuplicateAnalyzer _duplicateAnalyzer;
  final OpportunityCostAnalyzer _opportunityCostAnalyzer;
  final IncomeStressAnalyzer _incomeStressAnalyzer;
  final MonthlyReportAnalyzer _monthlyReportAnalyzer;
  final TimelineAnalyzer _timelineAnalyzer;
  final ChangeDeltaAnalyzer _changeDeltaAnalyzer;
  final GoalImpactAnalyzer _goalImpactAnalyzer;

  static RecurringCommitmentsIntelligenceEngine withDefaults() =>
      const RecurringCommitmentsIntelligenceEngine(
        forecastAnalyzer: ForecastAnalyzer(),
        calendarAnalyzer: CalendarAnalyzer(),
        cashFlowAnalyzer: CashFlowAnalyzer(),
        scoreAnalyzer: CommitmentScoreAnalyzer(),
        renewalAnalyzer: RenewalAnalyzer(),
        duplicateAnalyzer: DuplicateAnalyzer(),
        opportunityCostAnalyzer: OpportunityCostAnalyzer(),
        incomeStressAnalyzer: IncomeStressAnalyzer(),
        monthlyReportAnalyzer: MonthlyReportAnalyzer(),
        timelineAnalyzer: TimelineAnalyzer(),
        changeDeltaAnalyzer: ChangeDeltaAnalyzer(),
        goalImpactAnalyzer: GoalImpactAnalyzer(),
      );

  /// Run all analyzers and assemble canonical RecurringCommitmentsIntelligence.
  ///
  /// Pass [goals] (as [GoalSnapshot] list) to enable Goal Intelligence:
  /// per-commitment impact on goal achievement timelines.
  RecurringCommitmentsIntelligence analyze(
    CommitmentSummary summary, {
    List<GoalSnapshot> goals = const [],
    List<String>? previousMerchantKeys,
    Map<String, double>? previousAmounts,
  }) {
    final commitments = summary.all;
    final income = summary.monthlyIncome;

    // 1. Partition commitments
    final subscriptions = <DetectedCommitment>[];
    final mandates = <DetectedCommitment>[];
    for (final c in commitments) {
      if (_isSubscription(c)) {
        subscriptions.add(c);
      } else {
        mandates.add(c);
      }
    }

    // Build mandatesByCategory
    final mandatesByCategory =
        <CommitmentCategory, List<DetectedCommitment>>{};
    for (final c in mandates) {
      mandatesByCategory.putIfAbsent(_categoryFor(c), () => []).add(c);
    }

    // 2. Run analyzers
    final forecastResult =
        _forecastAnalyzer.analyze(commitments, income);
    final calendarResult = _calendarAnalyzer.analyze(commitments);
    final cashFlowResult =
        _cashFlowAnalyzer.analyze(income, mandatesByCategory, subscriptions);
    final scoreResult = _scoreAnalyzer.analyze(commitments, income);
    final renewalResult = _renewalAnalyzer.analyze(commitments);
    final duplicateResult = _duplicateAnalyzer.analyze(subscriptions);
    _opportunityCostAnalyzer.analyze(subscriptions); // computed, not in output
    final stressResult =
        _incomeStressAnalyzer.analyze(summary, mandatesByCategory);

    // 10. Compute health score (replicated from RecurringCommitmentsEngine)
    final subMonthly =
        subscriptions.fold<double>(0, (s, c) => s + c.monthlyEquivalent);
    final unusedSubCount =
        subscriptions.where((c) => c.likelyUnused).length;
    final healthScore =
        _computeHealthScore(summary, subMonthly: subMonthly, unusedSubCount: unusedSubCount);

    // 11. Monthly report
    final changeDelta = _changeDeltaAnalyzer.analyze(
        commitments, previousMerchantKeys, previousAmounts);
    final monthlyReportResult = _monthlyReportAnalyzer.analyze(
      summary: summary,
      forecast: forecastResult.result,
      duplicates: duplicateResult.result,
      stress: stressResult.result,
      healthScore: healthScore,
      changeDelta: changeDelta,
    );

    // 12. Goal Impact
    final goalImpactResult = _goalImpactAnalyzer.analyze(commitments, goals);

    // 13. Timeline
    final timelineResult = _timelineAnalyzer.analyze(commitments);
    // timelineResult is available for future screens but not in canonical output

    // 14. Emit platform events
    final events = <CommitmentPlatformEvent>[];
    final now = DateTime.now();

    // Large renewal events
    for (final renewal in renewalResult.result) {
      if (renewal.amount > 5000) {
        events.add(LargeRenewalDetectedEvent(
          occurredAt: now,
          description:
              '₹${renewal.amount.round()} renewal for ${renewal.merchantName} in ${renewal.daysUntil} days',
          merchantName: renewal.merchantName,
          amount: renewal.amount,
          expectedDate: renewal.expectedDate,
          daysUntil: renewal.daysUntil,
        ));
      }
    }

    // Duplicate subscription events
    for (final group in duplicateResult.result.groups) {
      events.add(DuplicateSubscriptionDetectedEvent(
        occurredAt: now,
        description:
            '${group.serviceNames.length} overlapping ${group.category} services detected',
        category: group.category,
        count: group.serviceNames.length,
        monthlyWastePotential: group.totalMonthly,
      ));
    }

    // Income stress event
    final twentyPctDrop = stressResult.result.twentyPercentDrop;
    if (twentyPctDrop != null &&
        (twentyPctDrop.affordability == StressAffordability.atRisk ||
            twentyPctDrop.affordability == StressAffordability.critical)) {
      events.add(IncomeStressDetectedEvent(
        occurredAt: now,
        description:
            'Income stress detected: ${twentyPctDrop.scenario.label} scenario is ${twentyPctDrop.assessmentLabel}',
        scenarioLabel: twentyPctDrop.scenario.label,
        affordabilityLabel: twentyPctDrop.assessmentLabel,
      ));
    }

    // Monthly review event
    events.add(MonthlyReviewGeneratedEvent(
      occurredAt: now,
      description: 'Monthly commitment review generated',
      monthLabel: monthlyReportResult.result.monthLabel,
      healthGrade: healthScore.grade.label,
    ));

    // 15. Compute overall confidence
    final confidences = [
      forecastResult.confidence,
      calendarResult.confidence,
      cashFlowResult.confidence,
      scoreResult.confidence,
      renewalResult.confidence,
      duplicateResult.confidence,
      stressResult.confidence,
      monthlyReportResult.confidence,
      timelineResult.confidence,
    ];
    // Goal impact confidence only included when goals are present
    if (goals.isNotEmpty) confidences.add(goalImpactResult.confidence);
    final overallConfidence =
        confidences.fold<double>(0, (s, c) => s + c) / confidences.length;

    // Aggregate limitations
    final limitations = [
      ...forecastResult.limitations,
      ...calendarResult.limitations,
      ...cashFlowResult.limitations,
      ...stressResult.limitations,
    ];

    final subscriptionMonthly = subMonthly;
    final mandateMonthly =
        mandates.fold<double>(0, (s, c) => s + c.monthlyEquivalent);

    return RecurringCommitmentsIntelligence(
      subscriptionCount: subscriptions.length,
      mandateCount: mandates.length,
      totalMonthlyCommitted: summary.totalMonthlyCommitted,
      subscriptionMonthly: subscriptionMonthly,
      mandateMonthly: mandateMonthly,
      monthlyIncome: income,
      calendar: calendarResult.result,
      forecast: forecastResult.result,
      cashFlow: cashFlowResult.result,
      monthlyReview: monthlyReportResult.result,
      scores: scoreResult.result,
      stressAnalysis: stressResult.result,
      duplicateAnalysis: duplicateResult.result,
      healthScore: healthScore.score,
      healthGrade: healthScore.grade.label,
      goalImpacts: goalImpactResult.result,
      changeDelta: changeDelta,
      overallConfidence: overallConfidence,
      analyzedAt: now,
      emittedEvents: events,
      limitations: limitations,
    );
  }

  // ── Partition helpers (mirror RecurringCommitmentsEngine) ─────────────────

  static bool _isSubscription(DetectedCommitment c) =>
      c.type == CommitmentType.subscription ||
      c.type == CommitmentType.membership;

  static CommitmentCategory _categoryFor(DetectedCommitment c) {
    switch (c.type) {
      case CommitmentType.emi:
      case CommitmentType.rent:
      case CommitmentType.tax:
        return CommitmentCategory.critical;
      case CommitmentType.insurance:
        return c.criticality == Criticality.essential
            ? CommitmentCategory.critical
            : CommitmentCategory.lifestyle;
      case CommitmentType.investment:
      case CommitmentType.savings:
        return CommitmentCategory.investment;
      case CommitmentType.utility:
      case CommitmentType.education:
      case CommitmentType.membership:
        return CommitmentCategory.lifestyle;
      default:
        return CommitmentCategory.optional;
    }
  }

  // ── Health score (mirror RecurringCommitmentsEngine._computeHealthScore) ──

  static CommitmentHealthScore _computeHealthScore(
    CommitmentSummary summary, {
    required double subMonthly,
    required int unusedSubCount,
  }) {
    final ratio = summary.commitmentRatio;
    final ratioScore = ratio < 0.40
        ? 30.0
        : ratio < 0.50
            ? 25.0
            : ratio < 0.60
                ? 15.0
                : ratio < 0.70
                    ? 5.0
                    : 0.0;

    final subRatio =
        summary.monthlyIncome > 0 ? subMonthly / summary.monthlyIncome : 0.0;
    final subScore = subRatio < 0.05
        ? 25.0
        : subRatio < 0.10
            ? 20.0
            : subRatio < 0.15
                ? 10.0
                : 0.0;

    final investTotal = (summary.byType[CommitmentType.investment] ?? 0.0) +
        (summary.byType[CommitmentType.savings] ?? 0.0);
    final investRate =
        summary.monthlyIncome > 0 ? investTotal / summary.monthlyIncome : 0.0;
    final investScore = investRate >= 0.20
        ? 30.0
        : investRate >= 0.15
            ? 25.0
            : investRate >= 0.10
                ? 15.0
                : investRate >= 0.05
                    ? 8.0
                    : 0.0;

    final unusedPenalty = (unusedSubCount * 5.0).clamp(0.0, 15.0);
    final unusedScore = 15.0 - unusedPenalty;

    final total =
        (ratioScore + subScore + investScore + unusedScore).clamp(0.0, 100.0);

    final grade = total >= 80
        ? CommitmentHealthGrade.a
        : total >= 65
            ? CommitmentHealthGrade.b
            : total >= 50
                ? CommitmentHealthGrade.c
                : total >= 35
                    ? CommitmentHealthGrade.d
                    : CommitmentHealthGrade.f;

    return CommitmentHealthScore(
      score: total,
      grade: grade,
      headline: grade.headline,
      commitmentRatioScore: ratioScore,
      subscriptionScore: subScore,
      investmentScore: investScore,
      unusedPenalty: unusedPenalty,
    );
  }
}
