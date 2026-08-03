import '../../../domain/ingestion/merchant_learning_entry.dart';

/// Returns the merchant learning queue sorted by review priority.
///
/// High-frequency unknown merchants appear first.
/// Called by developer tools / admin screens to action the review queue.
class GetMerchantReviewQueueUseCase {
  const GetMerchantReviewQueueUseCase(this._queue);

  final MerchantLearningQueue _queue;

  MerchantReviewQueueResult call() {
    final queue = _queue.reviewQueue;
    final pending = _queue.pendingReplay;
    return MerchantReviewQueueResult(
      pendingReview: queue,
      pendingReplay: pending,
      totalUnresolved: _queue.queueLength,
    );
  }
}

class MerchantReviewQueueResult {
  const MerchantReviewQueueResult({
    required this.pendingReview,
    required this.pendingReplay,
    required this.totalUnresolved,
  });

  /// Unknown merchants awaiting human review, sorted by priority.
  final List<MerchantLearningEntry> pendingReview;

  /// Resolved entries awaiting event replay.
  final List<MerchantLearningEntry> pendingReplay;

  final int totalUnresolved;

  bool get hasWork => pendingReview.isNotEmpty || pendingReplay.isNotEmpty;

  /// Top entry for immediate action.
  MerchantLearningEntry? get topPriority =>
      pendingReview.isEmpty ? null : pendingReview.first;
}
