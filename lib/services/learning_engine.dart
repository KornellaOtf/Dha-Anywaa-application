import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// The most effective spaced repetition engine for Dha Anywaa.
///
/// Core principles:
/// - Personalized: each word tracks difficulty for each learner
/// - Forgiving: one mistake doesn't reset everything
/// - Research-backed: uses modified Leitner + Half-Life inspired intervals
/// - Upgradeable: logs every review so you can switch to FSRS later
/// - Offline-first: everything in SharedPreferences
///
/// The algorithm:
/// 1. Words live in boxes 0-5 (0 = new, 5 = mastered)
/// 2. Each word has an ease factor (1.3 = hard, 2.5 = easy)
/// 3. Review intervals grow exponentially with ease adjustment
/// 4. Getting it wrong drops the word 1 box (not all the way back)
/// 5. Daily 5 mixes: 60% due, 30% weak (low ease), 10% new
class LearningEngine {
  LearningEngine._();
  static final LearningEngine instance = LearningEngine._();

  // ── Storage keys ──────────────────────────────────────────────────────────
  static const _kWordStates = 'learn_word_states'; // JSON map
  static const _kReviewLog = 'learn_review_log';   // JSON list (append-only)
  static const _kDailyCompleted = 'learn_daily_completed_date';

  // ── Box intervals (days until next review) ────────────────────────────────
  static const List<int> _baseIntervals = [
    0,  // box 0: new word, show immediately
    1,  // box 1: 1 day
    3,  // box 2: 3 days
    7,  // box 3: 7 days (1 week)
    21, // box 4: 21 days (3 weeks)
    60, // box 5: 60 days (2 months)
  ];

  // ── Daily 5 mix ratios ────────────────────────────────────────────────────
  static const int dailyTarget = 5;
  static const double dueMix = 0.6;   // 3 due words
  static const double weakMix = 0.3;  // 1-2 weak words (low ease)
  static const double newMix = 0.1;   // 0-1 new words

  // ── Ease bounds ───────────────────────────────────────────────────────────
  static const double minEase = 1.3;
  static const double maxEase = 2.5;
  static const double defaultEase = 1.8;
  static const double easeBonus = 0.15;   // correct: +0.15
  static const double easePenalty = 0.20; // wrong: -0.20

  // ══════════════════════════════════════════════════════════════════════════
  // Public API
  // ══════════════════════════════════════════════════════════════════════════

