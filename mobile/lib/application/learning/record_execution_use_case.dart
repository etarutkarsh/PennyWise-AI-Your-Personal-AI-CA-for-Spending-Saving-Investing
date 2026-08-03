import '../../domain/learning/decision_execution.dart';
import '../../domain/value_objects/ids.dart';

class RecordExecutionParams {
  const RecordExecutionParams({
    required this.decisionId,
    required this.userId,
    required this.executed,
    required this.executionSource,
    this.amountExecuted,
    this.confidence = 1.0,
    this.note,
  });

  final DecisionId decisionId;
  final UserId userId;
  final bool executed;
  final ExecutionSource executionSource;
  final double? amountExecuted;
  final double confidence;
  final String? note;
}

/// Records whether a decision was actually executed.
/// Source of truth for Step 3 of the Decision Learning Loop.
class RecordExecutionUseCase {
  const RecordExecutionUseCase();

  DecisionExecution call(RecordExecutionParams params) {
    return DecisionExecution(
      decisionId: params.decisionId,
      userId: params.userId,
      executed: params.executed,
      executionSource: params.executionSource,
      executedAt: DateTime.now(),
      amountExecuted: params.amountExecuted,
      confidence: params.confidence,
      note: params.note,
    );
  }
}
