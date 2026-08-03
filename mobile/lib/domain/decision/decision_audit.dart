// Defines DecisionAudit and EngineContribution for event-sourced decision tracing.

import 'package:flutter/foundation.dart';
import '../value_objects/ids.dart';

/// The contribution of a single engine to a decision computation.
@immutable
class EngineContribution {
  final String engineName;
  final String version;
  final String outputSummary;
  final int durationMs;

  const EngineContribution({
    required this.engineName,
    required this.version,
    required this.outputSummary,
    required this.durationMs,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EngineContribution &&
          other.engineName == engineName &&
          other.version == version);

  @override
  int get hashCode => Object.hash(engineName, version);

  @override
  String toString() =>
      'EngineContribution($engineName v$version: ${durationMs}ms)';
}

/// Event-sourcing audit trail for a Decision — what engines ran and can this be replayed?
@immutable
class DecisionAudit {
  final EventId eventId;
  final int sequenceNumber;
  final bool replayable;

  /// ID of the data snapshot used to generate this decision. Null if not snapshotted.
  final String? dataSnapshotId;

  final List<EngineContribution> engineTrace;

  const DecisionAudit({
    required this.eventId,
    required this.sequenceNumber,
    required this.replayable,
    this.dataSnapshotId,
    required this.engineTrace,
  });

  DecisionAudit copyWith({
    EventId? eventId,
    int? sequenceNumber,
    bool? replayable,
    String? dataSnapshotId,
    List<EngineContribution>? engineTrace,
  }) =>
      DecisionAudit(
        eventId: eventId ?? this.eventId,
        sequenceNumber: sequenceNumber ?? this.sequenceNumber,
        replayable: replayable ?? this.replayable,
        dataSnapshotId: dataSnapshotId ?? this.dataSnapshotId,
        engineTrace: engineTrace ?? this.engineTrace,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DecisionAudit &&
          other.eventId == eventId &&
          other.sequenceNumber == sequenceNumber);

  @override
  int get hashCode => Object.hash(eventId, sequenceNumber);

  @override
  String toString() =>
      'DecisionAudit(eventId: $eventId, seq: $sequenceNumber, '
      'engines: ${engineTrace.length}, replayable: $replayable)';
}
