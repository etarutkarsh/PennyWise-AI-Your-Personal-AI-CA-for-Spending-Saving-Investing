// Defines the abstract PartnerMatchingEngine interface — not yet built.

import '../shared/result.dart';
import '../decision/decision_type.dart';
import '../decision/behavioral_context.dart';
import '../partner/partner_program.dart';
import '../partner/ranked_partner_program.dart';

/// Abstract contract for the Partner Matching Engine (not built).
/// Ranks partner programs by fit for a given decision context and behavioral profile.
/// Commission is never a ranking signal — fiduciary invariant.
abstract class PartnerMatchingEngine {
  String get engineVersion;
  bool get isEnabled;

  Future<Result<List<RankedPartnerProgram>>> rankPrograms({
    required DecisionType context,
    required BehavioralContext behavioral,
    required List<PartnerProgram> catalog,
    int limit = 6,
  });
}
