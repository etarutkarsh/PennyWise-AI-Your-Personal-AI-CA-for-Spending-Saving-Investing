// Defines the abstract PartnerProgramRepository interface.

import '../../shared/result.dart';
import '../../value_objects/ids.dart';
import '../matching_context.dart';
import '../partner_program.dart';
import '../ranked_partner_program.dart';

/// Abstract contract for the partner program catalog and ranking pipeline.
///
/// The repository returns the raw catalog; ranking is delegated to
/// PartnerMatchingEngine inside the concrete implementation. The use case
/// layer builds a MatchingContext from available user data and passes it here.
abstract class PartnerProgramRepository {
  /// Returns programs ranked by fit for [context], up to [limit] results.
  ///
  /// Programs scoring below the 'consider' threshold are excluded.
  /// The caller must handle an empty list gracefully.
  Future<Result<List<RankedPartnerProgram>>> getRankedPrograms({
    required MatchingContext context,
    int limit = 6,
  });

  Future<Result<PartnerProgram>> getProgramById(ProgramId id);
}
