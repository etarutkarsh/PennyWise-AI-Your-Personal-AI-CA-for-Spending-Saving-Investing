// Defines the abstract PartnerProgramRepository interface for partner program data.

import '../../shared/result.dart';
import '../../value_objects/ids.dart';
import '../../decision/decision_type.dart';
import '../../decision/behavioral_context.dart';
import '../partner_program.dart';
import '../ranked_partner_program.dart';

/// Abstract contract for retrieving and ranking partner programs.
/// Implementations live in the data layer.
abstract class PartnerProgramRepository {
  Future<Result<List<RankedPartnerProgram>>> getRankedPrograms({
    required DecisionType decisionContext,
    required BehavioralContext behavioral,
    int limit = 6,
  });

  Future<Result<PartnerProgram>> getProgramById(ProgramId id);
}
