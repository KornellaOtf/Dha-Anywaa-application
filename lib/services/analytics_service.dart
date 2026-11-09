import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _fa = FirebaseAnalytics.instance;

  Future<void> logPlayAudio(String category, String itemId) => _fa.logEvent(
        name: 'play_lesson_audio',
        parameters: {'category': category, 'item_id': itemId},
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
