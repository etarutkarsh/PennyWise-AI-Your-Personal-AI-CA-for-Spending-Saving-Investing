import '../../domain/engines/momentum_engine.dart';
import '../../domain/finance/health_score.dart';
import '../../domain/finance/momentum.dart';

class GetMomentumParams {
  const GetMomentumParams({
    required this.snapshots,
    this.periodDays = 30,
  });

  /// Time-ordered list of health score snapshots (oldest first).
  final List<HealthScore> snapshots;
  final int periodDays;
}

class GetMomentumUseCase {
  const GetMomentumUseCase(this._engine);

  final MomentumEngine _engine;

  Momentum call(GetMomentumParams params) => _engine.compute(
        snapshots: params.snapshots,
        periodDays: params.periodDays,
      );
}
