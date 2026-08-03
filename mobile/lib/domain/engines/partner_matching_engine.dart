import '../partner/matching_context.dart';
import '../partner/partner_program.dart';
import '../partner/ranked_partner_program.dart';

/// Ranks partner programs by fit for the user's current financial context.
///
/// Commission is never a ranking signal — fiduciary invariant.
/// The engine is the only place where programs are ordered; the repository
/// provides the catalog, the Flutter layer only renders the ranked result.
///
/// v1 implementation: RuleBasedPartnerMatchingEngine (infrastructure).
/// Future: ML-driven BehavioralPartnerMatchingEngine once behavioral data flows.
abstract class PartnerMatchingEngine {
  String get engineVersion;

  /// Ranks [catalog] programs by fit for [context].
  ///
  /// Returns at most [limit] programs, ordered best-fit first.
  /// Programs scoring below the 'consider' threshold are excluded
  /// to avoid showing noise. The caller should handle an empty list.
  List<RankedPartnerProgram> rank({
    required List<PartnerProgram> catalog,
    required MatchingContext context,
    int limit = 6,
  });
}
