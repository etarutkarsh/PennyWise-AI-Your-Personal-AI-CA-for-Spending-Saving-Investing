import '../../domain/partner/financial_instrument.dart';
import '../../domain/partner/partner_assets.dart';
import '../../domain/partner/partner_brand.dart';
import '../../domain/partner/partner_icon_type.dart';
import '../../domain/partner/partner_program.dart';
import '../../domain/partner/product_catalog.dart';
import '../../domain/partner/product_metadata.dart';
import '../../domain/value_objects/currency.dart';
import '../../domain/value_objects/ids.dart';
import '../../domain/value_objects/money.dart';
import '../../domain/value_objects/risk_level.dart';

/// The canonical source of curated financial products.
///
/// Knows nothing about users. Contains only product, brand, and
/// regulatory data. The [PartnerMatchingEngine] does all user-specific
/// reasoning on top of this catalog.
///
/// Sprint 4: hardcoded. Sprint 5: loaded from JSON asset config.
/// Sprint 6+: fetched from /partner-catalog backend endpoint.
class HardcodedProductCatalog implements ProductCatalog {
  const HardcodedProductCatalog();

  // ── Brand Catalog ─────────────────────────────────────────────────────────

  static final _brands = <String, PartnerBrand>{
    'hdfc': PartnerBrand(
      id: 'hdfc',
      displayName: 'HDFC Bank',
      legalName: 'HDFC Bank Limited',
      shortName: 'HDFC',
      primaryColorHex: 0xFF004C8F,
      darkColorHex: 0xFF002D57,
      assets: const PartnerAssets(
        fallbackIcon: PartnerIconType.savings,
        fallbackLabel: 'HDFC',
      ),
      trustStatement: 'SEBI-regulated bank. Zero commission earned by PennyWise.',
      website: 'https://www.hdfcbank.com',
      regulatedEntity: true,
    ),
    'nippon': PartnerBrand(
      id: 'nippon',
      displayName: 'Nippon India MF',
      legalName: 'Nippon India Mutual Fund',
      shortName: 'NIPPON',
      primaryColorHex: 0xFFE63012,
      darkColorHex: 0xFFAF1C08,
      assets: const PartnerAssets(
        fallbackIcon: PartnerIconType.trendingUp,
        fallbackLabel: 'NIPPON',
      ),
      trustStatement: 'SEBI-registered AMC. Zero commission earned by PennyWise.',
      website: 'https://www.nipponindiamf.com',
      regulatedEntity: true,
    ),
    'jar': PartnerBrand(
      id: 'jar',
      displayName: 'Jar · Digital Gold',
      legalName: 'Jar Technologies Pvt Ltd',
      shortName: 'jar',
      primaryColorHex: 0xFFB45309,
      darkColorHex: 0xFF7C3A00,
      assets: const PartnerAssets(
        fallbackIcon: PartnerIconType.gold,
        fallbackLabel: 'jar',
      ),
      trustStatement:
          'RBI-compliant gold platform. Zero commission earned by PennyWise.',
      regulatedEntity: false,
    ),
    'axis': PartnerBrand(
      id: 'axis',
      displayName: 'Axis Mutual Fund',
      legalName: 'Axis Asset Management Company Limited',
      shortName: 'AXIS',
      primaryColorHex: 0xFF8B0000,
      darkColorHex: 0xFF5C0000,
      assets: const PartnerAssets(
        fallbackIcon: PartnerIconType.tax,
        fallbackLabel: 'AXIS',
      ),
      trustStatement:
          'SEBI-registered AMC. Zero commission earned by PennyWise.',
      website: 'https://www.axismf.com',
      regulatedEntity: true,
    ),
    'fi': PartnerBrand(
      id: 'fi',
      displayName: 'Fi Money',
      legalName: 'epiFi Technologies Pvt Ltd',
      shortName: 'fi',
      primaryColorHex: 0xFF0D9488,
      darkColorHex: 0xFF0A7570,
      assets: const PartnerAssets(
        fallbackIcon: PartnerIconType.autoSave,
        fallbackLabel: 'fi',
      ),
      trustStatement:
          'RBI-regulated neo-bank partner. Zero commission earned by PennyWise.',
      regulatedEntity: false,
    ),
    'icici': PartnerBrand(
      id: 'icici',
      displayName: 'ICICI Bank',
      legalName: 'ICICI Bank Limited',
      shortName: 'ICICI',
      primaryColorHex: 0xFFB44F00,
      darkColorHex: 0xFF7A3500,
      assets: const PartnerAssets(
        fallbackIcon: PartnerIconType.creditCard,
        fallbackLabel: 'ICICI',
      ),
      trustStatement:
          'RBI-regulated bank. Zero commission earned by PennyWise.',
      website: 'https://www.icicibank.com',
      regulatedEntity: true,
    ),
  };

