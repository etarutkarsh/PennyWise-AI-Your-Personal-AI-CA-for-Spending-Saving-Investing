import '../../../domain/ingestion/merchant_learning_entry.dart';

/// Marks a merchant learning queue entry as intentionally ignored.
///
/// Use for: bank internal codes, noise strings, spam prefixes that will
/// never map to a real merchant (e.g. "NEFT/00001234", "IMPS-REF", "XXXX").
/// Ignored entries are removed from the review queue but kept in the audit log.
class IgnoreMerchantEntryUseCase {
  const IgnoreMerchantEntryUseCase(this._queue);

  final MerchantLearningQueue _queue;

  void call(String rawMerchant) => _queue.ignore(rawMerchant);
}
