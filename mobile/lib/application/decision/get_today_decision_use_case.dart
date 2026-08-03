import '../../domain/decision/decision_response.dart';
import '../../domain/decision/repositories/decision_repository.dart';
import '../../domain/shared/result.dart';
import '../shared/use_case.dart';

class GetTodayDecisionUseCase implements NoParamUseCase<DecisionResponse> {
  const GetTodayDecisionUseCase(this._repository);
  final DecisionRepository _repository;

  @override
  Future<Result<DecisionResponse>> call() => _repository.getTodaysDecision();
}
