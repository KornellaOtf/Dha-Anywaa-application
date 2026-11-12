import 'package:dha_anywaaa/learning/card_state.dart';

/// Tracks mastery progress by category
/// Mastery = words with stability > 21 days (retained for 3 weeks)
class MasteryTracker {
  // Mastery threshold: 21 days stability = solid retention
  static const double masteryStabilityThreshold = 21.0;

  /// Calculate mastery percentage for a category
  /// Returns 0.0 to 1.0
  static double calculateMastery(List<CardState> cards) {
    if (cards.isEmpty) return 0.0;

    final masteredCount = cards.where((c) => 
      c.stability >= masteryStabilityThreshold
    ).length;

    return masteredCount / cards.length;
  }

  /// Get mastery level description
  static String getMasteryLevel(double mastery) {
    if (mastery >= 0.90) return 'Expert';
    if (mastery >= 0.75) return 'Advanced';
    if (mastery >= 0.60) return 'Proficient';
    if (mastery >= 0.40) return 'Intermediate';
    if (mastery >= 0.20) return 'Developing';
    if (mastery > 0.0) return 'Beginning';
    return 'Not Started';
  }

  /// Get mastery emoji
  static String getMasteryEmoji(double mastery) {
    if (mastery >= 0.90) return '🌟';
    if (mastery >= 0.75) return '💎';
    if (mastery >= 0.60) return '🔥';
    if (mastery >= 0.40) return '✨';
    if (mastery >= 0.20) return '🌱';
    return '🌰';
  }

  /// Calculate detailed mastery breakdown
  static MasteryBreakdown getMasteryBreakdown(List<CardState> cards) {
    if (cards.isEmpty) {
      return MasteryBreakdown(
        total: 0,
        mastered: 0,
        learning: 0,
        new_: 0,
        masteryPercentage: 0.0,
      );
    }

    final mastered = cards.where((c) => 
      c.stability >= masteryStabilityThreshold
    ).length;

    final learning = cards.where((c) => 
      c.state == CardStateType.learning || 
      c.state == CardStateType.relearning ||
      (c.state == CardStateType.review && c.stability < masteryStabilityThreshold)
    ).length;

    final new_ = cards.where((c) => 
      c.state == CardStateType.newCard
    ).length;

    return MasteryBreakdown(
      total: cards.length,
      mastered: mastered,
      learning: learning,
      new_: new_,
      masteryPercentage: mastered / cards.length,
    );
  }

  /// Calculate mastery by category (e.g., body parts, family, animals)
  static Map<String, double> calculateCategoryMastery({
    required Map<String, List<CardState>> cardsByCategory,
  }) {
    final Map<String, double> masteryByCategory = {};

    for (final entry in cardsByCategory.entries) {
      masteryByCategory[entry.key] = calculateMastery(entry.value);
    }

    return masteryByCategory;
  }

  /// Get next milestone (next 10% increment)
  static double getNextMilestone(double currentMastery) {
    final currentPercent = (currentMastery * 100).floor();
    final nextMilestone = ((currentPercent ~/ 10) + 1) * 10;
    return (nextMilestone / 100.0).clamp(0.0, 1.0);
  }

  /// Calculate words needed to reach next milestone
  static int getWordsToNextMilestone({
    required int totalWords,
    required int currentMastered,
  }) {
    if (totalWords == 0) return 0;

    final currentMastery = currentMastered / totalWords;
    final nextMilestone = getNextMilestone(currentMastery);
    final wordsNeeded = (nextMilestone * totalWords).ceil() - currentMastered;

    return wordsNeeded.clamp(0, totalWords - currentMastered);
  }
}

/// Detailed breakdown of mastery progress
class MasteryBreakdown {
  final int total;
  final int mastered;
  final int learning;
  final int new_;
  final double masteryPercentage;

  MasteryBreakdown({
    required this.total,
    required this.mastered,
    required this.learning,
    required this.new_,
    required this.masteryPercentage,
  });

  String get level => MasteryTracker.getMasteryLevel(masteryPercentage);
  String get emoji => MasteryTracker.getMasteryEmoji(masteryPercentage);

  @override
  String toString() {
    return 'MasteryBreakdown(total: $total, mastered: $mastered, '
        'learning: $learning, new: $new_, '
        '${(masteryPercentage * 100).toStringAsFixed(1)}% - $level)';
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'mastered': mastered,
      'learning': learning,
      'new': new_,
      'masteryPercentage': masteryPercentage,
      'level': level,
    };
  }
}

/// Category mastery summary for UI display
class CategoryMasterySummary {
  final String categoryName;
  final int totalWords;
  final int masteredWords;
  final double masteryPercentage;
  final String level;
  final String emoji;

  CategoryMasterySummary({
    required this.categoryName,
    required this.totalWords,
    required this.masteredWords,
    required this.masteryPercentage,
    required this.level,
    required this.emoji,
  });

  factory CategoryMasterySummary.fromCards({
    required String categoryName,
    required List<CardState> cards,
  }) {
    final breakdown = MasteryTracker.getMasteryBreakdown(cards);
    return CategoryMasterySummary(
      categoryName: categoryName,
      totalWords: breakdown.total,
      masteredWords: breakdown.mastered,
      masteryPercentage: breakdown.masteryPercentage,
      level: breakdown.level,
      emoji: breakdown.emoji,
    );
  }

  @override
  String toString() {
    return '$emoji $categoryName: $masteredWords/$totalWords ($level)';
  }
}
