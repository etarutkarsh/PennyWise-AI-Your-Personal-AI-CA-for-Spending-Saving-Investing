/// Stub — blocked on /ai/chat backend endpoint.
abstract interface class AIReviewGenerator {
  Future<String> generateNarrative(
    String merchantKey,
    double totalSpent,
    String usageInsight,
    String recommendation,
  );
}
