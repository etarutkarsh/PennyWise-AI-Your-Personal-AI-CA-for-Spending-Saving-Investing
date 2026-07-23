class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.categoryName,
    required this.categoryIcon,
    required this.monthlyLimit,
    required this.spent,
    required this.remainingAmount,
    required this.overBudget,
    required this.period,
  });

  final String id;
  final String categoryName;
  final String categoryIcon;
  final double monthlyLimit;
  final double spent;
  final double remainingAmount;
  final bool overBudget;
  final String period;

  double get progressFraction =>
      monthlyLimit > 0 ? (spent / monthlyLimit).clamp(0.0, 1.0) : 0.0;

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as String,
        categoryName: json['categoryName'] as String? ?? 'Unknown',
        categoryIcon: json['categoryIcon'] as String? ?? '💰',
        monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
        spent: (json['spent'] as num? ?? 0).toDouble(),
        remainingAmount: (json['remainingAmount'] as num? ?? 0).toDouble(),
        overBudget: json['overBudget'] as bool? ?? false,
        period: json['period'] as String? ?? '',
      );
}
