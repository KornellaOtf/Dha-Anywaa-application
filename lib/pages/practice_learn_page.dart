// lib/pages/practice_learn_page.dart
// Practice + Learn screens for Dha Anywaa vocabulary learning.
// Inspired by driving theory reference but adapted for language learning.

import 'package:flutter/material.dart';
import 'package:dha_anywaaa/services/word_aggregator.dart';
import 'package:dha_anywaaa/services/learning_engine.dart';
import 'package:dha_anywaaa/services/gamification_service.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────
const kScaffold = Color(0xFFF6F5F2);
const kCard = Colors.white;
const kTile = Color(0xFFECEAE6);
const kInk = Color(0xFF1B1B1B);
const kMuted = Color(0xFF6E6E6E);
const kTrack = Color(0xFFE3E1DC);

List<BoxShadow> get kSoftShadow => const [
      BoxShadow(
          color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 4)),
    ];

// ─── Models ────────────────────────────────────────────────────────────────
class DhaCategory {
  final String id, title, subtitle, imageAsset;
  final int done, total;

  const DhaCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.done,
    required this.total,
  });

  bool get completed => total > 0 && done >= total;
}

class PracticeStats {
  final int wordsLearned, wordsTotal, phrasesDone, phrasesTotal;
  final int dailyFiveStreak;

  const PracticeStats({
    required this.wordsLearned,
    required this.wordsTotal,
    required this.phrasesDone,
    required this.phrasesTotal,
    required this.dailyFiveStreak,
  });
}

// ─── Shell with floating navigation ────────────────────────────────────────
class PracticeLearnShell extends StatefulWidget {
  final Widget overviewPage;
  final Widget progressPage;

  const PracticeLearnShell({
    super.key,
    required this.overviewPage,
    required this.progressPage,
  });

  @override
  State<PracticeLearnShell> createState() => _PracticeLearnShellState();
}

class _PracticeLearnShellState extends State<PracticeLearnShell> {
  int _index = 2; // Start on Practice
  String _learnerName = '';
  PracticeStats _stats = const PracticeStats(
    wordsLearned: 0,
    wordsTotal: 0,
    phrasesDone: 0,
    phrasesTotal: 0,
    dailyFiveStreak: 0,
  );
  List<DhaCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('learner_name') ?? '';
    
    // Load gamification stats
    final gamState = await GamificationService.instance.load();
    
    // Load word progress from learning engine
    final allWords = await WordAggregator.loadAllWords();
    final learnedCount = allWords.where((w) {
      // Check if word has been seen/learned
      return prefs.containsKey('learned_${w.id}');
    }).length;

    // Build categories from existing routes
    final categories = <DhaCategory>[
      DhaCategory(
        id: 'number',
        title: 'Numbers',
        subtitle: 'Kwäänë',
        imageAsset: 'assets/category_image/numbers_2.png',
        done: _countLearned(prefs, 'number', 10),
        total: 10,
      ),
      DhaCategory(
        id: 'alphabet',
        title: 'Alphabets',
        subtitle: 'Gööre',
        imageAsset: 'assets/category_image/alphabets.png',
        done: _countLearned(prefs, 'alphabet', 29),
        total: 29,
      ),
      DhaCategory(
        id: 'word',
        title: 'Words',
        subtitle: 'Döötti',
        imageAsset: 'assets/category_image/book.png',
        done: _countLearned(prefs, 'word', 29),
        total: 29,
      ),
      DhaCategory(
        id: 'reading',
        title: 'Reading',
        subtitle: 'Kwäänö',
        imageAsset: 'assets/category_image/reading.png',
        done: _countLearned(prefs, 'reading', 29),
        total: 29,
      ),
      DhaCategory(
        id: 'colors',
        title: 'Colors',
        subtitle: 'Kït',
        imageAsset: 'assets/category_image/colors_4.png',
        done: _countLearned(prefs, 'colors', 8),
        total: 8,
      ),
      DhaCategory(
        id: 'shape',
        title: 'Shapes',
        subtitle: 'Yi cwääc',
        imageAsset: 'assets/category_image/shapes_1.png',
        done: _countLearned(prefs, 'shape', 4),
        total: 4,
      ),
      DhaCategory(
        id: 'body',
        title: 'Body',
        subtitle: 'Jap dëël',
        imageAsset: 'assets/category_image/body_part.png',
        done: _countLearned(prefs, 'body', 18),
        total: 18,
      ),
      DhaCategory(
        id: 'clothes',
        title: 'Clothes',
        subtitle: 'Abïëë',
        imageAsset: 'assets/word_images/cloth.png',
        done: _countLearned(prefs, 'clothes', 10),
        total: 10,
      ),
      DhaCategory(
        id: 'bird',
        title: 'Birds',
        subtitle: 'Winy',
        imageAsset: 'assets/word_images/birds.png',
        done: _countLearned(prefs, 'bird', 12),
        total: 12,
      ),
      DhaCategory(
        id: 'animal',
        title: 'Animals',
        subtitle: 'Lääy',
        imageAsset: 'assets/word_images/animals.png',
        done: _countLearned(prefs, 'animal', 14),
        total: 14,
      ),
      DhaCategory(
        id: 'fish',
        title: 'Fishes',
        subtitle: 'Ric',
        imageAsset: 'assets/word_images/fish.png',
        done: _countLearned(prefs, 'fish', 10),
        total: 10,
      ),
    ];

