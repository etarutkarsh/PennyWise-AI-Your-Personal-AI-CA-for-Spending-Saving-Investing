import 'package:pennywise_ai/domain/partner/financial_instrument.dart';
import 'package:pennywise_ai/domain/partner/partner_assets.dart';
import 'package:pennywise_ai/domain/partner/partner_brand.dart';
import 'package:pennywise_ai/domain/partner/partner_icon_type.dart';
import 'package:pennywise_ai/domain/partner/partner_program.dart';
import 'package:pennywise_ai/domain/partner/partner_suitability.dart';
import 'package:pennywise_ai/domain/partner/product_metadata.dart';
import 'package:pennywise_ai/domain/partner/ranked_partner_program.dart';
import 'package:pennywise_ai/domain/partner/recommendation_explanation.dart';
import 'package:pennywise_ai/domain/value_objects/currency.dart';
import 'package:pennywise_ai/domain/value_objects/ids.dart';
import 'package:pennywise_ai/domain/value_objects/money.dart';
import 'package:pennywise_ai/domain/value_objects/risk_level.dart';
import 'package:pennywise_ai/features/decisions/data/models/today_decision_model.dart';

/// Maps REST API partner data to domain entities.
///
/// [fromPartnerOptionModel] handles the v1/v2 backend response.
/// Hardcoded product construction moved to [HardcodedProductCatalog].
class PartnerMapper {
  const PartnerMapper();

  /// Maps the REST PartnerOptionModel to a RankedPartnerProgram.
  ///
  /// Builds a minimal PartnerBrand from the partner name string since the
  /// REST response doesn't carry full brand data (Sprint 4+ will fix this
  /// when /partner-catalog endpoint ships).
  RankedPartnerProgram fromPartnerOptionModel(PartnerOptionModel model) {
    final brandId =
        model.partner.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final shortName = model.partner
        .split(' ')
        .first
        .toUpperCase()
        .substring(0, model.partner.split(' ').first.length.clamp(0, 6));

    final minimalBrand = PartnerBrand(
      id: brandId,
      displayName: model.partner,
      legalName: model.partner,
      shortName: shortName,
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
      programId: ProgramId(brandId),
      brand: minimalBrand,
      productName:
          model.feature.isNotEmpty ? model.feature : 'Financial Product',
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
      metadata: const ProductMetadata(
        regulator: 'Unknown',
        taxTreatment: 'Refer to product documentation',
        lockInDays: 0,
        minHorizonMonths: 0,
        liquidityScore: 0.5,
        capitalGuarantee: false,
        returnType: 'Market-linked',
        suitableForGoalTypes: [],
        disclaimer:
            'Please read all scheme-related documents carefully before investing.',
      ),
      commissionRate: 0.0,
      lastUpdated: DateTime.now(),
    );

    return RankedPartnerProgram(
      program: program,
      rank: 1,
      matchScore: 0.8,
      suitability: PartnerSuitability.strongMatch,
      explanation: RecommendationExplanation(
        headline: model.feature,
        summary: model.feature,
        because: const ['Recommended by your advisor engine'],
        whyNot: const [],
        assumptions: const [],
        limitations: const [],
        alternatives: const [],
      ),
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
}
