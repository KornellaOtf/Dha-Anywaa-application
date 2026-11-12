import 'dart:math' as math;

/// Card state for FSRS algorithm
/// Represents the memory state of a single flashcard

enum CardStateType {
  newCard,      // Never reviewed
  learning,     // In initial learning phase
  review,       // In long-term review phase
  relearning,   // Forgotten and being relearned
}

class CardState {
  final String wordId;
  final double stability;      // S: How long the memory lasts (in days)
  final double difficulty;     // D: How hard this card is for this user (0-10)
  final DateTime dueDate;      // When next review is scheduled
  final DateTime lastReview;   // Timestamp of last review
  final CardStateType state;   // Current state in learning cycle
  final int reps;              // Total number of reviews
  final int lapses;            // Number of times forgotten (Again rating)
  final DateTime createdAt;    // When card was first created

  CardState({
    required this.wordId,
    required this.stability,
    required this.difficulty,
    required this.dueDate,
    required this.lastReview,
    required this.state,
    required this.reps,
    required this.lapses,
    required this.createdAt,
  });

  /// Create a brand new card
  factory CardState.newCard(String wordId, {DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    return CardState(
      wordId: wordId,
      stability: 0.0,
      difficulty: 5.0,  // FSRS default initial difficulty
      dueDate: timestamp,  // Due immediately
      lastReview: timestamp,
      state: CardStateType.newCard,
      reps: 0,
      lapses: 0,
      createdAt: timestamp,
    );
  }

  /// Migrate from Leitner box system
  factory CardState.fromLeitnerBox({
    required String wordId,
    required int boxLevel,
    required int reviewCount,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    
    // Map Leitner box to approximate stability (in days)
    const boxIntervals = [0.0, 1.0, 3.0, 7.0, 14.0, 30.0];
    final stability = boxIntervals[boxLevel < 6 ? boxLevel : 5];
    
    // Estimate due date based on box interval
    final dueDate = timestamp.add(Duration(days: stability.toInt()));
    
    return CardState(
      wordId: wordId,
      stability: stability,
      difficulty: 5.0,  // Default, will adjust with FSRS
      dueDate: dueDate,
      lastReview: timestamp,
      state: boxLevel == 0 ? CardStateType.newCard : CardStateType.review,
      reps: reviewCount,
      lapses: 0,  // Unknown from Leitner
      createdAt: timestamp,
    );
  }

  /// Copy with updated fields
  CardState copyWith({
    String? wordId,
    double? stability,
    double? difficulty,
    DateTime? dueDate,
    DateTime? lastReview,
    CardStateType? state,
    int? reps,
    int? lapses,
    DateTime? createdAt,
  }) {
    return CardState(
      wordId: wordId ?? this.wordId,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      dueDate: dueDate ?? this.dueDate,
      lastReview: lastReview ?? this.lastReview,
      state: state ?? this.state,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'wordId': wordId,
      'stability': stability,
      'difficulty': difficulty,
      'dueDate': dueDate.toIso8601String(),
      'lastReview': lastReview.toIso8601String(),
      'state': state.index,
      'reps': reps,
      'lapses': lapses,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory CardState.fromJson(Map<String, dynamic> json) {
    return CardState(
      wordId: json['wordId'] as String,
      stability: (json['stability'] as num).toDouble(),
      difficulty: (json['difficulty'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      lastReview: DateTime.parse(json['lastReview'] as String),
      state: CardStateType.values[json['state'] as int],
      reps: json['reps'] as int,
      lapses: json['lapses'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Check if card is due for review
  bool isDue({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    return currentTime.isAfter(dueDate) || currentTime.isAtSameMomentAs(dueDate);
  }

  /// Calculate retrievability (probability of recall) at given time
  /// R = e^(-(t - lastReview) / stability)
  double retrievability({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final elapsed = currentTime.difference(lastReview).inSeconds / 86400.0; // days
    
    if (stability <= 0) return 0.0;
    
    final r = math.exp(-elapsed / stability);
    return r.clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return 'CardState(word: $wordId, S: ${stability.toStringAsFixed(1)}, '
        'D: ${difficulty.toStringAsFixed(1)}, state: $state, '
        'reps: $reps, lapses: $lapses)';
  }
}
