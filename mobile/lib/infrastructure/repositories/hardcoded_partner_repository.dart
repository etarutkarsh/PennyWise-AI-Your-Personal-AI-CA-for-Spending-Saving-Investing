import 'package:pennywise_ai/domain/engines/partner_matching_engine.dart';
import 'package:pennywise_ai/domain/partner/matching_context.dart';
import 'package:pennywise_ai/domain/partner/partner_program.dart';
import 'package:pennywise_ai/domain/partner/product_catalog.dart';
import 'package:pennywise_ai/domain/partner/ranked_partner_program.dart';
import 'package:pennywise_ai/domain/partner/repositories/partner_repository.dart';
import 'package:pennywise_ai/domain/shared/result.dart';
import 'package:pennywise_ai/domain/value_objects/ids.dart';

/// Thin orchestrator: catalog → matching engine → ranked programs.
///
/// Owns no product data and no ranking logic — those belong to
/// [ProductCatalog] and [PartnerMatchingEngine] respectively.
/// This class only wires them together and adapts the result
/// to the [PartnerProgramRepository] contract.
class HardcodedPartnerRepository implements PartnerProgramRepository {
  const HardcodedPartnerRepository({
    required ProductCatalog catalog,
    required PartnerMatchingEngine engine,
  })  : _catalog = catalog,
        _engine = engine;

  final ProductCatalog _catalog;
  final PartnerMatchingEngine _engine;

  @override
  Future<Result<List<RankedPartnerProgram>>> getRankedPrograms({
    required MatchingContext context,
    int limit = 6,
  }) async {
    final ranked = _engine.rank(
      catalog: _catalog.getAll(),
      context: context,
      limit: limit,
    );
    return Result.success(ranked);
  }

  @override
  Future<Result<PartnerProgram>> getProgramById(ProgramId id) async {
    final program = _catalog.getById(id);
    if (program == null) return Result.failure('Program not found: ${id.value}');
    return Result.success(program);
  }
}
