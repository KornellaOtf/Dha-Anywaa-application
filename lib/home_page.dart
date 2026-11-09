import 'package:dha_anywaaa/about.dart';
import 'package:dha_anywaaa/anywaa_ai_page.dart';
import 'package:dha_anywaaa/ota_update_page.dart';
import 'package:dha_anywaaa/components/savedData.dart';
import 'package:dha_anywaaa/help.dart';
import 'package:dha_anywaaa/privacy_policy_page.dart';
import 'package:dha_anywaaa/services/ota_service.dart';
import 'package:dha_anywaaa/services/notification_service.dart';
import 'package:dha_anywaaa/settings_page.dart';
import 'package:dha_anywaaa/terms_page.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:dha_anywaaa/vowelLetter.dart';
import 'package:dha_anywaaa/widgets/body.dart';
import 'package:dha_anywaaa/widgets/brand_leaf.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    // Initialize notification service
    _initNotifications();
    // Run update check after the first frame so it never blocks the UI.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
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

    if (!mounted) return;
    setState(() {
      _name = name == 'guess' ? '' : name;
      _lastRoute = lastRoute;
      _lastRouteProgress = progress;
      _lastRouteTotal = total;
      _learnedCounts = counts;
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
            // ── Continue card ───────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              sliver: SliverToBoxAdapter(child: _buildContinueCard(context)),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Welcome back',
          style: TextStyle(fontSize: 13, color: context.c.textSub)),
      const SizedBox(height: 2),
      Text(
        _name.isEmpty ? 'Learner' : _name,
        style: GoogleFonts.playfairDisplay(
            fontSize: 32, fontWeight: FontWeight.w700, color: context.c.text),
      ),
    ]);
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
                  MaterialPageRoute(builder: (_) => const VowelLetter()));
            }),
            _drawerTile(context, Icons.face_retouching_natural_rounded,
                'Jap dëël', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const Body()));
            }),
            _drawerTile(context, Icons.eco_rounded, 'Anywaa AI', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AnywaaAiPage()));
            }, color: kGreen),
            _drawerTile(context, Icons.menu_book_rounded, 'Dictionary', () {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              messenger.showSnackBar(const SnackBar(
                content: Text('Dictionary is coming soon!!!'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ));
            }, trailing: _soonPill(context)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(),
            ),
            _drawerTile(context, Icons.settings_outlined, 'Settings',
                () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()));
            }),
            _drawerTile(context, Icons.privacy_tip_outlined, 'Privacy Policy',
                () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()));
            }),
            _drawerTile(context, Icons.gavel_outlined, 'Terms of Use',
                () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TermsPage()));
            }),
            _drawerTile(context, Icons.info_outline_rounded, 'About',
                () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const About()));
            }),
            _drawerTile(context, Icons.help_outline_rounded, 'Help',
                () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const Help()));
            }),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(),
            ),
            _drawerTile(context, Icons.logout_rounded, 'Log out', () async {
              Navigator.pop(context);
              await _savedData.setName('guess');
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

  // Small gold pill used to mark drawer entries that aren't built yet.
  Widget _soonPill(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: kGold.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Coming Soon',
            style: TextStyle(
                color: kGold, fontSize: 11, fontWeight: FontWeight.bold)),
      );
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
