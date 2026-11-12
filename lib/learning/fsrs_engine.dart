import 'dart:math' as math;
import 'package:dha_anywaa_app/learning/card_state.dart';

/// FSRS-6 (Free Spaced Repetition Scheduler) Algorithm
/// Based on: https://github.com/open-spaced-repetition/fsrs4anki
/// 
/// Core formula: S' = S × f(D, R, rating)
/// Where:
/// - S = stability (how long memory lasts in days)
/// - D = difficulty (0-10, how hard this card is for this user)
/// - R = retrievability (probability of recall at review time)
/// - rating = user's answer quality (Again/Hard/Good/Easy)

enum Rating {
  again,  // 1 - Incorrect/forgotten
  hard,   // 2 - Correct but difficult
  good,   // 3 - Correct with normal effort
  easy,   // 4 - Correct with ease
}

class FSRSParameters {
  // FSRS-6 default parameters (optimized for 90% retention)
  final double requestedRetention;
  final double maximumInterval;
  
  // Model parameters (w0-w18 from FSRS-6)
  final List<double> w;

  FSRSParameters({
    this.requestedRetention = 0.90,
    this.maximumInterval = 36500.0,  // ~100 years
    List<double>? weights,
  }) : w = weights ?? _defaultWeights;

  // FSRS-6 default weights (universal parameters)
  static const List<double> _defaultWeights = [
    0.4072, 1.1829, 3.1262, 15.4722, 7.2102,
    0.5316, 1.0651, 0.0234, 1.616,  0.1544,
    1.0824, 1.9813, 0.0953, 0.2975, 2.2042,
    0.2407, 2.9466, 0.5034, 0.6567,
  ];
}

class FSRSEngine {
  final FSRSParameters params;

  FSRSEngine({FSRSParameters? parameters})
      : params = parameters ?? FSRSParameters();

  /// Process a review and return updated card state
  ReviewResult review({
    required CardState card,
    required Rating rating,
    DateTime? now,
  }) {
    final reviewTime = now ?? DateTime.now();
    final elapsed = reviewTime.difference(card.lastReview).inSeconds / 86400.0;

    // Calculate retrievability
    final r = card.stability > 0
        ? math.exp(-elapsed / card.stability)
        : 0.0;

    // New card first review
    if (card.state == CardStateType.newCard) {
      return _handleNewCard(card, rating, reviewTime);
    }

    // Learning/relearning state
    if (card.state == CardStateType.learning ||
        card.state == CardStateType.relearning) {
      return _handleLearningCard(card, rating, reviewTime);
    }

    // Review state
    return _handleReviewCard(card, rating, reviewTime, r);
  }

  /// Handle first-time review of new card
  ReviewResult _handleNewCard(
    CardState card,
    Rating rating,
    DateTime reviewTime,
  ) {
    // Initial learning steps: 1m, 10m
    if (rating == Rating.again) {
      // Stay in learning, review in 1 minute
      final newCard = card.copyWith(
        state: CardStateType.learning,
        dueDate: reviewTime.add(Duration(minutes: 1)),
        lastReview: reviewTime,
        reps: card.reps + 1,
        lapses: card.lapses + 1,
      );
      return ReviewResult(card: newCard, scheduleInfo: '1 minute');
    }

    // First success: calculate initial stability
    final initialD = _initDifficulty(rating);
    final initialS = _initStability(rating);

    if (rating == Rating.good || rating == Rating.hard) {
      // Move to second learning step (10 minutes)
      final newCard = card.copyWith(
        stability: initialS,
        difficulty: initialD,
        state: CardStateType.learning,
        dueDate: reviewTime.add(Duration(minutes: 10)),
        lastReview: reviewTime,
        reps: card.reps + 1,
      );
      return ReviewResult(card: newCard, scheduleInfo: '10 minutes');
    }

    // Rating.easy: graduate immediately
    final newCard = card.copyWith(
      stability: initialS * 1.5,  // Bonus for easy
      difficulty: initialD,
      state: CardStateType.review,
      dueDate: reviewTime.add(Duration(days: (initialS * 1.5).round())),
      lastReview: reviewTime,
      reps: card.reps + 1,
    );
    return ReviewResult(
      card: newCard,
      scheduleInfo: '${(initialS * 1.5).round()} days',
    );
  }

