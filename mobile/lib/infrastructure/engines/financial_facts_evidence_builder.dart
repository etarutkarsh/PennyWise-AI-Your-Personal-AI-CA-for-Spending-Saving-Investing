import '../../domain/decision/decision_type.dart';
import '../../domain/decision/explanation.dart';
import '../../domain/engines/evidence_builder.dart';
import '../../domain/partner/matching_context.dart';
import '../../domain/shared/data_confidence_report.dart';
import '../../domain/shared/data_source.dart';
import '../../domain/shared/financial_facts.dart';
import '../../domain/value_objects/ids.dart';

/// Replaces [StubEvidenceBuilder] — assembles evidence from real [FinancialFacts]
/// and applies [DataConfidenceReport] gaps to [missingDataLimitations].
///
/// Two call paths:
/// 1. [buildFromFacts] — primary path; uses FinancialFacts + DataConfidenceReport
///    for structured, source-tagged evidence with confidence + freshness.
/// 2. [buildFor] — backward-compat interface path; falls back to MatchingContext
///    when the caller does not have FinancialFacts available yet.
///
/// Rule: evidence items are never invented. If a fact is null, no evidence
/// item is emitted for it. Gaps surface in limitations, not silent omissions.
class FinancialFactsEvidenceBuilder implements EvidenceBuilder {
  const FinancialFactsEvidenceBuilder();

  @override
  String get engineVersion => 'evidence-builder-rule-v1';

  // ─── Primary API ──────────────────────────────────────────────────────────

  /// Build structured evidence from computed [FinancialFacts] and a
  /// [DataConfidenceReport]. Call this from any engine that has run the
  /// full fact-builder pipeline.
  List<EvidenceItem> buildFromFacts(
    FinancialFacts facts,
    DataConfidenceReport report,
  ) {
    final items = <EvidenceItem>[];

    if (facts.monthlyIncome != null) {
      final f = facts.monthlyIncome!;
      items.add(EvidenceItem(
        label: 'Monthly income',
        value: '₹${f.value.toStringAsFixed(0)}',
        source: f.source.id,
        freshness: f.timestamp,
        confidence: f.confidence,
        engineVersion: f.engineVersion,
      ));
    }

    if (facts.monthlyExpenses != null) {
      final f = facts.monthlyExpenses!;
      items.add(EvidenceItem(
        label: 'Monthly expenses (3-month avg)',
        value: '₹${f.value.toStringAsFixed(0)}',
        source: f.source.id,
        freshness: f.timestamp,
        confidence: f.confidence,
        engineVersion: f.engineVersion,
      ));
    }

    if (facts.savingsRate != null) {
      final f = facts.savingsRate!;
      final pct = (f.value * 100).toStringAsFixed(1);
      items.add(EvidenceItem(
        label: 'Savings rate',
        value: '$pct%',
        source: f.source.id,
        freshness: f.timestamp,
        confidence: f.confidence,
        engineVersion: f.engineVersion,
      ));
    }

    if (facts.recurringCommitmentsTotal != null) {
      final f = facts.recurringCommitmentsTotal!;
      items.add(EvidenceItem(
        label: 'Monthly recurring commitments',
        value: '₹${f.value.toStringAsFixed(0)}',
        source: f.source.id,
        freshness: f.timestamp,
        confidence: f.confidence,
        engineVersion: f.engineVersion,
      ));
    }

    if (facts.emergencyFundMonths != null) {
      final f = facts.emergencyFundMonths!;
      items.add(EvidenceItem(
        label: 'Emergency fund coverage',
        value: '${f.value.toStringAsFixed(1)} months',
        source: f.source.id,
        freshness: f.timestamp,
        confidence: f.confidence,
        engineVersion: f.engineVersion,
      ));
    }

    if (facts.debtRatio != null) {
      final f = facts.debtRatio!;
      final pct = (f.value * 100).toStringAsFixed(1);
      items.add(EvidenceItem(
        label: 'EMI-to-income ratio',
        value: '$pct%',
        source: f.source.id,
        freshness: f.timestamp,
        confidence: f.confidence,
        engineVersion: f.engineVersion,
      ));
    }

    if (facts.existingInvestmentTotal != null) {
      final f = facts.existingInvestmentTotal!;
      items.add(EvidenceItem(
        label: 'Total investments',
        value: '₹${f.value.toStringAsFixed(0)}',
        source: f.source.id,
        freshness: f.timestamp,
        confidence: f.confidence,
        engineVersion: f.engineVersion,
      ));
    }

    // Data confidence summary evidence
    items.add(EvidenceItem(
      label: 'Data confidence',
      value: '${(report.overallConfidence * 100).toInt()}%',
      source: DataSource.transactionHistory.id,
      freshness: report.assessedAt,
      confidence: report.overallConfidence,
    ));

    return items;
  }

  /// Returns limitation strings derived from [DataConfidenceReport.missingDataGaps].
  /// These are honest, actionable messages — not hardcoded strings.
  List<String> missingDataLimitationsFromReport(DataConfidenceReport report) {
    return report.limitationStrings;
  }

  // ─── EvidenceBuilder interface (backward-compat path) ────────────────────

  @override
  Future<List<EvidenceItem>> buildFor({
    required UserId userId,
    required DecisionType decisionType,
    required MatchingContext context,
  }) async {
    final items = <EvidenceItem>[];
    final now = DateTime.now();

    if (context.monthlySurplus > 0) {
      items.add(EvidenceItem(
        label: 'Estimated monthly surplus',
        value: '₹${context.monthlySurplus.toStringAsFixed(0)}',
        source: DataSource.transactionHistory.id,
        freshness: now,
        confidence: 0.50,
      ));
    }

    if (context.emergencyFundMonths > 0) {
      items.add(EvidenceItem(
        label: 'Emergency fund coverage',
        value: '${context.emergencyFundMonths.toStringAsFixed(1)} months',
        source: DataSource.goalData.id,
        freshness: now,
        confidence: 0.60,
      ));
    }

    if (context.horizonMonths > 0) {
      final years = (context.horizonMonths / 12).toStringAsFixed(1);
      items.add(EvidenceItem(
        label: 'Goal investment horizon',
        value: '$years years',
        source: DataSource.goalData.id,
        freshness: now,
        confidence: 0.80,
      ));
    }

    items.add(EvidenceItem(
      label: 'Risk profile',
      value: context.riskProfile,
      source: DataSource.manual.id,
      freshness: now,
      confidence: 1.0,
    ));

    if (context.healthScore != 50) {
      items.add(EvidenceItem(
        label: 'Financial health score',
        value: '${context.healthScore.toInt()}/100',
        source: DataSource.transactionHistory.id,
        freshness: now,
        confidence: 0.70,
      ));
    }

    return items;
  }

  @override
  List<String> missingDataLimitations(MatchingContext context) {
    final limitations = <String>[
      'Bank account is not linked — connect via Account Aggregator for '
          'bank-verified evidence and higher recommendation confidence.',
      'SMS transaction intelligence is inactive — enable to detect '
          'salary, EMI, and subscription patterns automatically.',
    ];
    if (context.emergencyFundMonths <= 0) {
      limitations.add(
        'Emergency fund goal not found — add one to improve '
        'recommendation accuracy.',
      );
    }
    if (context.monthlySurplus <= 0) {
      limitations.add(
        'Monthly surplus cannot be estimated without transaction history.',
      );
    }
    return limitations;
  }
}
