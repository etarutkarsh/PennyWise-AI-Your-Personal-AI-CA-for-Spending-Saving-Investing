// Defines FinancialTwin — the Digital Twin aggregate for a user's financial persona.

import 'package:flutter/foundation.dart';
import '../value_objects/ids.dart';
import '../finance/financial_state.dart';
import '../behavioral/behavioral_vector.dart';
import 'twin_snapshot.dart';

/// The Digital Twin aggregate representing the model of a user's financial life.
/// Calibrated by the Behavioral Engine; stub until that engine is built.
@immutable
class FinancialTwin {
  final TwinId twinId;
  final UserId userId;
  final BehavioralVector vector;
  final FinancialState state;
  final List<TwinSnapshot> history;
  final DateTime lastUpdated;

  const FinancialTwin({
    required this.twinId,
    required this.userId,
    required this.vector,
    required this.state,
    required this.history,
    required this.lastUpdated,
  });

  FinancialTwin copyWith({
    TwinId? twinId,
    UserId? userId,
    BehavioralVector? vector,
    FinancialState? state,
    List<TwinSnapshot>? history,
    DateTime? lastUpdated,
  }) =>
      FinancialTwin(
        twinId: twinId ?? this.twinId,
        userId: userId ?? this.userId,
        vector: vector ?? this.vector,
        state: state ?? this.state,
        history: history ?? this.history,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinancialTwin && other.twinId == twinId);

  @override
  int get hashCode => twinId.hashCode;

  @override
  String toString() =>
      'FinancialTwin(twinId: $twinId, userId: $userId, state: $state, '
      'snapshots: ${history.length})';
}
