import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/analytics_service.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _kDark    = Color(0xFF0F1923);
const _kLight   = Color(0xFFF5EDD8);
const _kSurface = Color(0xFF1A2535);
const _kGold    = Color(0xFFC9993A);
const _kGoldSoft= Color(0xFFE8C87A);
const _kGreen   = Color(0xFF1F4D3A);
const _kInkDay  = Color(0xFF1A1A2E);
const _kSubDay  = Color(0xFF5A5F70);

// ─── Model ────────────────────────────────────────────────────────────────────
class BibleVerse {
  final String book;
  final int    chapter;
  final int    verse;
  final String anywaa;
  final String english;

  const BibleVerse({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.anywaa,
    required this.english,
  });

  factory BibleVerse.fromJson(Map<String, dynamic> j) => BibleVerse(
        book:    j['book']    as String,
        chapter: j['chapter'] as int,
        verse:   j['verse']   as int,
        anywaa:  j['anywaa']  as String,
        english: j['english'] as String,
      );
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class BiblePage extends StatefulWidget {
  const BiblePage({super.key});
  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage>
    with SingleTickerProviderStateMixin {

  List<BibleVerse>       _all           = [];
  final Map<String, int> _chapterCounts = {};
  List<String>           _otBooks       = [];
  List<String>           _ntBooks       = [];
  bool                   _loading       = true;

  String? _book;
  int?    _chapter;
  String? _lastBook;
  int?    _lastChapter;

  double _fontSize = 18;
  bool   _showEng  = false;
  bool   _night    = true;


  bool             _searchOpen = false;
  String           _query      = '';
  List<BibleVerse> _results    = [];
  final _searchCtrl            = TextEditingController();

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  // ─── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _loadData();
    _loadPrefs();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── data ───────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    try {
      final raw  = await rootBundle.loadString('assets/bible.json');
      final list = json.decode(raw) as List<dynamic>;
      final verses = list
          .map((v) => BibleVerse.fromJson(v as Map<String, dynamic>))
          .toList();
      _buildMeta(verses);
      if (mounted) {
        setState(() { _all = verses; _loading = false; });
        _fadeCtrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _buildMeta(List<BibleVerse> verses) {
    final seen = <String>{};
    for (final v in verses) {
      seen.add(v.book);
      final cur = _chapterCounts[v.book] ?? 0;
      if (v.chapter > cur) _chapterCounts[v.book] = v.chapter;
    }
    final books = seen.toList();
    _otBooks = books.take(39).toList();
    _ntBooks = books.skip(39).toList();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lastBook    = p.getString('bible_last_book');
      _lastChapter = p.getInt('bible_last_chapter');
      _fontSize    = p.getDouble('bible_font_size') ?? 18;
      _showEng     = p.getBool('bible_show_eng') ?? false;
      _night       = p.getBool('bible_night') ?? true;
    });
  }

  Future<void> _savePref(String key, dynamic val) async {
    final p = await SharedPreferences.getInstance();
    if (val is double) await p.setDouble(key, val);
    if (val is bool)   await p.setBool(key, val);
  }

  Future<void> _savePosition(String book, int chapter) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('bible_last_book', book);
    await p.setInt('bible_last_chapter', chapter);
    if (mounted) setState(() { _lastBook = book; _lastChapter = chapter; });
    AnalyticsService.instance.logBibleChapterOpened(book, chapter);
  }

  List<BibleVerse> _verses(String book, int chapter) =>
      _all.where((v) => v.book == book && v.chapter == chapter).toList();

  int get _maxChapter => _chapterCounts[_book ?? ''] ?? 1;

  String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // ─── audio — disabled, coming soon ────────────────────────────────────────

  void _search(String q) {
    q = q.trim().toLowerCase();
    if (q.isEmpty) { setState(() => _results = []); return; }
    setState(() {
      _results = _all
          .where((v) =>
              v.anywaa.toLowerCase().contains(q) ||
              v.english.toLowerCase().contains(q))
          .take(100)
          .toList();
    });
    AnalyticsService.instance.logBibleSearch(q, _results.length);
  }

  // ─── routing ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_searchOpen) return _searchView();
    if (_book != null && _chapter != null) return _readingView();
    if (_book != null) return _chapterGrid();
    return _library();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LIBRARY — hero + 3-col grid, no splash screen
  // ════════════════════════════════════════════════════════════════════════════

  Widget _library() {
    final bg = _night ? _kDark : _kLight;
    final fg = _night ? Colors.white : _kInkDay;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bg,
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: _night ? _kSurface : Colors.white,
              foregroundColor: fg,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: _libraryHero(),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.search, color: fg),
                  onPressed: () => setState(() => _searchOpen = true),
                ),
                IconButton(
                  icon: Icon(
                    _night
                        ? Icons.wb_sunny_outlined
                        : Icons.nights_stay_outlined,
                    color: fg,
                  ),
                  onPressed: () {
                    setState(() => _night = !_night);
                    _savePref('bible_night', _night);
                  },
                ),
              ],
              bottom: TabBar(
                labelColor: _kGold,
                unselectedLabelColor: fg.withValues(alpha: 0.45),
                indicatorColor: _kGold,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                tabs: [
                  Tab(text: 'Old Testament (${_otBooks.length})'),
                  Tab(text: 'New Testament (${_ntBooks.length})'),
                ],
              ),
            ),
          ],
          body: Column(
            children: [
              if (_lastBook != null && _lastChapter != null)
                _ContinueBanner(
                  book:    _lastBook!,
                  chapter: _lastChapter!,
                  night:   _night,
                  onTap: () => setState(() {
                    _book    = _lastBook;
                    _chapter = _lastChapter;
                  }),
                ),
              Expanded(
                child: _loading
                    ? _skeletonGrid()
                    : FadeTransition(
                        opacity: _fadeAnim,
                        child: TabBarView(children: [
                          _bookGrid(_otBooks),
                          _bookGrid(_ntBooks),
                        ]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _libraryHero() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _night
              ? [const Color(0xFF0D1B2A), const Color(0xFF1A2535)]
              : [_kGreen, const Color(0xFF2D6A4F)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 52),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // badge — no border, just soft bg
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Dha Anywaa · English',
                  style: TextStyle(
                      color: _kGoldSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Wëël Jwøk',
                style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _loading
                    ? 'Loading…'
                    : '${_fmt(_all.length)} verses · 66 books',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3-col book grid cards — no borders
  Widget _bookGrid(List<String> books) {
    final card = _night ? const Color(0xFF1E2A3A) : Colors.white;
    final fg   = _night ? Colors.white : _kInkDay;
    final sub  = _night ? Colors.white38 : _kSubDay;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   3,
        childAspectRatio: 0.95,
        crossAxisSpacing: 10,
        mainAxisSpacing:  10,
      ),
      itemCount: books.length,
      itemBuilder: (_, i) {
        final book     = books[i];
        final chapters = _chapterCounts[book] ?? 0;
        final isLast   = book == _lastBook;

        return GestureDetector(
          onTap: () => setState(() => _book = book),
          child: Container(
            decoration: BoxDecoration(
              color: isLast
                  ? _kGold.withValues(alpha: _night ? 0.18 : 0.14)
                  : card,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: _night ? 0.22 : 0.07),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // number badge — no border
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLast
                        ? _kGold.withValues(alpha: 0.25)
                        : (_night
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.07)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: isLast
                          ? _kGold
                          : fg.withValues(alpha: 0.5),
                      fontSize:   10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  book,
                  style: GoogleFonts.playfairDisplay(
                      color: isLast ? _kGold : fg,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text('$chapters ch',
                    style: TextStyle(color: sub, fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  // Skeleton while loading — shown inline, no separate splash screen
  Widget _skeletonGrid() {
    final card =
        _night ? const Color(0xFF1E2A3A) : Colors.black.withValues(alpha: 0.06);
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   3,
        childAspectRatio: 0.95,
        crossAxisSpacing: 10,
        mainAxisSpacing:  10,
      ),
      itemCount: 18,
      itemBuilder: (_, __) => _ShimmerCard(color: card),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CHAPTER GRID
  // ════════════════════════════════════════════════════════════════════════════

  Widget _chapterGrid() {
    final total = _chapterCounts[_book] ?? 0;
    final bg    = _night ? _kDark : _kLight;
    final fg    = _night ? Colors.white : _kInkDay;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: _night ? _kSurface : Colors.white,
        foregroundColor: fg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => setState(() => _book = null),
        ),
        title: Text(_book!,
            style: GoogleFonts.playfairDisplay(
                color: fg, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: fg),
            onPressed: () => setState(() => _searchOpen = true),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Text('$total chapters',
                style: TextStyle(
                    color: fg.withValues(alpha: 0.45), fontSize: 13)),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:   5,
                childAspectRatio: 1,
                crossAxisSpacing: 10,
                mainAxisSpacing:  10,
              ),
              itemCount: total,
              itemBuilder: (_, i) {
                final ch        = i + 1;
                final isCurrent =
                    _lastBook == _book && _lastChapter == ch;
                return _ChapterCell(
                  number:  ch,
                  current: isCurrent,
                  night:   _night,
                  onTap: () {
                    _savePosition(_book!, ch);
                    setState(() => _chapter = ch);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // READING VIEW
  // ════════════════════════════════════════════════════════════════════════════

  Widget _readingView() {
    final verses = _verses(_book!, _chapter!);
    final bg     = _night ? _kDark : _kLight;
    final fg     = _night ? const Color(0xFFE8E0D5) : _kInkDay;
    final sub    = _night ? const Color(0xFF8A9A92) : _kSubDay;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [

            // top bar
            Container(
              color: _night ? _kSurface : Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: _night ? Colors.white : _kInkDay,
                            size: 20),
                        onPressed: () {
                          setState(() => _chapter = null);
                        },
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(_book!,
                                style: GoogleFonts.playfairDisplay(
                                    color: _night
                                        ? Colors.white
                                        : _kInkDay,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold)),
                            Text(
                              'Chapter $_chapter of $_maxChapter',
                              style: TextStyle(
                                  color: (_night
                                          ? Colors.white
                                          : _kInkDay)
                                      .withValues(alpha: 0.45),
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.tune_rounded,
                            color: _night ? Colors.white : _kInkDay,
                            size: 22),
                        onPressed: _showSettings,
                      ),
                    ],
                  ),
                  // Audio coming soon
                  _AudioComingSoon(night: _night),
                ],
              ),
            ),

            // verses
            Expanded(
              child: verses.isEmpty
                  ? Center(
                      child: Text(
                        'No verses found for this chapter',
                        style: TextStyle(
                            color: (_night ? Colors.white : _kInkDay)
                                .withValues(alpha: 0.4),
                            fontSize: 15),
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(20, 20, 20, 48),
                      itemCount: verses.length,
                      itemBuilder: (_, i) => _VerseRow(
                        verse:     verses[i],
                        textColor: fg,
                        subColor:  sub,
                        fontSize:  _fontSize,
                        showEng:   _showEng,
                        night:     _night,
                      ),
                    ),
            ),

            // bottom nav
            _BottomNav(
              chapter:    _chapter!,
              maxChapter: _maxChapter,
              night:      _night,
              onPrev: () {
                final prev = _chapter! - 1;
                _savePosition(_book!, prev);
                setState(() => _chapter = prev);
              },
              onNext: () {
                final next = _chapter! + 1;
                _savePosition(_book!, next);
                setState(() => _chapter = next);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    final bg = _night ? _kSurface : Colors.white;
    final fg = _night ? Colors.white : _kInkDay;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        var localShowEng  = _showEng;
        var localNight    = _night;
        var localFontSize = _fontSize;

        return StatefulBuilder(
          builder: (ctx, local) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32, height: 4,
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Reading settings',
                    style: TextStyle(
                        color: fg,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text('Font size',
                    style: TextStyle(
                        color: fg.withValues(alpha: 0.55),
                        fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('A',
                        style: TextStyle(
                            color: fg.withValues(alpha: 0.45),
                            fontSize: 14)),
                    Expanded(
                      child: Slider(
                        value: localFontSize,
                        min: 14, max: 26, divisions: 6,
                        activeColor: _kGold,
                        inactiveColor: fg.withValues(alpha: 0.12),
                        onChanged: (v) {
                          local(() => localFontSize = v);
                          setState(() => _fontSize = v);
                          _savePref('bible_font_size', v);
                        },
                      ),
                    ),
                    Text('A',
                        style: TextStyle(
                            color: fg.withValues(alpha: 0.45),
                            fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 8),
                _PrefRow(
                  label: 'Show English translation',
                  value: localShowEng,
                  fg: fg,
                  onChanged: (v) {
                    local(() => localShowEng = v);
                    setState(() => _showEng = v);
                    _savePref('bible_show_eng', v);
                    AnalyticsService.instance.logBibleToggleEnglish(v);
                  },
                ),
                const SizedBox(height: 4),
                _PrefRow(
                  label: 'Night mode',
                  value: localNight,
                  fg: fg,
                  onChanged: (v) {
                    local(() => localNight = v);
                    setState(() => _night = v);
                    _savePref('bible_night', v);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SEARCH
  // ════════════════════════════════════════════════════════════════════════════

  Widget _searchView() {
    final bg  = _night ? _kDark : _kLight;
    final fg  = _night ? Colors.white : _kInkDay;
    final div = _night
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.07);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: _night ? _kSurface : Colors.white,
        foregroundColor: fg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => setState(() {
            _searchOpen = false;
            _query      = '';
            _results    = [];
            _searchCtrl.clear();
          }),
        ),
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: TextStyle(color: fg, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search in Anywaa or English…',
            hintStyle: TextStyle(color: fg.withValues(alpha: 0.35)),
            border: InputBorder.none,
          ),
          onChanged: (v) { _query = v; _search(v); },
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear,
                  color: fg.withValues(alpha: 0.5)),
              onPressed: () { _searchCtrl.clear(); _search(''); },
            ),
        ],
      ),
      body: _results.isEmpty
          ? Center(
              child: Text(
                _query.isEmpty
                    ? 'Type to search the Bible'
                    : 'No results found',
                style: TextStyle(
                    color: fg.withValues(alpha: 0.35), fontSize: 15),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${_results.length} results',
                        style: TextStyle(
                            color: fg.withValues(alpha: 0.4),
                            fontSize: 12)),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: div, height: 1),
                    itemBuilder: (_, i) {
                      final v = _results[i];
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                        title: Text(v.anywaa,
                            style: TextStyle(
                                color: fg,
                                fontSize: 14,
                                height: 1.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            '${v.book}  ${v.chapter}:${v.verse}',
                            style: const TextStyle(
                                color: _kGold,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        onTap: () {
                          _savePosition(v.book, v.chapter);
                          setState(() {
                            _book        = v.book;
                            _chapter     = v.chapter;
                            _searchOpen  = false;
                            _query       = '';
                            _results     = [];
                            _searchCtrl.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ════════════════════════════════════════════════════════════════════════════

// ── Shimmer skeleton card — no border ────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  final Color color;
  const _ShimmerCard({required this.color});
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.4 + 0.3 * _ctrl.value),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

// ── Continue reading banner — no border ──────────────────────────────────────
class _ContinueBanner extends StatelessWidget {
  final String       book;
  final int          chapter;
  final bool         night;
  final VoidCallback onTap;
  const _ContinueBanner({
    required this.book,
    required this.chapter,
    required this.night,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          color: _kGreen.withValues(alpha: night ? 0.9 : 0.8),
          child: Row(
            children: [
              Icon(Icons.bookmark_rounded, color: _kGoldSoft, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Continue reading',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4)),
                    const SizedBox(height: 2),
                    Text('$book · Chapter $chapter',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white54, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Chapter cell — no border on current, shadow only ─────────────────────────
class _ChapterCell extends StatelessWidget {
  final int          number;
  final bool         current;
  final bool         night;
  final VoidCallback onTap;
  const _ChapterCell({
    required this.number,
    required this.current,
    required this.night,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = current
        ? _kGold
        : night ? const Color(0xFF1E2A3A) : Colors.white;
    final fg =
        current ? Colors.white : (night ? Colors.white70 : _kInkDay);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          boxShadow: current
              ? [
                  BoxShadow(
                    color: _kGold.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: night ? 0.18 : 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ],
        ),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              color:      fg,
              fontSize:   16,
              fontWeight: current ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Audio bar — no border ─────────────────────────────────────────────────────
// ── Audio coming soon badge ──────────────────────────────────────────────────
class _AudioComingSoon extends StatelessWidget {
  final bool night;
  const _AudioComingSoon({required this.night});

  @override
  Widget build(BuildContext context) {
    final fg = night ? Colors.white : _kInkDay;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: night
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.headphones_rounded,
              color: _kGold.withValues(alpha: 0.6), size: 20),
          const SizedBox(width: 10),
          Text(
            'Audio Coming Soon',
            style: TextStyle(
              color:      fg.withValues(alpha: 0.5),
              fontSize:   14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Verse row — English block uses warm gold bg, no border ───────────────────
class _VerseRow extends StatelessWidget {
  final BibleVerse verse;
  final Color      textColor;
  final Color      subColor;
  final double     fontSize;
  final bool       showEng;
  final bool       night;
  const _VerseRow({
    required this.verse,
    required this.textColor,
    required this.subColor,
    required this.fontSize,
    required this.showEng,
    required this.night,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // verse number — gold, right-aligned
          SizedBox(
            width: 30,
            child: Text(
              '${verse.verse}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color:      _kGold.withValues(alpha: 0.75),
                fontSize:   11,
                fontWeight: FontWeight.bold,
                height:     fontSize / 11 * 1.75,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Anywaa ──────────────────────────────────────────────
                SelectableText(
                  verse.anywaa,
                  style: TextStyle(
                    color:         textColor,
                    fontSize:      fontSize,
                    height:        1.85,
                    letterSpacing: 0.1,
                  ),
                ),

                // ── English — warm gold card, no border ─────────────────
                if (showEng) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: night
                          ? _kGold.withValues(alpha: 0.1)
                          : _kGold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // "EN" pill label
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: _kGold.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'EN',
                            style: TextStyle(
                              color:         _kGold,
                              fontSize:      9,
                              fontWeight:    FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          verse.english,
                          style: TextStyle(
                            color:         subColor,
                            fontSize:      fontSize - 2,
                            height:        1.65,
                            fontStyle:     FontStyle.italic,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int          chapter;
  final int          maxChapter;
  final bool         night;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _BottomNav({
    required this.chapter,
    required this.maxChapter,
    required this.night,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final bg = night ? _kSurface : Colors.white;
    final fg = night ? Colors.white : _kInkDay;
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _NavBtn(
            label:   'Previous',
            icon:    Icons.arrow_back_ios_rounded,
            leading: true,
            enabled: chapter > 1,
            fg:      fg,
            onTap:   onPrev,
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$chapter / $maxChapter',
                  style: const TextStyle(
                      color:      _kGold,
                      fontSize:   13,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          _NavBtn(
            label:   'Next',
            icon:    Icons.arrow_forward_ios_rounded,
            leading: false,
            enabled: chapter < maxChapter,
            fg:      fg,
            onTap:   onNext,
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final bool         leading;
  final bool         enabled;
  final Color        fg;
  final VoidCallback onTap;
  const _NavBtn({
    required this.label,
    required this.icon,
    required this.leading,
    required this.enabled,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final col = enabled ? fg : fg.withValues(alpha: 0.22);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: leading
            ? [
                Icon(icon, color: col, size: 13),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(
                        color: col, fontWeight: FontWeight.w600)),
              ]
            : [
                Text(label,
                    style: TextStyle(
                        color: col, fontWeight: FontWeight.w600)),
                const SizedBox(width: 5),
                Icon(icon, color: col, size: 13),
              ],
      ),
    );
  }
}

// ── Settings row ──────────────────────────────────────────────────────────────
class _PrefRow extends StatelessWidget {
  final String             label;
  final bool               value;
  final Color              fg;
  final ValueChanged<bool> onChanged;
  const _PrefRow({
    required this.label,
    required this.value,
    required this.fg,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: fg, fontSize: 15)),
          Switch(
              value: value, activeTrackColor: _kGold, onChanged: onChanged),
        ],
      );
}
