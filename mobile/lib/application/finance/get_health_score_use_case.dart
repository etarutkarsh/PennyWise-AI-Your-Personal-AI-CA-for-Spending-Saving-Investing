import '../../domain/engines/health_score_engine.dart';
import '../../domain/finance/health_score.dart';
import '../../domain/partner/matching_context.dart';
import '../../domain/shared/result.dart';

/// Params for [GetHealthScoreUseCase].
class GetHealthScoreParams {
  const GetHealthScoreParams({
    required this.context,
    this.preferBackend = true,
  });

  /// The user's current financial context — used by the local engine
  /// as input when [preferBackend] is false or the backend call fails.
  final MatchingContext context;

  /// When true (default), attempt to fetch the richer backend score first.
  /// Falls back to the local [RuleBasedHealthScoreEngine] on network error.
  final bool preferBackend;
}

/// Computes or fetches the user's 10-dimension financial health score.
///
/// Strategy:
/// 1. If [GetHealthScoreParams.preferBackend] = true, calls [HealthScoreEngine.fetchFromBackend].
///    The backend engine has real transaction + goal data → richer score.
/// 2. On failure (offline, network error), falls back to [HealthScoreEngine.computeFrom]
///    with the current [MatchingContext].
///
/// Returns [HealthScore] with full [DimensionScore] breakdown, [topActions],
/// and [dataCompleteness] so callers know how much to trust the result.
class GetHealthScoreUseCase {
  const GetHealthScoreUseCase(this._engine);

  final HealthScoreEngine _engine;

  Future<Result<HealthScore>> call(GetHealthScoreParams params) async {
    if (params.preferBackend) {
      final backendResult = await _engine.fetchFromBackend();
      if (backendResult.isSuccess) return backendResult;
      // Fall through to local computation
    }

    // Local computation: no network, no database — uses MatchingContext
    final local = _engine.computeFrom(params.context);
    return Result.success(local);
  }
}
