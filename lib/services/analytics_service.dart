import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _fa = FirebaseAnalytics.instance;

  /// Initialize analytics with user ID (hashed for privacy).
  /// Call this once when the user sets their name.
  Future<void> setUser(String name) async {
    if (name.isEmpty || name == 'guess') return;
    
    // Create a stable but anonymous user ID from the name
    final bytes = utf8.encode(name.toLowerCase().trim());
    final digest = sha256.convert(bytes);
    final userId = digest.toString().substring(0, 32); // First 32 chars
    
    await _fa.setUserId(id: userId);
    await _fa.setUserProperty(name: 'user_type', value: 'registered');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('analytics_user_id', userId);
  }

  /// Initialize analytics from saved data (on app start).
  Future<void> initializeFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('analytics_user_id');
    
    if (userId != null && userId.isNotEmpty) {
      await _fa.setUserId(id: userId);
      await _fa.setUserProperty(name: 'user_type', value: 'registered');
    }
  }

  /// Clear user ID (on logout).
  Future<void> clearUser() async {
    await _fa.setUserId(id: null);
    await _fa.setUserProperty(name: 'user_type', value: 'guest');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('analytics_user_id');
  }

  Future<void> logPlayAudio(String category, String itemId) => _fa.logEvent(
        name: 'play_lesson_audio',
        parameters: {
          'category': category,
          'item_id': itemId,
          'song_name': '${category}_$itemId',
        },
      );

  Future<void> logCompleteLesson(String category, String itemId) => _fa.logEvent(
        name: 'complete_lesson',
        parameters: {'category': category, 'item_id': itemId},
      );

  Future<void> logFinishQuiz(int score, int total) => _fa.logEvent(
        name: 'finish_quiz',
        parameters: {'score': score, 'total': total},
      );

  Future<void> logCheckUpdate({required bool forced}) => _fa.logEvent(
        name: 'check_update',
        parameters: {'forced': forced ? 1 : 0},
      );

  Future<void> logDownloadUpdate(String fromVersion, String toVersion) => _fa.logEvent(
        name: 'download_update',
        parameters: {'from_version': fromVersion, 'to_version': toVersion},
      );

  Future<void> logInstallUpdate(String toVersion) => _fa.logEvent(
        name: 'install_update',
        parameters: {'to_version': toVersion},
      );

  Future<void> logChangeTheme(String mode) => _fa.logEvent(
        name: 'change_theme',
        parameters: {'mode': mode},
      );

  Future<void> logToggleSound(bool enabled) => _fa.logEvent(
        name: 'toggle_sound',
        parameters: {'enabled': enabled ? 1 : 0},
      );
}
