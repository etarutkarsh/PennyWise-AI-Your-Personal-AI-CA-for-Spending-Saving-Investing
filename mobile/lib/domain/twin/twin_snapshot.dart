// Defines TwinSnapshot — a point-in-time record of the Digital Twin's behavioral vector.

import 'package:flutter/foundation.dart';
import '../finance/financial_state.dart';
import '../behavioral/behavioral_vector.dart';

/// A point-in-time snapshot of the Digital Twin's behavioral vector and financial state.
@immutable
class TwinSnapshot {
  final String snapshotId;
  final BehavioralVector vector;
  final FinancialState state;
  final DateTime capturedAt;

  /// The event that triggered this snapshot (e.g. "MARKET_DRAWDOWN", "SALARY_INCREASE", "SIP_MISSED").
  final String trigger;

  const TwinSnapshot({
    required this.snapshotId,
    required this.vector,
    required this.state,
    required this.capturedAt,
    required this.trigger,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TwinSnapshot && other.snapshotId == snapshotId);

  @override
  int get hashCode => snapshotId.hashCode;

  @override
  String toString() =>
      'TwinSnapshot(id: $snapshotId, trigger: $trigger, capturedAt: $capturedAt)';
}
