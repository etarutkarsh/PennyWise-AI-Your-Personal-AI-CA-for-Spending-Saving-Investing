// Defines PartnerProgram — a financial product offered by a partner, ranked by the Partner Matching Engine.

import 'package:flutter/foundation.dart';
import '../value_objects/ids.dart';
import '../value_objects/money.dart';
import '../value_objects/risk_level.dart';
import 'financial_instrument.dart';
import 'partner_brand.dart';

/// A financial product from a partner that can be recommended to users.
///
/// Brand identity (name, colors, logo) lives on [PartnerBrand], not here.
/// One brand can own many products — this separation keeps product data
/// clean and avoids duplicating logo/color data per product.
///
/// [commissionRate] is always 0.0 — the fiduciary invariant of PennyWise.
@immutable
class PartnerProgram {
  final ProgramId programId;
  final PartnerBrand brand;
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

  /// One-line product benefit shown on the card face.
  final String tagline;

  /// Fiduciary invariant: PennyWise never earns commission on ranked programs.
  final double commissionRate;

  final DateTime lastUpdated;

  const PartnerProgram({
    required this.programId,
    required this.brand,
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
    this.tagline = '',
    this.commissionRate = 0.0,
    required this.lastUpdated,
  }) : assert(commissionRate == 0.0,
            'Fiduciary invariant violated: commissionRate must always be 0.0');

  // ── Convenience accessors (delegate to brand) ─────────────────────────────

  /// Short accessor for widgets that display the partner name.
  String get partnerName => brand.displayName;

  /// Partner identifier — delegates to brand.id.
  String get partnerId => brand.id;

  // ─────────────────────────────────────────────────────────────────────────

  PartnerProgram copyWith({
    PartnerBrand? brand,
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
    String? tagline,
    DateTime? lastUpdated,
  }) =>
      PartnerProgram(
        programId: programId,
        brand: brand ?? this.brand,
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
        tagline: tagline ?? this.tagline,
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
