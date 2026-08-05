import 'package:flutter/foundation.dart';

@immutable
class MonthlyFinancialReview {
  const MonthlyFinancialReview({
    required this.generatedAt,
    required this.monthLabel,
    required this.totalMonthlyCommitted,
    required this.totalAnnualCommitted,
    required this.investmentCommitments,
    required this.lifestyleCommitments,
    required this.criticalObligations,
    required this.unusedSubscriptionCount,
    required this.potentialMonthlySavings,
    required this.healthGrade,
    required this.healthScore,
    required this.nextMonthForecast,
    required this.upcomingRenewalCount,
    required this.riskAlerts,
    required this.savingsOpportunities,
    required this.aiRecommendations,
    this.changeSummary,
  });

  final DateTime generatedAt;
  final String monthLabel;

  // Summary numbers
  final double totalMonthlyCommitted;
  final double totalAnnualCommitted;
  final double investmentCommitments;
  final double lifestyleCommitments;
  final double criticalObligations;
  final int unusedSubscriptionCount;
  final double potentialMonthlySavings;

  // Health
  final String healthGrade;
  final double healthScore;

  // Outlook
  final double nextMonthForecast;
  final int upcomingRenewalCount;

  // Intelligence
  final List<String> riskAlerts;
  final List<String> savingsOpportunities;
  final List<String> aiRecommendations;

  // Delta
  final String? changeSummary;
}