    final totalWords = categories.fold<int>(0, (sum, cat) => sum + cat.total);
    final totalLearned = categories.fold<int>(0, (sum, cat) => sum + cat.done);

    if (mounted) {
      setState(() {
        _learnerName = name;
        _stats = PracticeStats(
          wordsLearned: totalLearned,
          wordsTotal: totalWords,
          phrasesDone: 0, // TODO: Add phrases tracking
          phrasesTotal: 0,
          dailyFiveStreak: gamState.currentStreak,
        );
        _categories = categories;
      });
    }
  }

  int _countLearned(SharedPreferences prefs, String category, int total) {
    int count = 0;
    for (int i = 0; i < total; i++) {
      if (prefs.getBool('learned_${category}_$i') ?? false) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      widget.overviewPage,
      LearnPage(
        stats: _stats,
        categories: _categories,
        onOpen: (cat) => Navigator.pushNamed(context, cat.id),
        showBack: false,
      ),
      PracticePage(
        learnerName: _learnerName,
        stats: _stats,
        onDailyFive: () => Navigator.pushNamed(context, 'daily_five'),
        onRandom: () => _showComingSoon('Random Words'),
        onMistakes: () => _showComingSoon('Mistakes Review'),
        onSaved: () => _showComingSoon('Saved Words'),
        onLongSession: () => _showComingSoon('Long Session'),
        onOpenWords: () => setState(() => _index = 1),
      ),
      widget.progressPage,
    ];

    return Scaffold(
      backgroundColor: kScaffold,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: FloatingNav(
            index: _index,
            onTap: (v) => setState(() => _index = v),
            items: const [
              NavItem(Icons.explore_outlined, 'Overview'),
              NavItem(Icons.menu_book_outlined, 'Learn'),
              NavItem(Icons.fitness_center, 'Practice'),
              NavItem(Icons.bar_chart_rounded, 'Progress'),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!')),
    );
  }
}

// ─── Floating navigation bar ───────────────────────────────────────────────
class NavItem {
  final IconData icon;
  final String label;
  const NavItem(this.icon, this.label);
}

class FloatingNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<NavItem> items;

  const FloatingNav({
    super.key,
    required this.index,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: kTile,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          children: [
            for (var n = 0; n < items.length; n++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: n == index
                          ? const Color(0xFFD9D5CD)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(items[n].icon,
                          size: 22, color: n == index ? kInk : kMuted),
                      const SizedBox(height: 3),
                      Text(
                        items[n].label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: n == index
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: n == index ? kInk : kMuted,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      );
}

// ─── Practice Page ─────────────────────────────────────────────────────────
class PracticePage extends StatelessWidget {
  final String learnerName;
  final PracticeStats stats;
  final VoidCallback onDailyFive,
      onRandom,
      onMistakes,
      onSaved,
      onLongSession,
      onOpenWords;

  const PracticePage({
    super.key,
    required this.learnerName,
    required this.stats,
    required this.onDailyFive,
    required this.onRandom,
    required this.onMistakes,
    required this.onSaved,
    required this.onLongSession,
    required this.onOpenWords,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        learnerName.isEmpty ? 'D' : learnerName.characters.first.toUpperCase();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Header
        Row(children: [
          const Expanded(
            child: Text(
              'Practice',
              style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w700, color: kInk),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration:
                const BoxDecoration(color: kCard, shape: BoxShape.circle),
            child: const Icon(Icons.notifications, size: 20, color: kInk),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 22,
            backgroundColor: kGreen,
            child: Text(
              initial,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
        const SizedBox(height: 18),

        // Stats cards
        Row(children: [
          Expanded(
            child: StatCard(
              title: 'Words',
              leading: Icons.translate,
              label: 'Learned',
              value: '${stats.wordsLearned}/${stats.wordsTotal}',
              progress: _ratio(stats.wordsLearned, stats.wordsTotal),
              onTap: onOpenWords,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              title: 'Phrases',
              leading: Icons.chat_bubble_outline,
              label: 'Done',
              value: '${stats.phrasesDone}/${stats.phrasesTotal}',
              progress: _ratio(stats.phrasesDone, stats.phrasesTotal),
              onTap: onOpenWords,
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Daily 5 hero card
        HeroCard(
          title: 'Daily 5',
          subtitle: stats.dailyFiveStreak > 0
              ? '${stats.dailyFiveStreak} day streak. Five words, five minutes.'
              : 'Five words, five minutes. Start your streak today.',
          icon: Icons.local_fire_department,
          onTap: onDailyFive,
        ),
        const SizedBox(height: 22),

        // More to explore
        const Text(
          'More to explore',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: kInk),
        ),
        const SizedBox(height: 8),
        ExploreRow(
          icon: Icons.casino_outlined,
          title: 'Random Words',
          subtitle: 'Practice mixed words',
          onTap: onRandom,
        ),
        ExploreRow(
          icon: Icons.edit_outlined,
          title: 'Mistakes',
          subtitle: 'Review words you got wrong',
          onTap: onMistakes,
        ),
        ExploreRow(
          icon: Icons.bookmark,
          title: 'Saved Words',
          subtitle: 'Revisit your saved words',
          onTap: onSaved,
        ),
        ExploreRow(
          icon: Icons.workspace_premium_outlined,
          title: 'Long Session',
          subtitle: 'Full length practice session',
          onTap: onLongSession,
        ),
      ],
    );
  }

  static double _ratio(int a, int b) => b <= 0 ? 0 : (a / b).clamp(0.0, 1.0);
}

// ─── Stat Card ─────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String title, label, value;
  final IconData leading;
  final double progress;
  final VoidCallback onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.leading,
    required this.label,
    required this.value,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(22),
            boxShadow: kSoftShadow,
          ),
          child: Column(children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F0EB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(leading, size: 32, color: kGreen),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600, color: kInk),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: kInk),
              ),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: kGreen,
                backgroundColor: kTrack,
              ),
            ),
          ]),
        ),
      );
}

