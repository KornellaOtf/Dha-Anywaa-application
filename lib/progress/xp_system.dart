import 'package:dha_anywaa_app/learning/fsrs_engine.dart';

/// XP (Experience Points) and Leveling System
/// Rewards consistent learning with visible progress
class XPSystem {
  // XP rewards per action
  static const int xpCorrect = 10;
  static const int xpIncorrect = 5;  // Still rewarded for trying
  static const int xpSessionComplete = 25;
  static const int xpStreakBonus = 15;  // Bonus for maintaining streak

  /// Calculate XP earned from a single review
  static int calculateReviewXP({
    required Rating rating,
    bool isFirstReview = false,
  }) {
    if (rating == Rating.again) {
      return xpIncorrect;
    }
    
    // Correct answer base
    int xp = xpCorrect;
    
    // Bonus for first-time success
    if (isFirstReview && rating == Rating.easy) {
      xp += 5;
    }
    
    return xp;
  }

  /// Calculate XP for completing Daily 5 session
  static int calculateSessionXP({
    required int correctCount,
    required int totalCount,
    bool hasActiveStreak = false,
  }) {
    int xp = xpSessionComplete;
    
    // Perfect session bonus
    if (correctCount == totalCount) {
      xp += 10;
    }
    
    // Streak bonus
    if (hasActiveStreak) {
      xp += xpStreakBonus;
    }
    
    return xp;
  }

  /// Get level from total XP
  /// Level thresholds grow gradually (not exponential)
  /// Designed to feel achievable but meaningful
  static int getLevelFromXP(int totalXP) {
    if (totalXP < 100) return 1;
    if (totalXP < 250) return 2;
    if (totalXP < 500) return 3;
    if (totalXP < 1000) return 4;
    if (totalXP < 1750) return 5;
    if (totalXP < 2500) return 6;
    if (totalXP < 3500) return 7;
    if (totalXP < 5000) return 8;
    if (totalXP < 7000) return 9;
    if (totalXP < 10000) return 10;
    
    // Beyond level 10: ~2000 XP per level
    final beyondLevel10 = ((totalXP - 10000) / 2000).floor();
    return 10 + beyondLevel10;
  }

  /// Get XP needed for next level
  static int getXPForLevel(int level) {
    const List<int> thresholds = [
      0,     // Level 1
      100,   // Level 2
      250,   // Level 3
      500,   // Level 4
      1000,  // Level 5
      1750,  // Level 6
      2500,  // Level 7
      3500,  // Level 8
      5000,  // Level 9
      7000,  // Level 10
      10000, // Level 11
    ];
    
    if (level < thresholds.length) {
      return thresholds[level];
    }
    
    // Beyond level 11: +2000 XP per level
    return 10000 + ((level - 10) * 2000);
  }

  /// Get progress to next level (0.0 to 1.0)
  static double getProgressToNextLevel(int totalXP) {
    final currentLevel = getLevelFromXP(totalXP);
    final currentLevelXP = getXPForLevel(currentLevel);
    final nextLevelXP = getXPForLevel(currentLevel + 1);
    
    final progress = (totalXP - currentLevelXP) / (nextLevelXP - currentLevelXP);
    return progress.clamp(0.0, 1.0);
  }

  /// Get remaining XP needed for next level
  static int getXPToNextLevel(int totalXP) {
    final currentLevel = getLevelFromXP(totalXP);
    final nextLevelXP = getXPForLevel(currentLevel + 1);
    return nextLevelXP - totalXP;
  }

  /// Get level title for display
  static String getLevelTitle(int level) {
    if (level >= 50) return 'Dhöödh (Elder)';
    if (level >= 40) return 'Twäär (Teacher)';
    if (level >= 30) return 'Jwøk (Expert)';
    if (level >= 20) return 'Gätjäk (Strong Speaker)';
    if (level >= 15) return 'Käny (Fluent)';
    if (level >= 10) return 'Cøl (Conversational)';
    if (level >= 7) return 'Mööth (Learning)';
    if (level >= 5) return 'Piny (Beginner)';
    if (level >= 3) return 'Bääny (New Learner)';
    return 'Bäär (Starting)';
  }

  /// Get emoji for level range
  static String getLevelEmoji(int level) {
    if (level >= 40) return '🌟';
    if (level >= 30) return '💎';
    if (level >= 20) return '🏆';
    if (level >= 15) return '🔥';
    if (level >= 10) return '⚡';
    if (level >= 5) return '✨';
    return '🌱';
  }
}

/// User progress state with XP tracking
class UserProgress {
  final int totalXP;
  final int currentStreak;
  final DateTime? lastSessionDate;
  final int totalSessions;
  final int totalReviews;
  final int totalCorrect;

  UserProgress({
    required this.totalXP,
    required this.currentStreak,
    this.lastSessionDate,
    required this.totalSessions,
    required this.totalReviews,
    required this.totalCorrect,
  });

  int get level => XPSystem.getLevelFromXP(totalXP);
  String get levelTitle => XPSystem.getLevelTitle(level);
  String get levelEmoji => XPSystem.getLevelEmoji(level);
  double get progressToNext => XPSystem.getProgressToNextLevel(totalXP);
  int get xpToNext => XPSystem.getXPToNextLevel(totalXP);
  
  double get accuracy => totalReviews > 0 
      ? totalCorrect / totalReviews 
      : 0.0;

  /// Add XP and return updated progress
  UserProgress addXP(int xp) {
    return UserProgress(
      totalXP: totalXP + xp,
      currentStreak: currentStreak,
      lastSessionDate: lastSessionDate,
      totalSessions: totalSessions,
      totalReviews: totalReviews,
      totalCorrect: totalCorrect,
    );
  }

  /// Record session completion
  UserProgress completeSession({
    required int correctCount,
    required int reviewCount,
    DateTime? sessionDate,
  }) {
    final now = sessionDate ?? DateTime.now();
    final isConsecutiveDay = _isConsecutiveDay(now);
    
    return UserProgress(
      totalXP: totalXP,
      currentStreak: isConsecutiveDay ? currentStreak + 1 : 1,
      lastSessionDate: now,
      totalSessions: totalSessions + 1,
      totalReviews: totalReviews + reviewCount,
      totalCorrect: totalCorrect + correctCount,
    );
  }

  bool _isConsecutiveDay(DateTime newDate) {
    if (lastSessionDate == null) return false;
    
    final daysDiff = newDate.difference(lastSessionDate!).inDays;
    return daysDiff == 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalXP': totalXP,
      'currentStreak': currentStreak,
      'lastSessionDate': lastSessionDate?.toIso8601String(),
      'totalSessions': totalSessions,
      'totalReviews': totalReviews,
      'totalCorrect': totalCorrect,
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      totalXP: json['totalXP'] as int,
      currentStreak: json['currentStreak'] as int,
      lastSessionDate: json['lastSessionDate'] != null
          ? DateTime.parse(json['lastSessionDate'] as String)
          : null,
      totalSessions: json['totalSessions'] as int,
      totalReviews: json['totalReviews'] as int,
      totalCorrect: json['totalCorrect'] as int,
    );
  }

  factory UserProgress.initial() {
    return UserProgress(
      totalXP: 0,
      currentStreak: 0,
      lastSessionDate: null,
      totalSessions: 0,
      totalReviews: 0,
      totalCorrect: 0,
    );
  }
}
