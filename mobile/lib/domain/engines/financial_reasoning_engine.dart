import '../reasoning/decision_confidence_report.dart';
import '../reasoning/financial_reasoning_context.dart';

/// Runs all 8 financial reasoning axes and produces a [DecisionConfidenceReport].
///
/// Implements the CTO compound confidence formula:
///   compoundConfidence = dataConf × decisionConf × behaviorConf × historicalAcc
///
/// Architectural invariants:
/// - Pure computation — synchronous, no async, no I/O, no repositories
/// - All inputs via [FinancialReasoningContext] — no external calls
/// - Degrades gracefully: null optional fields → conservative defaults + limitations
/// - The output drives recommendation strength on all intelligent surfaces
///
/// V1 is rule-based ([RuleBasedFinancialReasoningEngine]).
/// Future: Bayesian weights trained from [DecisionLearningEngine] outcomes.
abstract class FinancialReasoningEngine {
  String get engineVersion;

  DecisionConfidenceReport reason(FinancialReasoningContext ctx);
}
