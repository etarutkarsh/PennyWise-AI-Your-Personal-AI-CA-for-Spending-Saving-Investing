import 'package:flutter/foundation.dart';

import 'data_source.dart';
import 'financial_fact.dart';

/// Named collection of computed financial facts for a single user.
///
/// Each field is a typed [FinancialFact<T>] with provenance (source,
/// confidence, timestamp). Null means the fact has not yet been computed
/// — engines must handle missing facts gracefully with safe defaults.
///
/// [FinancialFacts] is the durable, auditable input to every intelligence
/// engine. Engines should consume [FinancialFacts], not raw events or
/// [MatchingContext].
///
/// Produced by [FinancialFactBuilder].
/// Consumed by [MatchingContextBuilder], [HealthScoreEngine], [DecisionEngine].
@immutable
class FinancialFacts {
  const FinancialFacts({
    this.monthlyIncome,
    this.monthlyExpenses,
    this.emergencyFundMonths,
    this.savingsRate,
    this.debtRatio,
    this.investmentRatio,
    this.recurringCommitmentsTotal,
    this.monthlyInsurancePremium,
    this.taxEfficiency,
    this.healthScore,
    this.existingInvestmentTotal,
    this.ageYears,
    this.riskProfile,
    this.dominantBehaviorProfile,
  });

  /// Monthly gross income in INR. Source: salary credit, AA, manual.
  final FinancialFact<double>? monthlyIncome;

  /// Average monthly total spend in INR. Source: canonical transactions.
  final FinancialFact<double>? monthlyExpenses;

  /// Months of expenses covered by liquid savings. Target: ≥ 6.
  final FinancialFact<double>? emergencyFundMonths;

  /// Fraction of income saved (0.0–1.0). Minimum target: 0.20.
  final FinancialFact<double>? savingsRate;

  /// EMI-to-income ratio (0.0–1.0). Safe maximum: 0.40.
  final FinancialFact<double>? debtRatio;

  /// Fraction of income invested in growth assets (0.0–1.0).
  final FinancialFact<double>? investmentRatio;

  /// Total of monthly mandate-rail commitments (EMIs, SIPs, subscriptions) in INR.
  final FinancialFact<double>? recurringCommitmentsTotal;

  /// Total monthly insurance premium in INR (health + life + vehicle).
  final FinancialFact<double>? monthlyInsurancePremium;

  /// Tax efficiency score (0.0–1.0): ratio of tax-saving investments to capacity.
  final FinancialFact<double>? taxEfficiency;

  /// PennyWise Financial Health Score (0–100). Produced by [HealthScoreEngine].
  final FinancialFact<double>? healthScore;

  /// Total current value of investments (MF, FD, Gold, Equity) in INR.
  final FinancialFact<double>? existingInvestmentTotal;

  /// User age in years. Used for horizon and insurance recommendations.
  final FinancialFact<int>? ageYears;

  /// 'conservative', 'moderate', or 'aggressive'. Source: user profile.
  final FinancialFact<String>? riskProfile;

  /// From Behavioral Engine. Null until calibrated.
  final FinancialFact<String>? dominantBehaviorProfile;

  // ─── Convenience accessors with safe defaults ────────────────────────────

  double get monthlyIncomeValue => monthlyIncome?.value ?? 0;
  double get monthlyExpensesValue => monthlyExpenses?.value ?? 0;
  double get emergencyFundMonthsValue => emergencyFundMonths?.value ?? 0;
  double get savingsRateValue => savingsRate?.value ?? 0.10;
  double get debtRatioValue => debtRatio?.value ?? 0.0;
  double get taxEfficiencyValue => taxEfficiency?.value ?? 0.0;
  double get investmentRatioValue => investmentRatio?.value ?? 0.0;
  double get recurringCommitmentsTotalValue => recurringCommitmentsTotal?.value ?? 0;
  double get healthScoreValue => healthScore?.value ?? 50;
  double get existingInvestmentTotalValue => existingInvestmentTotal?.value ?? 0;
  int get ageYearsValue => ageYears?.value ?? 30;
  String get riskProfileValue => riskProfile?.value ?? 'moderate';

