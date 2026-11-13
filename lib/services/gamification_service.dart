import 'package:shared_preferences/shared_preferences.dart';

/// Manages XP, levels, streaks and daily goals.
/// All data is stored locally in SharedPreferences.
/// No network calls, works fully offline.
class GamificationService {
  GamificationService._();
  static final GamificationService instance = GamificationService._();

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _kXp           = 'gam_xp';
  static const _kStreakDays   = 'gam_streak_days';
  static const _kStreakFreeze = 'gam_streak_freezes';
  static const _kLastActive   = 'gam_last_active_day'; // yyyy-MM-dd
  static const _kWeeklyBonus  = 'gam_weekly_bonus_week'; // week number
  static const _kDailyGoal    = 'gam_daily_goal_xp';    // 10 / 20 / 30
  static const _kTodayXp      = 'gam_today_xp';
  static const _kTodayDate    = 'gam_today_date';

  // ── XP per action ─────────────────────────────────────────────────────────
  static const int xpCompleteLesson = 5;
  static const int xpFinishQuiz     = 15;
  static const int xpCorrectAnswer  = 2;
  static const int xpCombo          = 3;  // per combo hit
  static const int xpStreak3        = 5;  // bonus at day 3
  static const int xpStreak7        = 15; // bonus at day 7
  static const int xpStreak14       = 25;
  static const int xpStreak30       = 50;

  // ── Level thresholds (cumulative XP) ─────────────────────────────────────
  static const List<int> _levelThresholds = [
    0, 50, 120, 220, 350, 520, 730, 980, 1270, 1600, 2000,
  ];

  // ── Public API ───────────────────────────────────────────────────────────

  Future<GamState> load() async {
    final p = await SharedPreferences.getInstance();
    final xp           = p.getInt(_kXp) ?? 0;
    final streak       = p.getInt(_kStreakDays) ?? 0;
    final freezes      = p.getInt(_kStreakFreeze) ?? 1;
    final lastActive   = p.getString(_kLastActive) ?? '';
    final dailyGoal    = p.getInt(_kDailyGoal) ?? 20;
    final todayXp      = _getTodayXp(p);
    return GamState(
      xp: xp,
      streakDays: streak,
      freezes: freezes,
      lastActiveDay: lastActive,
      dailyGoalXp: dailyGoal,
      todayXp: todayXp,
    );
  }

  /// Complete the Daily 5 session with final award calculation.
  /// [correct] = number of correct answers, [total] = total answers, [comboXp] = bonus from combos
  /// Returns the final state. This is the single source of truth for Daily 5 rewards.
  Future<GamState> completeDailyFive({
    required int correct,
    required int total,
    required int comboXp,
  }) {
    // Recall XP: 2 per correct, 1 per wrong, plus any combo bonus already earned
    final recallXp = correct * 2 + (total - correct) * 1 + comboXp;
    // Completion bonus: fixed 5 XP for finishing the session
    const completionBonus = 5;
    // Accuracy bonus: 5 XP if >= 80% correct
    final accuracyBonus = total > 0 && correct / total >= 0.8 ? 5 : 0;
    // Total award this session
    final totalAward = recallXp + completionBonus + accuracyBonus;
    return _award(totalAward);
  }

  /// Call when a lesson is completed.
  Future<GamState> onLessonComplete() => _award(xpCompleteLesson);

  /// Call when the quiz is finished. [correct] is the number of right answers.
  Future<GamState> onQuizFinish(int correct) =>
      _award(xpFinishQuiz + correct * xpCorrectAnswer);

  /// Call when the user gets a combo (several correct in a row).
  Future<GamState> onCombo() => _award(xpCombo);

  /// Award an arbitrary XP bonus (e.g. comeback bonus).
  Future<GamState> awardBonus(int xp) => _award(xp);

  /// Set the daily goal (XP target). [minutes] is 5/10/15 -> mapped to XP.
  Future<void> setDailyGoal(int minutes) async {
    final p = await SharedPreferences.getInstance();
    final xp = minutes <= 5 ? 10 : minutes <= 10 ? 20 : 30;
    await p.setInt(_kDailyGoal, xp);
  }

  /// Use a streak freeze. Returns false if no freezes available.
  Future<bool> useFreeze() async {
    final p = await SharedPreferences.getInstance();
    final freezes = p.getInt(_kStreakFreeze) ?? 1;
    if (freezes <= 0) return false;
    await p.setInt(_kStreakFreeze, freezes - 1);
    // Treat today as active so streak is not broken
    await p.setString(_kLastActive, _today());
    return true;
  }

  // ── Level helpers ─────────────────────────────────────────────────────────

  static int levelFromXp(int xp) {
    int lvl = 0;
    for (int i = 0; i < _levelThresholds.length; i++) {
      if (xp >= _levelThresholds[i]) lvl = i;
    }
    return lvl;
  }

