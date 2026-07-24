class SavingsRuleModel {
  const SavingsRuleModel({
    required this.id,
    required this.triggerType,
    this.categoryId,
    this.categoryName,
    required this.config,
    required this.active,
  });

  final String id;
  final String triggerType;
  final String? categoryId;
  final String? categoryName;
  final Map<String, dynamic> config;
  final bool active;

  factory SavingsRuleModel.fromJson(Map<String, dynamic> json) =>
      SavingsRuleModel(
        id: json['id'] as String,
        triggerType: json['triggerType'] as String,
        categoryId: json['categoryId'] as String?,
        categoryName: json['categoryName'] as String?,
        config: (json['config'] as Map<String, dynamic>?) ?? {},
        active: json['active'] as bool? ?? true,
      );

  SavingsRuleModel copyWith({bool? active}) => SavingsRuleModel(
        id: id,
        triggerType: triggerType,
        categoryId: categoryId,
        categoryName: categoryName,
        config: config,
        active: active ?? this.active,
      );
}
