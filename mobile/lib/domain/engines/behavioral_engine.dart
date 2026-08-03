// Defines the abstract BehavioralEngine interface — Tier 5, not yet built.

import '../shared/result.dart';
import '../value_objects/ids.dart';
import '../behavioral/behavior_profile.dart';
import '../behavioral/behavioral_vector.dart';

/// Abstract contract for the Behavioral Engine (Tier 5 — not built).
/// When built, this engine calibrates the BehavioralVector from observed user behaviour.
abstract class BehavioralEngine {
  String get engineVersion;
  bool get isEnabled;

  Future<Result<BehaviorProfile>> computeProfile({required UserId userId});

  Future<Result<BehavioralVector>> calibrateVector({
    required UserId userId,
    required List<Map<String, dynamic>> observations,
  });
}
