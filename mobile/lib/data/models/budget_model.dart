class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.monthlyLimit,
    required this.spent,
    required this.remainingAmount,
    required this.overBudget,
    required this.period,
    this.percentUsed = 0.0,
  });

  final String id;
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final double monthlyLimit;
  final double spent;
  final double remainingAmount;
  final bool overBudget;
  final String period;
  final double percentUsed;

  double get progressFraction =>
      monthlyLimit > 0 ? (spent / monthlyLimit).clamp(0.0, 1.0) : 0.0;

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? 'Unknown',
        categoryIcon: json['categoryIcon'] as String? ?? '💰',
        monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
        spent: (json['spentSoFar'] as num? ?? 0).toDouble(),
        remainingAmount: (json['remaining'] as num? ?? 0).toDouble(),
        overBudget: json['overBudget'] as bool? ?? false,
        period: json['period'] as String? ?? '',
        percentUsed: (json['percentUsed'] as num? ?? 0).toDouble(),
      );

  BudgetModel copyWith({double? monthlyLimit}) => BudgetModel(
        id: id,
        categoryId: categoryId,
        categoryName: categoryName,
        categoryIcon: categoryIcon,
        monthlyLimit: monthlyLimit ?? this.monthlyLimit,
        spent: spent,
        remainingAmount: remainingAmount,
        overBudget: overBudget,
        period: period,
        percentUsed: percentUsed,
      );
}
