import 'package:pennywise_ai/domain/partner/financial_instrument.dart';
import 'package:pennywise_ai/domain/partner/partner_assets.dart';
import 'package:pennywise_ai/domain/partner/partner_brand.dart';
import 'package:pennywise_ai/domain/partner/partner_icon_type.dart';
import 'package:pennywise_ai/domain/partner/partner_program.dart';
import 'package:pennywise_ai/domain/partner/ranked_partner_program.dart';
import 'package:pennywise_ai/domain/value_objects/currency.dart';
import 'package:pennywise_ai/domain/value_objects/ids.dart';
import 'package:pennywise_ai/domain/value_objects/money.dart';
import 'package:pennywise_ai/domain/value_objects/risk_level.dart';
import 'package:pennywise_ai/features/decisions/data/models/today_decision_model.dart';

class PartnerMapper {
  const PartnerMapper();

  /// Maps a hardcoded product entry (with its resolved PartnerBrand) to a RankedPartnerProgram.
  RankedPartnerProgram fromHardcodedProduct({
    required String id,
    required PartnerBrand brand,
    required String productName,
    required String keyMetric,
    required String keyMetricLabel,
    required String tagline,
    required String goalChip,
    required double minAmountValue,
    required String ctaLabel,
    required int rank,
    required double matchScore,
  }) {
    final program = PartnerProgram(
      programId: ProgramId(id),
      brand: brand,
      productName: productName,
      instrument: _instrumentFromProductName(productName),
      suitableDecisionTypes: const [],
      keyMetric: keyMetric,
      keyMetricLabel: keyMetricLabel,
      returnRate: null,
      minAmount: Money(amount: minAmountValue, currency: Currency.inr),
      riskLevel: RiskLevel.low,
      taxBenefit: id.contains('elss') || id.contains('ppf'),
      active: true,
      tagline: tagline,
      commissionRate: 0.0,
      lastUpdated: DateTime.now(),
    );
    return RankedPartnerProgram(
      program: program,
      rank: rank,
      matchScore: matchScore,
      matchExplanation: 'Matched to: $goalChip',
      trustStatement: brand.trustStatement,
      ctaLabel: ctaLabel,
    );
  }

  /// Maps the REST PartnerOptionModel to a RankedPartnerProgram.
  /// Builds a minimal PartnerBrand from the partner name string since the
  /// REST response doesn't carry full brand data yet (Sprint 4 will fix this).
  RankedPartnerProgram fromPartnerOptionModel(PartnerOptionModel model) {
    final minimalBrand = PartnerBrand(
      id: model.partner.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_'),
      displayName: model.partner,
      legalName: model.partner,
      shortName: model.partner.split(' ').first.toUpperCase().substring(
            0,
            model.partner.split(' ').first.length.clamp(0, 6),
          ),
      primaryColorHex: 0xFF16213E,
      darkColorHex: 0xFF0A1628,
      assets: const PartnerAssets(
        fallbackIcon: PartnerIconType.generic,
        fallbackLabel: '?',
      ),
      trustStatement: 'Zero commission. Ranked by your goal alignment only.',
      regulatedEntity: false,
    );

    final program = PartnerProgram(
      programId: ProgramId(
          model.partner.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')),
      brand: minimalBrand,
      productName: model.feature.isNotEmpty ? model.feature : 'Financial Product',
      instrument: _instrumentFromFeature(model.feature),
      suitableDecisionTypes: const [],
      keyMetric: '${model.rate.toStringAsFixed(1)}%',
      keyMetricLabel: 'Return rate',
      returnRate: model.rate,
      minAmount: Money(amount: model.minAmount, currency: Currency.inr),
      riskLevel: RiskLevel.low,
      taxBenefit: false,
      active: true,
      tagline: model.feature,
      commissionRate: 0.0,
      lastUpdated: DateTime.now(),
    );
    return RankedPartnerProgram(
      program: program,
      rank: 1,
      matchScore: 0.8,
      matchExplanation: model.feature,
      trustStatement: minimalBrand.trustStatement,
      ctaLabel: model.ctaLabel.isNotEmpty ? model.ctaLabel : 'View',
    );
  }

  FinancialInstrument _instrumentFromFeature(String feature) {
    final f = feature.toLowerCase();
    if (f.contains('rd') || f.contains('recurring deposit')) {
      return FinancialInstrument.recurringDeposit;
    }
    if (f.contains('elss')) return FinancialInstrument.elssSip;
    if (f.contains('sip') || f.contains('mutual fund')) {
      return FinancialInstrument.indexFundSip;
    }
    if (f.contains('gold')) return FinancialInstrument.digitalGold;
    if (f.contains('liquid')) return FinancialInstrument.liquidFund;
    if (f.contains('ppf')) return FinancialInstrument.ppf;
    if (f.contains('nps')) return FinancialInstrument.nps;
    return FinancialInstrument.recurringDeposit;
  }

  FinancialInstrument _instrumentFromProductName(String name) {
    return _instrumentFromFeature(name);
  }
}
