class InvestmentModel {
  const InvestmentModel({
    required this.id,
    required this.instrumentType,
    required this.name,
    required this.investedAmount,
    required this.currentValue,
    required this.returnsPercent,
    required this.returnsAmount,
    this.units,
    this.startedOn,
  });

  final String id;
  final String instrumentType;
  final String name;
  final double investedAmount;
  final double currentValue;
  final double returnsPercent;
  final double returnsAmount;
  final double? units;
  final DateTime? startedOn;

  bool get isPositive => returnsAmount >= 0;

  factory InvestmentModel.fromJson(Map<String, dynamic> json) => InvestmentModel(
        id: json['id'] as String,
        instrumentType: json['instrumentType'] as String,
        name: json['name'] as String,
        investedAmount: (json['investedAmount'] as num).toDouble(),
        currentValue: (json['currentValue'] as num).toDouble(),
        returnsPercent: (json['returnsPercent'] as num).toDouble(),
        returnsAmount: (json['returnsAmount'] as num).toDouble(),
        units: json['units'] != null ? (json['units'] as num).toDouble() : null,
        startedOn: json['startedOn'] != null
            ? DateTime.parse(json['startedOn'] as String)
            : null,
      );
}
