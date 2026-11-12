import 'dart:math' as math;
import 'package:dha_anywaaa/learning/card_state.dart';

/// Builds Daily 5 learning sessions
/// Smart card selection for habit formation
class SessionBuilder {
  final math.Random _random = math.Random();

  /// Build a Daily 5 session (5 cards)
  /// 
  /// Selection strategy:
  /// 1. Prioritize overdue cards (due date passed)
  /// 2. First 2-3 cards: bias toward easy/recent successes (build confidence)
  /// 3. Remaining cards: mix of new + due (maintain challenge)
  /// 4. Limit new cards to 1-2 per session (prevent overwhelm)
  /// 
  /// Goal: 2-3 minutes to complete, high success rate, satisfying
  List<CardState> buildDaily5Session({
    required List<CardState> allCards,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final List<CardState> session = [];

    // Separate cards by type
    final overdue = allCards.where((c) => c.isDue(now: currentTime)).toList();
    final newCards = allCards.where((c) => c.state == CardStateType.newCard).toList();
    
    // Sort overdue by priority
    overdue.sort((a, b) {
      // Most overdue first
      final daysPastA = currentTime.difference(a.dueDate).inDays;
      final daysPastB = currentTime.difference(b.dueDate).inDays;
      return daysPastB.compareTo(daysPastA);
    });

    // Separate overdue into easy and hard
    final easyOverdue = overdue.where((c) => 
      c.difficulty < 6.0 && c.lapses < 2
    ).toList();
    final hardOverdue = overdue.where((c) => 
      c.difficulty >= 6.0 || c.lapses >= 2
    ).toList();

    // Card 1-2: Easy wins (build confidence)
    for (int i = 0; i < 2 && session.length < 5; i++) {
      if (easyOverdue.isNotEmpty) {
        session.add(easyOverdue.removeAt(0));
      } else if (hardOverdue.isNotEmpty) {
        session.add(hardOverdue.removeAt(0));
      } else if (newCards.isNotEmpty) {
        session.add(newCards.removeAt(0));
      }
    }

    // Card 3: Mix it up (new or challenging)
    if (session.length < 5) {
      if (newCards.isNotEmpty && _random.nextBool()) {
        session.add(newCards.removeAt(0));
      } else if (hardOverdue.isNotEmpty) {
        session.add(hardOverdue.removeAt(0));
      } else if (easyOverdue.isNotEmpty) {
        session.add(easyOverdue.removeAt(0));
      } else if (newCards.isNotEmpty) {
        session.add(newCards.removeAt(0));
      }
    }

    // Card 4-5: Fill remaining slots
    final remaining = [...easyOverdue, ...hardOverdue, ...newCards.take(2)];
    remaining.shuffle(_random);
    
    while (session.length < 5 && remaining.isNotEmpty) {
      session.add(remaining.removeAt(0));
    }

    return session;
  }

  /// Check if user has any cards due today
  bool hasDueCards({
    required List<CardState> allCards,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    return allCards.any((c) => c.isDue(now: currentTime));
  }

  /// Get count of cards due today
  int getDueCount({
    required List<CardState> allCards,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    return allCards.where((c) => c.isDue(now: currentTime)).length;
  }

  /// Get count of new cards (never reviewed)
  int getNewCount({required List<CardState> allCards}) {
    return allCards.where((c) => c.state == CardStateType.newCard).length;
  }

  /// Calculate session summary stats
  SessionStats calculateSessionStats({
    required List<CardState> allCards,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    
    final due = allCards.where((c) => c.isDue(now: currentTime)).toList();
    final newCards = allCards.where((c) => c.state == CardStateType.newCard).length;
    final learning = allCards.where((c) => 
      c.state == CardStateType.learning || c.state == CardStateType.relearning
    ).length;
    final review = allCards.where((c) => c.state == CardStateType.review).length;

    return SessionStats(
      totalCards: allCards.length,
      dueCount: due.length,
      newCount: newCards,
      learningCount: learning,
      reviewCount: review,
      canBuildSession: due.length + newCards >= 5,
    );
  }
}

/// Statistics about available cards and session eligibility
class SessionStats {
  final int totalCards;
  final int dueCount;
  final int newCount;
  final int learningCount;
  final int reviewCount;
  final bool canBuildSession;

  SessionStats({
    required this.totalCards,
    required this.dueCount,
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
    required this.canBuildSession,
  });

  @override
  String toString() {
    return 'SessionStats(total: $totalCards, due: $dueCount, '
        'new: $newCount, learning: $learningCount, review: $reviewCount)';
  }
}
