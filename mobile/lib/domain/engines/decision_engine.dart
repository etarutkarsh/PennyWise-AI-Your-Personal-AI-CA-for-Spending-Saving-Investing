// Defines the abstract DecisionEngine interface — the primary computation engine of PennyWise.

import '../shared/result.dart';
import '../value_objects/ids.dart';
import '../decision/decision_response.dart';

/// Abstract contract for the Decision Engine.
/// V1 is rule-based (built). V2 is multi-axis (Tier 3 — not built).
abstract class DecisionEngine {
  String get engineVersion;
  bool get isEnabled;

  Future<Result<DecisionResponse>> compute({required UserId userId});
}