  /// Load all word states.
  Future<Map<String, WordState>> loadStates() async {
    final p = await SharedPreferences.getInstance();
    final json = p.getString(_kWordStates) ?? '{}';
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, WordState.fromJson(v)));
  }

  /// Save all word states.
  Future<void> _saveStates(Map<String, WordState> states) async {
    final p = await SharedPreferences.getInstance();
    final map = states.map((k, v) => MapEntry(k, v.toJson()));
    await p.setString(_kWordStates, jsonEncode(map));
  }

  /// Build today's Daily 5 session.
  /// Returns up to 5 word IDs mixing due, weak and new words.
  /// [allWordIds] is the full vocabulary list from your CSV/assets.
  Future<List<String>> buildDailyFive(List<String> allWordIds) async {
    if (allWordIds.isEmpty) return [];

    final states = await loadStates();
    final now = _today();

    // Categorize words
    final due = <String>[];
    final weak = <String>[];
    final newWords = <String>[];

    for (final id in allWordIds) {
      final state = states[id];
      if (state == null) {
        newWords.add(id);
      } else if (state.dueDate.compareTo(now) <= 0) {
        due.add(id);
        if (state.ease < 1.8) weak.add(id); // ease below average = weak
      }
    }

    // Shuffle for variety
    due.shuffle();
    weak.shuffle();
    newWords.shuffle();

    // Mix according to ratios
    final session = <String>[];
    final dueCount = (dailyTarget * dueMix).round();
    final weakCount = (dailyTarget * weakMix).round();

    session.addAll(due.take(dueCount));
    
    // Add weak words (not already in session)
    final weakNeeded = weakCount - session.where((id) => weak.contains(id)).length;
    session.addAll(weak.where((id) => !session.contains(id)).take(weakNeeded));

    // Fill with new words if we don't have enough due/weak
    if (session.length < dailyTarget) {
      session.addAll(newWords.take(dailyTarget - session.length));
    }

    // If still short, just take anything available
    if (session.length < dailyTarget) {
      final remaining = allWordIds.where((id) => !session.contains(id)).toList()..shuffle();
      session.addAll(remaining.take(dailyTarget - session.length));
    }

    return session.take(dailyTarget).toList();
  }

  /// Record a review: call this after every question answered.
  /// [wordId] the word being reviewed
  /// [correct] whether the answer was correct
  /// [responseTimeMs] how long the user took (optional, for future analysis)
  /// [questionType] e.g. 'picture_to_word', 'word_to_picture', 'audio'
  ///
  /// Returns the updated state for this word.
  Future<WordState> recordReview({
    required String wordId,
    required bool correct,
    int? responseTimeMs,
    String questionType = 'unknown',
  }) async {
    final states = await loadStates();
    final old = states[wordId];

    // Calculate new state
    final newState = _calculateNextState(
      wordId: wordId,
      current: old,
      correct: correct,
      now: _today(),
    );

    // Save state
    states[wordId] = newState;
    await _saveStates(states);

    // Log the review (append-only for future algorithm upgrades)
    await _logReview(
      wordId: wordId,
      correct: correct,
      oldBox: old?.box ?? 0,
      newBox: newState.box,
      oldEase: old?.ease ?? defaultEase,
      newEase: newState.ease,
      responseTimeMs: responseTimeMs,
      questionType: questionType,
    );

    return newState;
  }

  /// Get count of words due today.
  Future<int> getDueCount(List<String> allWordIds) async {
    final states = await loadStates();
    final now = _today();
    int count = 0;
    for (final id in allWordIds) {
      final state = states[id];
      if (state == null || state.dueDate.compareTo(now) <= 0) {
        count++;
      }
    }
    return count;
  }

  /// Get mastery progress for a topic.
  /// Returns (mastered, total) where mastered = words in box 4+
  Future<(int, int)> getTopicMastery(List<String> topicWordIds) async {
    final states = await loadStates();
    int mastered = 0;
    for (final id in topicWordIds) {
      final state = states[id];
      if (state != null && state.box >= 4) mastered++;
    }
    return (mastered, topicWordIds.length);
  }

  /// Mark today's Daily 5 as completed.
  Future<void> markDailyCompleted() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kDailyCompleted, _today());
  }

  /// Check if today's Daily 5 was already completed.
  Future<bool> isDailyCompleted() async {
    final p = await SharedPreferences.getInstance();
    final date = p.getString(_kDailyCompleted) ?? '';
    return date == _today();
  }

  /// Reset a word (for testing or if user wants to re-learn).
  Future<void> resetWord(String wordId) async {
    final states = await loadStates();
    states.remove(wordId);
    await _saveStates(states);
  }

  /// Reset all progress (danger zone, ask for confirmation).
  Future<void> resetAllProgress() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kWordStates);
    await p.remove(_kReviewLog);
    await p.remove(_kDailyCompleted);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Internal algorithm
  // ══════════════════════════════════════════════════════════════════════════

  WordState _calculateNextState({
    required String wordId,
    required WordState? current,
    required bool correct,
    required String now,
  }) {
    // First time seeing this word
    if (current == null) {
      return WordState(
        wordId: wordId,
        box: correct ? 1 : 0,
        ease: correct ? defaultEase + easeBonus : defaultEase,
        dueDate: _addDays(now, correct ? _baseIntervals[1] : 0),
        reviewCount: 1,
        correctCount: correct ? 1 : 0,
        lastReviewed: now,
      );
    }

    // Existing word
    int newBox = current.box;
    double newEase = current.ease;

    if (correct) {
      // Move up one box (max 5)
      newBox = min(current.box + 1, 5);
      // Increase ease slightly
      newEase = min(current.ease + easeBonus, maxEase);
    } else {
      // Move down one box (min 0), but not catastrophic
      newBox = max(current.box - 1, 0);
      // Decrease ease
      newEase = max(current.ease - easePenalty, minEase);
    }

    // Calculate next due date with ease modifier
    final baseInterval = _baseIntervals[newBox];
    final adjustedInterval = (baseInterval * newEase).round();
    final dueDate = _addDays(now, adjustedInterval);

    return WordState(
      wordId: wordId,
      box: newBox,
      ease: newEase,
      dueDate: dueDate,
      reviewCount: current.reviewCount + 1,
      correctCount: current.correctCount + (correct ? 1 : 0),
      lastReviewed: now,
    );
  }

  Future<void> _logReview({
    required String wordId,
    required bool correct,
    required int oldBox,
    required int newBox,
    required double oldEase,
    required double newEase,
    int? responseTimeMs,
    required String questionType,
  }) async {
    final p = await SharedPreferences.getInstance();
    final json = p.getString(_kReviewLog) ?? '[]';
    final list = jsonDecode(json) as List<dynamic>;

    list.add({
      'timestamp': DateTime.now().toIso8601String(),
      'wordId': wordId,
      'correct': correct,
      'oldBox': oldBox,
      'newBox': newBox,
      'oldEase': oldEase,
      'newEase': newEase,
      'responseTimeMs': responseTimeMs,
      'questionType': questionType,
    });

    // Keep only last 10,000 reviews to avoid storage bloat
    if (list.length > 10000) {
      list.removeRange(0, list.length - 10000);
    }

    await p.setString(_kReviewLog, jsonEncode(list));
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _addDays(String date, int days) {
    final parts = date.split('-');
    final d = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    ).add(Duration(days: days));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Word State Model
// ══════════════════════════════════════════════════════════════════════════

class WordState {
  final String wordId;
  final int box;            // 0 = new, 5 = mastered
  final double ease;        // 1.3 (hard) to 2.5 (easy)
  final String dueDate;     // yyyy-MM-dd
  final int reviewCount;    // total times reviewed
  final int correctCount;   // total correct answers
  final String lastReviewed; // yyyy-MM-dd

  const WordState({
    required this.wordId,
    required this.box,
    required this.ease,
    required this.dueDate,
    required this.reviewCount,
    required this.correctCount,
    required this.lastReviewed,
  });

  /// Accuracy percentage (0.0 to 1.0)
  double get accuracy => reviewCount > 0 ? correctCount / reviewCount : 0.0;

  /// Is this word mastered? (box 4 or 5)
  bool get isMastered => box >= 4;

  /// Is this word weak? (low ease factor)
  bool get isWeak => ease < 1.8;

  Map<String, dynamic> toJson() => {
        'wordId': wordId,
        'box': box,
        'ease': ease,
        'dueDate': dueDate,
        'reviewCount': reviewCount,
        'correctCount': correctCount,
        'lastReviewed': lastReviewed,
      };

  factory WordState.fromJson(Map<String, dynamic> json) => WordState(
        wordId: json['wordId'] as String,
        box: json['box'] as int,
        ease: (json['ease'] as num).toDouble(),
        dueDate: json['dueDate'] as String,
        reviewCount: json['reviewCount'] as int,
        correctCount: json['correctCount'] as int,
        lastReviewed: json['lastReviewed'] as String,
      );
}
