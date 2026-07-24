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
        id: json['id'].toString(),
        name: json['name'] as String,
        goalType: json['goalType'] as String,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        currentSaved: (json['currentSaved'] as num).toDouble(),
        deadline: _parseDate(json['deadline']),
        recommendedMonthlyContribution: (json['recommendedMonthlyContribution'] as num? ?? 0).toDouble(),
        investmentSuggestion: json['investmentSuggestion'] as String? ?? '',
        progressPercent: (json['progressPercent'] as num? ?? 0).toDouble(),
      );

  // Backend may return LocalDate as [year, month, day] array or "yyyy-MM-dd" string.
  static DateTime _parseDate(dynamic raw) {
    if (raw is String) return DateTime.parse(raw);
    if (raw is List) return DateTime(raw[0] as int, raw[1] as int, raw[2] as int);
    throw FormatException('Cannot parse date from: $raw');
  }
}
