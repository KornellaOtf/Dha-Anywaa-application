// ignore_for_file: prefer_const_constructors
import 'package:dha_anywaaa/about.dart';
import 'package:dha_anywaaa/components/savedData.dart';
import 'package:dha_anywaaa/help.dart';
import 'package:dha_anywaaa/services/ota_service.dart';
import 'package:dha_anywaaa/settings_page.dart';
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
  Color(0xFFC9993A),
  Color(0xFF7A2D1E),
  Color(0xFF1B4332),
  Color(0xFFC9993A),
  Color(0xFF7A2D1E),
  Color(0xFF1B4332),
  Color(0xFFC9993A),
  Color(0xFF7A2D1E),
  Color(0xFF1B4332),
  Color(0xFFC9993A),
  Color(0xFF7A2D1E),
  Color(0xFF1B4332),
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
  int _lastRouteProgress = 0; // learned count
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
    const green = Color(0xFF1B4332);
    const gold  = Color(0xFFC9993A);
    showDialog(
      context: context,
      barrierDismissible: !result.mandatory,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.system_update_rounded, color: green),
          const SizedBox(width: 8),
          const Text('Update available',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version ${result.latestVersion} is ready.',
                style: const TextStyle(fontSize: 14, color: Color(0xFF444444))),
            const SizedBox(height: 8),
            if (result.releaseNotes.isNotEmpty)
              Text(result.releaseNotes,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF666666), height: 1.5)),
            if (result.sizeBytes > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Size: ${(result.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB',
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
              ),
            ],
          ],
        ),
        actions: [
          if (!result.mandatory)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later',
                  style: TextStyle(color: Color(0xFF888888))),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: const Color(0xFF1C1C1C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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


    super.didChangeDependencies();
    // Refresh when returning from a sub-screen
    _load();
  }

  Future<void> _load() async {
    final name      = await _savedData.getName();
    final lastRoute = await _savedData.getLastRoute();
    final total     = _categoryTotals[lastRoute] ?? 29;
    final progress  = await _savedData.learnedCount(lastRoute, total);

    // Load learned counts for all categories
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
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF1C1C1C), size: 20),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      bottomNavigationBar: _buildBottomNav(),
      body: RefreshIndicator(
        color: const Color(0xFF1B4332),
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(child: _buildGreeting()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(child: _buildContinueCard(context)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
              sliver: SliverToBoxAdapter(
                child: const Text('Explore',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildCategoryCard(context, i),
                  childCount: categories.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.25,
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
          style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
      const SizedBox(height: 2),
      Text(_name.isEmpty ? 'Learner' : _name,
          style: const TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1C))),
    ]);
  }

  Widget _buildContinueCard(BuildContext context) {
    final progress = _lastRouteTotal > 0
        ? _lastRouteProgress / _lastRouteTotal
        : 0.0;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B4332),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('CONTINUE',
            style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: Color(0xFFC9993A))),
        const SizedBox(height: 4),
        Text(_lastRouteName,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text('$_lastRouteProgress / $_lastRouteTotal learned',
            style: const TextStyle(fontSize: 12, color: Color(0xAAFFFFFF))),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.2),
            color: const Color(0xFFC9993A),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () async {
            await _savedData.setLastRoute(_lastRoute);
            if (!mounted) return;
            Navigator.pushNamed(context, _lastRoute).then((_) => _load());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC9993A),
            foregroundColor: const Color(0xFF1C1C1C),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Resume', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _buildCategoryCard(BuildContext context, int i) {
    final cat         = categories[i];
    final route       = cat['route']!;
    final accentColor = _accentColors[i % _accentColors.length];
    final total       = _categoryTotals[route] ?? 0;
    final learned     = _learnedCounts[route] ?? 0;
    final hasProgress = total > 0 && learned > 0;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        await _savedData.setLastRoute(route);
        if (!mounted) return;
        Navigator.pushNamed(context, route).then((_) => _load());
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(top: BorderSide(color: accentColor, width: 3)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 28, height: 4,
                decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const Spacer(),
              if (hasProgress)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
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
                    fontSize: 15, fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1C))),
            const SizedBox(height: 2),
            Text(cat['anyName']!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
            if (total > 0) ...[
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: total > 0 ? learned / total : 0,
                  minHeight: 3,
                  backgroundColor: const Color(0xFFE0E0E0),
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
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1B4332),
        unselectedItemColor: const Color(0xFF666666),
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        onTap: (i) {
          setState(() => _bottomNavIndex = i);
          if (i == 0) {
            // already home — scroll to top handled by RefreshIndicator
          } else if (i == 1) {
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
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Learn'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Quiz'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), label: 'Read'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(children: [
        // Header
        DrawerHeader(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/word_images/side_bar_bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dha Anywaa',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold,
                        color: Colors.white)),
                if (_name.isNotEmpty)
                  Text(_name,
                      style: const TextStyle(fontSize: 14, color: Color(0xCCFFFFFF))),
              ],
            ),
          ),
        ),
        // Items
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            _drawerTile(context, Icons.abc_rounded, 'Göörë moo cïp dwøl',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VowelLetter()))),
            _drawerTile(context, Icons.boy_outlined, 'Jap dëël',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Body()))),
            const Divider(indent: 16, endIndent: 16),
            _drawerTile(context, Icons.settings_outlined, 'Settings',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
            _drawerTile(context, Icons.info_outline_rounded, 'About',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const About()))),
            _drawerTile(context, Icons.help_outline_rounded, 'Help',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Help()))),
            _drawerTile(context, Icons.open_in_browser_outlined, 'More',
                () async {
              try {
                await launchUrl(_webUrl, mode: LaunchMode.externalApplication);
              } catch (_) {}
            }),
            const Divider(indent: 16, endIndent: 16),
            _drawerTile(context, Icons.logout_rounded, 'Log out', () async {
              await _savedData.setName('guess');
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/');
            }, color: const Color(0xFF8B3A2A)),
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
    Color color = const Color(0xFF1B4332),
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color == const Color(0xFF8B3A2A)
                  ? color
                  : const Color(0xFF1C1C1C))),
      onTap: onTap,
    );
  }
}
