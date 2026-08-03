// Defines the abstract KnowledgeRepository interface for lesson and learning path data.

import '../../shared/result.dart';
import '../../behavioral/financial_personality.dart';
import '../../behavioral/habit.dart';
import '../lesson.dart';
import '../learning_path.dart';

/// Abstract contract for accessing learning content and behavioral interventions.
/// Implementations live in the data layer.
abstract class KnowledgeRepository {
  Future<Result<List<Lesson>>> getLessonsForTrigger(LessonTrigger trigger);

  Future<Result<LearningPath>> getLearningPath(FinancialPersonality personality);

  Future<Result<List<BehavioralIntervention>>> getInterventionsForHabit(HabitType habit);
}
