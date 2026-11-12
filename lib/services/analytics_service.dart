import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Central analytics service — all Firebase Analytics calls go through here.
/// Never call FirebaseAnalytics.instance directly in other files.
///
/// Event naming convention:  snake_case, max 40 chars
/// Parameter naming:         snake_case, max 40 chars, value max 100 chars
/// All booleans logged as 1/0 (Firebase doesn't support bool params)
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _fa = FirebaseAnalytics.instance;

  // ── User identity ─────────────────────────────────────────────────────────

  /// Hash + store user ID on name entry. Call once when user sets their name.
  Future<void> setUser(String name) async {
    if (name.isEmpty || name == 'guess') return;
    final bytes  = utf8.encode(name.toLowerCase().trim());
    final userId = sha256.convert(bytes).toString().substring(0, 32);
    await _fa.setUserId(id: userId);
    await _fa.setUserProperty(name: 'user_type', value: 'registered');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('analytics_user_id', userId);
  }

  /// Restore user ID from storage on app start.
  Future<void> initializeFromStorage() async {
    final prefs  = await SharedPreferences.getInstance();
    final userId = prefs.getString('analytics_user_id');
    if (userId != null && userId.isNotEmpty) {
      await _fa.setUserId(id: userId);
      await _fa.setUserProperty(name: 'user_type', value: 'registered');
    }
  }

  /// Clear user ID on logout / name reset.
  Future<void> clearUser() async {
    await _fa.setUserId(id: null);
    await _fa.setUserProperty(name: 'user_type', value: 'guest');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('analytics_user_id');
  }

  // ── App lifecycle ─────────────────────────────────────────────────────────

  /// Log every cold open (called from main.dart / home_page initState).
  Future<void> logAppOpen() => _fa.logAppOpen();

  // ── Lesson / category ─────────────────────────────────────────────────────

  Future<void> logPlayAudio(String category, String itemId) =>
      _fa.logEvent(name: 'play_lesson_audio', parameters: {
        'category': category,
        'item_id':  itemId,
        'song_name': '${category}_$itemId',
      });

  Future<void> logCompleteLesson(String category, String itemId) =>
      _fa.logEvent(name: 'complete_lesson', parameters: {
        'category': category,
        'item_id':  itemId,
      });

  // ── Quiz ──────────────────────────────────────────────────────────────────

  Future<void> logFinishQuiz(int score, int total) =>
      _fa.logEvent(name: 'finish_quiz', parameters: {
        'score': score,
        'total': total,
      });

  // ── Daily 5 / FSRS ───────────────────────────────────────────────────────

  /// Fired when a Daily 5 session starts.
  Future<void> logDaily5Start() =>
      _fa.logEvent(name: 'daily5_start');

  /// Fired when a Daily 5 session is fully completed.
  /// [correct] = correct answers, [total] = cards shown, [xp] = XP earned.
  Future<void> logDaily5Complete({
    required int correct,
    required int total,
    required int xp,
  }) =>
      _fa.logEvent(name: 'daily5_complete', parameters: {
        'correct':  correct,
        'total':    total,
        'xp_earned': xp,
        'accuracy': total > 0 ? (correct * 100 ~/ total) : 0,
      });

  /// Fired after each individual card review.
  /// [correct] 1/0, [category] word category, [response_ms] answer time.
  Future<void> logCardReview({
    required bool   correct,
    required String category,
    required int    responseMs,
  }) =>
      _fa.logEvent(name: 'card_review', parameters: {
        'correct':     correct ? 1 : 0,
        'category':    category,
        'response_ms': responseMs,
      });

  // ── Gamification ──────────────────────────────────────────────────────────

  /// Fired when user reaches a new XP level.
  Future<void> logLevelUp(int newLevel, String levelTitle) =>
      _fa.logEvent(name: 'level_up', parameters: {
        'new_level':   newLevel,
        'level_title': levelTitle,
      });

  Future<void> logStreakMilestone(int days) =>
      _fa.logEvent(name: 'streak_milestone', parameters: {'days': days});

  Future<void> logComebackBonus(int bonusXp) =>
      _fa.logEvent(name: 'comeback_bonus_claimed', parameters: {
        'bonus_xp': bonusXp,
      });

  // ── Bible ─────────────────────────────────────────────────────────────────

  /// Fired when user opens a Bible chapter.
  Future<void> logBibleChapterOpened(String book, int chapter) =>
      _fa.logEvent(name: 'bible_chapter_opened', parameters: {
        'book':    book,
        'chapter': chapter,
      });

  /// Fired when user starts playing Bible audio.
  Future<void> logBibleAudioPlayed(String book, int chapter) =>
      _fa.logEvent(name: 'bible_audio_played', parameters: {
        'book':    book,
        'chapter': chapter,
      });

  /// Fired when user performs a Bible search.
  Future<void> logBibleSearch(String query, int resultCount) =>
      _fa.logEvent(name: 'bible_search', parameters: {
        'query_length':  query.length,
        'result_count':  resultCount,
      });

  /// Fired when user toggles English translation on/off.
  Future<void> logBibleToggleEnglish(bool shown) =>
      _fa.logEvent(name: 'bible_toggle_english', parameters: {
        'shown': shown ? 1 : 0,
      });

  // ── OTA updates ───────────────────────────────────────────────────────────

  Future<void> logCheckUpdate({required bool forced}) =>
      _fa.logEvent(name: 'check_update', parameters: {
        'forced': forced ? 1 : 0,
      });

  Future<void> logDownloadUpdate(String fromVersion, String toVersion) =>
      _fa.logEvent(name: 'download_update', parameters: {
        'from_version': fromVersion,
        'to_version':   toVersion,
      });

  Future<void> logInstallUpdate(String toVersion) =>
      _fa.logEvent(name: 'install_update', parameters: {
        'to_version': toVersion,
      });

  Future<void> logAppUpdate({
    required String version,
    required String method,
  }) =>
      _fa.logEvent(name: 'app_update', parameters: {
        'version': version,
        'method':  method,
      });

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<void> logChangeTheme(String mode) =>
      _fa.logEvent(name: 'change_theme', parameters: {'mode': mode});

  Future<void> logToggleSound(bool enabled) =>
      _fa.logEvent(name: 'toggle_sound', parameters: {
        'enabled': enabled ? 1 : 0,
      });

  // ── Navigation ────────────────────────────────────────────────────────────

  /// Log screen views manually where Navigator.observer isn't available.
  Future<void> logScreen(String screenName) =>
      _fa.logScreenView(screenName: screenName);
}
