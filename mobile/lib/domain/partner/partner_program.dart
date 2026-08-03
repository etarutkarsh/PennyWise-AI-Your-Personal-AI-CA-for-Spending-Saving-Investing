// Defines PartnerProgram — a financial product offered by a partner, ranked by the Partner Matching Engine.

import 'package:flutter/foundation.dart';
import '../value_objects/ids.dart';
import '../value_objects/money.dart';
import '../value_objects/risk_level.dart';
import 'financial_instrument.dart';

/// A financial product from a partner that can be recommended to users.
/// [commissionRate] is always 0.0 — the fiduciary invariant of PennyWise.
@immutable
class PartnerProgram {
  final ProgramId programId;
  final String partnerId;
  final String partnerName;
  final String productName;
  final FinancialInstrument instrument;
  final List<String> suitableDecisionTypes;
  final String keyMetric;
  final String keyMetricLabel;
  final double? returnRate;
  final Money minAmount;
  final RiskLevel riskLevel;
  final bool taxBenefit;
  final bool active;

  /// Fiduciary invariant: PennyWise never earns commission on ranked programs.
  final double commissionRate;

  final DateTime lastUpdated;

  const PartnerProgram({
    required this.programId,
    required this.partnerId,
    required this.partnerName,
    required this.productName,
    required this.instrument,
    required this.suitableDecisionTypes,
    required this.keyMetric,
    required this.keyMetricLabel,
    this.returnRate,
    required this.minAmount,
    required this.riskLevel,
    required this.taxBenefit,
    required this.active,
    this.commissionRate = 0.0,
    required this.lastUpdated,
  }) : assert(commissionRate == 0.0,
            'Fiduciary invariant violated: commissionRate must always be 0.0');

  PartnerProgram copyWith({
    ProgramId? programId,
    String? partnerId,
    String? partnerName,
    String? productName,
    FinancialInstrument? instrument,
    List<String>? suitableDecisionTypes,
    String? keyMetric,
    String? keyMetricLabel,
    double? returnRate,
    Money? minAmount,
    RiskLevel? riskLevel,
    bool? taxBenefit,
    bool? active,
    DateTime? lastUpdated,
  }) =>
      PartnerProgram(
        programId: programId ?? this.programId,
        partnerId: partnerId ?? this.partnerId,
        partnerName: partnerName ?? this.partnerName,
        productName: productName ?? this.productName,
        instrument: instrument ?? this.instrument,
        suitableDecisionTypes: suitableDecisionTypes ?? this.suitableDecisionTypes,
        keyMetric: keyMetric ?? this.keyMetric,
        keyMetricLabel: keyMetricLabel ?? this.keyMetricLabel,
        returnRate: returnRate ?? this.returnRate,
        minAmount: minAmount ?? this.minAmount,
        riskLevel: riskLevel ?? this.riskLevel,
        taxBenefit: taxBenefit ?? this.taxBenefit,
        active: active ?? this.active,
        commissionRate: 0.0,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PartnerProgram && other.programId == programId);

  @override
  int get hashCode => programId.hashCode;

  @override
  String toString() => 'PartnerProgram($partnerName — $productName)';
}