  // ── Product Catalog ───────────────────────────────────────────────────────

  static late final List<PartnerProgram> _programs = [
    PartnerProgram(
      programId: const ProgramId('hdfc_rd'),
      brand: _brands['hdfc']!,
      productName: 'Recurring Deposit',
      instrument: FinancialInstrument.recurringDeposit,
      suitableDecisionTypes: const ['buildEmergencyFund', 'increaseSavingsRate'],
      keyMetric: '7.1% p.a.',
      keyMetricLabel: 'Guaranteed return',
      returnRate: 7.1,
      minAmount: const Money(amount: 1000, currency: Currency.inr),
      riskLevel: RiskLevel.low,
      taxBenefit: false,
      active: true,
      tagline: 'Safe, predictable savings — zero market risk',
      metadata: const ProductMetadata(
        regulator: 'RBI',
        taxTreatment: 'Interest taxable as income (TDS above ₹40,000/year)',
        lockInDays: 0,
        minHorizonMonths: 6,
        liquidityScore: 0.60,
        capitalGuarantee: true,
        returnType: 'Guaranteed',
        suitableForGoalTypes: ['buildEmergencyFund', 'increaseSavingsRate'],
        disclaimer:
            'Premature withdrawal may attract penalty. TDS applicable on interest above ₹40,000 per year.',
      ),
      commissionRate: 0.0,
      lastUpdated: _kNow,
    ),
    PartnerProgram(
      programId: const ProgramId('nippon_sip'),
      brand: _brands['nippon']!,
      productName: 'Nifty 50 Index SIP',
      instrument: FinancialInstrument.indexFundSip,
      suitableDecisionTypes: const ['startGoalSip', 'stepUpSip'],
      keyMetric: '₹5K → ₹1.75 Cr',
      keyMetricLabel: '20-year SIP projection',
      returnRate: 12.5,
      minAmount: const Money(amount: 500, currency: Currency.inr),
      riskLevel: RiskLevel.medium,
      taxBenefit: false,
      active: true,
      tagline: "Own all of India's top 50 companies for ₹100/day",
      metadata: const ProductMetadata(
        regulator: 'SEBI',
        taxTreatment: 'LTCG 10% after 12 months (above ₹1L per year)',
        lockInDays: 0,
        minHorizonMonths: 36,
        liquidityScore: 0.85,
        capitalGuarantee: false,
        returnType: 'Market-linked',
        suitableForGoalTypes: ['startGoalSip', 'stepUpSip'],
        disclaimer:
            'Mutual fund investments are subject to market risks. Past performance is not indicative of future results.',
      ),
      commissionRate: 0.0,
      lastUpdated: _kNow,
    ),
    PartnerProgram(
      programId: const ProgramId('jar_gold'),
      brand: _brands['jar']!,
      productName: 'Digital Gold SIP',
      instrument: FinancialInstrument.digitalGold,
      suitableDecisionTypes: const ['startGoalSip', 'rebalancePortfolio'],
      keyMetric: '12.4% CAGR',
      keyMetricLabel: '10-year gold return',
      returnRate: 12.4,
      minAmount: const Money(amount: 1, currency: Currency.inr),
      riskLevel: RiskLevel.medium,
      taxBenefit: false,
      active: true,
      tagline: 'Inflation hedge that never rusts',
      metadata: const ProductMetadata(
        regulator: 'Self-regulated',
        taxTreatment: 'LTCG 20% with indexation after 36 months',
        lockInDays: 0,
        minHorizonMonths: 12,
        liquidityScore: 0.75,
        capitalGuarantee: false,
        returnType: 'Market-linked',
        suitableForGoalTypes: ['startGoalSip', 'rebalancePortfolio'],
        disclaimer:
            'Digital gold prices are market-linked. Jar is not SEBI/RBI regulated for gold investment.',
      ),
      commissionRate: 0.0,
      lastUpdated: _kNow,
    ),
    PartnerProgram(
      programId: const ProgramId('axis_elss'),
      brand: _brands['axis']!,
      productName: 'ELSS Tax Saver Fund',
      instrument: FinancialInstrument.elssSip,
      suitableDecisionTypes: const ['optimizeTax'],
      keyMetric: '₹46,800 saved',
      keyMetricLabel: 'Max annual tax saving',
      returnRate: 14.0,
      minAmount: const Money(amount: 500, currency: Currency.inr),
      riskLevel: RiskLevel.high,
      taxBenefit: true,
      active: true,
      tagline: 'Invest ₹1.5L, save ₹46,800 tax — every year',
      metadata: const ProductMetadata(
        regulator: 'SEBI',
        taxTreatment:
            'Exempt under Section 80C up to ₹1.5L; LTCG 10% after lock-in',
        lockInDays: 1095,
        minHorizonMonths: 36,
        liquidityScore: 0.0,
        capitalGuarantee: false,
        returnType: 'Market-linked',
        suitableForGoalTypes: ['optimizeTax'],
        disclaimer:
            'ELSS funds have a mandatory 3-year lock-in. Market-linked returns — past performance not guaranteed.',
      ),
      commissionRate: 0.0,
      lastUpdated: _kNow,
    ),
    PartnerProgram(
      programId: const ProgramId('fi_auto_save'),
      brand: _brands['fi']!,
      productName: 'Smart Deposit (Auto-Save)',
      instrument: FinancialInstrument.recurringDeposit,
      suitableDecisionTypes: const ['increaseSavingsRate', 'buildEmergencyFund'],
      keyMetric: '6.5% p.a.',
      keyMetricLabel: 'On auto-saved balance',
      returnRate: 6.5,
      minAmount: const Money(amount: 500, currency: Currency.inr),
      riskLevel: RiskLevel.low,
      taxBenefit: false,
      active: true,
      tagline: 'Savings happen automatically — no willpower needed',
      metadata: const ProductMetadata(
        regulator: 'RBI',
        taxTreatment: 'Interest taxable as income',
        lockInDays: 0,
        minHorizonMonths: 1,
        liquidityScore: 0.95,
        capitalGuarantee: true,
        returnType: 'Guaranteed',
        suitableForGoalTypes: ['increaseSavingsRate', 'buildEmergencyFund'],
        disclaimer:
            'Fi Smart Deposits are powered by Federal Bank. DICGC insurance up to ₹5 lakh applies.',
      ),
      commissionRate: 0.0,
      lastUpdated: _kNow,
    ),
    PartnerProgram(
      programId: const ProgramId('icici_amazon_cc'),
      brand: _brands['icici']!,
      productName: 'Amazon Pay Credit Card',
      instrument: FinancialInstrument.creditCardCashback,
      suitableDecisionTypes: const ['optimizeSubscription'],
      keyMetric: 'Up to 5%',
      keyMetricLabel: 'Cashback on every spend',
      returnRate: null,
      minAmount: const Money(amount: 0, currency: Currency.inr),
      riskLevel: RiskLevel.low,
      taxBenefit: false,
      active: true,
      tagline: "Earn ₹12,000–18,000/year on money you'd spend anyway",
      metadata: const ProductMetadata(
        regulator: 'RBI',
        taxTreatment: 'Cashback is non-taxable',
        lockInDays: 0,
        minHorizonMonths: 0,
        liquidityScore: 1.0,
        capitalGuarantee: false,
        returnType: 'Guaranteed',
        suitableForGoalTypes: ['optimizeSubscription'],
        disclaimer:
            'Credit cards involve risk of debt if balance is not paid in full. Subject to credit eligibility.',
      ),
      commissionRate: 0.0,
      lastUpdated: _kNow,
    ),
  ];

  // Stable timestamp for all catalog entries — avoids unnecessary rebuilds.
  static final _kNow = DateTime(2026, 8, 3);

  // ── ProductCatalog implementation ─────────────────────────────────────────

  @override
  List<PartnerProgram> getAll() =>
      List.unmodifiable(_programs.where((p) => p.active));

  @override
  List<PartnerProgram> getByInstrument(FinancialInstrument instrument) =>
      _programs.where((p) => p.active && p.instrument == instrument).toList();

  @override
  PartnerProgram? getById(ProgramId id) {
    for (final p in _programs) {
      if (p.active && p.programId == id) return p;
    }
    return null;
  }
}