  /// Handle card in learning/relearning phase
  ReviewResult _handleLearningCard(
    CardState card,
    Rating rating,
    DateTime reviewTime,
  ) {
    if (rating == Rating.again) {
      // Restart learning: back to 1 minute
      final newCard = card.copyWith(
        dueDate: reviewTime.add(Duration(minutes: 1)),
        lastReview: reviewTime,
        reps: card.reps + 1,
        lapses: card.lapses + 1,
      );
      return ReviewResult(card: newCard, scheduleInfo: '1 minute');
    }

    // Graduate to review state
    final newS = card.stability > 0 ? card.stability : _initStability(rating);
    final interval = _calculateInterval(newS);

    final newCard = card.copyWith(
      state: CardStateType.review,
      dueDate: reviewTime.add(Duration(days: interval)),
      lastReview: reviewTime,
      reps: card.reps + 1,
    );
    return ReviewResult(card: newCard, scheduleInfo: '$interval days');
  }

  /// Handle card in review phase (core FSRS algorithm)
  ReviewResult _handleReviewCard(
    CardState card,
    Rating rating,
    DateTime reviewTime,
    double retrievability,
  ) {
    // Calculate new difficulty
    final newD = _nextDifficulty(card.difficulty, rating);

    if (rating == Rating.again) {
      // Lapse: move to relearning
      final newS = _nextForgetStability(card.difficulty, card.stability, retrievability);
      
      final newCard = card.copyWith(
        stability: newS,
        difficulty: newD,
        state: CardStateType.relearning,
        dueDate: reviewTime.add(Duration(minutes: 10)),
        lastReview: reviewTime,
        reps: card.reps + 1,
        lapses: card.lapses + 1,
      );
      return ReviewResult(card: newCard, scheduleInfo: '10 minutes');
    }

    // Success: calculate new stability
    final newS = _nextRecallStability(
      card.difficulty,
      card.stability,
      retrievability,
      rating,
    );
    final interval = _calculateInterval(newS);

    final newCard = card.copyWith(
      stability: newS,
      difficulty: newD,
      dueDate: reviewTime.add(Duration(days: interval)),
      lastReview: reviewTime,
      reps: card.reps + 1,
    );
    return ReviewResult(card: newCard, scheduleInfo: '$interval days');
  }

  /// Initial difficulty based on first rating
  double _initDifficulty(Rating rating) {
    final w = params.w;
    return w[4] - (rating.index - 1) * w[5];
  }

  /// Initial stability based on first rating
  double _initStability(Rating rating) {
    final w = params.w;
    return w[rating.index].clamp(0.1, double.infinity);
  }

  /// Calculate next difficulty after review
  double _nextDifficulty(double d, Rating rating) {
    final w = params.w;
    final deltaD = -(rating.index - 2) * w[6];
    return (d + deltaD).clamp(1.0, 10.0);
  }

  /// Calculate new stability after successful recall
  double _nextRecallStability(
    double d,
    double s,
    double r,
    Rating rating,
  ) {
    final w = params.w;
    final hardPenalty = rating == Rating.hard ? w[15] : 1.0;
    final easyBonus = rating == Rating.easy ? w[16] : 1.0;
    
    final newS = s * (
      1 +
      math.exp(w[8]) *
      (11 - d) *
      math.pow(s, -w[9]) *
      (math.exp((1 - r) * w[10]) - 1) *
      hardPenalty *
      easyBonus
    );
    
    return newS.clamp(0.1, params.maximumInterval);
  }

  /// Calculate new stability after lapse (forgotten)
  double _nextForgetStability(double d, double s, double r) {
    final w = params.w;
    final newS = w[11] *
        math.pow(d, -w[12]) *
        (math.pow(s + 1, w[13]) - 1) *
        math.exp((1 - r) * w[14]);
    
    return newS.clamp(0.1, params.maximumInterval);
  }

  /// Calculate interval days from stability and desired retention
  int _calculateInterval(double stability) {
    final interval = (stability * 9 * (1 / params.requestedRetention - 1)).round();
    return interval.clamp(1, params.maximumInterval.round());
  }
}

/// Result of a review operation
class ReviewResult {
  final CardState card;
  final String scheduleInfo;

  ReviewResult({
    required this.card,
    required this.scheduleInfo,
  });

  @override
  String toString() {
    return 'ReviewResult(next: $scheduleInfo, S: ${card.stability.toStringAsFixed(1)}, '
        'D: ${card.difficulty.toStringAsFixed(1)})';
  }
}
