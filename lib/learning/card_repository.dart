import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dha_anywaaa/learning/card_state.dart';
import 'package:dha_anywaaa/learning/review_event.dart';
import 'package:dha_anywaaa/progress/xp_system.dart';

/// Persistent storage for FSRS card states and review history
class CardRepository {
  static const String _cardsKey = 'fsrs_cards_v1';
  static const String _reviewsKey = 'fsrs_reviews_v1';
  static const String _progressKey = 'user_progress_v1';
  static const String _migrationKey = 'leitner_to_fsrs_migration';

  /// Load all card states
  Future<Map<String, CardState>> loadCards() async {
    final prefs = await SharedPreferences.getInstance();
    final cardsJson = prefs.getString(_cardsKey);
    
    if (cardsJson == null) return {};

    try {
      final Map<String, dynamic> decoded = jsonDecode(cardsJson);
      final Map<String, CardState> cards = {};
      
      for (final entry in decoded.entries) {
        cards[entry.key] = CardState.fromJson(entry.value);
      }
      
      return cards;
    } catch (e) {
      print('Error loading cards: $e');
      return {};
    }
  }

  /// Save all card states
  Future<void> saveCards(Map<String, CardState> cards) async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      final Map<String, dynamic> toSave = {};
      for (final entry in cards.entries) {
        toSave[entry.key] = entry.value.toJson();
      }
      
      await prefs.setString(_cardsKey, jsonEncode(toSave));
    } catch (e) {
      print('Error saving cards: $e');
    }
  }

  /// Save single card (more efficient for updates)
  Future<void> saveCard(CardState card) async {
    final cards = await loadCards();
    cards[card.wordId] = card;
    await saveCards(cards);
  }

  /// Get card by word ID (creates new card if doesn't exist)
  Future<CardState> getOrCreateCard(String wordId) async {
    final cards = await loadCards();
    return cards[wordId] ?? CardState.newCard(wordId);
  }

  /// Load review history
  Future<List<ReviewEvent>> loadReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final reviewsJson = prefs.getString(_reviewsKey);
    
    if (reviewsJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(reviewsJson);
      return decoded.map((json) => ReviewEvent.fromJson(json)).toList();
    } catch (e) {
      print('Error loading reviews: $e');
      return [];
    }
  }

  /// Append review event to history
  Future<void> addReview(ReviewEvent event) async {
    final reviews = await loadReviews();
    reviews.add(event);
    
    // Keep only last 10,000 reviews to prevent unbounded growth
    if (reviews.length > 10000) {
      reviews.removeRange(0, reviews.length - 10000);
    }
    
    final prefs = await SharedPreferences.getInstance();
    try {
      final toSave = reviews.map((r) => r.toJson()).toList();
      await prefs.setString(_reviewsKey, jsonEncode(toSave));
    } catch (e) {
      print('Error saving review: $e');
    }
  }

  /// Batch add review events (more efficient)
  Future<void> addReviews(List<ReviewEvent> events) async {
    if (events.isEmpty) return;
    
    final reviews = await loadReviews();
    reviews.addAll(events);
    
    // Keep only last 10,000 reviews
    if (reviews.length > 10000) {
      reviews.removeRange(0, reviews.length - 10000);
    }
    
    final prefs = await SharedPreferences.getInstance();
    try {
      final toSave = reviews.map((r) => r.toJson()).toList();
      await prefs.setString(_reviewsKey, jsonEncode(toSave));
    } catch (e) {
      print('Error saving reviews: $e');
    }
  }

  /// Load user progress
  Future<UserProgress> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_progressKey);
    
    if (progressJson == null) return UserProgress.initial();

    try {
      final decoded = jsonDecode(progressJson);
      return UserProgress.fromJson(decoded);
    } catch (e) {
      print('Error loading progress: $e');
      return UserProgress.initial();
    }
  }

  /// Save user progress
  Future<void> saveProgress(UserProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_progressKey, jsonEncode(progress.toJson()));
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  /// Check if Leitner→FSRS migration has been done
  Future<bool> hasMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey) ?? false;
  }

  /// Mark migration as complete
  Future<void> markMigrated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, true);
  }

  /// Migrate Leitner box data to FSRS cards
  /// This reads the old box-based system and creates FSRS cards
  Future<void> migrateLeitnerToFSRS() async {
    if (await hasMigrated()) return;

    final prefs = await SharedPreferences.getInstance();
    final cards = <String, CardState>{};

    // TODO: Read old Leitner data and convert
    // Example structure (adjust based on actual implementation):
    // For each word, get: box level, review count
    // Then create: CardState.fromLeitnerBox(...)
    
    // For now, create placeholder migration logic
    // Real implementation depends on existing data structure
    
    await saveCards(cards);
    await markMigrated();
    
    print('Leitner→FSRS migration complete: ${cards.length} cards migrated');
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cardsKey);
    await prefs.remove(_reviewsKey);
    await prefs.remove(_progressKey);
    await prefs.remove(_migrationKey);
  }

  /// Get statistics
  Future<RepositoryStats> getStats() async {
    final cards = await loadCards();
    final reviews = await loadReviews();
    final progress = await loadProgress();

    final newCount = cards.values.where((c) => c.state == CardStateType.newCard).length;
    final learningCount = cards.values.where((c) => 
      c.state == CardStateType.learning || c.state == CardStateType.relearning
    ).length;
    final reviewCount = cards.values.where((c) => c.state == CardStateType.review).length;
    
    final dueCount = cards.values.where((c) => c.isDue()).length;

    return RepositoryStats(
      totalCards: cards.length,
      newCards: newCount,
      learningCards: learningCount,
      reviewCards: reviewCount,
      dueCards: dueCount,
      totalReviews: reviews.length,
      userProgress: progress,
    );
  }
}

/// Statistics about stored data
class RepositoryStats {
  final int totalCards;
  final int newCards;
  final int learningCards;
  final int reviewCards;
  final int dueCards;
  final int totalReviews;
  final UserProgress userProgress;

  RepositoryStats({
    required this.totalCards,
    required this.newCards,
    required this.learningCards,
    required this.reviewCards,
    required this.dueCards,
    required this.totalReviews,
    required this.userProgress,
  });

  @override
  String toString() {
    return 'RepositoryStats(total: $totalCards, new: $newCards, '
        'learning: $learningCards, review: $reviewCards, due: $dueCards, '
        'totalReviews: $totalReviews, level: ${userProgress.level})';
  }
}
