// Defines the domain-level GoalRepository interface and GoalSummary value object.

import 'package:flutter/foundation.dart';
import '../../shared/result.dart';
import '../../value_objects/ids.dart';
import '../../value_objects/money.dart';

/// A lightweight summary of a goal used by the Decision Engine and Health Engine.
/// This is separate from the data-layer goal model in features/goals/.
@immutable
class GoalSummary {
  final GoalId id;
  final String name;
  final String goalType;
  final Money targetAmount;
  final Money currentSaved;
  final DateTime? deadline;
  final Money? monthlyContribution;

  const GoalSummary({
    required this.id,
    required this.name,
    required this.goalType,
    required this.targetAmount,
    required this.currentSaved,
    this.deadline,
    this.monthlyContribution,
  });

  /// Progress as a fraction from 0.0 to 1.0+ (can exceed 1.0 if overfunded).
  double get progressPercent =>
      targetAmount.amount > 0 ? currentSaved.amount / targetAmount.amount : 0.0;

  bool get isFullyFunded => currentSaved.amount >= targetAmount.amount;

  GoalSummary copyWith({
    GoalId? id,
    String? name,
    String? goalType,
    Money? targetAmount,
    Money? currentSaved,
    DateTime? deadline,
    Money? monthlyContribution,
  }) =>
      GoalSummary(
        id: id ?? this.id,
        name: name ?? this.name,
        goalType: goalType ?? this.goalType,
        targetAmount: targetAmount ?? this.targetAmount,
        currentSaved: currentSaved ?? this.currentSaved,
        deadline: deadline ?? this.deadline,
        monthlyContribution: monthlyContribution ?? this.monthlyContribution,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalSummary && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'GoalSummary(id: $id, name: $name, '
      'progress: ${(progressPercent * 100).round()}%)';
}

/// Domain-level abstract contract for goal data used by engines.
/// The existing data/repositories/goal_repository.dart continues unchanged.
/// This contract will eventually be the dependency everything compiles against.
abstract class GoalRepository {
  Future<Result<List<GoalSummary>>> getActiveGoals(UserId userId);

  Future<Result<GoalSummary?>> getEmergencyFundGoal(UserId userId);
}
