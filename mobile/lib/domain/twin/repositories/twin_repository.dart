// Defines the abstract TwinRepository interface for the Digital Twin bounded context.

import '../../shared/result.dart';
import '../../value_objects/ids.dart';
import '../../behavioral/behavioral_vector.dart';
import '../financial_twin.dart';

/// Abstract contract for reading and updating the Digital Twin.
/// Implementations live in the data layer.
abstract class TwinRepository {
  Future<Result<FinancialTwin>> getTwin(UserId userId);

  Future<Result<void>> updateVector(
    TwinId twinId,
    BehavioralVector updatedVector,
  );
}
