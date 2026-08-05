import 'package:flutter/foundation.dart';

import '../behavioral/behavior_interpretation.dart';
import '../commitments/goal_snapshot.dart';
import '../learning/learning_snapshot.dart';
import '../shared/data_confidence_report.dart';
import '../shared/financial_facts.dart';

/// Universal input object for [FinancialReasoningEngine].
///
/// Wraps all available financial state. The engine degrades gracefully when
/// optional fields are null, applying conservative defaults and recording
/// limitations in the output report.
///
/// Usage: build from currently loaded state — no backend calls needed.
@immutable
class FinancialReasoningContext {
  const FinancialReasoningContext({
    required this.facts,
    required this.dataConfidence,
    this.behavior,
    this.learningSnapshot,
    this.goals = const [],
    this.contextLabel,
  });

  /// Computed financial facts — income, expenses, EF, savings rate, etc.
  /// Produced by [FinancialFactBuilder]. Required — all axes need at least
  /// the basic facts to compute.
  final FinancialFacts facts;

  /// Data quality assessment. Drives [DecisionConfidenceReport.dataConfidenceFactor].
  /// Use [DataConfidenceReport.empty] when no engine has run yet.
  final DataConfidenceReport dataConfidence;

  /// Behavioral interpretation from Phase 9.
  /// Null → behavioral engine has not run; engine uses neutral 0.50 prior.
  final BehaviorInterpretation? behavior;

  /// Decision learning history from Phase 7.
  /// Null → no past recommendations reviewed; engine uses neutral 0.50 prior.
  final LearningSnapshot? learningSnapshot;

  /// Active goals for the goal impact axis.
  final List<GoalSnapshot> goals;

  /// Optional label for logging ("Today's decision", "Affordability check").
  final String? contextLabel;
}
