// Defines BehavioralContext — a flattened snapshot of behavioral parameters for decision generation.

import 'package:flutter/foundation.dart';
import '../finance/financial_state.dart';
import '../behavioral/behavioral_vector.dart';

/// A flattened snapshot of the behavioral parameters relevant to a single decision.
/// Derived from [BehavioralVector] and [FinancialState] for use within a decision context.
@immutable
class BehavioralContext {
  final FinancialState financialState;
  final double lossAversion;
  final double riskTolerance;
  final double presentBias;
  final double impulseVolatility;

  /// SIP adherence rate from 0.0 to 1.0. Null until Behavioral Engine has data.
  final double? sipAdherence;

  final double savingsConsistency;

  /// Human-readable behavioral insight shown to the user.
  final String behavioralNote;

  const BehavioralContext({
    required this.financialState,
    required this.lossAversion,
    required this.riskTolerance,
    required this.presentBias,
    required this.impulseVolatility,
    this.sipAdherence,
    required this.savingsConsistency,
    required this.behavioralNote,
  });

  /// Constructs a [BehavioralContext] from a [BehavioralVector] and [FinancialState].
  factory BehavioralContext.fromVector(
    BehavioralVector vector,
    FinancialState state,
  ) =>
      BehavioralContext(
        financialState: state,
        lossAversion: vector.lossAversion,
        riskTolerance: vector.riskToleranceDrift,
        presentBias: vector.presentBias,
        impulseVolatility: vector.impulseVolatility,
        savingsConsistency: 1.0 - vector.impulseVolatility,
        behavioralNote: 'Derived from uncalibrated behavioral vector.',
      );

  BehavioralContext copyWith({
    FinancialState? financialState,
    double? lossAversion,
    double? riskTolerance,
    double? presentBias,
    double? impulseVolatility,
    double? sipAdherence,
    double? savingsConsistency,
    String? behavioralNote,
  }) =>
      BehavioralContext(
        financialState: financialState ?? this.financialState,
        lossAversion: lossAversion ?? this.lossAversion,
        riskTolerance: riskTolerance ?? this.riskTolerance,
        presentBias: presentBias ?? this.presentBias,
        impulseVolatility: impulseVolatility ?? this.impulseVolatility,
        sipAdherence: sipAdherence ?? this.sipAdherence,
        savingsConsistency: savingsConsistency ?? this.savingsConsistency,
        behavioralNote: behavioralNote ?? this.behavioralNote,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BehavioralContext &&
          other.financialState == financialState &&
          other.lossAversion == lossAversion &&
          other.riskTolerance == riskTolerance);

  @override
  int get hashCode => Object.hash(financialState, lossAversion, riskTolerance, presentBias);

  @override
  String toString() =>
      'BehavioralContext(state: $financialState, λ=$lossAversion, '
      'riskTolerance=$riskTolerance)';
}
