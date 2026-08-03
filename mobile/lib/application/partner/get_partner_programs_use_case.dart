import '../../domain/decision/behavioral_context.dart';
import '../../domain/decision/decision_type.dart';
import '../../domain/partner/ranked_partner_program.dart';
import '../../domain/partner/repositories/partner_repository.dart';
import '../../domain/shared/result.dart';

class GetPartnerProgramsParams {
  final DecisionType decisionContext;
  final BehavioralContext behavioral;
  final int limit;
  const GetPartnerProgramsParams({
    required this.decisionContext,
    required this.behavioral,
    this.limit = 6,
  });
}

class GetPartnerProgramsUseCase {
  const GetPartnerProgramsUseCase(this._repository);
  final PartnerProgramRepository _repository;

  Future<Result<List<RankedPartnerProgram>>> call(
          GetPartnerProgramsParams params) =>
      _repository.getRankedPrograms(
        decisionContext: params.decisionContext,
        behavioral: params.behavioral,
        limit: params.limit,
      );
}
