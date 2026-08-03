import '../ingestion/transaction_candidate.dart';

/// Converts a raw ingestion event into a normalized TransactionCandidate.
/// Responsibilities: merchant resolution, payment rail classification, confidence assignment.
/// Does NOT deduplicate — that is DuplicateDetector's job.
abstract class TransactionNormalizer {
  String get engineVersion;

  /// Normalize a single raw event.
  /// [rawId] — the RawFinancialEvent.id from the ingestion layer.
  /// [rawMerchant] — original merchant string from the source.
  /// [amount] — transaction amount.
  /// [direction] — 'DEBIT' or 'CREDIT'.
  /// [date] — transaction date.
  /// [source] — DataSource of the originating event.
  /// [paymentRailHint] — optional raw rail string from the source (e.g. 'UPI-AUTOPAY', 'NACH').
  /// [confidence] — base confidence from the source (AA=1.0, SMS≈0.85, OCR≈0.70).
  /// [rawText] — original message for debugging.
  TransactionCandidate normalize({
    required String rawId,
    required String rawMerchant,
    required double amount,
    required String direction,
    required DateTime date,
    required String source,
    String? paymentRailHint,
    double confidence = 0.80,
    String? accountLast4,
    String? rawText,
  });

  /// Normalize a batch of raw events. Default implementation calls normalize() in a loop.
  List<TransactionCandidate> normalizeAll(List<Map<String, dynamic>> rawEvents) =>
      rawEvents.map((e) => normalize(
            rawId: e['id'] as String,
            rawMerchant: e['rawMerchant'] as String,
            amount: (e['amount'] as num).toDouble(),
            direction: e['direction'] as String,
            date: e['date'] as DateTime,
            source: e['source'] as String,
            paymentRailHint: e['paymentRailHint'] as String?,
            confidence: (e['confidence'] as num?)?.toDouble() ?? 0.80,
            accountLast4: e['accountLast4'] as String?,
            rawText: e['rawText'] as String?,
          )).toList();
}
