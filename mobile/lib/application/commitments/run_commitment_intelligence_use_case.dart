import '../../core/services/commitment_intelligence/commitment_engine.dart';
import '../../domain/commitments/goal_snapshot.dart';
import '../../domain/commitments/recurring_commitments_intelligence.dart';
import '../../features/goals/domain/entities/goal_entity.dart';
import '../../features/transactions/domain/entities/transaction_entity.dart';
import '../../infrastructure/engines/commitments/recurring_commitments_intelligence_engine.dart';

class RunCommitmentIntelligenceParams {
  const RunCommitmentIntelligenceParams({
    required this.transactions,
    required this.monthlyIncome,
    this.goals = const [],
    this.previousMerchantKeys,
    this.previousAmounts,
  });

  final List<TransactionEntity> transactions;
  final double monthlyIncome;
  final List<GoalEntity> goals;
  final List<String>? previousMerchantKeys;
  final Map<String, double>? previousAmounts;
}

class RunCommitmentIntelligenceUseCase {
  const RunCommitmentIntelligenceUseCase(this._engine);

  final RecurringCommitmentsIntelligenceEngine _engine;

  RecurringCommitmentsIntelligence call(
      RunCommitmentIntelligenceParams params) {
    final summary = CommitmentEngine.analyze(
      params.transactions,
      params.monthlyIncome,
    );
    final goalSnapshots = params.goals.map(_toSnapshot).toList();
    return _engine.analyze(
      summary,
      goals: goalSnapshots,
      previousMerchantKeys: params.previousMerchantKeys,
      previousAmounts: params.previousAmounts,
    );
  }

  static GoalSnapshot _toSnapshot(GoalEntity g) => GoalSnapshot(
        id: g.id,
        name: g.name,
        goalType: g.goalType,
        targetAmount: g.targetAmount,
        currentSaved: g.currentSaved,
        monthlyContribution: g.recommendedMonthlyContribution,
        deadline: g.deadline,
      );
}
