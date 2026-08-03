import '../../domain/engines/decision_learning_engine.dart';
import '../../domain/learning/learning_snapshot.dart';
import '../../domain/learning/decision_lesson.dart';

/// Returns the current learning state and all actionable lessons for a user.
/// Consumed by the Financial Journal AAR card and Digital Twin screen.
class GetLearningInsightsUseCase {
  const GetLearningInsightsUseCase(this._engine);

  final DecisionLearningEngine _engine;

  LearningInsights call(LearningSnapshot snapshot) {
    final activeLessons = _engine.getActiveLessons(snapshot);
    final actionable = activeLessons.where((l) => l.isActionable).toList();
    final pending = activeLessons.where((l) => !l.isActionable).toList();

    return LearningInsights(
      snapshot: snapshot,
      activeLessons: activeLessons,
      actionableLessons: actionable,
      pendingLessons: pending,
    );
  }
}

class LearningInsights {
  const LearningInsights({
    required this.snapshot,
    required this.activeLessons,
    required this.actionableLessons,
    required this.pendingLessons,
  });

  final LearningSnapshot snapshot;
  final List<DecisionLesson> activeLessons;
  final List<DecisionLesson> actionableLessons;
  final List<DecisionLesson> pendingLessons;

  String get calibrationLabel => snapshot.calibrationLabel;
  double get maturity => snapshot.maturity;
  int get completedCycles => snapshot.completedCycles;

  bool get hasActionableLessons => actionableLessons.isNotEmpty;
}
