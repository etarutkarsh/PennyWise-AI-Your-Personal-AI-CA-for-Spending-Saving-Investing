import 'package:flutter/foundation.dart';

import '../decision/decision_type.dart';

/// The user's current financial context — the input signal for the
/// Partner Matching Engine.
///
/// All fields have safe defaults so the engine can operate even when
/// data is incomplete. As more data sources are connected (Account
/// Aggregator, Goals, Health Score), these fields are populated with
/// real values and recommendation quality improves automatically.
///
/// Fields are named from the user's perspective: "what do I have" rather
/// than "what does the engine need".
@immutable
class MatchingContext {
  const MatchingContext({
    required this.primaryGoal,
    this.horizonMonths = 12,
    this.goalAmountTarget = 0,
    this.monthlySurplus = 0,
    this.emergencyFundMonths = 0,
    this.riskProfile = 'moderate',
    this.healthScore = 50,
    this.existingInvestmentTotal = 0,
    this.monthlyCommitmentsTotal = 0,
    this.ageYears = 30,
    this.monthlySavingsRate = 0.10,
    this.dominantBehaviorProfile,
  });

  /// The financial goal driving today's recommendation session.
  final DecisionType primaryGoal;

  /// How many months until the goal needs to be achieved.
  final int horizonMonths;

  /// Target amount for the goal (in INR). 0 = unknown.
  final double goalAmountTarget;

  /// Monthly disposable income after expenses and commitments.
  /// Derived from: salary × (1 - savingsRate - EMI ratio - expense ratio).
  final double monthlySurplus;

  /// How many months of expenses the user currently has in liquid savings.
  /// 0 = no emergency fund. Target: 6 months.
  final double emergencyFundMonths;

  /// 'conservative', 'moderate', 'aggressive' — from user risk profile.
  final String riskProfile;

  /// PennyWise Financial Health Score (0–100). 50 = unknown.
  final double healthScore;

  /// Total value of existing investments (MF, FD, Gold, etc.).
  final double existingInvestmentTotal;

  /// Total of existing monthly commitments (EMIs, SIPs, subscriptions).
  final double monthlyCommitmentsTotal;

  /// User age in years. Used for long-horizon and insurance decisions.
  final int ageYears;

  /// Current monthly savings rate as a fraction (0.0–1.0).
  final double monthlySavingsRate;

  /// From Behavioral Engine (future). null = uncalibrated.
  final String? dominantBehaviorProfile;

  /// Builds context from the minimal data available at startup:
  /// today's decision type + salary from prefs.
  ///
  /// Conservative defaults throughout — the engine undersells rather than
  /// oversells when data is incomplete.
  factory MatchingContext.fromDecisionAndSalary({
    required DecisionType primaryGoal,
    required double monthlySalary,
    String riskProfile = 'moderate',
    int horizonMonths = 12,
  }) {
    // Conservative surplus: salary minus assumed 70% expenses and 5% EMI buffer
    final estimatedSurplus = monthlySalary * 0.20;
    return MatchingContext(
      primaryGoal: primaryGoal,
      horizonMonths: horizonMonths,
      monthlySurplus: estimatedSurplus,
      emergencyFundMonths: 0, // unknown — conservative
      riskProfile: riskProfile,
      healthScore: 50, // unknown
      monthlySavingsRate: 0.10, // assumed baseline
    );
  }

  bool get isConservative => riskProfile == 'conservative';
  bool get isModerate => riskProfile == 'moderate';
  bool get isAggressive => riskProfile == 'aggressive';
  bool get hasEmergencyFund => emergencyFundMonths >= 3;
  bool get hasAdequateEmergencyFund => emergencyFundMonths >= 6;

  MatchingContext copyWith({
    DecisionType? primaryGoal,
    int? horizonMonths,
    double? goalAmountTarget,
    double? monthlySurplus,
    double? emergencyFundMonths,
    String? riskProfile,
    double? healthScore,
    double? existingInvestmentTotal,
    double? monthlyCommitmentsTotal,
    int? ageYears,
    double? monthlySavingsRate,
    String? dominantBehaviorProfile,
  }) =>
      MatchingContext(
        primaryGoal: primaryGoal ?? this.primaryGoal,
        horizonMonths: horizonMonths ?? this.horizonMonths,
        goalAmountTarget: goalAmountTarget ?? this.goalAmountTarget,
        monthlySurplus: monthlySurplus ?? this.monthlySurplus,
        emergencyFundMonths: emergencyFundMonths ?? this.emergencyFundMonths,
        riskProfile: riskProfile ?? this.riskProfile,
        healthScore: healthScore ?? this.healthScore,
        existingInvestmentTotal:
            existingInvestmentTotal ?? this.existingInvestmentTotal,
        monthlyCommitmentsTotal:
            monthlyCommitmentsTotal ?? this.monthlyCommitmentsTotal,
        ageYears: ageYears ?? this.ageYears,
        monthlySavingsRate: monthlySavingsRate ?? this.monthlySavingsRate,
        dominantBehaviorProfile:
            dominantBehaviorProfile ?? this.dominantBehaviorProfile,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MatchingContext &&
          other.primaryGoal == primaryGoal &&
          other.horizonMonths == horizonMonths &&
          other.riskProfile == riskProfile);

  @override
  int get hashCode =>
      Object.hash(primaryGoal, horizonMonths, riskProfile);
}
