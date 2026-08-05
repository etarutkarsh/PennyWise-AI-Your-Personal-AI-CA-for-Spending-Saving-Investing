import 'package:flutter/foundation.dart';

@immutable
class DuplicateGroup {
  const DuplicateGroup({
    required this.category,
    required this.serviceNames,
    required this.totalMonthly,
    required this.annualTotal,
    required this.insight,
    required this.consolidationSuggestion,
  });

  final String category;
  final List<String> serviceNames;
  final double totalMonthly;
  final double annualTotal;
  final String insight;
  final String consolidationSuggestion;
}

@immutable
class DuplicateAnalysis {
  const DuplicateAnalysis({
    required this.groups,
    required this.totalMonthlyWaste,
    required this.totalAnnualWaste,
    required this.consolidationSuggestions,
  });

  final List<DuplicateGroup> groups;
  final double totalMonthlyWaste;
  final double totalAnnualWaste;
  final List<String> consolidationSuggestions;

  bool get hasDuplicates => groups.isNotEmpty;
}
