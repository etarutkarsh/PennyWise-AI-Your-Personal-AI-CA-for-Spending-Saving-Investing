// Defines Decision — the aggregate root of the Decision bounded context.

import 'package:flutter/foundation.dart';
import '../value_objects/ids.dart';
import '../finance/financial_state.dart';
import 'decision_type.dart';
import 'recommendation.dart';
import 'explanation.dart';
import 'goal_impact.dart';
import 'behavioral_context.dart';
import 'trust_metadata.dart';
import 'decision_audit.dart';

/// The lifecycle state of a Decision from generation to the memory loop.
enum DecisionLifecycleState {
  generated,
  viewed,
  accepted,
  rejected,
  deferred,
  executed,
  observed,
  reviewed,
  learned,
}

/// The aggregate root of the Decision bounded context.
/// Represents a single financial recommendation with full explainability and audit trail.
@immutable
class Decision {
  final DecisionId id;
  final CorrelationId correlationId;
  final SessionId sessionId;
  final EventId eventId;
  final UserId userId;
  final DecisionType type;

  /// Priority classification: "HIGH", "MEDIUM", or "LOW".
  final String priority;

  final FinancialState financialState;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final String engineVersion;

  final Recommendation recommendation;
  final Explanation explanation;
  final List<GoalImpact> goalImpacts;
  final BehavioralContext behavioralContext;
  final TrustMetadata trust;
  final DecisionAudit audit;
  final DecisionLifecycleState lifecycleState;

  const Decision({
    required this.id,
    required this.correlationId,
    required this.sessionId,
    required this.eventId,
    required this.userId,
    required this.type,
    required this.priority,
    required this.financialState,
    required this.generatedAt,
    required this.expiresAt,
    required this.engineVersion,
    required this.recommendation,
    required this.explanation,
    required this.goalImpacts,
    required this.behavioralContext,
    required this.trust,
    required this.audit,
    this.lifecycleState = DecisionLifecycleState.generated,
  });

  /// True if the decision has passed its expiry timestamp.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Decision copyWith({
    DecisionId? id,
    CorrelationId? correlationId,
    SessionId? sessionId,
    EventId? eventId,
    UserId? userId,
    DecisionType? type,
    String? priority,
    FinancialState? financialState,
    DateTime? generatedAt,
    DateTime? expiresAt,
    String? engineVersion,
    Recommendation? recommendation,
    Explanation? explanation,
    List<GoalImpact>? goalImpacts,
    BehavioralContext? behavioralContext,
    TrustMetadata? trust,
    DecisionAudit? audit,
    DecisionLifecycleState? lifecycleState,
  }) =>
      Decision(
        id: id ?? this.id,
        correlationId: correlationId ?? this.correlationId,
        sessionId: sessionId ?? this.sessionId,
        eventId: eventId ?? this.eventId,
        userId: userId ?? this.userId,
        type: type ?? this.type,
        priority: priority ?? this.priority,
        financialState: financialState ?? this.financialState,
        generatedAt: generatedAt ?? this.generatedAt,
        expiresAt: expiresAt ?? this.expiresAt,
        engineVersion: engineVersion ?? this.engineVersion,
        recommendation: recommendation ?? this.recommendation,
        explanation: explanation ?? this.explanation,
        goalImpacts: goalImpacts ?? this.goalImpacts,
        behavioralContext: behavioralContext ?? this.behavioralContext,
        trust: trust ?? this.trust,
        audit: audit ?? this.audit,
        lifecycleState: lifecycleState ?? this.lifecycleState,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Decision && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Decision(id: $id, type: $type, priority: $priority, state: $lifecycleState, '
      'expired: $isExpired)';
}
