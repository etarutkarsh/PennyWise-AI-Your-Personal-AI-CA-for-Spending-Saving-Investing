import '../../domain/engines/partner_matching_engine.dart';
import '../../domain/partner/financial_instrument.dart';
import '../../domain/partner/match_result.dart';
import '../../domain/partner/matching_context.dart';
import '../../domain/partner/matching_policy.dart';
import '../../domain/partner/partner_program.dart';
import '../../domain/partner/partner_suitability.dart';
import '../../domain/partner/ranked_partner_program.dart';
import '../../domain/partner/recommendation_explanation.dart';
import '../../domain/partner/rejection_reason.dart';

/// Reasoning-first partner matching engine powered by modular policies.
///
/// Architecture:
///   1. Dispatch to the [MatchingPolicy] whose [targetGoals] covers the request.
///   2. Hard reject: programs that fail a fiduciary filter are excluded —
///      their [RejectionReason] surfaces in the "why not?" section of shown results.
///   3. Evaluate: policy returns a [MatchResult] with full structured reasoning.
///      Score is a *consequence* of the reasons, not the input to them.
///   4. Sort by score, discard 'notSuitable', cap at [limit].
///   5. Build [RankedPartnerProgram] — explanation sourced entirely from [MatchResult].
///
/// Commission is never a scoring signal. Fiduciary invariant enforced here.
class RuleBasedPartnerMatchingEngine implements PartnerMatchingEngine {
  const RuleBasedPartnerMatchingEngine(this._policies);

  final List<MatchingPolicy> _policies;

  @override
  String get engineVersion => 'rule-based-v1';

  @override
  List<RankedPartnerProgram> rank({
    required List<PartnerProgram> catalog,
    required MatchingContext context,
    int limit = 6,
  }) {
    final policy = _policyFor(context);
    final scored = <_ScoredProgram>[];
    final rejected = <RejectionReason>[];

    for (final program in catalog) {
      if (!program.active) continue;

      // Hard rejection — fiduciary filters.
      if (policy != null) {
        final reason = policy.reject(program, context);
        if (reason != null) {
          rejected.add(reason);
          continue;
        }
      }

      // Evaluate fit — reasoning-first.
      final result = policy?.evaluate(program, context) ??
          _defaultEvaluate(program, context);

      // Exclude programs below the minimum bar — don't show noise.
      if (PartnerSuitability.fromScore(result.score * 100) ==
          PartnerSuitability.notSuitable) continue;

      scored.add(_ScoredProgram(program: program, result: result));
    }

    // Sort best-fit first.
    scored.sort((a, b) => b.result.score.compareTo(a.result.score));

    final rejectionSummaries = _summariseRejections(rejected);

    return scored.take(limit).toList().asMap().entries.map((entry) {
      return _toRanked(
        rank: entry.key + 1,
        scored: entry.value,
        rejectionSummaries: rejectionSummaries,
      );
    }).toList();
  }

  // ── Policy dispatch ───────────────────────────────────────────────────────

  MatchingPolicy? _policyFor(MatchingContext context) {
    for (final policy in _policies) {
      if (policy.targetGoals.contains(context.primaryGoal)) return policy;
    }
    return null;
  }

  // ── Default evaluation (no policy for this goal) ──────────────────────────

  MatchResult _defaultEvaluate(PartnerProgram program, MatchingContext context) {
    final reasons = <String>[];
    double score = 0.40; // conservative neutral baseline

    if (program.metadata.capitalGuarantee) {
      score += 0.10;
      reasons.add('Capital protected');
    }
    if (program.metadata.liquidityScore >= 0.8) {
      score += 0.10;
      reasons.add('Highly liquid');
    }

    return MatchResult(
      score: score.clamp(0.0, 1.0),
      reasons: reasons,
      warnings: [],
      assumptions: ['No goal-specific policy active for this decision type yet'],
      limitations: ['Recommendation improves when a matching policy is built for this goal'],
    );
  }

  // ── Rejection summary ─────────────────────────────────────────────────────

  List<String> _summariseRejections(List<RejectionReason> rejected) {
    if (rejected.isEmpty) return [];
    final entries = rejected.take(2).map(
          (r) => '${r.program.productName}: ${r.explanation}',
        );
    return [
      if (rejected.length > 2)
        '${rejected.length} products excluded by fiduciary filters',
      ...entries,
      if (rejected.length > 2) '…and ${rejected.length - 2} more',
    ];
  }

  // ── Build RankedPartnerProgram ────────────────────────────────────────────

  RankedPartnerProgram _toRanked({
    required int rank,
    required _ScoredProgram scored,
    required List<String> rejectionSummaries,
  }) {
    final suitability = PartnerSuitability.fromScore(scored.result.score * 100);

    return RankedPartnerProgram(
      program: scored.program,
      rank: rank,
      matchScore: scored.result.score,
      suitability: suitability,
      explanation: RecommendationExplanation(
        headline: _headline(suitability, scored.program),
        summary: scored.program.tagline,
        because: scored.result.reasons,
        whyNot: [...scored.result.warnings, ...rejectionSummaries],
        assumptions: scored.result.assumptions,
        limitations: scored.result.limitations,
        alternatives: const [],
      ),
      trustStatement: scored.program.brand.trustStatement,
      ctaLabel: _ctaLabel(scored.program.instrument),
    );
  }

  String _headline(PartnerSuitability suitability, PartnerProgram program) =>
      switch (suitability) {
        PartnerSuitability.excellentMatch => 'Best fit for your goal',
        PartnerSuitability.strongMatch =>
          'Strong match — ${program.brand.shortName}',
        PartnerSuitability.goodMatch => 'Good option — ${program.productName}',
        PartnerSuitability.consider => 'Consider — ${program.productName}',
        PartnerSuitability.notSuitable => 'Not recommended',
      };

  String _ctaLabel(FinancialInstrument instrument) => switch (instrument) {
        FinancialInstrument.indexFundSip => 'Start SIP',
        FinancialInstrument.elssSip => 'Start ELSS SIP',
        FinancialInstrument.digitalGold => 'See Gold Price',
        FinancialInstrument.recurringDeposit => 'Compare Rates',
        FinancialInstrument.liquidFund => 'Invest Now',
        FinancialInstrument.ppf => 'Open PPF Account',
        FinancialInstrument.nps => 'Open NPS Account',
        FinancialInstrument.creditCardCashback => 'Check Eligibility',
        FinancialInstrument.termInsurance => 'Get Quote',
        FinancialInstrument.healthInsurance => 'Get Quote',
        _ => 'Learn More',
      };
}

class _ScoredProgram {
  const _ScoredProgram({required this.program, required this.result});
  final PartnerProgram program;
  final MatchResult result;
}
