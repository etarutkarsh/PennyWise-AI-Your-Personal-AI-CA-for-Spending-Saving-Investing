import '../../domain/decision/decision_type.dart';
import '../../domain/engines/product_knowledge_graph.dart';
import '../../domain/partner/financial_instrument.dart';
import '../../domain/value_objects/risk_level.dart';

/// Static implementation of [ProductKnowledgeGraph].
///
/// Encodes financial domain knowledge (risk, liquidity, regulatory body,
/// capital guarantee, minimum investment horizon) for every [FinancialInstrument].
///
/// This replaces scattered if-statements across policies and engines with
/// one authoritative source. All policies query this graph rather than
/// embedding instrument facts inline.
///
/// Phase 6: replaced by [PostgresProductKnowledgeGraph] backed by kg_nodes
/// seed data (V13 migration) — the entity_id values in the DB match the
/// Dart enum names exactly to enable a clean swap.
class HardcodedProductKnowledgeGraph implements ProductKnowledgeGraph {
  const HardcodedProductKnowledgeGraph();

  @override
  List<FinancialInstrument> instrumentsFor(DecisionType goal) => switch (goal) {
        DecisionType.buildEmergencyFund => const [
          FinancialInstrument.recurringDeposit,
          FinancialInstrument.liquidFund,
        ],
        DecisionType.increaseSavingsRate => const [
          FinancialInstrument.recurringDeposit,
          FinancialInstrument.liquidFund,
          FinancialInstrument.ppf,
        ],
        DecisionType.startGoalSip => const [
          FinancialInstrument.indexFundSip,
          FinancialInstrument.digitalGold,
          FinancialInstrument.recurringDeposit,
        ],
        DecisionType.stepUpSip => const [
          FinancialInstrument.indexFundSip,
          FinancialInstrument.nps,
        ],
        DecisionType.optimizeTax => const [
          FinancialInstrument.elssSip,
          FinancialInstrument.ppf,
          FinancialInstrument.nps,
        ],
        DecisionType.reduceDebt => const [],
        DecisionType.getInsurance => const [
          FinancialInstrument.termInsurance,
          FinancialInstrument.healthInsurance,
        ],
        DecisionType.optimizeSubscription => const [
          FinancialInstrument.creditCardCashback,
        ],
        DecisionType.rebalancePortfolio => const [
          FinancialInstrument.indexFundSip,
          FinancialInstrument.digitalGold,
          FinancialInstrument.nps,
        ],
        DecisionType.reviewPastDecision => const [],
      };

  @override
  RiskLevel riskFor(FinancialInstrument instrument) => switch (instrument) {
        FinancialInstrument.recurringDeposit => RiskLevel.low,
        FinancialInstrument.liquidFund => RiskLevel.low,
        FinancialInstrument.indexFundSip => RiskLevel.medium,
        FinancialInstrument.elssSip => RiskLevel.high,
        FinancialInstrument.digitalGold => RiskLevel.medium,
        FinancialInstrument.creditCardCashback => RiskLevel.low,
        FinancialInstrument.ppf => RiskLevel.low,
        FinancialInstrument.nps => RiskLevel.medium,
        FinancialInstrument.termInsurance => RiskLevel.low,
        FinancialInstrument.healthInsurance => RiskLevel.low,
      };

  @override
  double liquidityFor(FinancialInstrument instrument) => switch (instrument) {
        FinancialInstrument.recurringDeposit => 0.60,
        FinancialInstrument.liquidFund => 0.95,
        FinancialInstrument.indexFundSip => 0.85,
        FinancialInstrument.elssSip => 0.00, // 3-year lock-in
        FinancialInstrument.digitalGold => 0.75,
        FinancialInstrument.creditCardCashback => 1.00,
        FinancialInstrument.ppf => 0.10,  // 15-year lock-in
        FinancialInstrument.nps => 0.05,  // locked until 60
        FinancialInstrument.termInsurance => 0.00,
        FinancialInstrument.healthInsurance => 0.00,
      };

  @override
  String regulatorFor(FinancialInstrument instrument) => switch (instrument) {
        FinancialInstrument.recurringDeposit => 'RBI',
        FinancialInstrument.liquidFund => 'SEBI',
        FinancialInstrument.indexFundSip => 'SEBI',
        FinancialInstrument.elssSip => 'SEBI',
        FinancialInstrument.digitalGold => 'Self-regulated',
        FinancialInstrument.creditCardCashback => 'RBI',
        FinancialInstrument.ppf => 'Government of India',
        FinancialInstrument.nps => 'PFRDA',
        FinancialInstrument.termInsurance => 'IRDAI',
        FinancialInstrument.healthInsurance => 'IRDAI',
      };

  @override
  bool isCapitalGuaranteed(FinancialInstrument instrument) => switch (instrument) {
        FinancialInstrument.recurringDeposit => true,
        FinancialInstrument.liquidFund => false,
        FinancialInstrument.indexFundSip => false,
        FinancialInstrument.elssSip => false,
        FinancialInstrument.digitalGold => false,
        FinancialInstrument.creditCardCashback => false,
        FinancialInstrument.ppf => true,
        FinancialInstrument.nps => false,
        FinancialInstrument.termInsurance => false,
        FinancialInstrument.healthInsurance => false,
      };

  @override
  int minHorizonMonthsFor(FinancialInstrument instrument) => switch (instrument) {
        FinancialInstrument.recurringDeposit => 6,
        FinancialInstrument.liquidFund => 1,
        FinancialInstrument.indexFundSip => 36,
        FinancialInstrument.elssSip => 36,
        FinancialInstrument.digitalGold => 12,
        FinancialInstrument.creditCardCashback => 0,
        FinancialInstrument.ppf => 180, // 15 years
        FinancialInstrument.nps => 240, // until retirement (~20 years minimum)
        FinancialInstrument.termInsurance => 120, // 10-year minimum meaningful coverage
        FinancialInstrument.healthInsurance => 12,
      };
}
