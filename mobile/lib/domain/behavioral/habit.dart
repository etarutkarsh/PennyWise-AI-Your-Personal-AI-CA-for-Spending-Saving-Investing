// Defines Habit and HabitType for behavioral pattern detection in the Behavioral Engine.

import 'package:flutter/foundation.dart';

/// Types of financial habits the Behavioral Engine can detect.
enum HabitType {
  impulseWindow,         // overspends in the days after salary credit
  lossAversionTrigger,   // cancels SIPs during market drawdowns
  sipAdherence,          // never misses a SIP — positive habit
  subscriptionBloat,     // accumulating too many forgotten subscriptions
  salaryBounce,          // spends 40%+ of salary in the first 5 days
}

/// A detected behavioral habit with confidence score and evidence count.
@immutable
class Habit {
  final String habitId;
  final HabitType type;
  final String description;

  /// Confidence score from 0.0 to 1.0.
  final double confidence;

  final DateTime detectedAt;

  /// Number of data points supporting this detection.
  final int evidenceCount;

  const Habit({
    required this.habitId,
    required this.type,
    required this.description,
    required this.confidence,
    required this.detectedAt,
    required this.evidenceCount,
  }) : assert(confidence >= 0.0 && confidence <= 1.0,
            'Habit confidence must be between 0.0 and 1.0');

  Habit copyWith({
    String? habitId,
    HabitType? type,
    String? description,
    double? confidence,
    DateTime? detectedAt,
    int? evidenceCount,
  }) =>
      Habit(
        habitId: habitId ?? this.habitId,
        type: type ?? this.type,
        description: description ?? this.description,
        confidence: confidence ?? this.confidence,
        detectedAt: detectedAt ?? this.detectedAt,
        evidenceCount: evidenceCount ?? this.evidenceCount,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Habit && other.habitId == habitId && other.type == type);

  @override
  int get hashCode => Object.hash(habitId, type);

  @override
  String toString() =>
      'Habit(type: $type, confidence: ${(confidence * 100).round()}%, evidence: $evidenceCount)';
}
