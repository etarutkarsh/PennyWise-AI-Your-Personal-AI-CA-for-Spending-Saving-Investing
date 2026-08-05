import '../../domain/behavioral/behavior_interpretation.dart';
import '../../domain/commitments/goal_snapshot.dart';
import '../../domain/engines/financial_reasoning_engine.dart';
import '../../domain/learning/learning_snapshot.dart';
import '../../domain/reasoning/decision_confidence_report.dart';
import '../../domain/reasoning/financial_reasoning_context.dart';
import '../../domain/shared/data_confidence_report.dart';
import '../../domain/shared/financial_facts.dart';

class RunFinancialReasoningParams {
  const RunFinancialReasoningParams({
    required this.facts,
    required this.dataConfidence,
    this.behavior,
    this.learningSnapshot,
    this.goals = const [],
    this.contextLabel,
  });

  final FinancialFacts facts;
  final DataConfidenceReport dataConfidence;
  final BehaviorInterpretation? behavior;
  final LearningSnapshot? learningSnapshot;
  final List<GoalSnapshot> goals;
  final String? contextLabel;
}

class RunFinancialReasoningUseCase {
  const RunFinancialReasoningUseCase(this._engine);

  final FinancialReasoningEngine _engine;

  DecisionConfidenceReport call(RunFinancialReasoningParams params) {
    final ctx = FinancialReasoningContext(
      facts: params.facts,
      dataConfidence: params.dataConfidence,
      behavior: params.behavior,
      learningSnapshot: params.learningSnapshot,
      goals: params.goals,
      contextLabel: params.contextLabel,
    );
    return _engine.reason(ctx);
  }
}
