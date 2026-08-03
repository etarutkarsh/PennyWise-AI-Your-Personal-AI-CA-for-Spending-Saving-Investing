import '../../domain/engines/resilience_engine.dart';
import '../../domain/finance/resilience_index.dart';
import '../../domain/partner/matching_context.dart';

class GetResilienceIndexUseCase {
  const GetResilienceIndexUseCase(this._engine);

  final ResilienceEngine _engine;

  ResilienceIndex call(MatchingContext context) => _engine.compute(context);
}
