// Defines DecisionResponse — the unified envelope returned by the Decision Engine.

import 'package:flutter/foundation.dart';
import '../value_objects/ids.dart';
import '../partner/ranked_partner_program.dart';
import 'decision.dart';
import 'explanation.dart';
import 'goal_impact.dart';
import 'next_action.dart';
import 'recommendation.dart';
import 'behavioral_context.dart';
import 'trust_metadata.dart';
import 'decision_audit.dart';

/// The unified response envelope from the Decision Engine.
/// All UI layers consume this single object.
@immutable
class DecisionResponse {
  final Decision decision;
  final List<RankedPartnerProgram> partnerPrograms;

  /// Goal impacts (convenience copy — also available via [decision.goalImpacts]).
  final List<GoalImpact> goalImpacts;

  final List<NextAction> nextActions;

  const DecisionResponse({
    required this.decision,
    required this.partnerPrograms,
    required this.goalImpacts,
    required this.nextActions,
  });

  // Convenience delegates — avoid navigating decision.x in UI code.
  DecisionId get id => decision.id;
  Recommendation get recommendation => decision.recommendation;
  Explanation get explanation => decision.explanation;
  BehavioralContext get behavioralContext => decision.behavioralContext;
  TrustMetadata get trust => decision.trust;
  DecisionAudit get audit => decision.audit;

  DecisionResponse copyWith({
    Decision? decision,
    List<RankedPartnerProgram>? partnerPrograms,
    List<GoalImpact>? goalImpacts,
    List<NextAction>? nextActions,
  }) =>
      DecisionResponse(
        decision: decision ?? this.decision,
        partnerPrograms: partnerPrograms ?? this.partnerPrograms,
        goalImpacts: goalImpacts ?? this.goalImpacts,
        nextActions: nextActions ?? this.nextActions,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DecisionResponse && other.decision == decision);

  @override
  int get hashCode => decision.hashCode;

  @override
  String toString() =>
      'DecisionResponse(decisionId: ${decision.id}, '
      'partners: ${partnerPrograms.length}, actions: ${nextActions.length})';
}
