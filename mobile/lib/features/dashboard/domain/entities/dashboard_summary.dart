/// Aggregated data shown at the top of the Dashboard (PRD Section 8).
/// In the real app this is populated from /transactions, /budgets and
/// /goals responses combined by DashboardBloc; hardcoded here as a
/// placeholder until that wiring is implemented.
class DashboardSummary {
  const DashboardSummary({
    required this.salary,
    required this.savings,
    required this.investments,
    required this.remainingBudget,
    required this.financialHealthScore,
    required this.dailyTip,
  });

  final double salary;
  final double savings;
  final double investments;
  final double remainingBudget;
  final int financialHealthScore;
  final String dailyTip;

  static const placeholder = DashboardSummary(
    salary: 50000,
    savings: 12000,
    investments: 8000,
    remainingBudget: 18500,
    financialHealthScore: 82,
    dailyTip: 'Did you know? Investing ₹500/day at 12% for 30 years grows to ~₹1.2 Crore.',
  );
}
