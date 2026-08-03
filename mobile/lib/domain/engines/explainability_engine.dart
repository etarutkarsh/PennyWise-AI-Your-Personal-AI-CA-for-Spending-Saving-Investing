// Defines the abstract ExplainabilityEngine interface — not yet built.

import '../shared/result.dart';
import '../decision/decision_type.dart';
import '../decision/explanation.dart';
import '../decision/behavioral_context.dart';

/// Abstract contract for the Explainability Engine (not built).
/// Generates human-readable, auditable explanations for every Decision.
abstract class ExplainabilityEngine {
  String get engineVersion;
  bool get isEnabled;

  Future<Result<Explanation>> explain({
    required DecisionType decisionType,
    required Map<String, dynamic> evidence,
    required BehavioralContext behavioral,
  });
}
