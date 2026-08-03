import 'package:flutter/foundation.dart';
import '../value_objects/ids.dart';

enum ExecutionSource {
  userConfirmed,
  transactionDetected,
  smsDetected,
  aaVerified,
  inferred,
}

/// Records that a recommended decision was actually executed.
/// Detected from transaction history, SMS, AA data, or explicit user confirmation.
@immutable
class DecisionExecution {
  final DecisionId decisionId;
  final UserId userId;
  final bool executed;
  final ExecutionSource executionSource;
  final DateTime executedAt;

  /// Actual amount executed — may differ from recommended amount.
  final double? amountExecuted;

  /// How confident we are that this execution matches the recommendation (0.0–1.0).
  final double confidence;

  /// Optional note from user or detection engine.
  final String? note;

  const DecisionExecution({
    required this.decisionId,
    required this.userId,
    required this.executed,
    required this.executionSource,
    required this.executedAt,
    this.amountExecuted,
    this.confidence = 1.0,
    this.note,
  }) : assert(confidence >= 0.0 && confidence <= 1.0);

  bool get isVerified =>
      executionSource == ExecutionSource.aaVerified ||
      executionSource == ExecutionSource.userConfirmed;

  bool get isInferred => executionSource == ExecutionSource.inferred;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DecisionExecution && other.decisionId == decisionId);

  @override
  int get hashCode => decisionId.hashCode;

  @override
  String toString() =>
      'DecisionExecution(decision: $decisionId, executed: $executed, '
      'source: $executionSource, confidence: $confidence)';
}