// ─── Hero Card ─────────────────────────────────────────────────────────────
class HeroCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const HeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(22),
            boxShadow: kSoftShadow,
          ),
          child: Row(children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFBE9D0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 38, color: const Color(0xFFD9730D)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w600, color: kInk),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, height: 1.3, color: kMuted),
                ),
              ]),
            ),
            const Icon(Icons.chevron_right, color: kMuted),
          ]),
        ),
      );
}

// ─── Explore Row ───────────────────────────────────────────────────────────
class ExploreRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  const ExploreRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: kTrack, width: 1)),
          ),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: kTile, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, size: 22, color: kInk),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: kInk),
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 13, color: kMuted)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: kMuted),
          ]),
        ),
      );
}

// ─── Learn Page ────────────────────────────────────────────────────────────
class LearnPage extends StatelessWidget {
  final PracticeStats stats;
  final List<DhaCategory> categories;
  final void Function(DhaCategory) onOpen;
  final bool showBack;

  const LearnPage({
    super.key,
    required this.stats,
    required this.categories,
    required this.onOpen,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final words = stats.wordsTotal;
    final seen = stats.wordsLearned;
    final ratio = words <= 0 ? 0.0 : (seen / words).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Header
        Row(children: [
          showBack
              ? InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                        color: kTile, shape: BoxShape.circle),
                    child: const Icon(Icons.chevron_left, color: kInk),
                  ),
                )
              : const SizedBox(width: 46),
          const Expanded(
            child: Text(
              'Learn',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: kInk),
            ),
          ),
          ProgressRing(ratio),
        ]),
        const SizedBox(height: 18),

        // Mini stats
        Row(children: [
          MiniStat('Topics', categories.length),
          MiniStat('Words', words),
          MiniStat('Seen', seen),
          MiniStat('New', (words - seen).clamp(0, words)),
        ]),
        const SizedBox(height: 16),

        // Category cards
        for (final c in categories)
          TopicCard(category: c, onTap: () => onOpen(c)),
      ],
    );
  }
}

// ─── Mini Stat ─────────────────────────────────────────────────────────────
class MiniStat extends StatelessWidget {
  final String label;
  final int value;

  const MiniStat(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          decoration: BoxDecoration(
              color: kTile, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$value',
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w600, color: kInk),
                ),
              ),
            ),
          ]),
        ),
      );
}

// ─── Progress Ring ─────────────────────────────────────────────────────────
class ProgressRing extends StatelessWidget {
  final double value;

  const ProgressRing(this.value, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 46,
        height: 46,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 3.5,
              color: kGreen,
              backgroundColor: kTrack,
            ),
          ),
          Text(
            '${(value * 100).round()}%',
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: kInk),
          ),
        ]),
      );
}

// ─── Topic Card ────────────────────────────────────────────────────────────
class TopicCard extends StatelessWidget {
  final DhaCategory category;
  final VoidCallback onTap;

  const TopicCard({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = category;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(22),
          boxShadow: kSoftShadow,
        ),
        child: Row(children: [
          SizedBox(
            width: 72,
            height: 72,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                c.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: kTile,
                  child: const Icon(Icons.image_outlined, color: kMuted),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                c.title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600, color: kInk),
              ),
              const SizedBox(height: 2),
              Text(c.subtitle,
                  style: const TextStyle(fontSize: 13, color: kMuted)),
              const SizedBox(height: 8),
              Row(children: [
                Icon(
                  c.completed ? Icons.check_circle : Icons.help,
                  size: 16,
                  color: c.completed ? kGreen : kMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  c.completed ? 'Completed' : '${c.done}/${c.total} Words',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        c.completed ? FontWeight.w600 : FontWeight.w400,
                    color: c.completed ? kGreen : kMuted,
                  ),
                ),
              ]),
            ]),
          ),
          const Icon(Icons.chevron_right, color: kMuted),
        ]),
      ),
    );
  }
}
