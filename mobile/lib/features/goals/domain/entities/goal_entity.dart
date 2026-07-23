/// Mirrors com.pennywise.dto.GoalDto on the backend.
class GoalEntity {
  const GoalEntity({
    required this.id,
    required this.name,
    required this.goalType,
    required this.targetAmount,
    required this.currentSaved,
    required this.deadline,
    required this.recommendedMonthlyContribution,
    required this.investmentSuggestion,
    required this.progressPercent,
  });

  final String id;
  final String name;
  final String goalType;
  final double targetAmount;
  final double currentSaved;
  final DateTime deadline;
  final double recommendedMonthlyContribution;
  final String investmentSuggestion;
  final double progressPercent;

  factory GoalEntity.fromJson(Map<String, dynamic> json) => GoalEntity(
        id: json['id'] as String,
        name: json['name'] as String,
        goalType: json['goalType'] as String,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        currentSaved: (json['currentSaved'] as num).toDouble(),
        deadline: DateTime.parse(json['deadline'] as String),
        recommendedMonthlyContribution: (json['recommendedMonthlyContribution'] as num? ?? 0).toDouble(),
        investmentSuggestion: json['investmentSuggestion'] as String? ?? '',
        progressPercent: (json['progressPercent'] as num? ?? 0).toDouble(),
      );
}
