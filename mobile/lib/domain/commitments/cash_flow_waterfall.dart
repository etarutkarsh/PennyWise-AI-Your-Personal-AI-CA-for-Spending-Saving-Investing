import 'package:flutter/foundation.dart';

@immutable
class CashFlowWaterfallStep {
  const CashFlowWaterfallStep({
    required this.label,
    required this.amount,
    required this.runningBalance,
    required this.isDeduction,
    this.note,
  });

  final String label;
  final double amount;
  final double runningBalance;
  final bool isDeduction;
  final String? note;
}

@immutable
class CashFlowWaterfall {
  const CashFlowWaterfall({
    required this.monthlyIncome,
    required this.criticalCommitments,
    required this.investmentCommitments,
    required this.lifestyleCommitments,
    required this.subscriptionCommitments,
    required this.surplus,
    required this.suggestedEmergencyContribution,
    required this.availableDiscretionary,
    required this.steps,
    required this.isHealthy,
  });

  final double monthlyIncome;
  final double criticalCommitments;
  final double investmentCommitments;
  final double lifestyleCommitments;
  final double subscriptionCommitments;
  final double surplus;
  final double suggestedEmergencyContribution;
  final double availableDiscretionary;
  final List<CashFlowWaterfallStep> steps;
  final bool isHealthy;

  double get totalCommitments =>
      criticalCommitments +
      investmentCommitments +
      lifestyleCommitments +
      subscriptionCommitments;

  double get commitmentRatio =>
      monthlyIncome > 0
          ? (totalCommitments / monthlyIncome).clamp(0.0, 1.0)
          : 0.0;
}
