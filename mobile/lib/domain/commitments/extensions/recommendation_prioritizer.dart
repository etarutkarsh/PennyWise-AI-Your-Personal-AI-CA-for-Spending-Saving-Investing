import '../recurring_commitments_intelligence.dart';

/// Stub — will use Decision Engine v3 when built (Phase 10).
abstract interface class CommitmentRecommendationPrioritizer {
  List<String> topRecommendations(
    RecurringCommitmentsIntelligence intelligence, {
    int limit = 3,
  });
}
