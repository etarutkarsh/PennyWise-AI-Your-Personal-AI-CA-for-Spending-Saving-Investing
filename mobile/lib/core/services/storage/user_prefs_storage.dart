import 'package:shared_preferences/shared_preferences.dart';

class UserPrefsStorage {
  UserPrefsStorage._();

  static const _keySalary = 'user_salary';
  static const _keyAchievements = 'user_achievements';
  static const _keyQuizScore = 'quiz_total_score';
  static const _keyCompletedQuizzes = 'completed_quizzes';
  static const _keyStreak = 'activity_streak';
  static const _keyLastActivityDate = 'last_activity_date';

  // ── Salary ────────────────────────────────────────────────────────────────

  static Future<void> saveSalary(double salary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keySalary, salary);
  }

  static Future<double> getSalary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keySalary) ?? 50000.0;
  }

  // ── Achievements ──────────────────────────────────────────────────────────

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

  // ── Quiz / XP ─────────────────────────────────────────────────────────────

  static Future<int> getTotalQuizScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyQuizScore) ?? 0;
  }

  static Future<void> addQuizScore(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyQuizScore) ?? 0;
    await prefs.setInt(_keyQuizScore, current + points);
    // Check level-up achievements after adding XP
    await _checkLevelAchievements(current + points);
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

  // ── Gamification: Levels ──────────────────────────────────────────────────

  /// Returns (levelName, emoji, currentXp, nextLevelXp).
  static Future<(String, String, int, int)> getLevel() async {
    final xp = await getTotalQuizScore();
    return _levelFromXp(xp);
  }

  static (String, String, int, int) _levelFromXp(int xp) {
    if (xp >= 1000) return ('Platinum', '💎', xp, 2000);
    if (xp >= 500) return ('Gold', '🥇', xp, 1000);
    if (xp >= 200) return ('Silver', '🥈', xp, 500);
    return ('Bronze', '🥉', xp, 200);
  }

  static Future<void> _checkLevelAchievements(int xp) async {
    if (xp >= 200) await addAchievement('level_silver');
    if (xp >= 500) await addAchievement('level_gold');
    if (xp >= 1000) await addAchievement('level_platinum');
  }

  // ── Gamification: Streaks ─────────────────────────────────────────────────

  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStreak) ?? 0;
  }

  /// Call when the user performs an activity (e.g. adds a transaction).
  /// Increments streak if activity is on a new day; resets if a day was missed.
  static Future<int> recordActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    final last = prefs.getString(_keyLastActivityDate);

    if (last == today) {
      // Already recorded today — streak unchanged
      return prefs.getInt(_keyStreak) ?? 1;
    }

    int streak = prefs.getInt(_keyStreak) ?? 0;
    if (last == _dateKey(DateTime.now().subtract(const Duration(days: 1)))) {
      streak += 1;
    } else {
      streak = 1; // missed a day — reset
    }

    await prefs.setInt(_keyStreak, streak);
    await prefs.setString(_keyLastActivityDate, today);

    // Streak achievements
    if (streak >= 7) await addAchievement('streak_7');
    if (streak >= 30) await addAchievement('streak_30');

    return streak;
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
