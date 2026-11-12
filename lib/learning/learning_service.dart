import 'package:dha_anywaaa/learning/card_state.dart';
import 'package:dha_anywaaa/learning/card_repository.dart';
import 'package:dha_anywaaa/learning/fsrs_engine.dart';
import 'package:dha_anywaaa/learning/session_builder.dart';
import 'package:dha_anywaaa/learning/review_event.dart';
import 'package:dha_anywaaa/learning/rating_mapper.dart';
import 'package:dha_anywaaa/progress/xp_system.dart';

/// Main learning service - coordinates FSRS algorithm with persistence
/// Singleton service that manages the entire learning system
class LearningService {
  static final LearningService instance = LearningService._();
  LearningService._();

  final CardRepository _repository = CardRepository();
  final FSRSEngine _fsrsEngine = FSRSEngine();
  final SessionBuilder _sessionBuilder = SessionBuilder();

  Map<String, CardState> _cards = {};
  UserProgress _progress = UserProgress.initial();
  bool _initialized = false;

  /// Initialize the service (load data from storage)
  Future<void> initialize() async {
    if (_initialized) return;

    // Load all data
    _cards = await _repository.loadCards();
    _progress = await _repository.loadProgress();
    
    // Run migration if needed
    if (!await _repository.hasMigrated()) {
      await _repository.migrateLeitnerToFSRS();
      _cards = await _repository.loadCards();
    }

    _initialized = true;
    print('LearningService initialized: ${_cards.length} cards loaded');
  }

  /// Ensure initialization before operations
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// Build a Daily 5 session
  Future<List<CardState>> buildDaily5Session() async {
    await _ensureInitialized();
    
    final allCards = _cards.values.toList();
    return _sessionBuilder.buildDaily5Session(allCards: allCards);
  }

  /// Check if Daily 5 is available
  Future<bool> canBuildSession() async {
    await _ensureInitialized();
    
    final stats = _sessionBuilder.calculateSessionStats(
      allCards: _cards.values.toList(),
    );
    return stats.canBuildSession;
  }

  /// Get session statistics
  Future<SessionStats> getSessionStats() async {
    await _ensureInitialized();
    
    return _sessionBuilder.calculateSessionStats(
      allCards: _cards.values.toList(),
    );
  }

  /// Process a single review
  Future<ReviewResult> processReview({
    required String wordId,
    required bool correct,
    int? responseTimeMs,
  }) async {
    await _ensureInitialized();

    // Get or create card
    CardState card = _cards[wordId] ?? CardState.newCard(wordId);
    
    // Map answer to rating
    final rating = RatingMapper.mapBinaryAnswer(
      correct: correct,
      responseTimeMs: responseTimeMs,
    );

    // Run FSRS algorithm
    final reviewResult = _fsrsEngine.review(card: card, rating: rating);
    
    // Update storage
    _cards[wordId] = reviewResult.card;
    await _repository.saveCard(reviewResult.card);

    return reviewResult;
  }

  /// Complete a session (batch review processing)
  Future<SessionResult> completeSession({
    required List<ReviewEvent> reviewEvents,
    required List<CardState> updatedCards,
  }) async {
    await _ensureInitialized();

    // Update all cards
    for (final card in updatedCards) {
      _cards[card.wordId] = card;
    }
    await _repository.saveCards(_cards);

    // Save review events
    await _repository.addReviews(reviewEvents);

    // Calculate session XP
    final correctCount = reviewEvents.where((e) => e.rating != Rating.again).length;
    final totalCount = reviewEvents.length;
    
    int sessionXP = 0;
    for (final event in reviewEvents) {
      sessionXP += XPSystem.calculateReviewXP(
        rating: event.rating,
        isFirstReview: event.stabilityBefore == 0.0,
      );
    }

    final bonusXP = XPSystem.calculateSessionXP(
      correctCount: correctCount,
      totalCount: totalCount,
      hasActiveStreak: _progress.currentStreak > 0,
    );
    sessionXP += bonusXP;

    // Update user progress
    final oldLevel = _progress.level;
    _progress = _progress
        .addXP(sessionXP)
        .completeSession(
          correctCount: correctCount,
          reviewCount: totalCount,
        );
    await _repository.saveProgress(_progress);

    final newLevel = _progress.level;
    final leveledUp = newLevel > oldLevel;

    return SessionResult(
      correctCount: correctCount,
      totalCount: totalCount,
      xpEarned: sessionXP,
      oldLevel: oldLevel,
      newLevel: newLevel,
      leveledUp: leveledUp,
      streakCount: _progress.currentStreak,
    );
  }

  /// Get or create a card for a word
  Future<CardState> getCard(String wordId) async {
    await _ensureInitialized();
    return _cards[wordId] ?? CardState.newCard(wordId);
  }

  /// Initialize cards for new words (bulk operation)
  Future<void> initializeWords(List<String> wordIds) async {
    await _ensureInitialized();

    bool updated = false;
    for (final wordId in wordIds) {
      if (!_cards.containsKey(wordId)) {
        _cards[wordId] = CardState.newCard(wordId);
        updated = true;
      }
    }

    if (updated) {
      await _repository.saveCards(_cards);
    }
  }

  /// Get user progress
  Future<UserProgress> getProgress() async {
    await _ensureInitialized();
    return _progress;
  }

  /// Get repository statistics
  Future<RepositoryStats> getStats() async {
    await _ensureInitialized();
    return _repository.getStats();
  }

  /// Reset all data (for testing/debugging)
  Future<void> resetAll() async {
    await _repository.clearAll();
    _cards = {};
    _progress = UserProgress.initial();
    _initialized = false;
  }

  /// Export data for backup/debugging
  Future<Map<String, dynamic>> exportData() async {
    await _ensureInitialized();
    
    return {
      'cards': _cards.map((k, v) => MapEntry(k, v.toJson())),
      'progress': _progress.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Result of completing a session
class SessionResult {
  final int correctCount;
  final int totalCount;
  final int xpEarned;
  final int oldLevel;
  final int newLevel;
  final bool leveledUp;
  final int streakCount;

  SessionResult({
    required this.correctCount,
    required this.totalCount,
    required this.xpEarned,
    required this.oldLevel,
    required this.newLevel,
    required this.leveledUp,
    required this.streakCount,
  });

  double get accuracy => totalCount > 0 ? correctCount / totalCount : 0.0;

  @override
  String toString() {
    return 'SessionResult(correct: $correctCount/$totalCount, '
        'xp: $xpEarned, level: $oldLevel→$newLevel, streak: $streakCount)';
  }
}
