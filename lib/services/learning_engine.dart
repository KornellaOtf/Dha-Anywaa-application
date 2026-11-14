import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

/// FSRS-6 powered learning engine for Dha Anywaa.
///
/// Replaces the Leitner box system with the Free Spaced Repetition Scheduler
/// (FSRS-6), which tracks two values per word:
///   S  — Stability: how many days until 90% chance of forgetting
///   D  — Difficulty: how hard this specific word is for this learner (1–10)
///
/// Public API is identical to the old Leitner engine so DailyFivePage,
/// home_page, and all callers work without any changes.
class LearningEngine {
  LearningEngine._();
  static final LearningEngine instance = LearningEngine._();

  // ── Storage keys ──────────────────────────────────────────────────────────
  static const _kWordStates     = 'fsrs_word_states_v1';
  static const _kReviewLog      = 'learn_review_log';       // kept for history
  static const _kDailyCompleted = 'learn_daily_completed_date';
  static const _kDailyStreak    = 'learn_daily_streak';

  // ── FSRS-6 default weights (w0–w18) ──────────────────────────────────────
  static const List<double> _w = [
    0.4072, 1.1829, 3.1262, 15.4722, 7.2102,
    0.5316, 1.0651, 0.0234, 1.6160, 0.1544,
    1.0824, 1.9813, 0.0953, 0.2975, 2.2042,
    0.2407, 2.9466, 0.5034, 0.6567,
  ];

  // Target 90% retention; maximum schedulable interval ~100 years
  static const double _requestedRetention = 0.90;
  static const double _maxInterval        = 36500.0;

  // Session size
  static const int dailyTarget = 5;

  // ══════════════════════════════════════════════════════════════════════════
  // Public API  (unchanged signatures — all callers work as-is)
  // ══════════════════════════════════════════════════════════════════════════

