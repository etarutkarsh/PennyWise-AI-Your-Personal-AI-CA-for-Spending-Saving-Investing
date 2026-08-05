import 'package:flutter/foundation.dart';

@immutable
class OpportunityCostProjection {
  const OpportunityCostProjection({
    required this.years,
    required this.totalSpent,
    required this.investedValue,
    required this.opportunityCost,
    required this.returnAssumption,
  });

  final int years;
  final double totalSpent;
  final double investedValue;
  final double opportunityCost;
  final double returnAssumption;
}

@immutable
class OpportunityCostSimulation {
  const OpportunityCostSimulation({
    required this.merchantKey,
    required this.displayName,
    required this.monthlyAmount,
    required this.annualAmount,
    required this.fiveYear,
    required this.tenYear,
    required this.twentyYear,
    required this.thirtyYear,
    required this.returnAssumption,
    required this.returnAssumptionLabel,
  });

  final String merchantKey;
  final String displayName;
  final double monthlyAmount;
  final double annualAmount;
  final OpportunityCostProjection fiveYear;
  final OpportunityCostProjection tenYear;
  final OpportunityCostProjection twentyYear;
  final OpportunityCostProjection thirtyYear;
  final double returnAssumption;
  final String returnAssumptionLabel;
}
