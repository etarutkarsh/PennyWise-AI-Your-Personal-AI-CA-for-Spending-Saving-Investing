// Defines strongly-typed ID value objects to prevent primitive obsession with raw strings.

import 'package:flutter/foundation.dart';

/// A decision record identifier.
@immutable
class DecisionId {
  final String value;
  const DecisionId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is DecisionId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DecisionId($value)';
}

/// A recommendation identifier.
@immutable
class RecommendationId {
  final String value;
  const RecommendationId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is RecommendationId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'RecommendationId($value)';
}

/// A user identifier.
@immutable
class UserId {
  final String value;
  const UserId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UserId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'UserId($value)';
}

/// A goal identifier.
@immutable
class GoalId {
  final String value;
  const GoalId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is GoalId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'GoalId($value)';
}

/// A domain event identifier.
@immutable
class EventId {
  final String value;
  const EventId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is EventId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'EventId($value)';
}

/// A user session identifier.
@immutable
class SessionId {
  final String value;
  const SessionId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SessionId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'SessionId($value)';
}

/// A distributed tracing correlation identifier.
@immutable
class CorrelationId {
  final String value;
  const CorrelationId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CorrelationId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'CorrelationId($value)';
}

/// A distributed tracing trace identifier.
@immutable
class TraceId {
  final String value;
  const TraceId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TraceId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'TraceId($value)';
}

/// A digital twin identifier.
@immutable
class TwinId {
  final String value;
  const TwinId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TwinId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'TwinId($value)';
}

/// A partner program identifier.
@immutable
class ProgramId {
  final String value;
  const ProgramId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ProgramId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ProgramId($value)';
}
