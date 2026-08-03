import '../../domain/engines/duplicate_detector.dart';
import '../../domain/engines/transaction_normalizer.dart';
import '../../domain/ingestion/canonical_transaction.dart';
import '../../domain/ingestion/transaction_candidate.dart';
import '../../domain/shared/data_source.dart';

class IngestTransactionsParams {
  const IngestTransactionsParams({
    required this.rawEvents,
    this.amountTolerance = 1.0,
    this.dateToleranceDays = 2,
  });

  /// Each map must have: id, rawMerchant, amount, direction, date (DateTime),
  /// source (String), and optionally: paymentRailHint, confidence, accountLast4, rawText.
  final List<Map<String, dynamic>> rawEvents;
  final double amountTolerance;
  final int dateToleranceDays;
}

/// Full canonical transaction pipeline — the single entry point for all ingestion sources.
///
/// Pipeline:
///   RawEvents → TransactionNormalizer → [TransactionCandidate] →
///   DuplicateDetector → [CanonicalTransaction]
///
/// Every ingestion source (SMS, AA, OCR, manual) calls this use case.
/// The output is a list of CanonicalTransactions ready for Health/Decision/Behavioral engines.
class IngestTransactionsUseCase {
  const IngestTransactionsUseCase({
    required TransactionNormalizer normalizer,
    required DuplicateDetector deduplicator,
  })  : _normalizer = normalizer,
        _deduplicator = deduplicator;

  final TransactionNormalizer _normalizer;
  final DuplicateDetector _deduplicator;

  IngestionResult call(IngestTransactionsParams params) {
    if (params.rawEvents.isEmpty) {
      return const IngestionResult(
        canonical: [],
        candidateCount: 0,
        duplicatesRemoved: 0,
        reconciledCount: 0,
        sourceBreakdown: {},
      );
    }

    // Step 1: Normalize all raw events
    final candidates = _normalizer.normalizeAll(params.rawEvents);

    // Step 2: Deduplicate and reconcile
    final dedup = _deduplicator.deduplicate(
      candidates,
      amountTolerance: params.amountTolerance,
      dateToleranceDays: params.dateToleranceDays,
    );

    // Step 3: Build source breakdown
    final sourceBreakdown = <DataSource, int>{};
    for (final c in candidates) {
      sourceBreakdown[c.source] = (sourceBreakdown[c.source] ?? 0) + 1;
    }

    return IngestionResult(
      canonical: dedup.canonical,
      candidateCount: candidates.length,
      duplicatesRemoved: dedup.duplicatesRemoved,
      reconciledCount: dedup.reconciledCount,
      sourceBreakdown: sourceBreakdown,
    );
  }
}

class IngestionResult {
  const IngestionResult({
    required this.canonical,
    required this.candidateCount,
    required this.duplicatesRemoved,
    required this.reconciledCount,
    required this.sourceBreakdown,
  });

  final List<CanonicalTransaction> canonical;
  final int candidateCount;
  final int duplicatesRemoved;
  final int reconciledCount;
  final Map<DataSource, int> sourceBreakdown;

  int get canonicalCount => canonical.length;
  bool get hasReconciliation => reconciledCount > 0;

  /// Subset of canonical transactions that are mandate-based (key for CommitmentEngine).
  List<CanonicalTransaction> get mandateTransactions =>
      canonical.where((t) => t.isMandate).toList();

  /// Subset confirmed by AA or multi-source reconciliation.
  List<CanonicalTransaction> get verifiedTransactions =>
      canonical.where((t) => t.isVerified).toList();

  @override
  String toString() =>
      'IngestionResult(canonical: $canonicalCount, deduped: $duplicatesRemoved, '
      'reconciled: $reconciledCount)';
}
