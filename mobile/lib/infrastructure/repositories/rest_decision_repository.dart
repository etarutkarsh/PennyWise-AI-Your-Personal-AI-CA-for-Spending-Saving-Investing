import 'package:pennywise_ai/core/services/app_services.dart';
import 'package:pennywise_ai/domain/decision/decision.dart';
import 'package:pennywise_ai/domain/decision/decision_feed.dart';
import 'package:pennywise_ai/domain/decision/decision_response.dart';
import 'package:pennywise_ai/domain/decision/repositories/decision_repository.dart';
import 'package:pennywise_ai/domain/shared/result.dart';
import 'package:pennywise_ai/domain/value_objects/ids.dart';
import 'package:pennywise_ai/infrastructure/mappers/decision_mapper.dart';

class RestDecisionRepository implements DecisionRepository {
  const RestDecisionRepository(this._mapper);
  final DecisionMapper _mapper;

  @override
  Future<Result<DecisionResponse>> getTodaysDecision() async {
    try {
      final model = await AppServices.instance.todayDecision.getToday();
      return Result.success(_mapper.fromModel(model));
    } catch (e) {
      return Result.failure(
        'Failed to fetch today\'s decision: $e',
        e is Exception ? e : null,
      );
    }
  }

  @override
  Future<Result<Decision>> getDecisionById(DecisionId id) async {
    return Result.failure('getDecisionById not yet implemented');
  }

  @override
  Future<Result<List<Decision>>> getDecisionHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    return Result.success(const []);
  }

  @override
  Future<Result<void>> recordLifecycleEvent(
    DecisionId id,
    DecisionLifecycleState state,
  ) async {
    try {
      // Fire-and-forget to backend — failure is non-fatal
      await AppServices.instance.apiClient.dio.post(
        '/decisions/${id.value}/lifecycle',
        data: {'state': state.name.toUpperCase()},
      );
      return Result.success(null);
    } catch (_) {
      // Non-fatal: lifecycle recording failure should never break the UI
      return Result.success(null);
    }
  }

  @override
  Future<Result<DecisionFeed>> getDecisionFeed({int limit = 20}) async {
    return Result.success(DecisionFeed(
      items: const [],
      generatedAt: DateTime.now(),
    ));
  }
}
