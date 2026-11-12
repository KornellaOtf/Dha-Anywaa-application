import 'package:dha_anywaaa/about.dart';
import 'package:dha_anywaaa/anywaa_ai_page.dart';
import 'package:dha_anywaaa/components/savedData.dart';
import 'package:dha_anywaaa/dictionary_coming_soon_page.dart';
import 'package:dha_anywaaa/help.dart';
import 'package:dha_anywaaa/privacy_policy_page.dart';
import 'package:dha_anywaaa/services/analytics_service.dart';
import 'package:dha_anywaaa/services/gamification_service.dart';
import 'package:dha_anywaaa/services/ota_service.dart';
import 'package:dha_anywaaa/services/notification_service.dart';
import 'package:dha_anywaaa/services/retention_engine.dart';
import 'package:dha_anywaaa/settings_page.dart';
import 'package:dha_anywaaa/terms_page.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:dha_anywaaa/vowelLetter.dart';
import 'package:dha_anywaaa/widgets/body.dart';
import 'package:dha_anywaaa/widgets/brand_leaf.dart';
import 'package:dha_anywaaa/widgets/celebration_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Items per category: used to calculate progress %.
const Map<String, int> _categoryTotals = {
  'alphabet': 29,
  'number': 10,
  'word': 29,
  'reading': 29,
  'colors': 8,
  'shape': 4,
  'body': 18,
  'clothes': 10,
  'bird': 12,
  'animal': 14,
  'fish': 10,
  'quiz': 31,
};

