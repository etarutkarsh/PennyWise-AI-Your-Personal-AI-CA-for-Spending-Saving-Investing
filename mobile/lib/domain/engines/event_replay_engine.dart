import '../ingestion/canonical_transaction.dart';
import '../ingestion/extraction_result.dart';
import '../ingestion/parser_versions.dart';

/// Parameters for a replay run.
class EventReplayParams {
  const EventReplayParams({
    required this.rawEvents,
    required this.fromParserVersion,
    this.toParserVersion = kSmsParserVersion,
    this.dryRun = false,
  });

  /// The stored raw events to re-process (from the raw_transaction_sources audit table).
  /// Each map must have: id, rawText, source, originalParserVersion, ingestedAt.
  final List<Map<String, dynamic>> rawEvents;

  /// Only replay events parsed with versions older than this.
  final String fromParserVersion;

  /// The target version (defaults to the current parser version).
  final String toParserVersion;

  /// If true, compute what would change but do not write canonical transactions.
  final bool dryRun;
}

/// The result of a single event replay run.
class EventReplayResult {
  const EventReplayResult({
    required this.totalEvents,
    required this.eligibleForReplay,
    required this.successCount,
    required this.failedCount,
    required this.skippedCount,
    required this.updatedCanonical,
    required this.dryRun,
  });

  /// Total raw events examined.
  final int totalEvents;

  /// Events that matched the version filter.
  final int eligibleForReplay;

  /// Events successfully re-parsed and updated.
  final int successCount;

  /// Events that failed re-parsing (parser error or confidence < threshold).
  final int failedCount;

  /// Events skipped (already at target version, or isRejected/isPreDebitAlert).
  final int skippedCount;

  /// Updated canonical transactions (empty if dryRun = true).
  final List<CanonicalTransaction> updatedCanonical;

  final bool dryRun;

  double get successRate => eligibleForReplay > 0 ? successCount / eligibleForReplay : 0.0;

  @override
  String toString() =>
      'EventReplayResult(eligible=$eligibleForReplay, success=$successCount, '
      'failed=$failedCount, dry=$dryRun)';
}

/// Replays historical RawFinancialEvents through the current parser pipeline.
///
/// Use case: the SMS parser is upgraded to detect a new rail or fix a bug.
/// Without replay, historical transactions remain at the old (lower) quality.
/// With replay, re-parsing produces better ExtractionResults → updated CanonicalTransactions.
///
/// The audit trail is preserved: raw_transaction_sources.source_ref still points
/// to the original SMS. Only merchant_id, payment_rail, and confidence may be updated.
///
/// Pipeline per replayed event:
///   raw_text → SmsParserService.parse() → ExtractionResult
///            → TransactionNormalizer.normalize() → TransactionCandidate
///            → existing CanonicalTransaction updated (NOT replaced — same UUID)
abstract class EventReplayEngine {
  String get engineVersion;

  /// Replay a batch of raw events.
  /// Implementations must call SmsParserService (or the appropriate source parser)
  /// based on the event's source type.
  Future<EventReplayResult> replay(EventReplayParams params);

  /// Parse a single raw SMS body and return the ExtractionResult only.
  /// Used for ad-hoc re-parsing without writing to storage.
  ExtractionResult reparse(String rawText, {required String targetParserVersion});

  /// Returns the list of raw event IDs that would be eligible for replay
  /// given the version filter — without actually re-parsing them.
  List<String> eligibleEventIds(
    List<Map<String, dynamic>> rawEvents, {
    required String fromParserVersion,
    required String toParserVersion,
  });
}
