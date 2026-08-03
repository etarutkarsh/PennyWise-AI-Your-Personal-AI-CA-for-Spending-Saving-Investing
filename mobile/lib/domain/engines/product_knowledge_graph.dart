import '../decision/decision_type.dart';
import '../partner/financial_instrument.dart';
import '../value_objects/risk_level.dart';

/// Structured knowledge about financial instruments and their relationships.
///
/// The knowledge graph encodes financial domain expertise that would
/// otherwise live as scattered if-statements across policies and engines.
/// When it lives here, every engine can query it consistently.
///
/// Relationships:
///   Goal → suitable instruments
///   Instrument → asset class → risk
///   Instrument → regulatory body
///   Instrument → typical liquidity range
///   Instrument → tax treatment category
///
/// Today: [HardcodedProductKnowledgeGraph] (infrastructure).
/// Future: PostgreSQL entity graph (Phase 6 in the canonical build order).
abstract class ProductKnowledgeGraph {
  /// Get instruments that can execute [goal].
  List<FinancialInstrument> instrumentsFor(DecisionType goal);

  /// Typical risk level for [instrument].
  RiskLevel riskFor(FinancialInstrument instrument);

  /// Typical liquidity score 0.0–1.0 for [instrument].
  /// 1.0 = same-day redemption, 0.0 = fully locked.
  double liquidityFor(FinancialInstrument instrument);

  /// Primary regulatory body for [instrument].
  /// e.g. 'SEBI', 'RBI', 'IRDAI', 'PFRDA', 'Self-regulated'.
  String regulatorFor(FinancialInstrument instrument);

  /// Whether [instrument] is capital-guaranteed.
  bool isCapitalGuaranteed(FinancialInstrument instrument);

  /// Minimum recommended investment horizon in months for [instrument].
  int minHorizonMonthsFor(FinancialInstrument instrument);
}
