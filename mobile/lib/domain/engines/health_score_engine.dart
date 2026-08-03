// Defines the HealthScoreEngine domain interface.

import '../finance/health_score.dart';
import '../partner/matching_context.dart';
import '../shared/result.dart';

/// Computes the 10-dimension financial health score.
///
/// The health score is the operating metric of PennyWise — used by the
/// Partner Matching Engine, Decision Engine, Behavioral Engine, and
/// Digital Twin. Improving data quality (connecting AA, enabling SMS)
/// directly improves the health score's [HealthScore.dataCompleteness]
/// and therefore the quality of every downstream recommendation.
///
/// Today: [RuleBasedHealthScoreEngine] computes from [MatchingContext].
/// Phase 6: [RestHealthScoreEngine] uses backend transaction + goal data.
abstract class HealthScoreEngine {
  String get engineVersion;

  /// Compute from the [MatchingContext] already assembled by the calling engine.
  ///
  /// This is synchronous — no network call. Uses whatever data is in the
  /// context to produce the best-available score. Dimensions without real
  /// data return conservative estimates with honest limitations.
  HealthScore computeFrom(MatchingContext context);

  /// Fetch the full health score from the backend.
  ///
  /// The backend engine has access to full transaction history and goal data
  /// and returns richer dimension breakdowns than the local [computeFrom].
  Future<Result<HealthScore>> fetchFromBackend();
}
