import 'package:dha_anywaa_app/learning/fsrs_engine.dart';

/// Append-only log entry for every review
/// Used for analytics and algorithm tuning
class ReviewEvent {
  final String wordId;
  final DateTime timestamp;
  final Rating rating;              // User's rating (Again/Good/Easy)
  final int responseTimeMs;         // How long to answer (milliseconds)
  final double stabilityBefore;     // S before this review
  final double stabilityAfter;      // S after this review
  final double difficultyBefore;    // D before this review
  final double difficultyAfter;     // D after this review
  final int scheduledInterval;      // Days until next review
  final String sessionId;           // Group reviews in same session

  ReviewEvent({
    required this.wordId,
    required this.timestamp,
    required this.rating,
    required this.responseTimeMs,
    required this.stabilityBefore,
    required this.stabilityAfter,
    required this.difficultyBefore,
    required this.difficultyAfter,
    required this.scheduledInterval,
    required this.sessionId,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'wordId': wordId,
      'timestamp': timestamp.toIso8601String(),
      'rating': rating.index,
      'responseTimeMs': responseTimeMs,
      'stabilityBefore': stabilityBefore,
      'stabilityAfter': stabilityAfter,
      'difficultyBefore': difficultyBefore,
      'difficultyAfter': difficultyAfter,
      'scheduledInterval': scheduledInterval,
      'sessionId': sessionId,
    };
  }

  /// Create from JSON
  factory ReviewEvent.fromJson(Map<String, dynamic> json) {
    return ReviewEvent(
      wordId: json['wordId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      rating: Rating.values[json['rating'] as int],
      responseTimeMs: json['responseTimeMs'] as int,
      stabilityBefore: (json['stabilityBefore'] as num).toDouble(),
      stabilityAfter: (json['stabilityAfter'] as num).toDouble(),
      difficultyBefore: (json['difficultyBefore'] as num).toDouble(),
      difficultyAfter: (json['difficultyAfter'] as num).toDouble(),
      scheduledInterval: json['scheduledInterval'] as int,
      sessionId: json['sessionId'] as String,
    );
  }

  @override
  String toString() {
    return 'ReviewEvent(word: $wordId, rating: $rating, responseTime: ${responseTimeMs}ms, '
        'S: ${stabilityBefore.toStringAsFixed(1)} → ${stabilityAfter.toStringAsFixed(1)}, '
        'interval: $scheduledInterval days)';
  }
}
