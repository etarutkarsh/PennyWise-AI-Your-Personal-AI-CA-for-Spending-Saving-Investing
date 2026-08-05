import 'package:flutter/foundation.dart';

import 'cash_flow_waterfall.dart';
import 'commitment_change_delta.dart';
import 'commitment_platform_event.dart';
import 'commitment_score.dart';
import 'duplicate_analysis.dart';
import 'financial_calendar.dart';
import 'forecast_result.dart';
import 'goal_impact_result.dart';
import 'income_stress_analysis.dart';
import 'monthly_financial_review.dart';

@immutable
class RecurringCommitmentsIntelligence {
  const RecurringCommitmentsIntelligence({
    required this.subscriptionCount,
    required this.mandateCount,
    required this.totalMonthlyCommitted,
    required this.subscriptionMonthly,
    required this.mandateMonthly,
    required this.monthlyIncome,
    required this.calendar,
    required this.forecast,
    required this.cashFlow,
    required this.monthlyReview,
    required this.scores,
    required this.stressAnalysis,
    required this.duplicateAnalysis,
    required this.healthScore,
    required this.healthGrade,
    required this.overallConfidence,
    required this.analyzedAt,
    required this.emittedEvents,
    this.goalImpacts = const {},
    this.changeDelta,
    this.limitations = const [],
  });

  final int subscriptionCount;
  final int mandateCount;
  final double totalMonthlyCommitted;
  final double subscriptionMonthly;
  final double mandateMonthly;
  final double monthlyIncome;

  final FinancialCalendar calendar;
  final ForecastResult forecast;
  final CashFlowWaterfall cashFlow;
  final MonthlyFinancialReview monthlyReview;
  final Map<String, CommitmentScore> scores;
  final IncomeStressAnalysis stressAnalysis;
  final DuplicateAnalysis duplicateAnalysis;
  final double healthScore;
  final String healthGrade;

  /// Goal impact per commitment, keyed by merchantKey.
  /// Empty when no goals are configured or no meaningful impact found.
  final Map<String, GoalImpactResult> goalImpacts;

  final CommitmentChangeDelta? changeDelta;
  final double overallConfidence;
  final DateTime analyzedAt;
  final List<CommitmentPlatformEvent> emittedEvents;
  final List<String> limitations;

  double get commitmentRatio => monthlyIncome > 0
      ? (totalMonthlyCommitted / monthlyIncome).clamp(0.0, 1.0)
      : 0.0;

  double get flexibleIncome => monthlyIncome - totalMonthlyCommitted;
  bool get isCalibrated => totalMonthlyCommitted > 0 && monthlyIncome > 0;
  bool get hasRenewals => forecast.renewalTimeline.isNotEmpty;
  bool get hasDuplicates => duplicateAnalysis.hasDuplicates;
  bool get hasStressRisk =>
      stressAnalysis.twentyPercentDrop?.affordability ==
          StressAffordability.atRisk ||
      stressAnalysis.twentyPercentDrop?.affordability ==
          StressAffordability.critical;
}