  double get monthlySurplus {
    if (monthlyIncome == null) return 0;
    return (monthlyIncomeValue - monthlyExpensesValue - recurringCommitmentsTotalValue)
        .clamp(0, double.infinity);
  }

  // ─── Data quality ────────────────────────────────────────────────────────

  /// Highest-fidelity source seen across all non-null facts.
  DataSource get dominantSource {
    final sources = _nonNullSources;
    if (sources.contains(DataSource.aaData)) return DataSource.aaData;
    if (sources.contains(DataSource.smsIntelligence)) return DataSource.smsIntelligence;
    return DataSource.manual;
  }

  List<DataSource> get _nonNullSources => [
        monthlyIncome?.source,
        monthlyExpenses?.source,
        emergencyFundMonths?.source,
        savingsRate?.source,
      ].whereType<DataSource>().toList();

  /// Average confidence across all non-null facts.
  double get overallConfidence {
    final facts = _confidenceList;
    if (facts.isEmpty) return 0;
    return facts.reduce((a, b) => a + b) / facts.length;
  }

  List<double> get _confidenceList => [
        monthlyIncome?.confidence,
        monthlyExpenses?.confidence,
        emergencyFundMonths?.confidence,
        savingsRate?.confidence,
        healthScore?.confidence,
      ].whereType<double>().toList();

  int get populatedFactCount => [
        monthlyIncome,
        monthlyExpenses,
        emergencyFundMonths,
        savingsRate,
        debtRatio,
        investmentRatio,
        recurringCommitmentsTotal,
        monthlyInsurancePremium,
        taxEfficiency,
        healthScore,
        existingInvestmentTotal,
        ageYears,
        riskProfile,
        dominantBehaviorProfile,
      ].where((f) => f != null).length;

  static const int totalFactCount = 14;

  double get completeness => populatedFactCount / totalFactCount;

  FinancialFacts copyWith({
    FinancialFact<double>? monthlyIncome,
    FinancialFact<double>? monthlyExpenses,
    FinancialFact<double>? emergencyFundMonths,
    FinancialFact<double>? savingsRate,
    FinancialFact<double>? debtRatio,
    FinancialFact<double>? investmentRatio,
    FinancialFact<double>? recurringCommitmentsTotal,
    FinancialFact<double>? monthlyInsurancePremium,
    FinancialFact<double>? taxEfficiency,
    FinancialFact<double>? healthScore,
    FinancialFact<double>? existingInvestmentTotal,
    FinancialFact<int>? ageYears,
    FinancialFact<String>? riskProfile,
    FinancialFact<String>? dominantBehaviorProfile,
  }) =>
      FinancialFacts(
        monthlyIncome: monthlyIncome ?? this.monthlyIncome,
        monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
        emergencyFundMonths: emergencyFundMonths ?? this.emergencyFundMonths,
        savingsRate: savingsRate ?? this.savingsRate,
        debtRatio: debtRatio ?? this.debtRatio,
        investmentRatio: investmentRatio ?? this.investmentRatio,
        recurringCommitmentsTotal:
            recurringCommitmentsTotal ?? this.recurringCommitmentsTotal,
        monthlyInsurancePremium:
            monthlyInsurancePremium ?? this.monthlyInsurancePremium,
        taxEfficiency: taxEfficiency ?? this.taxEfficiency,
        healthScore: healthScore ?? this.healthScore,
        existingInvestmentTotal:
            existingInvestmentTotal ?? this.existingInvestmentTotal,
        ageYears: ageYears ?? this.ageYears,
        riskProfile: riskProfile ?? this.riskProfile,
        dominantBehaviorProfile:
            dominantBehaviorProfile ?? this.dominantBehaviorProfile,
      );
}
