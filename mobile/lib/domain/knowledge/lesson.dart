// Defines Lesson, LessonCategory, and LessonTrigger for the contextual learning system.

import 'package:flutter/foundation.dart';

/// Subject categories for learning content.
enum LessonCategory {
  behaviorAndHabits,
  investing,
  taxPlanning,
  insurance,
  debtManagement,
  goalSetting,
  marketBasics,
  retirementPlanning,
}

/// Events that trigger contextual lesson delivery to the user.
enum LessonTrigger {
  firstSalaryCredit,
  firstSipStarted,
  firstGoalCreated,
  emergencyFundComplete,
  budgetBreached,
  drawdownDetected,
  subscriptionDetected,
  taxSeasonApproaching,
  salaryIncreaseDetected,
}

/// A single learning lesson that can be delivered contextually based on life events.
@immutable
class Lesson {
  final String lessonId;
  final String title;
  final String summary;
  final LessonCategory category;

  /// The events that should trigger this lesson being surfaced to the user.
  final List<LessonTrigger> triggers;

  final int estimatedMinutes;
  final bool isPremium;

  const Lesson({
    required this.lessonId,
    required this.title,
    required this.summary,
    required this.category,
    required this.triggers,
    required this.estimatedMinutes,
    required this.isPremium,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Lesson && other.lessonId == lessonId);

  @override
  int get hashCode => lessonId.hashCode;

  @override
  String toString() => 'Lesson(id: $lessonId, title: "$title", category: $category)';
}
