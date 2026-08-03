// Defines the abstract BehaviorRepository interface for behavioral profile data.

import '../../shared/result.dart';
import '../../value_objects/ids.dart';
import '../behavior_profile.dart';

/// Abstract contract for reading and writing behavioral profile data.
/// Implementations live in the data layer.
abstract class BehaviorRepository {
  Future<Result<BehaviorProfile>> getProfile(UserId userId);

  Future<Result<void>> recordObservation({
    required UserId userId,
    required String observationType,
    required Map<String, dynamic> data,
  });
}
