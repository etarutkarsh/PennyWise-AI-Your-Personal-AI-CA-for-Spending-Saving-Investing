import '../../domain/decision/decision_response.dart';
import '../../domain/decision/decision_type.dart';
import '../../domain/decision/repositories/decision_repository.dart';
import '../../domain/partner/matching_context.dart';
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

    // Build MatchingContext from the decision type; fall back to a safe default.
    final decisionType = decision?.decision.type ?? DecisionType.buildEmergencyFund;
    final context = MatchingContext(primaryGoal: decisionType);

    List<RankedPartnerProgram> programs = [];
    final programsResult = await _partnerRepo.getRankedPrograms(
      context: context,
      limit: 6,
    );
    if (programsResult is Success<List<RankedPartnerProgram>>) {
      programs = programsResult.value;
    }

    return Result.success(DashboardFeedResult(
      todaysDecision: decision,
      partnerPrograms: programs,
    ));
  }
}
