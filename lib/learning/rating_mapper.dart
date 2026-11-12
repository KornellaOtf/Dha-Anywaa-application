import 'package:dha_anywaaa/learning/fsrs_engine.dart';

/// Maps user answer to FSRS rating
/// Current: binary correct/incorrect → Again/Good
/// Future: add response-time based Hard/Easy split
class RatingMapper {
  /// Map simple correct/incorrect to FSRS rating
  /// 
  /// Current mapping:
  /// - incorrect → Rating.again (1)
  /// - correct → Rating.good (3)
  /// 
  /// Future upgrade path:
  /// - incorrect → Rating.again (1)
  /// - correct + slow response → Rating.hard (2)
  /// - correct + normal response → Rating.good (3)
  /// - correct + fast response → Rating.easy (4)
  static Rating mapBinaryAnswer({
    required bool correct,
    int? responseTimeMs,
  }) {
    if (!correct) {
      return Rating.again;
    }
    
    // For now, all correct answers → Good
    // TODO: Split into Hard/Easy based on response time
    return Rating.good;
  }

  /// Future: Response-time based difficulty adjustment
  /// This will be used to automatically assign Hard/Easy ratings
  /// based on how quickly the user answered
  static Rating mapWithResponseTime({
    required bool correct,
    required int responseTimeMs,
    int hardThresholdMs = 8000,   // >8s = hard
    int easyThresholdMs = 3000,   // <3s = easy
  }) {
    if (!correct) {
      return Rating.again;
    }

    if (responseTimeMs > hardThresholdMs) {
      return Rating.hard;
    } else if (responseTimeMs < easyThresholdMs) {
      return Rating.easy;
    } else {
      return Rating.good;
    }
  }

  /// Get user-friendly description of rating
  static String getRatingDescription(Rating rating) {
    switch (rating) {
      case Rating.again:
        return 'Incorrect - Review soon';
      case Rating.hard:
        return 'Correct, but difficult';
      case Rating.good:
        return 'Correct!';
      case Rating.easy:
        return 'Correct and easy!';
    }
  }

  /// Get emoji for rating feedback
  static String getRatingEmoji(Rating rating) {
    switch (rating) {
      case Rating.again:
        return '🔄';
      case Rating.hard:
        return '💪';
      case Rating.good:
        return '✅';
      case Rating.easy:
        return '🌟';
    }
  }
}
