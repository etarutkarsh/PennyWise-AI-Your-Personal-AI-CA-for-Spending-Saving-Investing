// Defines all domain events emitted by the PennyWise bounded contexts.

import 'package:flutter/foundation.dart';
import '../value_objects/ids.dart';
import '../value_objects/money.dart';
import '../decision/decision_type.dart';
import '../knowledge/lesson.dart';

// ─── Decision lifecycle events ───────────────────────────────────────────────

/// Emitted when the Decision Engine generates a new Decision.
@immutable
class DecisionGeneratedEvent {
  final EventId eventId;
  final UserId userId;
  final DateTime occurredAt;
  final DecisionId decisionId;
  final DecisionType decisionType;
  final String engineVersion;

  const DecisionGeneratedEvent({
    required this.eventId,
    required this.userId,
    required this.occurredAt,
    required this.decisionId,
    required this.decisionType,
    required this.engineVersion,
  });
}

/// Emitted when the user first views a Decision card.
@immutable
class DecisionViewedEvent {
  final EventId eventId;
  final UserId userId;
  final DateTime occurredAt;
  final DecisionId decisionId;

  const DecisionViewedEvent({
    required this.eventId,
    required this.userId,
    required this.occurredAt,
    required this.decisionId,
  });
}

/// Emitted when the user accepts a Decision.
@immutable
class DecisionAcceptedEvent {
  final EventId eventId;
  final UserId userId;
  final DateTime occurredAt;
  final DecisionId decisionId;
  final String channelUsed;

  const DecisionAcceptedEvent({
    required this.eventId,
    required this.userId,
    required this.occurredAt,
    required this.decisionId,
    required this.channelUsed,
  });
}

/// Emitted when the user rejects a Decision.
@immutable
class DecisionRejectedEvent {
  final EventId eventId;
  final UserId userId;
  final DateTime occurredAt;
  final DecisionId decisionId;
  final String? reason;

  const DecisionRejectedEvent({
    required this.eventId,
    required this.userId,
    required this.occurredAt,
    required this.decisionId,
    this.reason,
  });
}

/// Emitted when the user confirms they have executed a Decision.
@immutable
class DecisionExecutedEvent {
  final EventId eventId;
  final UserId userId;
  final DateTime occurredAt;
  final DecisionId decisionId;
  final String? evidenceNote;

  const DecisionExecutedEvent({
    required this.eventId,
    required this.userId,
    required this.occurredAt,
    required this.decisionId,
    this.evidenceNote,
  });
}

/// Emitted during After-Action Review of a Decision.
@immutable
class DecisionReviewedEvent {
  final EventId eventId;
  final UserId userId;
  final DateTime occurredAt;
  final DecisionId decisionId;

  /// Variance between expected and actual outcome (positive = better than expected).
  final double decisionExpectationVariance;

  const DecisionReviewedEvent({
    required this.eventId,
    required this.userId,
    required this.occurredAt,
    required this.decisionId,
    required this.decisionExpectationVariance,
  });
}

/// Emitted when a lesson is extracted from a reviewed Decision.
@immutable
class DecisionLearnedEvent {
  final EventId eventId;
  final UserId userId;
  final DateTime occurredAt;
  final DecisionId decisionId;
  final String lesson;

  const DecisionLearnedEvent({
    required this.eventId,
    required this.userId,
    required this.occurredAt,
    required this.decisionId,
    required this.lesson,
  });
}

// ─── Recommendation & partner events ─────────────────────────────────────────

/// Emitted when the user views a Recommendation card.
@immutable
class RecommendationViewedEvent {
  final EventId eventId;
  final UserId userId;
  final DateTime occurredAt;
  final RecommendationId recommendationId;
  final DecisionId decisionId;

  const RecommendationViewedEvent({
    required this.eventId,
    required this.userId,
    required this.occurredAt,
    required this.recommendationId,
    required this.decisionId,
  });
}