const List<Color> _accentColors = [
  kGold, // gold
  kRust, // rust
  kGreen, // green
  kGreenMid, // mid-green
  kGold,
  kRust,
  kGreen,
  kGreenMid,
  kGold,
  kRust,
  kGreen,
  kGreenMid,
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SavedData _savedData = SavedData();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _name = '';
  String _lastRoute = 'alphabet';
  int _lastRouteProgress = 0;
  int _lastRouteTotal = 29;
  Map<String, int> _learnedCounts = {};
  int _bottomNavIndex = 0;
  GamState? _gamState;

  final List<Map<String, String>> categories = [
    {'engName': 'Numbers',   'anyName': 'Kwäänë',   'imageLink': 'assets/category_image/numbers_2.png', 'route': 'number'},
    {'engName': 'Alphabets', 'anyName': 'Göörë',    'imageLink': 'assets/category_image/alphabets.png', 'route': 'alphabet'},
    {'engName': 'Words',     'anyName': 'Dööttï',   'imageLink': 'assets/category_image/book.png',      'route': 'word'},
    {'engName': 'Reading',   'anyName': 'Kwäänö',   'imageLink': 'assets/category_image/reading.png',   'route': 'reading'},
    {'engName': 'Colors',    'anyName': 'Kït',      'imageLink': 'assets/category_image/colors_4.png',  'route': 'colors'},
    {'engName': 'Shapes',    'anyName': 'Yi cwääc', 'imageLink': 'assets/category_image/shapes_1.png',  'route': 'shape'},
    {'engName': 'Body',      'anyName': 'Jap dëël', 'imageLink': 'assets/category_image/body_part.png', 'route': 'body'},
    {'engName': 'Clothes',   'anyName': 'Abïëë',   'imageLink': 'assets/word_images/cloth.png',        'route': 'clothes'},
    {'engName': 'Birds',     'anyName': 'Winy',     'imageLink': 'assets/word_images/birds.png',        'route': 'bird'},
    {'engName': 'Animals',   'anyName': 'Lääy',     'imageLink': 'assets/word_images/animals.png',      'route': 'animal'},
    {'engName': 'Fishes',    'anyName': 'Ric',      'imageLink': 'assets/word_images/fish.png',         'route': 'fish'},
    {'engName': 'Quiz',      'anyName': 'Päärö',    'imageLink': 'assets/category_image/quiz.png',      'route': 'quiz'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
    // Track app open for retention engine
    RetentionEngine.instance.onAppOpen();
    // Check for comeback bonus
    _checkComebackBonus();
    // Initialize notification service
    _initNotifications();
    // Run update check after the first frame so it never blocks the UI.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkComebackBonus() async {
    try {
      final eligible = await RetentionEngine.instance.isComebackEligible();
      if (eligible) {
        final bonusXp = await RetentionEngine.instance.claimComebackBonus();
        if (bonusXp > 0 && mounted) {
          // Show celebration
          CelebrationHelper.show(
            context,
            type: CelebrationType.confetti,
            message: 'Welcome back! +$bonusXp XP bonus!',
          );
          // Award the XP
          await GamificationService.instance.onLessonComplete();
          // Reload stats
          _load();
        }
      }
    } catch (e) {
      debugPrint('Comeback bonus check failed: $e');
    }
  }

  Future<void> _initNotifications() async {
    try {
      // Request permission first (required on Android 13+)
      await NotificationService().requestPermission();
      // Then initialize with settings
      await NotificationService().initialize();
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  Future<void> _checkForUpdate() async {
    // Skip if offline.
    try {
      // Use silent mode to show notification instead of dialog
      await OtaService().checkForUpdate(silent: true);
    } catch (_) {
      // Network unavailable or timeout: fail silently.
    }
  }

  Future<void> _load() async {
    final name      = await _savedData.getName();
    final lastRoute = await _savedData.getLastRoute();
    final total     = _categoryTotals[lastRoute] ?? 29;
    final progress  = await _savedData.learnedCount(lastRoute, total);

    final counts = <String, int>{};
    for (final cat in _categoryTotals.entries) {
      counts[cat.key] = await _savedData.learnedCount(cat.key, cat.value);
    }

    final gam = await GamificationService.instance.load();

    if (!mounted) return;
    setState(() {
      _name = name == 'guess' ? '' : name;
      _lastRoute = lastRoute;
      _lastRouteProgress = progress;
      _lastRouteTotal = total;
      _learnedCounts = counts;
      _gamState = gam;
    });
  }

  String get _lastRouteName {
    final match = categories.firstWhere(
      (c) => c['route'] == _lastRoute,
      orElse: () => {'engName': 'Alphabet'},
    );
    return match['engName'] ?? 'Alphabet';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.c.bg,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            elevation: 3,
            shape: const CircleBorder(),
            color: context.c.card,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.menu_rounded, color: context.c.text, size: 20),
              ),
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      bottomNavigationBar: _buildBottomNav(),
      body: RefreshIndicator(
        color: context.c.accent,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ── Greeting ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: _buildGreeting(),
              ),
            ),
            // ── Daily 5 card (NEW!) ─────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              sliver: SliverToBoxAdapter(child: _buildDailyFiveCard(context)),
            ),
            // ── Continue card ───────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              sliver: SliverToBoxAdapter(child: _buildContinueCard(context)),
            ),
            // ── Quiz highlight card ──────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              sliver: SliverToBoxAdapter(child: _buildQuizCard(context)),
            ),
            // ── Explore header ──────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
              sliver: SliverToBoxAdapter(
                child: Text('Explore',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: context.c.text)),
              ),
            ),
            // ── Category grid ───────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildCategoryCard(context, i),
                  childCount: categories.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final gam = _gamState;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back',
                      style: TextStyle(fontSize: 13, color: context.c.textSub)),
                  const SizedBox(height: 2),
                  Text(
                    _name.isEmpty ? 'Learner' : _name,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: context.c.text),
                  ),
                ],
              ),
            ),
            // ── Daily goal ring ─────────────────────────────────────────────
            if (gam != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: CircularProgressIndicator(
                          value: gam.dailyGoalPct,
                          strokeWidth: 5,
                          backgroundColor: context.c.border,
                          valueColor: AlwaysStoppedAnimation(
                              gam.dailyGoalMet ? kGreen : kGold),
                        ),
                      ),
                      Icon(
                        gam.dailyGoalMet
                            ? Icons.check_rounded
                            : Icons.bolt_rounded,
                        size: 20,
                        color: gam.dailyGoalMet ? kGreen : kGold,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (gam != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              // ── Streak chip ───────────────────────────────────────────────
              _StatChip(
                icon: Icons.local_fire_department_rounded,
                color: kRust,
                label: '${gam.streakDays} day streak',
              ),
              const SizedBox(width: 10),
              // ── XP chip ───────────────────────────────────────────────────
              _StatChip(
                icon: Icons.star_rounded,
                color: kGold,
                label: '${gam.xp} XP · Lv ${gam.level}',
              ),
            ],
          ),
          // ── Level progress bar ───────────────────────────────────────────
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: gam.levelPct,
              minHeight: 4,
              backgroundColor: context.c.border,
              valueColor: AlwaysStoppedAnimation(context.c.accent),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDailyFiveCard(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkDailyFiveStatus(),
      builder: (context, snapshot) {
        final completed = snapshot.data ?? false;
        
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: completed 
                ? [kGreen.withOpacity(0.6), kGreenMid.withOpacity(0.6)]
                : [kGreen, kGreenMid],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [kShadowSoft],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: completed 
                ? null 
                : () => _startDailyFive(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        completed ? Icons.check_circle : Icons.school,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            completed ? 'Daily 5 Complete!' : 'Daily 5',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            completed
                                ? 'Come back tomorrow'
                                : '5 quick questions to keep your streak',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!completed)
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _checkDailyFiveStatus() async {
    // Check if today's Daily 5 was completed
    // For now, this will integrate with LearningEngine once you connect your word data
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final lastCompleted = prefs.getString('daily_five_completed') ?? '';
      return lastCompleted == today;
    } catch (e) {
      return false;
    }
  }

  void _startDailyFive(BuildContext context) {
    // For now, show a coming soon message
    // Once you connect your word data, this will navigate to DailyFivePage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Daily 5 feature coming in next update! Connect your word data to enable.'),
        backgroundColor: kGreen,
        duration: const Duration(seconds: 3),
      ),
    );
    
    // TODO: Replace above with this once word data is connected:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => DailyFivePage(allWords: yourWordDataHere),
    //   ),
    // ).then((_) => _load());
  }

  Widget _buildContinueCard(BuildContext context) {
    final progress = _lastRouteTotal > 0
        ? _lastRouteProgress / _lastRouteTotal
        : 0.0;
    return DecoratedBox(
      decoration: cardDeco(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await _savedData.setLastRoute(_lastRoute);
            if (!mounted) return;
            // ignore: use_build_context_synchronously
            Navigator.pushNamed(context, _lastRoute).then((_) => _load());
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Continue',
                          style: TextStyle(fontSize: 12, color: context.c.textSub)),
                      const SizedBox(height: 2),
                      Text(_lastRouteName,
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: context.c.text)),
                      if (_lastRouteProgress > 0) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: context.c.border,
                            color: context.c.accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                            '$_lastRouteProgress / $_lastRouteTotal learned',
                            style: TextStyle(
                                fontSize: 11, color: context.c.textSub)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.chevron_right_rounded, color: context.c.textSub),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, 'quiz');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kGreen, kGreenMid],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [kShadowSoft],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.quiz_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Test your skills!',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Take the quiz and see how much you\'ve learned',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Start',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kGreen)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, int i) {
    final cat         = categories[i];
    final route       = cat['route']!;
    final accentColor = _accentColors[i % _accentColors.length];
    final total       = _categoryTotals[route] ?? 0;
    final learned     = _learnedCounts[route] ?? 0;
    final hasProgress = total > 0 && learned > 0;

    return _PressableCard(
      onTap: () async {
        await _savedData.setLastRoute(route);
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        Navigator.pushNamed(context, route).then((_) => _load());
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.c.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [kShadowSoft],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area ─────────────────────────────────────────────────
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18)),
                child: Container(
                  width: double.infinity,
                  color: context.c.card,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      cat['imageLink']!,
                      fit: BoxFit.contain,
                      cacheWidth: 200,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image_not_supported_outlined,
                        color: accentColor.withValues(alpha: 0.4),
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // ── Label area ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat['engName']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.c.text)),
                  const SizedBox(height: 1),
                  Text(cat['anyName']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: context.c.textSub)),
                  if (hasProgress) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: learned / total,
                        minHeight: 3,
                        backgroundColor: context.c.border,
                        color: accentColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: context.c.card,
        border: Border(top: BorderSide(color: context.c.border)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _bottomNavIndex,
          backgroundColor: context.c.card,
          selectedItemColor: context.c.accent,
          unselectedItemColor: context.c.textSub,
          selectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (i) {
            setState(() => _bottomNavIndex = i);
            if (i == 1) {
              Navigator.pushNamed(context, 'quiz').then((_) {
                setState(() => _bottomNavIndex = 0);
                _load();
              });
            } else if (i == 2) {
              Navigator.pushNamed(context, 'reading').then((_) {
                setState(() => _bottomNavIndex = 0);
              });
            } else if (i == 3) {
              _scaffoldKey.currentState?.openDrawer();
              setState(() => _bottomNavIndex = 0);
            }
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined), label: 'Learn'),
            BottomNavigationBarItem(
                icon: Icon(Icons.check_circle_outline), label: 'Quiz'),
            BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_outlined), label: 'Read'),
            BottomNavigationBarItem(
                icon: Icon(Icons.more_horiz), label: 'More'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: context.c.card,
      child: Column(children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          height: 170,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/word_images/side_bar_bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x66000000)],
              ),
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const BrandLeaf(size: 52),
                    const SizedBox(width: 14),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dha Anywaa',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                      color: Color(0x40000000),
                                      blurRadius: 8)
                                ])),
                        if (_name.isNotEmpty)
                          Text(_name,
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xDDFFFFFF))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // ── Items ───────────────────────────────────────────────────────────
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            const SizedBox(height: 8),
            _drawerTile(context, Icons.abc_rounded, 'Göörë moo cïp dwøl',
                () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const VowelLetter(),
                      settings: const RouteSettings(name: 'vowel_letters')));
            }),
            _drawerTile(context, Icons.face_retouching_natural_rounded,
                'Jap dëël', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const Body(),
                      settings: const RouteSettings(name: 'body_parts')));
            }),
            _drawerTile(context, Icons.eco_rounded, 'Anywaa AI', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AnywaaAiPage(),
                      settings: const RouteSettings(name: 'anywaa_ai')));
            }, color: kGreen),
            _drawerTile(context, Icons.menu_book_rounded, 'Dictionary', () {
              Navigator.pop(context);
              // Dictionary coming soon page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DictionaryComingSoonPage(),
                  settings: const RouteSettings(name: 'dictionary_coming_soon'),
                ),
              );
            }),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(),
            ),
            _drawerTile(context, Icons.settings_outlined, 'Settings',
                () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsPage(),
                      settings: const RouteSettings(name: 'settings')));
            }),
            _drawerTile(context, Icons.privacy_tip_outlined, 'Privacy Policy',
                () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyPage(),
                      settings: const RouteSettings(name: 'privacy_policy')));
            }),
            _drawerTile(context, Icons.gavel_outlined, 'Terms of Use',
                () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TermsPage(),
                      settings: const RouteSettings(name: 'terms_of_use')));
            }),
            _drawerTile(context, Icons.info_outline_rounded, 'About',
                () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const About(),
                      settings: const RouteSettings(name: 'about')));
            }),
            _drawerTile(context, Icons.help_outline_rounded, 'Help',
                () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const Help(),
                      settings: const RouteSettings(name: 'help')));
            }),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(),
            ),
            _drawerTile(context, Icons.logout_rounded, 'Log out', () async {
              Navigator.pop(context);
              await _savedData.setName('guess');
              // Clear analytics user ID
              await AnalyticsService.instance.clearUser();
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.pushReplacementNamed(context, '/');
            }, color: kRust),
            const SizedBox(height: 16),
          ]),
        ),
      ]),
    );
  }

  Widget _drawerTile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color color = kGreen,
    Widget? leading,
    Widget? trailing,
  }) {
    final iconColor = color == kGreen ? context.c.accent : color;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: leading ??
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
      title: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: color == kRust ? color : context.c.text)),
      trailing: trailing,
      onTap: onTap,
    );
  }

}

// ── Animated press-scale wrapper ─────────────────────────────────────────────
class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableCard({required this.child, required this.onTap});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ── Small stat chip (streak, XP) ─────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _StatChip({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}
