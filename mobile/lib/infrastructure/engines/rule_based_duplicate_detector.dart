import '../../domain/engines/duplicate_detector.dart';
import '../../domain/ingestion/canonical_transaction.dart';
import '../../domain/ingestion/transaction_candidate.dart';

/// Rule-based duplicate detection using merchant + amount + date fingerprinting.
///
/// A duplicate is: same canonical merchant id + same amount (within tolerance)
/// + same direction + same date (within tolerance window).
///
/// Cross-source duplicates (e.g. same transaction from SMS + AA) are reconciled
/// into a single CanonicalTransaction with confidence boosted by multi-source agreement.
class RuleBasedDuplicateDetector implements DuplicateDetector {
  const RuleBasedDuplicateDetector();

  static const _kVersion = 'dedup-rule-v1';

  @override
  String get engineVersion => _kVersion;

  @override
  DeduplicationResult deduplicate(
    List<TransactionCandidate> candidates, {
    double amountTolerance = 1.0,
    int dateToleranceDays = 2,
  }) {
    if (candidates.isEmpty) {
      return const DeduplicationResult(
        canonical: [],
        totalInputCount: 0,
        duplicatesRemoved: 0,
        reconciledCount: 0,
      );
    }

    final total = candidates.length;
    final groups = <String, List<TransactionCandidate>>{};

    for (final candidate in candidates) {
      bool merged = false;
      for (final key in groups.keys) {
        final group = groups[key]!;
        if (_areDuplicates(candidate, group.first, amountTolerance, dateToleranceDays)) {
          group.add(candidate);
          merged = true;
          break;
        }
      }
      if (!merged) {
        groups[candidate.id] = [candidate];
      }
    }

    int duplicatesRemoved = 0;
    int reconciledCount = 0;

    final canonical = groups.values.map((group) {
      duplicatesRemoved += group.length - 1;
      if (group.length > 1) reconciledCount++;
      return group.length == 1
          ? CanonicalTransaction.fromCandidate(group.first)
          : CanonicalTransaction.reconcile(group);
    }).toList();

    return DeduplicationResult(
      canonical: canonical,
      totalInputCount: total,
      duplicatesRemoved: duplicatesRemoved,
      reconciledCount: reconciledCount,
    );
  }

  bool _areDuplicates(
    TransactionCandidate a,
    TransactionCandidate b,
    double amountTolerance,
    int dateToleranceDays,
  ) {
    // Direction must match
    if (a.direction != b.direction) return false;

    // Amount within tolerance
    if ((a.amount - b.amount).abs() > amountTolerance) return false;

    // Date within tolerance window
    final dateDiff = a.transactionDate.difference(b.transactionDate).inDays.abs();
    if (dateDiff > dateToleranceDays) return false;

    // Same canonical merchant id — the key dedup signal
    if (a.merchant.id != b.merchant.id) return false;

    // If both are unknown merchants, also require same raw merchant string
    if (!a.merchant.isKnown && !b.merchant.isKnown) {
      final aNorm = a.rawMerchant.toLowerCase().trim();
      final bNorm = b.rawMerchant.toLowerCase().trim();
      if (aNorm != bNorm) return false;
    }

    return true;
  }
}
