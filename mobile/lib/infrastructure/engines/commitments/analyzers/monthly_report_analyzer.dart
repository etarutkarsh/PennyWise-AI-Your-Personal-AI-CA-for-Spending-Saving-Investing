import '../../../../core/services/commitment_intelligence/commitment_engine.dart';
import '../../../../domain/commitments/commitment_change_delta.dart';
import '../../../../domain/commitments/duplicate_analysis.dart';
import '../../../../domain/commitments/forecast_result.dart';
import '../../../../domain/commitments/income_stress_analysis.dart';
import '../../../../domain/commitments/monthly_financial_review.dart';
import '../../../../domain/shared/analyzer_result.dart';

class MonthlyReportAnalyzer {
  const MonthlyReportAnalyzer();

  AnalyzerResult<MonthlyFinancialReview> analyze({
    required CommitmentSummary summary,
    required ForecastResult forecast,
    required DuplicateAnalysis duplicates,
    required IncomeStressAnalysis stress,
    required CommitmentHealthScore healthScore,
    CommitmentChangeDelta? changeDelta,
  }) {
    final startedAt = DateTime.now();
    final now = DateTime.now();

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthLabel = '${monthNames[now.month - 1]} ${now.year}';

    final unusedSubscriptionCount = summary.unusedCommitments
        .where((c) =>
            c.type == CommitmentType.subscription ||
            c.type == CommitmentType.membership)
        .length;

    final unusedMonthly = summary.unusedCommitments
        .where((c) =>
            c.type == CommitmentType.subscription ||
            c.type == CommitmentType.membership)
        .fold<double>(0, (s, c) => s + c.monthlyEquivalent);

    final investmentCommitments =
        (summary.byType[CommitmentType.investment] ?? 0) +
            (summary.byType[CommitmentType.savings] ?? 0);

    final lifestyleCommitments =
        (summary.byType[CommitmentType.utility] ?? 0) +
            (summary.byType[CommitmentType.membership] ?? 0) +
            (summary.byType[CommitmentType.education] ?? 0);

    final criticalObligations =
        (summary.byType[CommitmentType.emi] ?? 0) +
            (summary.byType[CommitmentType.rent] ?? 0) +
            (summary.byType[CommitmentType.tax] ?? 0);

    final commitmentRatio = summary.commitmentRatio;
    final investmentRatio = summary.monthlyIncome > 0
        ? investmentCommitments / summary.monthlyIncome
        : 0.0;

    // Risk alerts
    final riskAlerts = <String>[];
    if (commitmentRatio > 0.65) {
      riskAlerts.add(
          'Over 65% of income is pre-committed. New financial commitments are not advisable.');
    }
    if (stress.twentyPercentDrop?.affordability == StressAffordability.critical) {
      riskAlerts.add(
          'A 20% income drop would make essential commitments unaffordable.');
    } else if (stress.twentyPercentDrop?.affordability ==
        StressAffordability.atRisk) {
      riskAlerts.add(
          'A 20% income drop would require pausing investment commitments.');
    }
    if (unusedSubscriptionCount > 0) {
      riskAlerts.add(
          '₹${unusedMonthly.round()}/month in subscriptions shows no recent activity.');
    }

    // Savings opportunities
    final savingsOpportunities = <String>[];
    if (duplicates.hasDuplicates) {
      savingsOpportunities.add(
          'Consolidating overlapping services could save ₹${duplicates.totalMonthlyWaste.round()}/month.');
    }
    if (unusedSubscriptionCount > 0) {
      savingsOpportunities
          .add('₹${unusedMonthly.round()}/month in likely-unused subscriptions.');
    }
    if (commitmentRatio < 0.40 && investmentRatio < 0.15) {
      final potentialIncrease =
          (summary.monthlyIncome * 0.20 - investmentCommitments).round();
      if (potentialIncrease > 0) {
        savingsOpportunities.add(
            'Strong cash position — consider increasing SIP by ₹$potentialIncrease.');
      }
    }

    // AI recommendations
    final aiRecommendations = <String>[];
    if (investmentRatio < 0.10) {
      aiRecommendations.add(
          'Increase investment commitments to 20% of income for long-term wealth building.');
    }
    final subMonthly = summary.byType[CommitmentType.subscription] ?? 0;
    if (summary.monthlyIncome > 0 &&
        subMonthly / summary.monthlyIncome > 0.15) {
      aiRecommendations.add(
          'Subscription spending is high relative to income — review for consolidation.');
    }
    for (final renewal in forecast.renewalTimeline) {
      if (renewal.daysUntil <= 14) {
        aiRecommendations.add(
            '₹${renewal.amount.round()} renewal in ${renewal.daysUntil} days — ensure sufficient account balance.');
        break; // one renewal alert is enough
      }
    }

    // Change summary
    String? changeSummaryText;
    if (changeDelta != null) {
      if (changeDelta.hasChanges) {
        final parts = <String>[];
        if (changeDelta.newCommitmentNames.isNotEmpty) {
          parts.add(
              '${changeDelta.newCommitmentNames.length} new commitment${changeDelta.newCommitmentNames.length > 1 ? 's' : ''}');
        }
        if (changeDelta.removedCommitmentNames.isNotEmpty) {
          parts.add(
              '${changeDelta.removedCommitmentNames.length} removed');
        }
        final changeSign = changeDelta.netMonthlyChange > 0 ? '+' : '';
        parts.add(
            '${changeSign}₹${changeDelta.netMonthlyChange.round()}/month');
        changeSummaryText = parts.join(', ');
      } else {
        changeSummaryText = 'No changes since last month';
      }
    }

    final nextMonthForecast = forecast.monthlyForecasts.length > 1
        ? forecast.monthlyForecasts[1].expectedTotal
        : forecast.averageMonthly;

    final review = MonthlyFinancialReview(
      generatedAt: now,
      monthLabel: monthLabel,
      totalMonthlyCommitted: summary.totalMonthlyCommitted,
      totalAnnualCommitted: summary.totalMonthlyCommitted * 12,
      investmentCommitments: investmentCommitments,
      lifestyleCommitments: lifestyleCommitments,
      criticalObligations: criticalObligations,
      unusedSubscriptionCount: unusedSubscriptionCount,
      potentialMonthlySavings: unusedMonthly + duplicates.totalMonthlyWaste,
      healthGrade: healthScore.grade.label,
      healthScore: healthScore.score,
      nextMonthForecast: nextMonthForecast,
      upcomingRenewalCount: forecast.renewalTimeline.length,
      riskAlerts: riskAlerts,
      savingsOpportunities: savingsOpportunities,
      aiRecommendations: aiRecommendations,
      changeSummary: changeSummaryText,
    );

    return AnalyzerResult.of(
      analyzerId: 'monthly_report_analyzer',
      result: review,
      confidence: 0.85,
      startedAt: startedAt,
    );
  }
}
