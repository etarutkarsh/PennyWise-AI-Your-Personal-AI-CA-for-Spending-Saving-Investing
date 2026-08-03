import '../finance/resilience_index.dart';
import '../partner/matching_context.dart';

/// Computes the Resilience Index — distinct from Health Score.
/// Answers: "If something bad happens tomorrow, how long can you survive?"
abstract class ResilienceEngine {
  String get engineVersion;

  ResilienceIndex compute(MatchingContext context);
}
