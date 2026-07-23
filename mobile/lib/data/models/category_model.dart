class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
  });

  final String id;
  final String name;
  final String icon;
  final String type; // EXPENSE | INCOME

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String? ?? '💰',
        type: json['type'] as String? ?? 'EXPENSE',
      );
}
