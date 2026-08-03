// Defines Recommendation — the concrete action the Decision Engine recommends to the user.

import 'package:flutter/foundation.dart';
import '../value_objects/ids.dart';
import '../value_objects/money.dart';
import '../value_objects/time_horizon.dart';
import '../partner/financial_instrument.dart';

/// The concrete actions a Recommendation can prescribe.
enum RecommendedAction {
  startRd,
  startSip,
  startElssSip,
  increaseEmergencyFund,
  increaseSavingsRate,
  stepUpExistingSip,
  payDownDebt,
  getTermInsurance,
  getHealthInsurance,
  optimizeSubscription,
  reviewPastDecision,
}

/// The concrete action recommended by the Decision Engine for a user.
@immutable
class Recommendation {
  final RecommendationId id;
  final RecommendedAction action;
  final Money monthlyAmount;
  final FinancialInstrument instrument;
  final TimeHorizon horizon;

  /// Annual step-up rate as a fraction. Null for non-SIP recommendations.
  final double? stepUpRate;

  /// Initial SIP amount from the Step-Up SIP formula. Null if not computed yet.
  final Money? m0;

  const Recommendation({
    required this.id,
    required this.action,
    required this.monthlyAmount,
    required this.instrument,
    required this.horizon,
    this.stepUpRate,
    this.m0,
  });

  Recommendation copyWith({
    RecommendationId? id,
    RecommendedAction? action,
    Money? monthlyAmount,
    FinancialInstrument? instrument,
    TimeHorizon? horizon,
    double? stepUpRate,
    Money? m0,
  }) =>
      Recommendation(
        id: id ?? this.id,
        action: action ?? this.action,
        monthlyAmount: monthlyAmount ?? this.monthlyAmount,
        instrument: instrument ?? this.instrument,
        horizon: horizon ?? this.horizon,
        stepUpRate: stepUpRate ?? this.stepUpRate,
        m0: m0 ?? this.m0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recommendation && other.id == id && other.action == action);

  @override
  int get hashCode => Object.hash(id, action);

  @override
  String toString() =>
      'Recommendation(action: $action, amount: $monthlyAmount, horizon: ${horizon.label})';
}
