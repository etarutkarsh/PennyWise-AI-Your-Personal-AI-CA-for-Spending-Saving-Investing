import '../value_objects/ids.dart';
import 'financial_instrument.dart';
import 'partner_program.dart';

/// The source of truth for available financial products.
///
/// The catalog knows nothing about users. It is a pure product database.
/// User context belongs to [MatchingContext]; reasoning belongs to [MatchingPolicy].
///
/// Today: [HardcodedProductCatalog] (infrastructure).
/// Sprint 4: JSON config loaded from assets.
/// Future: CMS-backed catalog served from /partner-catalog endpoint.
abstract class ProductCatalog {
  /// All currently active programs. Inactive programs are never returned.
  List<PartnerProgram> getAll();

  /// Programs that can be used as [instrument].
  List<PartnerProgram> getByInstrument(FinancialInstrument instrument);

  /// Look up a specific program. Returns null if not found or inactive.
  PartnerProgram? getById(ProgramId id);
}
