import '../../domain/decision/decision.dart';
import '../../domain/decision/repositories/decision_repository.dart';
import '../../domain/shared/result.dart';
import '../../domain/value_objects/ids.dart';

class RecordDecisionLifecycleParams {
  final DecisionId decisionId;
  final DecisionLifecycleState state;
  const RecordDecisionLifecycleParams(this.decisionId, this.state);
}

class RecordDecisionLifecycleUseCase {
  const RecordDecisionLifecycleUseCase(this._repository);
  final DecisionRepository _repository;

  Future<Result<void>> call(RecordDecisionLifecycleParams params) =>
      _repository.recordLifecycleEvent(params.decisionId, params.state);
}
