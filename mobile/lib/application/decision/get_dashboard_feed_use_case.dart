import '../../domain/decision/behavioral_context.dart';
import '../../domain/decision/decision_response.dart';
import '../../domain/decision/decision_type.dart';
import '../../domain/decision/repositories/decision_repository.dart';
import '../../domain/partner/ranked_partner_program.dart';
import '../../domain/partner/repositories/partner_repository.dart';
import '../../domain/shared/result.dart';
import '../shared/use_case.dart';

class DashboardFeedResult {
  final DecisionResponse? todaysDecision;
  final List<RankedPartnerProgram> partnerPrograms;
  const DashboardFeedResult({
    this.todaysDecision,
    required this.partnerPrograms,
  });
}

class GetDashboardFeedUseCase implements NoParamUseCase<DashboardFeedResult> {
  const GetDashboardFeedUseCase(this._decisionRepo, this._partnerRepo);
  final DecisionRepository _decisionRepo;
  final PartnerProgramRepository _partnerRepo;

  @override
  Future<Result<DashboardFeedResult>> call() async {
    // Fetch today's decision (best effort — failure returns null, not an error)
    DecisionResponse? decision;
    final decisionResult = await _decisionRepo.getTodaysDecision();
    if (decisionResult is Success<DecisionResponse>) {
      decision = decisionResult.value;
    }

    // Fetch partner programs contextual to the decision type
    final decisionType = decision?.decision.type;
    final behavioral = decision?.behavioralContext;

    List<RankedPartnerProgram> programs = [];
    if (decisionType != null && behavioral != null) {
      final programsResult = await _partnerRepo.getRankedPrograms(
        decisionContext: decisionType,
        behavioral: behavioral,
        limit: 6,
      );
      if (programsResult is Success<List<RankedPartnerProgram>>) {
        programs = programsResult.value;
      }
    } else {
      // Fallback: fetch default programs with no context
      final programsResult = await _partnerRepo.getRankedPrograms(
        decisionContext: DecisionType.buildEmergencyFund, // default context
        behavioral: BehavioralContext.uncalibrated(),
        limit: 6,
      );
      if (programsResult is Success<List<RankedPartnerProgram>>) {
        programs = programsResult.value;
      }
    }

    return Result.success(DashboardFeedResult(
      todaysDecision: decision,
      partnerPrograms: programs,
    ));
  }
}
