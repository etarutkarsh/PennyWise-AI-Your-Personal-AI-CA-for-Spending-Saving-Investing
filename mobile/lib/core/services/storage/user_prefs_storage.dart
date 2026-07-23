import 'package:shared_preferences/shared_preferences.dart';

class UserPrefsStorage {
  UserPrefsStorage._();

  static const _keySalary = 'user_salary';
  static const _keyAchievements = 'user_achievements';
  static const _keyQuizScore = 'quiz_total_score';
  static const _keyCompletedQuizzes = 'completed_quizzes';

  static Future<void> saveSalary(double salary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keySalary, salary);
  }

  static Future<double> getSalary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keySalary) ?? 50000.0;
  }

  static Future<List<String>> getAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyAchievements) ?? [];
  }

  /// Returns true if the achievement was newly earned (not a duplicate).
  static Future<bool> addAchievement(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_keyAchievements) ?? [];
    if (current.contains(id)) return false;
    current.add(id);
    await prefs.setStringList(_keyAchievements, current);
    return true;
  }

  static Future<int> getTotalQuizScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyQuizScore) ?? 0;
  }

  static Future<void> addQuizScore(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyQuizScore) ?? 0;
    await prefs.setInt(_keyQuizScore, current + points);
  }

  static Future<List<String>> getCompletedQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyCompletedQuizzes) ?? [];
  }

  static Future<void> markQuizCompleted(String quizId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_keyCompletedQuizzes) ?? [];
    if (!current.contains(quizId)) {
      current.add(quizId);
      await prefs.setStringList(_keyCompletedQuizzes, current);
    }
  }
}
