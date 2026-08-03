// Defines LearningPath and BehavioralIntervention for structured learning journeys.

import 'package:flutter/foundation.dart';
import '../behavioral/financial_personality.dart';
import '../behavioral/habit.dart';

/// An ordered sequence of lessons tailored to a financial personality archetype.
@immutable
class LearningPath {
  final String pathId;
  final String title;
  final FinancialPersonality targetPersonality;

  /// Ordered list of lesson IDs in the recommended sequence.
  final List<String> lessonIds;

  final int totalMinutes;

  const LearningPath({
    required this.pathId,
    required this.title,
    required this.targetPersonality,
    required this.lessonIds,
    required this.totalMinutes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LearningPath && other.pathId == pathId);

  @override
  int get hashCode => pathId.hashCode;

  @override
  String toString() =>
      'LearningPath(id: $pathId, personality: $targetPersonality, '
      'lessons: ${lessonIds.length})';
}

/// A targeted intervention that assigns a lesson when a specific habit is detected.
@immutable
class BehavioralIntervention {
  final String interventionId;
  final HabitType targetHabit;
  final String lessonId;
  final String triggerDescription;
  final String expectedOutcome;

  const BehavioralIntervention({
    required this.interventionId,
    required this.targetHabit,
    required this.lessonId,
    required this.triggerDescription,
    required this.expectedOutcome,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BehavioralIntervention && other.interventionId == interventionId);

  @override
  int get hashCode => interventionId.hashCode;

  @override
  String toString() =>
      'BehavioralIntervention(id: $interventionId, habit: $targetHabit)';
}