  /// Load all word states from storage.
  Future<Map<String, WordState>> loadStates() async {
    final p   = await SharedPreferences.getInstance();
    final raw = p.getString(_kWordStates) ?? '{}';
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, WordState.fromJson(v)));
    } catch (_) {
      return {};
    }
  }

  /// Build today's Daily 5 session.
  /// Returns up to 5 word IDs: overdue first, then new words to fill gaps.
  Future<List<String>> buildDailyFive(List<String> allWordIds) async {
    if (allWordIds.isEmpty) return [];

    final states  = await loadStates();
    final today   = DateTime.now();
    final session = <String>[];

    // Bucket words
    final overdue  = <String>[];   // past due date
    final upcoming = <String>[];   // not yet due (review state)
    final newWords = <String>[];   // never seen

    for (final id in allWordIds) {
      final s = states[id];
      if (s == null) {
        newWords.add(id);
      } else if (s.dueDate.isBefore(today) || s.dueDate.isAtSameMomentAs(today)) {
        overdue.add(id);
      } else {
        upcoming.add(id);
      }
    }

    // Sort overdue: most overdue first
    overdue.sort((a, b) {
      final da = states[a]!.dueDate;
      final db = states[b]!.dueDate;
      return da.compareTo(db);
    });

    // Easy-wins first: low difficulty overdue cards build confidence
    final easyOverdue = overdue
        .where((id) => states[id]!.difficulty < 5.5)
        .toList();
    final hardOverdue = overdue
        .where((id) => states[id]!.difficulty >= 5.5)
        .toList();

    // Fill session: 2 easy → 1 new → 2 hard/remaining
    session.addAll(easyOverdue.take(2));
    if (session.length < dailyTarget && newWords.isNotEmpty) {
      session.add(newWords.first);
    }
    for (final id in hardOverdue) {
      if (session.length >= dailyTarget) break;
      session.add(id);
    }
    // Top up with any remaining
    for (final id in [...newWords.skip(1), ...upcoming..shuffle()]) {
      if (session.length >= dailyTarget) break;
      if (!session.contains(id)) session.add(id);
    }

    return session.take(dailyTarget).toList();
  }

  /// Record a review after every answered question.
  /// Returns the updated WordState.
  Future<WordState> recordReview({
    required String wordId,
    required bool correct,
    int? responseTimeMs,
    String questionType = 'unknown',
  }) async {
    final states = await loadStates();
    final old    = states[wordId];

    final newState = _fsrsUpdate(
      wordId:      wordId,
      current:     old,
      correct:     correct,
      now:         DateTime.now(),
    );

    states[wordId] = newState;
    await _saveStates(states);
    await _logReview(
      wordId:        wordId,
      correct:       correct,
      stabilityBefore: old?.stability ?? 0,
      stabilityAfter:  newState.stability,
      difficultyAfter: newState.difficulty,
      interval:        newState.dueDate.difference(DateTime.now()).inDays,
      responseTimeMs:  responseTimeMs,
      questionType:    questionType,
    );

    return newState;
  }

  /// Number of words due today across the given vocabulary list.
  Future<int> getDueCount(List<String> allWordIds) async {
    final states = await loadStates();
    final today  = DateTime.now();
    int count    = 0;
    for (final id in allWordIds) {
      final s = states[id];
      if (s == null || !s.dueDate.isAfter(today)) count++;
    }
    return count;
  }

  /// (mastered, total) — mastered = stability ≥ 21 days (3-week retention).
  Future<(int, int)> getTopicMastery(List<String> topicWordIds) async {
    final states   = await loadStates();
    int mastered   = 0;
    for (final id in topicWordIds) {
      final s = states[id];
      if (s != null && s.stability >= 21) mastered++;
    }
    return (mastered, topicWordIds.length);
  }

  /// Mark today's Daily 5 as completed and update the completion streak.
  Future<void> markDailyCompleted() async {
    final p      = await SharedPreferences.getInstance();
    final today  = _todayStr();
    final last   = p.getString(_kDailyCompleted) ?? '';
    if (last == today) return; // already counted today

    final streak = last == _daysAgoStr(1)
        ? (p.getInt(_kDailyStreak) ?? 0) + 1
        : 1;
    await p.setInt(_kDailyStreak, streak);
    await p.setString(_kDailyCompleted, today);
  }

  /// Current Daily 5 completion streak (consecutive days).
  Future<int> getDailyStreak() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kDailyStreak) ?? 0;
  }

  /// Whether today's Daily 5 session is already done.
  Future<bool> isDailyCompleted() async {
    final p    = await SharedPreferences.getInstance();
    final date = p.getString(_kDailyCompleted) ?? '';
    return date == _todayStr();
  }

  /// Reset a single word (re-learn from scratch).
  Future<void> resetWord(String wordId) async {
    final states = await loadStates();
    states.remove(wordId);
    await _saveStates(states);
  }

  /// Wipe all learning progress (ask for confirmation before calling).
  Future<void> resetAllProgress() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kWordStates);
    await p.remove(_kReviewLog);
    await p.remove(_kDailyCompleted);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FSRS-6 Core Algorithm
  // ══════════════════════════════════════════════════════════════════════════

  WordState _fsrsUpdate({
    required String    wordId,
    required WordState? current,
    required bool      correct,
    required DateTime  now,
  }) {
    // Rating: incorrect → Again (1), correct → Good (3)
    final rating = correct ? 3 : 1;

    // ── Brand-new card ────────────────────────────────────────────────────
    if (current == null || current.reviewCount == 0) {
      final s = _initStability(rating).clamp(0.1, _maxInterval);
      final d = _initDifficulty(rating).clamp(1.0, 10.0);

      // First correct: go to short learning step (10 min); wrong: 1 min
      final due = correct
          ? now.add(const Duration(minutes: 10))
          : now.add(const Duration(minutes: 1));

      return WordState(
        wordId:       wordId,
        stability:    s,
        difficulty:   d,
        dueDate:      due,
        reviewCount:  1,
        correctCount: correct ? 1 : 0,
        lapses:       correct ? 0 : 1,
        lastReviewed: now,
        graduated:    false,
      );
    }

    // ── Learning / re-learning (not yet graduated) ────────────────────────
    if (!current.graduated) {
      if (!correct) {
        return current.copyWith(
          dueDate:      now.add(const Duration(minutes: 1)),
          reviewCount:  current.reviewCount + 1,
          lapses:       current.lapses + 1,
          lastReviewed: now,
        );
      }
      // Correct in learning → graduate to review
      final interval = _calcInterval(current.stability);
      return current.copyWith(
        dueDate:      now.add(Duration(days: interval)),
        reviewCount:  current.reviewCount + 1,
        correctCount: current.correctCount + 1,
        lastReviewed: now,
        graduated:    true,
      );
    }

    // ── Review state (graduated) ──────────────────────────────────────────
    final elapsed = now.difference(current.lastReviewed).inSeconds / 86400.0;
    final r = math.exp(math.log(0.9) * elapsed / current.stability)
        .clamp(0.0, 1.0); // retrievability

    final newD = _nextDifficulty(current.difficulty, rating).clamp(1.0, 10.0);

    if (!correct) {
      // Lapse: drop to re-learning
      final newS = _forgetStability(current.difficulty, current.stability, r)
          .clamp(0.1, _maxInterval);
      return current.copyWith(
        stability:    newS,
        difficulty:   newD,
        dueDate:      now.add(const Duration(minutes: 10)),
        reviewCount:  current.reviewCount + 1,
        lapses:       current.lapses + 1,
        lastReviewed: now,
        graduated:    false,
      );
    }

    // Correct review → new stability and interval
    final newS = _recallStability(current.difficulty, current.stability, r, rating)
        .clamp(0.1, _maxInterval);
    final interval = _calcInterval(newS);

    return current.copyWith(
      stability:    newS,
      difficulty:   newD,
      dueDate:      now.add(Duration(days: interval)),
      reviewCount:  current.reviewCount + 1,
      correctCount: current.correctCount + 1,
      lastReviewed: now,
      graduated:    true,
    );
  }

  // ── FSRS-6 formulas ───────────────────────────────────────────────────────

  double _initStability(int rating) => _w[rating - 1]; // w0–w3

  double _initDifficulty(int rating) =>
      _w[4] - (_w[5] * (rating - 3));

  double _nextDifficulty(double d, int rating) =>
      d - (_w[6] * (rating - 3));

  double _recallStability(double d, double s, double r, int rating) {
    final hardPenalty = rating == 2 ? _w[15] : 1.0;
    final easyBonus   = rating == 4 ? _w[16] : 1.0;
    return s * (1 +
        math.exp(_w[8]) *
        (11 - d) *
        math.pow(s, -_w[9]) *
        (math.exp((1 - r) * _w[10]) - 1) *
        hardPenalty *
        easyBonus);
  }

  double _forgetStability(double d, double s, double r) =>
      _w[11] *
      math.pow(d, -_w[12]) *
      (math.pow(s + 1, _w[13]) - 1) *
      math.exp((1 - r) * _w[14]);

  int _calcInterval(double stability) {
    final days = (stability * 9 * (1 / _requestedRetention - 1)).round();
    return days.clamp(1, _maxInterval.toInt());
  }

  // ── Persistence helpers ───────────────────────────────────────────────────

  Future<void> _saveStates(Map<String, WordState> states) async {
    final p   = await SharedPreferences.getInstance();
    final map = states.map((k, v) => MapEntry(k, v.toJson()));
    await p.setString(_kWordStates, jsonEncode(map));
  }

  Future<void> _logReview({
    required String wordId,
    required bool   correct,
    required double stabilityBefore,
    required double stabilityAfter,
    required double difficultyAfter,
    required int    interval,
    int?    responseTimeMs,
    required String questionType,
  }) async {
    final p    = await SharedPreferences.getInstance();
    final raw  = p.getString(_kReviewLog) ?? '[]';
    final list = jsonDecode(raw) as List<dynamic>;

    list.add({
      'ts':              DateTime.now().toIso8601String(),
      'wordId':          wordId,
      'correct':         correct,
      'sBefore':         stabilityBefore,
      'sAfter':          stabilityAfter,
      'difficulty':      difficultyAfter,
      'interval':        interval,
      'responseTimeMs':  responseTimeMs,
      'questionType':    questionType,
    });

    if (list.length > 10000) list.removeRange(0, list.length - 10000);
    await p.setString(_kReviewLog, jsonEncode(list));
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  String _daysAgoStr(int days) {
    final n = DateTime.now().subtract(Duration(days: days));
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}

// ══════════════════════════════════════════════════════════════════════════
// WordState — FSRS card model (replaces the old Leitner WordState)
// ══════════════════════════════════════════════════════════════════════════

class WordState {
  final String   wordId;
  final double   stability;    // S: days until 90% forgetting
  final double   difficulty;   // D: 1 (easy) – 10 (hard)
  final DateTime dueDate;      // next scheduled review
  final int      reviewCount;
  final int      correctCount;
  final int      lapses;       // times forgotten after graduating
  final DateTime lastReviewed;
  final bool     graduated;    // false = still in learning steps

  const WordState({
    required this.wordId,
    required this.stability,
    required this.difficulty,
    required this.dueDate,
    required this.reviewCount,
    required this.correctCount,
    required this.lapses,
    required this.lastReviewed,
    required this.graduated,
  });

  // Convenience getters
  double get accuracy =>
      reviewCount > 0 ? correctCount / reviewCount : 0.0;

  bool isDue({DateTime? now}) =>
      !(dueDate.isAfter(now ?? DateTime.now()));

  /// Mastery = graduated + stability ≥ 21 days
  bool get mastered => graduated && stability >= 21;

  WordState copyWith({
    double?   stability,
    double?   difficulty,
    DateTime? dueDate,
    int?      reviewCount,
    int?      correctCount,
    int?      lapses,
    DateTime? lastReviewed,
    bool?     graduated,
  }) =>
      WordState(
        wordId:       wordId,
        stability:    stability    ?? this.stability,
        difficulty:   difficulty   ?? this.difficulty,
        dueDate:      dueDate      ?? this.dueDate,
        reviewCount:  reviewCount  ?? this.reviewCount,
        correctCount: correctCount ?? this.correctCount,
        lapses:       lapses       ?? this.lapses,
        lastReviewed: lastReviewed ?? this.lastReviewed,
        graduated:    graduated    ?? this.graduated,
      );

  Map<String, dynamic> toJson() => {
        'wordId':       wordId,
        'stability':    stability,
        'difficulty':   difficulty,
        'dueDate':      dueDate.toIso8601String(),
        'reviewCount':  reviewCount,
        'correctCount': correctCount,
        'lapses':       lapses,
        'lastReviewed': lastReviewed.toIso8601String(),
        'graduated':    graduated,
      };

  factory WordState.fromJson(Map<String, dynamic> j) => WordState(
        wordId:       j['wordId']       as String,
        stability:    (j['stability']   as num).toDouble(),
        difficulty:   (j['difficulty']  as num).toDouble(),
        dueDate:      DateTime.parse(j['dueDate']      as String),
        reviewCount:  j['reviewCount']  as int,
        correctCount: j['correctCount'] as int,
        lapses:       (j['lapses']      as int?) ?? 0,
        lastReviewed: DateTime.parse(j['lastReviewed'] as String),
        graduated:    (j['graduated']   as bool?) ?? false,
      );

  @override
  String toString() =>
      'WordState($wordId S=${stability.toStringAsFixed(1)} '
      'D=${difficulty.toStringAsFixed(1)} due=$dueDate '
      'reps=$reviewCount lapses=$lapses graduated=$graduated)';
}
