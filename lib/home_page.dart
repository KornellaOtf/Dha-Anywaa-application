// ignore_for_file: prefer_const_constructors
import 'package:dha_anywaaa/about.dart';
import 'package:dha_anywaaa/components/savedData.dart';
import 'package:dha_anywaaa/help.dart';
import 'package:dha_anywaaa/services/ota_service.dart';
import 'package:dha_anywaaa/settings_page.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:dha_anywaaa/vowelLetter.dart';
import 'package:dha_anywaaa/widgets/body.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final Uri _webUrl = Uri.parse('https://dha-anywaa-app.netlify.app/');

// Items per category — used to calculate progress %.
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
  Color(0xFFC9993A), // gold
  Color(0xFF7A2D1E), // rust
  Color(0xFF1B4332), // green
  Color(0xFF4A7C59), // mid-green
  Color(0xFFC9993A),
  Color(0xFF7A2D1E),
  Color(0xFF1B4332),
  Color(0xFF4A7C59),
  Color(0xFFC9993A),
  Color(0xFF7A2D1E),
  Color(0xFF1B4332),
  Color(0xFF4A7C59),
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
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    final result = await OtaService().checkForUpdate();
    if (result == null || !mounted) return;
    _showUpdateDialog(result);
  }

  void _showUpdateDialog(OtaCheckResult result) {
    showDialog(
      context: context,
      barrierDismissible: !result.mandatory,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(children: [
          const Icon(Icons.system_update_rounded, color: kGreen),
          const SizedBox(width: 8),
          const Text('Update available',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version ${result.latestVersion} is ready.',
                style: const TextStyle(fontSize: 14, color: kTextSub)),
            const SizedBox(height: 8),
            if (result.releaseNotes.isNotEmpty)
              Text(result.releaseNotes,
                  style: const TextStyle(
                      fontSize: 13, color: kTextMuted, height: 1.5)),
            if (result.sizeBytes > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Size: ${(result.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB',
                style: const TextStyle(fontSize: 12, color: kTextMuted),
              ),
            ],
          ],
        ),
        actions: [
          if (!result.mandatory)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later', style: TextStyle(color: kTextMuted)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kGold,
              foregroundColor: kText,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              launchUrl(Uri.parse(result.apkUrl),
                  mode: LaunchMode.externalApplication);
            },
            child: const Text('Download update',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
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
      backgroundColor: kBg,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            elevation: 3,
            shape: const CircleBorder(),
            color: Colors.white,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.menu_rounded, color: kText, size: 20),
              ),
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      bottomNavigationBar: _buildBottomNav(),
      body: RefreshIndicator(
        color: kGreen,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ── Greeting ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [kBg, Color(0xFFEDE5D0)],
                  ),
                ),
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
                child: Row(
                  children: [
                    const Text('Explore',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${categories.length} topics',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kGreen),
                      ),
                    ),
                  ],
                ),
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
      const Text('Welcome back',
          style: TextStyle(fontSize: 13, color: kTextSub)),
      const SizedBox(height: 2),
      Text(
        _name.isEmpty ? 'Learner' : _name,
        style: const TextStyle(
            fontSize: 32, fontWeight: FontWeight.bold, color: kText),
      ),
    ]);
  }

  Widget _buildContinueCard(BuildContext context) {
    final progress = _lastRouteTotal > 0
        ? _lastRouteProgress / _lastRouteTotal
        : 0.0;
    return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kGreen, kGreenMid],
          ),
          boxShadow: [
            BoxShadow(
              color: kGreen.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () async {
              await _savedData.setLastRoute(_lastRoute);
              if (!mounted) return;
              Navigator.pushNamed(context, _lastRoute).then((_) => _load());
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CONTINUE',
                        style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.5,
                            color: kGold,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(_lastRouteName,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                        '$_lastRouteProgress / $_lastRouteTotal learned',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xAAFFFFFF))),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        color: kGold,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: kGold.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGold,
                              foregroundColor: kText,
                              elevation: 0,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 11),
                            ),
                            onPressed: () async {
                              await _savedData.setLastRoute(_lastRoute);
                              if (!mounted) return;
                              Navigator.pushNamed(context, _lastRoute)
                                  .then((_) => _load());
                            },
                            child: const Text('Resume',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_right_rounded,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ]),
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
        Navigator.pushNamed(context, route).then((_) => _load());
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border(top: BorderSide(color: accentColor, width: 3)),
          boxShadow: const [kShadowSoft],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 28,
                height: 4,
                decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const Spacer(),
              if (hasProgress)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$learned/$total',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: accentColor)),
                ),
            ]),
            const SizedBox(height: 10),
            Text(cat['engName']!,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: kText)),
            const SizedBox(height: 2),
            Text(cat['anyName']!,
                style: const TextStyle(fontSize: 12, color: kTextSub)),
            if (total > 0) ...[
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: total > 0 ? learned / total : 0,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFE8E8E8),
                  color: accentColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kBorder)),
        boxShadow: [
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
          backgroundColor: Colors.white,
          selectedItemColor: kGreen,
          unselectedItemColor: kTextSub,
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
      backgroundColor: Colors.white,
      child: Column(children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          height: 170,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/word_images/side_bar_bg.png'),
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
                child: Column(
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
              ),
            ),
          ),
        ),
        // ── Items ───────────────────────────────────────────────────────────
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            const SizedBox(height: 8),
            _drawerTile(context, Icons.abc_rounded, 'Göörë moo cïp dwøl',
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const VowelLetter()))),
            _drawerTile(context, Icons.face_retouching_natural_rounded,
                'Jap dëël',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const Body()))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(),
            ),
            _drawerTile(context, Icons.settings_outlined, 'Settings',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()))),
            _drawerTile(context, Icons.info_outline_rounded, 'About',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const About()))),
            _drawerTile(context, Icons.help_outline_rounded, 'Help',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const Help()))),
            _drawerTile(context, Icons.language_rounded, 'Website',
                () async {
              try {
                await launchUrl(_webUrl,
                    mode: LaunchMode.externalApplication);
              } catch (_) {}
            }),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(),
            ),
            _drawerTile(context, Icons.logout_rounded, 'Log out', () async {
              await _savedData.setName('guess');
              if (!mounted) return;
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
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 19),
      ),
      title: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: color == kRust ? color : kText)),
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
