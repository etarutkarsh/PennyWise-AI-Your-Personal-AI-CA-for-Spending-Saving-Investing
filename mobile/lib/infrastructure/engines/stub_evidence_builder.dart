import '../../domain/decision/decision_type.dart';
import '../../domain/decision/explanation.dart';
import '../../domain/engines/evidence_builder.dart';
import '../../domain/partner/matching_context.dart';
import '../../domain/shared/data_source.dart';
import '../../domain/value_objects/ids.dart';

/// Stub implementation of [EvidenceBuilder].
///
/// Produces minimal evidence from the [MatchingContext] already assembled
/// by the calling engine. This is honest about what it has: manual profile
/// data, goal state, and inferred commitment load. It does not produce
/// bank-grade evidence — that requires AA integration or SMS parsing.
///
/// When the Evidence Builder returns few items with low-fidelity sources,
/// [Confidence.score] automatically degrades. That degradation is then
/// surfaced honestly in [Explanation.limitations].
///
/// Replace with [GraphBackedEvidenceBuilder] in Phase 6 when the knowledge
/// graph is populated by the Financial Data Platform.
class StubEvidenceBuilder implements EvidenceBuilder {
  const StubEvidenceBuilder();

  static final _kNow = DateTime(2026, 8, 3);

  @override
  Future<List<EvidenceItem>> buildFor({
    required UserId userId,
    required DecisionType decisionType,
    required MatchingContext context,
  }) async {
    final items = <EvidenceItem>[];

    // ── Monthly surplus evidence ──────────────────────────────────────
    if (context.monthlySurplus > 0) {
      items.add(EvidenceItem(
        label: 'Estimated monthly surplus',
        value: '₹${context.monthlySurplus.toStringAsFixed(0)}',
        source: DataSource.transactionHistory.id,
        freshness: _kNow,
      ));
    }

    // ── Emergency fund evidence ───────────────────────────────────────
    if (context.emergencyFundMonths > 0) {
      items.add(EvidenceItem(
        label: 'Emergency fund coverage',
        value: '${context.emergencyFundMonths.toStringAsFixed(1)} months',
        source: DataSource.goalData.id,
        freshness: _kNow,
      ));
    }

    // ── Investment horizon evidence ───────────────────────────────────
    if (context.horizonMonths > 0) {
      final years = (context.horizonMonths / 12).toStringAsFixed(1);
      items.add(EvidenceItem(
        label: 'Goal investment horizon',
        value: '$years years',
        source: DataSource.goalData.id,
        freshness: _kNow,
      ));
    }

    // ── Risk profile evidence ─────────────────────────────────────────
    items.add(EvidenceItem(
      label: 'Risk profile',
      value: context.riskProfile,
      source: DataSource.manual.id,
      freshness: _kNow,
    ));

    // ── Health score evidence ─────────────────────────────────────────
    // 50 is the default unknown value; only emit if it looks meaningful
    if (context.healthScore != 50) {
      items.add(EvidenceItem(
        label: 'Financial health score',
        value: '${context.healthScore.toInt()}/100',
        source: DataSource.transactionHistory.id,
        freshness: _kNow,
      ));
    }

    return items;
  }

  @override
  List<String> missingDataLimitations(MatchingContext context) {
    final limitations = <String>[];

    limitations.add(
      'Bank account data is not linked — connect via Account Aggregator '
      'for bank-verified evidence.',
    );
    limitations.add(
      'SMS transaction intelligence is inactive — enable to detect '
      'salary, EMI, and subscription patterns automatically.',
    );

    if (context.emergencyFundMonths <= 0) {
      limitations.add('Emergency fund goal not found — add one to improve recommendation accuracy.');
    }
    if (context.monthlySurplus <= 0) {
      limitations.add(
        'Monthly surplus cannot be estimated without transaction history.',
      );
    }

    return limitations;
  }
}
