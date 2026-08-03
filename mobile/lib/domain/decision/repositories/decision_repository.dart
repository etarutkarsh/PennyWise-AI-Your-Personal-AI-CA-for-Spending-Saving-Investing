// Defines the abstract DecisionRepository interface for the Decision bounded context.

import '../../shared/result.dart';
import '../../value_objects/ids.dart';
import '../decision.dart';
import '../decision_feed.dart';
import '../decision_response.dart';

/// Abstract contract for accessing and mutating Decision data.
/// Implementations live in the data layer and must not be imported by domain code.
abstract class DecisionRepository {
  Future<Result<DecisionResponse>> getTodaysDecision();

  Future<Result<Decision>> getDecisionById(DecisionId id);

  Future<Result<List<Decision>>> getDecisionHistory({
    int limit = 20,
    int offset = 0,
  });

  Future<Result<void>> recordLifecycleEvent(
    DecisionId id,
    DecisionLifecycleState state,
  );

  Future<Result<DecisionFeed>> getDecisionFeed({int limit = 20});
}
