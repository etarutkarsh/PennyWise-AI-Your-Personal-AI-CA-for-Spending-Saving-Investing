import '../ingestion/canonical_transaction.dart';
import '../ingestion/transaction_candidate.dart';

/// Result of duplicate detection over a set of TransactionCandidates.
class DeduplicationResult {
  const DeduplicationResult({
    required this.canonical,
    required this.totalInputCount,
    required this.duplicatesRemoved,
    required this.reconciledCount,
  });

  /// Final canonical transactions — deduplicated and reconciled.
  final List<CanonicalTransaction> canonical;

  final int totalInputCount;
  final int duplicatesRemoved;

  /// How many canonical transactions were confirmed by 2+ sources.
  final int reconciledCount;

  int get uniqueCount => canonical.length;

  double get deduplicationRate =>
      totalInputCount > 0 ? duplicatesRemoved / totalInputCount : 0.0;
}

/// Detects and merges duplicate TransactionCandidates from different sources.
///
/// A duplicate is: same canonical merchant + same amount (within tolerance)
/// + same direction + same date (within tolerance window).
///
/// Cross-source duplicates are reconciled into a single CanonicalTransaction
/// that carries confidence from all sources.
abstract class DuplicateDetector {
  String get engineVersion;

  /// Detect duplicates and produce canonical transactions.
  /// [candidates] — all normalized candidates from all sources.
  /// [amountTolerance] — max amount difference to still consider duplicate (default ₹1.0).
  /// [dateTolerance] — max date difference in days (default 2).
  DeduplicationResult deduplicate(
    List<TransactionCandidate> candidates, {
    double amountTolerance = 1.0,
    int dateToleranceDays = 2,
  });
}
