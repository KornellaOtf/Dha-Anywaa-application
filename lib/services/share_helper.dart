import 'package:share_plus/share_plus.dart';

class ShareHelper {
  ShareHelper._();
  
  static final ShareHelper instance = ShareHelper._();
  
  static const String _apkUrl =
      'https://github.com/KornellaOtf/Dha-Anywaa-application/releases/latest/download/dha-anywaa-v1.4.13.apk';

  /// Generic share (used from menu)
  Future<void> shareApp() async {
    await Share.share(
      'Learn to read Dha Anywaa with audio, pictures, and quizzes!\n\n'
      'Free\n'
      '100% Offline\n'
      'Beginner-friendly\n\n'
      'Download here:\n$_apkUrl',
      subject: 'Learn Dha Anywaa',
    );
  }
  
  /// Share with a streak milestone
  Future<void> shareStreak(int days) async {
    String achievement = days >= 30 
        ? 'Champion' 
        : days >= 7 
            ? 'On Fire' 
            : 'Started';
    
    await Share.share(
      '$achievement - I\'m on a $days-day streak learning Dha Anywaa!\n\n'
      'Join me and let\'s keep the language alive:\n'
      '$_apkUrl',
      subject: 'My Dha Anywaa streak: $days days',
    );
  }
  
  /// Share quiz result
  Future<void> shareQuizResult(int score, int total) async {
    final percent = ((score / total) * 100).round();
    await Share.share(
      'I just scored $score/$total ($percent%) on the Dha Anywaa quiz!\n\n'
      'Can you beat me? Download the free app:\n'
      '$_apkUrl',
      subject: 'My Dha Anywaa Quiz Score',
    );
  }
  
  /// Share a specific word they just learned
  Future<void> shareWord(String anywaaWord, String englishWord) async {
    await Share.share(
      'Today I learned: "$anywaaWord" ($englishWord) in Dha Anywaa!\n\n'
      'Start learning your language too:\n'
      '$_apkUrl',
      subject: 'I learned a Dha Anywaa word!',
    );
  }
  
  /// Share personal best
  Future<void> sharePersonalBest(int wordsLearned) async {
    await Share.share(
      'New personal record: $wordsLearned words learned this week in Dha Anywaa!\n\n'
      'Challenge me:\n'
      '$_apkUrl',
      subject: 'My Dha Anywaa Personal Best',
    );
  }
}
