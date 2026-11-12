import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardService {
  LeaderboardService._();
  
  static final LeaderboardService instance = LeaderboardService._();
  
  static const String _keyWeeklyWordCount = 'weekly_word_count';
  static const String _keyPersonalBest = 'personal_best';
  static const String _keyWeekStartDate = 'week_start_date';
  static const String _keyTotalWordsLearned = 'total_words_learned';
  static const String _keyQuizzesCompleted = 'quizzes_completed';
  static const String _keyBestQuizScore = 'best_quiz_score';
  
  /// Initialize or reset weekly counter if new week
  Future<void> checkAndResetWeek() async {
    final prefs = await SharedPreferences.getInstance();
    
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);
    final storedWeekStart = prefs.getString(_keyWeekStartDate);
    
    if (storedWeekStart == null || storedWeekStart != weekStart.toIso8601String()) {
      // New week - check if we beat personal best
      final currentWeekly = prefs.getInt(_keyWeeklyWordCount) ?? 0;
      final personalBest = prefs.getInt(_keyPersonalBest) ?? 0;
      
      if (currentWeekly > personalBest) {
        await prefs.setInt(_keyPersonalBest, currentWeekly);
      }
      
      // Reset weekly counter
      await prefs.setInt(_keyWeeklyWordCount, 0);
      await prefs.setString(_keyWeekStartDate, weekStart.toIso8601String());
    }
  }
  
  /// Get Monday of current week (week starts on Monday)
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: weekday - 1));
  }
  
  /// Increment word count for this week
  Future<void> incrementWeeklyWords({int count = 1}) async {
    await checkAndResetWeek();
    
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyWeeklyWordCount) ?? 0;
    final total = prefs.getInt(_keyTotalWordsLearned) ?? 0;
    
    await prefs.setInt(_keyWeeklyWordCount, current + count);
    await prefs.setInt(_keyTotalWordsLearned, total + count);
  }
  
  /// Increment quiz counter
  Future<void> incrementQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyQuizzesCompleted) ?? 0;
    await prefs.setInt(_keyQuizzesCompleted, current + 1);
  }
  
  /// Update best quiz score if current is higher
  Future<void> updateBestQuizScore(int percentage) async {
    final prefs = await SharedPreferences.getInstance();
    final best = prefs.getInt(_keyBestQuizScore) ?? 0;
    
    if (percentage > best) {
      await prefs.setInt(_keyBestQuizScore, percentage);
    }
  }
  
  /// Get current weekly stats
  Future<Map<String, int>> getWeeklyStats() async {
    await checkAndResetWeek();
    
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'weeklyWords': prefs.getInt(_keyWeeklyWordCount) ?? 0,
      'personalBest': prefs.getInt(_keyPersonalBest) ?? 0,
      'totalWords': prefs.getInt(_keyTotalWordsLearned) ?? 0,
      'quizzesCompleted': prefs.getInt(_keyQuizzesCompleted) ?? 0,
      'bestQuizScore': prefs.getInt(_keyBestQuizScore) ?? 0,
    };
  }
  
  /// Get progress towards personal best (0.0 to 1.0)
  Future<double> getProgressTowardsBest() async {
    final stats = await getWeeklyStats();
    final weekly = stats['weeklyWords']!;
    final best = stats['personalBest']!;
    
    if (best == 0) return 0.0;
    return (weekly / best).clamp(0.0, 1.0);
  }
  
  /// Check if user beat their personal best this week
  Future<bool> didBeatPersonalBest() async {
    final stats = await getWeeklyStats();
    final weekly = stats['weeklyWords']!;
    final best = stats['personalBest']!;
    
    return weekly > best && best > 0;
  }
}
