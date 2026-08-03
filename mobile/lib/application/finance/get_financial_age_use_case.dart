import '../../domain/engines/financial_age_engine.dart';
import '../../domain/finance/financial_age.dart';
import '../../domain/finance/health_score.dart';
import '../../domain/partner/matching_context.dart';

class GetFinancialAgeParams {
  const GetFinancialAgeParams({
    required this.context,
    required this.healthScore,
    required this.chronologicalAge,
  });

  final MatchingContext context;
  final HealthScore healthScore;
  final int chronologicalAge;
}

class GetFinancialAgeUseCase {
  const GetFinancialAgeUseCase(this._engine);

  final FinancialAgeEngine _engine;

  FinancialAge call(GetFinancialAgeParams params) => _engine.compute(
        context: params.context,
        healthScore: params.healthScore,
        chronologicalAge: params.chronologicalAge,
      );
}