  /// Progress towards the next level (0.0 – 1.0).
  static double levelProgress(int xp) {
    final lvl = levelFromXp(xp);
    final thisFloor = _levelThresholds[lvl.clamp(0, _levelThresholds.length - 1)];
    final nextCeil = lvl + 1 < _levelThresholds.length
        ? _levelThresholds[lvl + 1]
        : thisFloor + 500;
    if (nextCeil == thisFloor) return 1.0;
    return ((xp - thisFloor) / (nextCeil - thisFloor)).clamp(0.0, 1.0);
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  Future<GamState> _award(int xp) async {
    final p = await SharedPreferences.getInstance();

    // ── XP ───────────────────────────────────────────────────────────────
    final totalXp = (p.getInt(_kXp) ?? 0) + xp;
    await p.setInt(_kXp, totalXp);

    // ── Today's XP ──────────────────────────────────────────────────────
    int todayXp = _getTodayXp(p) + xp;
    await p.setInt(_kTodayXp, todayXp);
    await p.setString(_kTodayDate, _today());

    // ── Streak ───────────────────────────────────────────────────────────
    final lastActive = p.getString(_kLastActive) ?? '';
    final today      = _today();
    final yesterday  = _daysAgo(1);
    int streak       = p.getInt(_kStreakDays) ?? 0;
    int freezes      = p.getInt(_kStreakFreeze) ?? 1;
    int bonusXp      = 0;

    if (lastActive == today) {
      // Already active today — no change
    } else if (lastActive == yesterday) {
      // Consecutive day
      streak++;
      await p.setInt(_kStreakDays, streak);
      await p.setString(_kLastActive, today);
      bonusXp = _streakBonus(streak);
      if (bonusXp > 0) {
        await p.setInt(_kXp, totalXp + bonusXp);
        todayXp += bonusXp;
        await p.setInt(_kTodayXp, todayXp);
      }
      // Every 7 days earn a freeze (max 2)
      final weekNum = int.tryParse(_weekNumber()) ?? 0;
      final lastBonusWeek = p.getInt(_kWeeklyBonus) ?? -1;
      if (streak % 7 == 0 && weekNum != lastBonusWeek && freezes < 2) {
        freezes++;
        await p.setInt(_kStreakFreeze, freezes);
        await p.setInt(_kWeeklyBonus, weekNum);
      }
    } else if (lastActive.isEmpty) {
      // First ever active day
      streak = 1;
      await p.setInt(_kStreakDays, streak);
      await p.setString(_kLastActive, today);
    } else {
      // Missed at least one day
      if (freezes > 0) {
        // Auto-use freeze silently
        freezes--;
        streak++;
        await p.setInt(_kStreakFreeze, freezes);
        await p.setInt(_kStreakDays, streak);
        await p.setString(_kLastActive, today);
      } else {
        // Streak broken
        streak = 1;
        await p.setInt(_kStreakDays, streak);
        await p.setString(_kLastActive, today);
      }
    }

    final dailyGoal = p.getInt(_kDailyGoal) ?? 20;
    return GamState(
      xp: totalXp + bonusXp,
      streakDays: streak,
      freezes: freezes,
      lastActiveDay: today,
      dailyGoalXp: dailyGoal,
      todayXp: todayXp,
      awardedXp: xp + bonusXp,
      streakBonus: bonusXp,
    );
  }

  int _streakBonus(int streak) {
    if (streak == 3)  return xpStreak3;
    if (streak == 7)  return xpStreak7;
    if (streak == 14) return xpStreak14;
    if (streak == 30) return xpStreak30;
    return 0;
  }

  int _getTodayXp(SharedPreferences p) {
    final date = p.getString(_kTodayDate) ?? '';
    if (date != _today()) return 0;
    return p.getInt(_kTodayXp) ?? 0;
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }

  String _daysAgo(int n) {
    final d = DateTime.now().subtract(Duration(days: n));
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  String _weekNumber() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final diff = now.difference(start).inDays;
    return '${now.year}-${(diff ~/ 7).toString()}';
  }
}

// ── State object returned from every call ─────────────────────────────────
class GamState {
  final int xp;
  final int streakDays;
  final int freezes;
  final String lastActiveDay;
  final int dailyGoalXp;
  final int todayXp;
  final int awardedXp;   // XP earned this call (0 if just loading)
  final int streakBonus; // Extra XP from hitting a streak milestone

  const GamState({
    required this.xp,
    required this.streakDays,
    required this.freezes,
    required this.lastActiveDay,
    required this.dailyGoalXp,
    required this.todayXp,
    this.awardedXp = 0,
    this.streakBonus = 0,
  });

  int get level => GamificationService.levelFromXp(xp);
  double get levelPct => GamificationService.levelProgress(xp);
  double get dailyGoalPct => (todayXp / dailyGoalXp).clamp(0.0, 1.0);
  bool get dailyGoalMet => todayXp >= dailyGoalXp;
  bool get leveledUp => awardedXp > 0 &&
      GamificationService.levelFromXp(xp) >
          GamificationService.levelFromXp(xp - awardedXp);
}
