import 'package:pennywise_ai/domain/partner/financial_instrument.dart';
import 'package:pennywise_ai/domain/partner/partner_program.dart';
import 'package:pennywise_ai/domain/partner/ranked_partner_program.dart';
import 'package:pennywise_ai/domain/value_objects/currency.dart';
import 'package:pennywise_ai/domain/value_objects/ids.dart';
import 'package:pennywise_ai/domain/value_objects/money.dart';
import 'package:pennywise_ai/domain/value_objects/risk_level.dart';
import 'package:pennywise_ai/features/decisions/data/models/today_decision_model.dart';

class PartnerMapper {
  const PartnerMapper();

  /// Maps the REST PartnerOptionModel to a RankedPartnerProgram domain entity.
  RankedPartnerProgram fromPartnerOptionModel(PartnerOptionModel model) {
    final program = PartnerProgram(
      programId: ProgramId(model.partner.toLowerCase().replaceAll(' ', '_')),
      partnerId: model.partner,
      partnerName: model.partner,
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
      commissionRate: 0.0,
      lastUpdated: DateTime.now(),
    );
    return RankedPartnerProgram(
      program: program,
      rank: 1,
      matchScore: 0.8,
      matchExplanation: model.feature,
      trustStatement:
          'Zero commission. Ranked by your goal alignment only.',
      ctaLabel: model.ctaLabel.isNotEmpty ? model.ctaLabel : 'View',
    );
  }

  /// Maps hardcoded bank program data into a RankedPartnerProgram.
  /// Parameters mirror the fields that used to live in bank_program_slider.dart.
  RankedPartnerProgram fromHardcodedProgram({
    required String id,
    required String partnerName,
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
      partnerId: partnerName,
      partnerName: partnerName,
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
      commissionRate: 0.0,
      lastUpdated: DateTime.now(),
    );
    return RankedPartnerProgram(
      program: program,
      rank: rank,
      matchScore: matchScore,
      matchExplanation: 'Matched to: $goalChip',
      trustStatement:
          'PennyWise earns nothing from this. Shown because it matched your goals.',
      ctaLabel: ctaLabel,
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
