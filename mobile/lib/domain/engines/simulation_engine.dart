// Defines the abstract SimulationEngine interface for Step-Up SIP and Monte Carlo projections.

import '../shared/result.dart';
import '../value_objects/money.dart';
import '../value_objects/time_horizon.dart';
import '../finance/sip_calculation.dart';

/// Abstract contract for the Simulation Engine.
/// Step-Up SIP formula is Tier 3 (not built); Monte Carlo is not built.
abstract class SimulationEngine {
  String get engineVersion;
  bool get isEnabled;

  Future<Result<SIPCalculation>> computeStepUpSip({
    required Money targetAmount,
    required TimeHorizon horizon,
    required double stepUpRate,
    required Money maxMonthlyCapacity,
  });
}
