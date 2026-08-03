// Defines BehaviorProfile — the complete behavioral snapshot of a user.

import 'package:flutter/foundation.dart';
import '../value_objects/ids.dart';
import '../finance/financial_state.dart';
import 'behavioral_vector.dart';
import 'financial_personality.dart';
import 'habit.dart';

/// A complete behavioral profile for a user, computed by the Behavioral Engine.
@immutable
class BehaviorProfile {
  final UserId userId;
  final FinancialState financialState;
  final BehavioralVector vector;
  final FinancialPersonality personality;
  final List<Habit> detectedHabits;
  final DateTime lastCalibrated;
  final String calibrationVersion;

  const BehaviorProfile({
    required this.userId,
    required this.financialState,
    required this.vector,
    required this.personality,
    required this.detectedHabits,
    required this.lastCalibrated,
    required this.calibrationVersion,
  });

  /// Returns safe defaults for a user whose profile has not been calibrated yet.
  factory BehaviorProfile.uncalibrated(UserId userId) => BehaviorProfile(
        userId: userId,
        financialState: FinancialState.build,
        vector: BehavioralVector.uncalibrated,
        personality: FinancialPersonality.builder,
        detectedHabits: const [],
        lastCalibrated: DateTime(2000),
        calibrationVersion: 'uncalibrated',
      );

  bool get isUncalibrated => calibrationVersion == 'uncalibrated';

  BehaviorProfile copyWith({
    UserId? userId,
    FinancialState? financialState,
    BehavioralVector? vector,
    FinancialPersonality? personality,
    List<Habit>? detectedHabits,
    DateTime? lastCalibrated,
    String? calibrationVersion,
  }) =>
      BehaviorProfile(
        userId: userId ?? this.userId,
        financialState: financialState ?? this.financialState,
        vector: vector ?? this.vector,
        personality: personality ?? this.personality,
        detectedHabits: detectedHabits ?? this.detectedHabits,
        lastCalibrated: lastCalibrated ?? this.lastCalibrated,
        calibrationVersion: calibrationVersion ?? this.calibrationVersion,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BehaviorProfile &&
          other.userId == userId &&
          other.calibrationVersion == calibrationVersion);

  @override
  int get hashCode => Object.hash(userId, calibrationVersion);

  @override
  String toString() =>
      'BehaviorProfile(userId: $userId, personality: $personality, '
      'state: $financialState, version: $calibrationVersion)';
}
