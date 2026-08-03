import 'package:flutter/foundation.dart';

/// Aggregate statistics for a single extracted field across a batch of SMS messages.
@immutable
class FieldMetrics {
  const FieldMetrics({
    required this.attempted,
    required this.succeeded,
    required this.highConfidence,
    required this.ambiguous,
  });

  /// Total number of SMS messages where extraction of this field was attempted.
  final int attempted;

  /// Number of attempts that produced a value (any confidence level).
  final int succeeded;

  /// Subset of [succeeded] where confidence was ≥ 0.85.
  final int highConfidence;

  /// Subset of [succeeded] where confidence was in [0.50, 0.85).
  final int ambiguous;

  /// Fraction of attempts that produced any value.
  double get successRate => attempted > 0 ? succeeded / attempted : 0.0;

  /// Fraction of attempts that produced a high-confidence value.
  double get highConfidenceRate => attempted > 0 ? highConfidence / attempted : 0.0;

  /// Number of attempts that produced no value.
  int get failed => attempted - succeeded;

  /// Zero-value sentinel for map lookups on fields that have no recorded data.
  static const FieldMetrics zero = FieldMetrics(
    attempted: 0,
    succeeded: 0,
    highConfidence: 0,
    ambiguous: 0,
  );
}

/// Immutable snapshot of parser performance for a specific bank (or all banks).
///
/// Produced by [SmsParserMetricsAccumulator.snapshot].
@immutable
class SmsParserMetrics {
  const SmsParserMetrics({
    required this.parserVersion,
    required this.bankId,
    required this.totalMessages,
    required this.usableCount,
    required this.rejectedCount,
    required this.preDebitFiltered,
    required this.unknownMerchants,
    required this.perField,
    required this.snapshotAt,
  });

  final String parserVersion;

  /// Bank this snapshot covers, or null for an aggregate across all banks.
  final String? bankId;

  final int totalMessages;
  final int usableCount;
  final int rejectedCount;

  /// SMS messages that were valid pre-debit alerts and correctly filtered out.
  final int preDebitFiltered;

  /// Transactions where merchant field could not be resolved to a known entity.
  final int unknownMerchants;

  /// Per-field extraction statistics keyed by field name
  /// ('amount', 'direction', 'merchant', 'rail', 'date', 'refId', etc.).
  final Map<String, FieldMetrics> perField;

  final DateTime snapshotAt;

  double get usableRate => totalMessages > 0 ? usableCount / totalMessages : 0.0;
  double get rejectionRate => totalMessages > 0 ? rejectedCount / totalMessages : 0.0;

  FieldMetrics? metricsFor(String field) => perField[field];
  FieldMetrics get amountMetrics => perField['amount'] ?? FieldMetrics.zero;
  FieldMetrics get merchantMetrics => perField['merchant'] ?? FieldMetrics.zero;
  FieldMetrics get railMetrics => perField['rail'] ?? FieldMetrics.zero;
  FieldMetrics get directionMetrics => perField['direction'] ?? FieldMetrics.zero;

  @override
  String toString() =>
      'SmsParserMetrics(v=$parserVersion, bank=$bankId, '
      'total=$totalMessages, usable=${(usableRate * 100).toStringAsFixed(1)}%, '
      'merchant=${(merchantMetrics.successRate * 100).toStringAsFixed(1)}%)';
}

// ── Accumulator helpers ───────────────────────────────────────────────────────

/// Outcome of a single field extraction attempt within one SMS message.
/// Used by [SmsParserMetricsAccumulator.recordMessage] to update per-field statistics.
enum FieldOutcome { success, highConfidence, ambiguous, failed }

class _FieldAccum {
  int attempted = 0;
  int succeeded = 0;
  int highConfidence = 0;
  int ambiguous = 0;

  void record(FieldOutcome outcome) {
    attempted++;
    switch (outcome) {
      case FieldOutcome.highConfidence:
        succeeded++;
        highConfidence++;
      case FieldOutcome.success:
        succeeded++;
      case FieldOutcome.ambiguous:
        succeeded++;
        ambiguous++;
      case FieldOutcome.failed:
        break;
    }
  }

  FieldMetrics toMetrics() => FieldMetrics(
        attempted: attempted,
        succeeded: succeeded,
        highConfidence: highConfidence,
        ambiguous: ambiguous,
      );
}

// ── Public accumulator ────────────────────────────────────────────────────────

/// Mutable accumulator that collects parser outcomes and produces an immutable
/// [SmsParserMetrics] snapshot on demand.
///
/// Typical usage:
/// ```dart
/// final accum = SmsParserMetricsAccumulator(parserVersion: 'hdfc-v1', bankId: 'hdfc');
/// // ... call accum.recordMessage(...) for each parsed SMS ...
/// final snapshot = accum.snapshot();
/// ```
class SmsParserMetricsAccumulator {
  SmsParserMetricsAccumulator({required this.parserVersion, this.bankId});

  final String parserVersion;

  /// Bank being tracked, or null for aggregate metrics.
  final String? bankId;

  int _total = 0;
  int _usable = 0;
  int _rejected = 0;
  int _preDebit = 0;
  int _unknownMerchants = 0;

  final Map<String, _FieldAccum> _fields = {};

  /// Record the outcome of parsing a single SMS message.
  ///
  /// [fieldOutcomes] maps field names to their extraction outcome so that
  /// per-field statistics stay up to date.
  void recordMessage({
    required bool usable,
    required bool isPreDebit,
    required bool rejected,
    required bool unknownMerchant,
    required Map<String, FieldOutcome> fieldOutcomes,
  }) {
    _total++;
    if (usable) _usable++;
    if (rejected) _rejected++;
    if (isPreDebit) _preDebit++;
    if (unknownMerchant) _unknownMerchants++;

    for (final entry in fieldOutcomes.entries) {
      _fields.putIfAbsent(entry.key, _FieldAccum.new);
      _fields[entry.key]!.record(entry.value);
    }
  }

  /// Produce an immutable snapshot of current statistics.
  SmsParserMetrics snapshot() {
    final fieldMap = <String, FieldMetrics>{
      for (final entry in _fields.entries) entry.key: entry.value.toMetrics(),
    };
    return SmsParserMetrics(
      parserVersion: parserVersion,
      bankId: bankId,
      totalMessages: _total,
      usableCount: _usable,
      rejectedCount: _rejected,
      preDebitFiltered: _preDebit,
      unknownMerchants: _unknownMerchants,
      perField: Map.unmodifiable(fieldMap),
      snapshotAt: DateTime.now(),
    );
  }

  /// Reset all counters — useful between processing batches.
  void reset() {
    _total = 0;
    _usable = 0;
    _rejected = 0;
    _preDebit = 0;
    _unknownMerchants = 0;
    _fields.clear();
  }
}