/// Emitted when the user taps a partner program CTA.
@immutable
class PartnerClickedEvent {
  final EventId eventId;
  final UserId userId;
  final DateTime occurredAt;
  final ProgramId programId;
  final DecisionId decisionId;
  final String ctaLabel;

  const PartnerClickedEvent({
    required this.eventId,
    required this.userId,
    required this.occurredAt,
    required this.programId,
    required this.decisionId,
    required this.ctaLabel,
  });
}

// ─── Learning events ──────────────────────────────────────────────────────────

/// Emitted when the user completes a lesson.
@immutable
class LessonCompletedEvent {
  final EventId eventId;
  final UserId userId;
  final DateTime occurredAt;
  final String lessonId;
  final LessonCategory category;

  const LessonCompletedEvent({
    required this.eventId,
    required this.userId,
    required this.occurredAt,
    required this.lessonId,
    required this.category,
  });
}

// ─── Finance detection events ─────────────────────────────────────────────────

/// Emitted when the Subscription Intelligence Engine detects a subscription.
@immutable
class SubscriptionDetectedEvent {
  final EventId eventId;
  final UserId userId;
  final DateTime occurredAt;
  final String merchantName;
  final Money monthlyAmount;

  /// Detection confidence from 0.0 to 1.0.
  final double confidence;

  const SubscriptionDetectedEvent({
    required this.eventId,
    required this.userId,
    required this.occurredAt,
    required this.merchantName,
    required this.monthlyAmount,
    required this.confidence,
  });
}

/// Emitted when the Health Engine computes a new HealthScore.
@immutable
class HealthScoreChangedEvent {
  final EventId eventId;
  final UserId userId;
  final DateTime occurredAt;
  final int previousScore;
  final int newScore;
  final String trigger;

  const HealthScoreChangedEvent({
    required this.eventId,
    required this.userId,
    required this.occurredAt,
    required this.previousScore,
    required this.newScore,
    required this.trigger,
  });

  int get delta => newScore - previousScore;
}

// ─── Goal events ──────────────────────────────────────────────────────────────

/// Emitted when a user creates a new financial goal.
@immutable
class GoalCreatedEvent {
  final EventId eventId;
  final UserId userId;
  final DateTime occurredAt;
  final GoalId goalId;
  final String goalType;
  final Money targetAmount;

  const GoalCreatedEvent({
    required this.eventId,
    required this.userId,
    required this.occurredAt,
    required this.goalId,
    required this.goalType,
    required this.targetAmount,
  });
}

/// Emitted when funds are added to a goal.
@immutable
class GoalFundedEvent {
  final EventId eventId;
  final UserId userId;
  final DateTime occurredAt;
  final GoalId goalId;
  final String goalName;
  final Money amountAdded;

  const GoalFundedEvent({
    required this.eventId,
    required this.userId,
    required this.occurredAt,
    required this.goalId,
    required this.goalName,
    required this.amountAdded,
  });
}

// ─── Behavioral events ────────────────────────────────────────────────────────

/// Emitted by the Behavioral Engine when it observes a behavioural signal.
@immutable
class BehaviorObservedEvent {
  final EventId eventId;
  final UserId userId;
  final DateTime occurredAt;
  final String observationType;
  final Map<String, dynamic> data;

  const BehaviorObservedEvent({
    required this.eventId,
    required this.userId,
    required this.occurredAt,
    required this.observationType,
    required this.data,
  });
}

/// Emitted when the Digital Twin's behavioral vector is recalibrated.
@immutable
class TwinCalibratedEvent {
  final EventId eventId;
  final UserId userId;
  final DateTime occurredAt;
  final TwinId twinId;
  final List<String> parametersChanged;

  const TwinCalibratedEvent({
    required this.eventId,
    required this.userId,
    required this.occurredAt,
    required this.twinId,
    required this.parametersChanged,
  });
}
