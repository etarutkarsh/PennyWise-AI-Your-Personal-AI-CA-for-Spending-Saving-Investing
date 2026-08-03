import '../../domain/partner/matching_context.dart';
import '../../domain/partner/ranked_partner_program.dart';
import '../../domain/partner/repositories/partner_repository.dart';
import '../../domain/shared/result.dart';

class GetPartnerProgramsParams {
  final MatchingContext context;
  final int limit;
  const GetPartnerProgramsParams({
    required this.context,
    this.limit = 6,
  });
}

class GetPartnerProgramsUseCase {
  const GetPartnerProgramsUseCase(this._repository);
  final PartnerProgramRepository _repository;

  Future<Result<List<RankedPartnerProgram>>> call(
          GetPartnerProgramsParams params) =>
      _repository.getRankedPrograms(
        context: params.context,
        limit: params.limit,
      );
}
