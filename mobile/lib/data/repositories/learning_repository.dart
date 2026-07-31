import '../../core/services/network/api_client.dart';

class LessonProgress {
  final String id;
  final String topic;
  final String lessonId;
  final bool completed;
  final int? quizScore;

  const LessonProgress({
    required this.id,
    required this.topic,
    required this.lessonId,
    required this.completed,
    this.quizScore,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> j) => LessonProgress(
        id: j['id'] as String,
        topic: j['topic'] as String,
        lessonId: j['lessonId'] as String,
        completed: j['completed'] as bool? ?? false,
        quizScore: j['quizScore'] as int?,
      );
}

class AchievementItem {
  final String id;
  final String code;
  final String title;

  const AchievementItem({
    required this.id,
    required this.code,
    required this.title,
  });

  factory AchievementItem.fromJson(Map<String, dynamic> j) => AchievementItem(
        id: j['id'] as String,
        code: j['code'] as String,
        title: j['title'] as String,
      );
}

class LearningRepository {
  LearningRepository(this._client);

  final ApiClient _client;

  static const _quizLessonMap = {
    'salary_quiz_done':     ('salary_basics',     'salary'),
    'savings_quiz_done':    ('savings_basics',     'savings'),
    'investment_quiz_done': ('investment_basics',  'investments'),
    'budget_quiz_done':     ('budget_basics',      'budget'),
  };

  Future<List<LessonProgress>> getProgress() async {
    final res = await _client.dio.get('/learning');
    return (res.data as List)
        .map((j) => LessonProgress.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<int> getTotalXp() async {
    final res = await _client.dio.get('/learning/xp');
    return (res.data as Map<String, dynamic>)['totalXp'] as int? ?? 0;
  }

  Future<List<AchievementItem>> getAchievements() async {
    final res = await _client.dio.get('/learning/achievements');
    return (res.data as List)
        .map((j) => AchievementItem.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> completeLesson(String quizId, int quizScore) async {
    final mapped = _quizLessonMap[quizId];
    if (mapped == null) return;
    final (lessonId, topic) = mapped;
    await _client.dio.post('/learning', data: {
      'topic': topic,
      'lessonId': lessonId,
      'quizScore': quizScore,
    });
  }

  Future<void> unlockAchievement(String code) async {
    await _client.dio.post('/learning/achievements', data: {'code': code});
  }
}
