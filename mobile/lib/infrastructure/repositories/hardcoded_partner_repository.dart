import 'package:pennywise_ai/domain/decision/behavioral_context.dart';
import 'package:pennywise_ai/domain/decision/decision_type.dart';
import 'package:pennywise_ai/domain/partner/partner_assets.dart';
import 'package:pennywise_ai/domain/partner/partner_brand.dart';
import 'package:pennywise_ai/domain/partner/partner_icon_type.dart';
import 'package:pennywise_ai/domain/partner/partner_program.dart';
import 'package:pennywise_ai/domain/partner/ranked_partner_program.dart';
import 'package:pennywise_ai/domain/partner/repositories/partner_repository.dart';
import 'package:pennywise_ai/domain/shared/result.dart';
import 'package:pennywise_ai/domain/value_objects/ids.dart';
import 'package:pennywise_ai/infrastructure/mappers/partner_mapper.dart';

class HardcodedPartnerRepository implements PartnerProgramRepository {
  const HardcodedPartnerRepository(this._mapper);
  final PartnerMapper _mapper;

  // ── Partner Brand Catalog ─────────────────────────────────────────────────
  // Brand data lives here, not inside product entries — one brand, many products.

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
        // logoAssetPath: null — set when asset license is obtained (Sprint 2 step 2)
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
      trustStatement: 'RBI-compliant gold platform. Zero commission earned by PennyWise.',
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
      trustStatement: 'SEBI-registered AMC. Zero commission earned by PennyWise.',
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
      trustStatement: 'RBI-regulated neo-bank partner. Zero commission earned by PennyWise.',
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
      trustStatement: 'RBI-regulated bank. Zero commission earned by PennyWise.',
      website: 'https://www.icicibank.com',
      regulatedEntity: true,
    ),
  };

  // ── Product Catalog ───────────────────────────────────────────────────────

  static final List<_HardcodedProduct> _catalog = [
    _HardcodedProduct(
      id: 'hdfc_rd',
      brandId: 'hdfc',
      productName: 'Recurring Deposit',
      keyMetric: '7.1% p.a.',
      keyMetricLabel: 'Guaranteed return',
      tagline: 'Safe, predictable savings — zero market risk',
      goalChip: 'Emergency Fund',
      suitableTypes: {
        DecisionType.buildEmergencyFund,
        DecisionType.increaseSavingsRate,
      },
      minAmount: 1000,
      ctaLabel: 'Compare RD Rates',
      matchScore: 0.91,
    ),
    _HardcodedProduct(
      id: 'nippon_sip',
      brandId: 'nippon',
      productName: 'Nifty 50 Index SIP',
      keyMetric: '₹5K → ₹1.75 Cr',
      keyMetricLabel: '20-year SIP projection',
      tagline: 'Own all of India\'s top 50 companies for ₹100/day',
      goalChip: 'Long-term Wealth',
      suitableTypes: {DecisionType.startGoalSip, DecisionType.stepUpSip},
      minAmount: 500,
      ctaLabel: 'Start SIP',
      matchScore: 0.88,
    ),
    _HardcodedProduct(
      id: 'jar_gold',
      brandId: 'jar',
      productName: 'Digital Gold SIP',
      keyMetric: '12.4% CAGR',
      keyMetricLabel: '10-year gold return',
      tagline: 'Inflation hedge that never rusts',
      goalChip: 'Wealth Preservation',
      suitableTypes: {
        DecisionType.startGoalSip,
        DecisionType.rebalancePortfolio,
      },
      minAmount: 1,
      ctaLabel: 'See Gold Price',
      matchScore: 0.74,
    ),
    _HardcodedProduct(
      id: 'axis_elss',
      brandId: 'axis',
      productName: 'ELSS Tax Saver Fund',
      keyMetric: '₹46,800 saved',
      keyMetricLabel: 'Max annual tax saving',
      tagline: 'Invest ₹1.5L, save ₹46,800 tax — every year',
      goalChip: 'Tax Saving',
      suitableTypes: {DecisionType.optimizeTax},
      minAmount: 500,
      ctaLabel: 'Check 80C Limit',
      matchScore: 0.95,
    ),
    _HardcodedProduct(
      id: 'fi_auto_save',
      brandId: 'fi',
      productName: 'Smart Deposit (Auto-Save)',
      keyMetric: '6.5% p.a.',
      keyMetricLabel: 'On auto-saved balance',
      tagline: 'Savings happen automatically — no willpower needed',
      goalChip: 'Daily Discipline',
      suitableTypes: {
        DecisionType.increaseSavingsRate,
        DecisionType.buildEmergencyFund,
      },
      minAmount: 500,
      ctaLabel: 'Open Fi Account',
      matchScore: 0.82,
    ),
    _HardcodedProduct(
      id: 'icici_amazon_cc',
      brandId: 'icici',
      productName: 'Amazon Pay Credit Card',
      keyMetric: 'Up to 5%',
      keyMetricLabel: 'Cashback on every spend',
      tagline: 'Earn ₹12,000–18,000/year on money you\'d spend anyway',
      goalChip: 'Spend Smarter',
      suitableTypes: {DecisionType.optimizeSubscription},
      minAmount: 0,
      ctaLabel: 'Check Eligibility',
      matchScore: 0.68,
    ),
  ];

  @override
  Future<Result<List<RankedPartnerProgram>>> getRankedPrograms({
    required DecisionType decisionContext,
    required BehavioralContext behavioral,
    int limit = 6,
  }) async {
    final matched = _catalog
        .where((p) => p.suitableTypes.contains(decisionContext))
        .toList();
    final others = _catalog
        .where((p) => !p.suitableTypes.contains(decisionContext))
        .toList();

    final ranked = [...matched, ...others].take(limit).toList();

    final result = ranked.asMap().entries.map((entry) {
      final idx = entry.key;
      final p = entry.value;
      final brand = _brands[p.brandId]!;
      return _mapper.fromHardcodedProduct(
        id: p.id,
        brand: brand,
        productName: p.productName,
        keyMetric: p.keyMetric,
        keyMetricLabel: p.keyMetricLabel,
        tagline: p.tagline,
        goalChip: p.goalChip,
        minAmountValue: p.minAmount,
        ctaLabel: p.ctaLabel,
        rank: idx + 1,
        matchScore: p.matchScore,
      );
    }).toList();

    return Result.success(result);
  }

  @override
  Future<Result<PartnerProgram>> getProgramById(ProgramId id) async {
    _HardcodedProduct? match;
    for (final p in _catalog) {
      if (p.id == id.value) {
        match = p;
        break;
      }
    }
    if (match == null) return Result.failure('Program not found: ${id.value}');
    final brand = _brands[match.brandId]!;
    final ranked = _mapper.fromHardcodedProduct(
      id: match.id,
      brand: brand,
      productName: match.productName,
      keyMetric: match.keyMetric,
      keyMetricLabel: match.keyMetricLabel,
      tagline: match.tagline,
      goalChip: match.goalChip,
      minAmountValue: match.minAmount,
      ctaLabel: match.ctaLabel,
      rank: 1,
      matchScore: match.matchScore,
    );
    return Result.success(ranked.program);
  }
}

class _HardcodedProduct {
  final String id;
  final String brandId;
  final String productName;
  final String keyMetric;
  final String keyMetricLabel;
  final String tagline;
  final String goalChip;
  final Set<DecisionType> suitableTypes;
  final double minAmount;
  final String ctaLabel;
  final double matchScore;

  const _HardcodedProduct({
    required this.id,
    required this.brandId,
    required this.productName,
    required this.keyMetric,
    required this.keyMetricLabel,
    required this.tagline,
    required this.goalChip,
    required this.suitableTypes,
    required this.minAmount,
    required this.ctaLabel,
    required this.matchScore,
  });
}
