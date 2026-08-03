import 'package:pennywise_ai/domain/decision/behavioral_context.dart';
import 'package:pennywise_ai/domain/decision/decision_type.dart';
import 'package:pennywise_ai/domain/partner/partner_program.dart';
import 'package:pennywise_ai/domain/partner/ranked_partner_program.dart';
import 'package:pennywise_ai/domain/partner/repositories/partner_repository.dart';
import 'package:pennywise_ai/domain/shared/result.dart';
import 'package:pennywise_ai/domain/value_objects/ids.dart';
import 'package:pennywise_ai/infrastructure/mappers/partner_mapper.dart';

class HardcodedPartnerRepository implements PartnerProgramRepository {
  const HardcodedPartnerRepository(this._mapper);
  final PartnerMapper _mapper;

  // Authoritative hardcoded list — moved OUT of bank_program_slider.dart
  // into this infrastructure class. The slider receives these as parameters.
  static final List<_HardcodedProgram> _catalog = [
    _HardcodedProgram(
      id: 'hdfc_rd',
      partnerName: 'HDFC Bank',
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
    _HardcodedProgram(
      id: 'nippon_sip',
      partnerName: 'Nippon India MF',
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
    _HardcodedProgram(
      id: 'jar_gold',
      partnerName: 'Jar · Digital Gold',
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
    _HardcodedProgram(
      id: 'axis_elss',
      partnerName: 'Axis Mutual Fund',
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
    _HardcodedProgram(
      id: 'fi_auto_save',
      partnerName: 'Fi Money',
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
    _HardcodedProgram(
      id: 'icici_amazon_cc',
      partnerName: 'ICICI Bank',
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
    // Simple ranking: exact decision type match first, then everything else
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
      return _mapper.fromHardcodedProgram(
        id: p.id,
        partnerName: p.partnerName,
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
    _HardcodedProgram? match;
    for (final p in _catalog) {
      if (p.id == id.value) {
        match = p;
        break;
      }
    }
    if (match == null) return Result.failure('Program not found: ${id.value}');
    final ranked = _mapper.fromHardcodedProgram(
      id: match.id,
      partnerName: match.partnerName,
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

class _HardcodedProgram {
  final String id;
  final String partnerName;
  final String productName;
  final String keyMetric;
  final String keyMetricLabel;
  final String tagline;
  final String goalChip;
  final Set<DecisionType> suitableTypes;
  final double minAmount;
  final String ctaLabel;
  final double matchScore;

  const _HardcodedProgram({
    required this.id,
    required this.partnerName,
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
