import '../finance/financial_age.dart';
import '../partner/matching_context.dart';
import '../finance/health_score.dart';

/// Computes Financial Age from the MatchingContext and HealthScore.
/// Financial Age surfaces the gap between chronological and behavioral financial maturity.
abstract class FinancialAgeEngine {
  String get engineVersion;

  FinancialAge compute({
    required MatchingContext context,
    required HealthScore healthScore,
    required int chronologicalAge,
  });
}
