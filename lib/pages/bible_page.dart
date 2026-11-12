import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ── Colour palette used only inside this page ────────────────────────────────
const _kInk     = Color(0xFF1A1A2E);   // near-black background
const _kParch   = Color(0xFFF6EFE3);   // warm parchment
const _kGold    = Color(0xFFC9993A);   // gold accent
const _kGoldSoft= Color(0xFFE8C87A);   // lighter gold for verse numbers
const _kForest  = Color(0xFF1F4D3A);   // brand green
const _kForestLt= Color(0xFF2D6A4F);   // lighter green

// ── Data model ───────────────────────────────────────────────────────────────
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

// ── Page ─────────────────────────────────────────────────────────────────────
class BiblePage extends StatefulWidget {
  const BiblePage({Key? key}) : super(key: key);

  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage> with TickerProviderStateMixin {
  // ── data ──────────────────────────────────────────────────────────────────
  List<BibleVerse>   _allVerses         = [];
  Map<String, int>   _bookChapterCounts = {};
  List<String>       _otBooks           = [];
  List<String>       _ntBooks           = [];
  bool               _isLoading         = true;

  // ── navigation state ──────────────────────────────────────────────────────
  String? _selectedBook;
  int?    _selectedChapter;

  // ── continue reading ──────────────────────────────────────────────────────
  String? _lastBook;
  int?    _lastChapter;

  // ── reading prefs ─────────────────────────────────────────────────────────
  double _fontSize       = 18;
  bool   _showEnglish    = false;
  bool   _nightMode      = true;   // dark = true, light = false

  // ── audio ─────────────────────────────────────────────────────────────────
  final AudioPlayer _audio    = AudioPlayer();
  bool              _isPlaying = false;

  // ── search ────────────────────────────────────────────────────────────────
  bool   _searchOpen = false;
  String _searchQuery= '';
  List<BibleVerse> _searchResults = [];
  final _searchCtrl  = TextEditingController();

  // ── animations ────────────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _loadBible();
    _loadPrefs();
  }

  @override
  void dispose() {
    _audio.dispose();
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── loaders ───────────────────────────────────────────────────────────────

  Future<void> _loadBible() async {
    try {
      final raw  = await rootBundle.loadString('assets/bible.json');
      final list = json.decode(raw) as List<dynamic>;
      final verses = list.map((v) => BibleVerse.fromJson(v)).toList();
      _buildMeta(verses);
      setState(() { _allVerses = verses; _isLoading = false; });
      _fadeCtrl.forward();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _buildMeta(List<BibleVerse> verses) {
    final seen = <String>{};
    for (final v in verses) {
      seen.add(v.book);
      final cur = _bookChapterCounts[v.book] ?? 0;
      if (v.chapter > cur) _bookChapterCounts[v.book] = v.chapter;
    }
    final books = seen.toList();
    _otBooks = books.take(39).toList();
    _ntBooks = books.skip(39).toList();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _lastBook      = p.getString('bible_last_book');
      _lastChapter   = p.getInt('bible_last_chapter');
      _fontSize      = p.getDouble('bible_font_size') ?? 18;
      _showEnglish   = p.getBool('bible_show_english') ?? false;
      _nightMode     = p.getBool('bible_night_mode') ?? true;
    });
  }

  Future<void> _savePosition(String book, int chapter) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('bible_last_book', book);
    await p.setInt('bible_last_chapter', chapter);
    setState(() { _lastBook = book; _lastChapter = chapter; });
    FirebaseAnalytics.instance.logEvent(
      name: 'bible_chapter_opened',
      parameters: {'book': book, 'chapter': chapter},
    );
  }

  Future<void> _savePref(String key, dynamic value) async {
    final p = await SharedPreferences.getInstance();
    if (value is double)  await p.setDouble(key, value);
    if (value is bool)    await p.setBool(key, value);
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  List<BibleVerse> _chapterVerses(String book, int chapter) => _allVerses
      .where((v) => v.book == book && v.chapter == chapter)
      .toList();

  void _search(String q) {
    q = q.trim().toLowerCase();
    if (q.isEmpty) { setState(() => _searchResults = []); return; }
    setState(() {
      _searchResults = _allVerses
          .where((v) =>
              v.anywaa.toLowerCase().contains(q) ||
              v.english.toLowerCase().contains(q))
          .take(100)
          .toList();
    });
  }

  Future<void> _toggleAudio() async {
    final bookSlug = _selectedBook!.replaceAll(' ', '_').toLowerCase();
    final url =
        'https://firebasestorage.googleapis.com/v0/b/learn-dha-anywaa.appspot.com/o/'
        'bible_audio%2F$bookSlug%2Fchapter_$_selectedChapter.mp3?alt=media';
    if (_isPlaying) {
      await _audio.pause();
      setState(() => _isPlaying = false);
    } else {
      try {
        await _audio.play(UrlSource(url));
        setState(() => _isPlaying = true);
        _audio.onPlayerComplete.listen((_) => setState(() => _isPlaying = false));
        FirebaseAnalytics.instance.logEvent(
          name: 'bible_audio_played',
          parameters: {'book': _selectedBook, 'chapter': _selectedChapter},
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Audio not available for this chapter yet'),
          ));
        }
      }
    }
  }

  // ── routing ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSplash();

    if (_searchOpen) return _buildSearchView();

    if (_selectedBook != null && _selectedChapter != null) {
      return _buildReadingView();
    }
    if (_selectedBook != null) return _buildChapterGrid();
    return _buildLibrary();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SPLASH
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSplash() {
    return Scaffold(
      backgroundColor: _kInk,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('✝', style: GoogleFonts.playfairDisplay(
              fontSize: 64, color: _kGold)),
            const SizedBox(height: 20),
            Text('Wëël Jwøk', style: GoogleFonts.playfairDisplay(
              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            const SizedBox(
              width: 40,
              child: LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation(_kGold),
                backgroundColor: Colors.white12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LIBRARY  (book selection)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLibrary() {
    final bg   = _nightMode ? _kInk    : _kParch;
    final text = _nightMode ? Colors.white : _kInk;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bg,
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: _nightMode ? _kInk : _kParch,
              foregroundColor: text,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildLibraryHero(),
                collapseMode: CollapseMode.parallax,
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.search, color: text),
                  onPressed: () => setState(() => _searchOpen = true),
                ),
                IconButton(
                  icon: Icon(_nightMode ? Icons.wb_sunny_outlined
                                        : Icons.nights_stay_outlined,
                      color: text),
                  onPressed: () {
                    setState(() => _nightMode = !_nightMode);
                    _savePref('bible_night_mode', _nightMode);
                  },
                ),
              ],
              bottom: TabBar(
                labelColor: _kGold,
                unselectedLabelColor: text.withOpacity(0.5),
                indicatorColor: _kGold,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: 'Old Testament  ${_otBooks.length}'),
                  Tab(text: 'New Testament  ${_ntBooks.length}'),
                ],
              ),
            ),
          ],
          body: Column(
            children: [
              // ── Continue reading banner ─────────────────────────────────
              if (_lastBook != null && _lastChapter != null)
                _ContinueBanner(
                  book:    _lastBook!,
                  chapter: _lastChapter!,
                  night:   _nightMode,
                  onTap: () {
                    setState(() {
                      _selectedBook    = _lastBook;
                      _selectedChapter = _lastChapter;
                    });
                  },
                ),
              Expanded(
                child: TabBarView(children: [
                  _buildBookGrid(_otBooks),
                  _buildBookGrid(_ntBooks),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryHero() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _nightMode
              ? [const Color(0xFF0D1B2A), _kInk]
              : [const Color(0xFF2D6A4F), _kParch],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _kGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _kGold.withOpacity(0.5), width: 1),
                    ),
                    child: Text('Dha Anywaa · English',
                        style: TextStyle(
                            color: _kGoldSoft,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Wëël Jwøk',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text('${_allVerses.length.toString().replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (m) => '${m[1]},',
                  )} verses · 66 books',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookGrid(List<String> books) {
    final bg   = _nightMode ? _kInk    : _kParch;
    final card = _nightMode ? const Color(0xFF1E2A3A) : Colors.white;
    final text = _nightMode ? Colors.white : _kInk;
    final sub  = _nightMode ? Colors.white38 : Colors.black38;

    return FadeTransition(
      opacity: _fadeAnim,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: books.length,
        itemBuilder: (_, i) {
          final book     = books[i];
          final chapters = _bookChapterCounts[book] ?? 0;
          final number   = i + 1;

          return _BookCell(
            book:     book,
            number:   number,
            chapters: chapters,
            card:     card,
            text:     text,
            sub:      sub,
            onTap: () => setState(() => _selectedBook = book),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CHAPTER GRID
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildChapterGrid() {
    final total = _bookChapterCounts[_selectedBook] ?? 0;
    final bg    = _nightMode ? _kInk    : _kParch;
    final text  = _nightMode ? Colors.white : _kInk;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        title: Text(_selectedBook!,
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                color: text)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: text),
          onPressed: () => setState(() => _selectedBook = null),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: text),
            onPressed: () => setState(() => _searchOpen = true),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              '$total chapters',
              style: TextStyle(color: text.withOpacity(0.5), fontSize: 13),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: total,
              itemBuilder: (_, i) {
                final ch = i + 1;
                final isCurrent =
                    _lastBook == _selectedBook && _lastChapter == ch;

                return _ChapterCell(
                  chapter:  ch,
                  isCurrent: isCurrent,
                  night:    _nightMode,
                  onTap: () {
                    _savePosition(_selectedBook!, ch);
                    setState(() => _selectedChapter = ch);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // READING VIEW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildReadingView() {
    final verses   = _chapterVerses(_selectedBook!, _selectedChapter!);
    final maxCh    = _bookChapterCounts[_selectedBook!] ?? 1;
    final bg       = _nightMode ? const Color(0xFF12191F) : _kParch;
    final textCol  = _nightMode ? const Color(0xFFE8E0D5) : const Color(0xFF1A1A2E);
    final subCol   = _nightMode ? const Color(0xFF9BA8A0) : const Color(0xFF5B625D);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [

            // ── Top bar ──────────────────────────────────────────────────
            _ReadingTopBar(
              book:      _selectedBook!,
              chapter:   _selectedChapter!,
              maxChapter: maxCh,
              night:     _nightMode,
              isPlaying: _isPlaying,
              showEng:   _showEnglish,
              fontSize:  _fontSize,
              onBack: () => setState(() => _selectedChapter = null),
              onAudio:   _toggleAudio,
              onToggleEnglish: () {
                setState(() => _showEnglish = !_showEnglish);
                _savePref('bible_show_english', _showEnglish);
              },
              onFontSize: (v) {
                setState(() => _fontSize = v);
                _savePref('bible_font_size', v);
              },
              onNight: () {
                setState(() => _nightMode = !_nightMode);
                _savePref('bible_night_mode', _nightMode);
              },
            ),

            // ── Verses ───────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                // +1 for the chapter header item at index 0
                itemCount: verses.length + 1,
                itemBuilder: (_, i) {
                  // Index 0: decorative chapter header
                  if (i == 0) {
                    return _ChapterHeader(
                      book:    _selectedBook!,
                      chapter: _selectedChapter!,
                      night:   _nightMode,
                    );
                  }
                  final verse = verses[i - 1];
                  return _VerseItem(
                    verse:       verse,
                    textColor:   textCol,
                    subColor:    subCol,
                    fontSize:    _fontSize,
                    showEnglish: _showEnglish,
                    night:       _nightMode,
                    isFirst:     i == 1,
                  );
                },
              ),
            ),

            // ── Bottom nav ───────────────────────────────────────────────
            _ChapterNavBar(
              chapter:   _selectedChapter!,
              maxChapter: maxCh,
              night:     _nightMode,
              onPrev: () {
                final p = _selectedChapter! - 1;
                _savePosition(_selectedBook!, p);
                setState(() => _selectedChapter = p);
              },
              onNext: () {
                final n = _selectedChapter! + 1;
                _savePosition(_selectedBook!, n);
                setState(() => _selectedChapter = n);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SEARCH VIEW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchView() {
    final bg   = _nightMode ? _kInk    : _kParch;
    final text = _nightMode ? Colors.white : _kInk;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: text),
          onPressed: () {
            setState(() {
              _searchOpen   = false;
              _searchQuery  = '';
              _searchResults= [];
              _searchCtrl.clear();
            });
          },
        ),
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: TextStyle(color: text, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search in Anywaa or English…',
            hintStyle: TextStyle(color: text.withOpacity(0.4)),
            border: InputBorder.none,
          ),
          onChanged: (v) {
            _searchQuery = v;
            _search(v);
          },
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: text.withOpacity(0.6)),
              onPressed: () {
                _searchCtrl.clear();
                _search('');
              },
            ),
        ],
      ),
      body: _searchResults.isEmpty
          ? Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'Type to search the Bible'
                    : 'No results found',
                style: TextStyle(color: text.withOpacity(0.4), fontSize: 16),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => Divider(
                color: text.withOpacity(0.1), height: 1),
              itemBuilder: (_, i) {
                final v = _searchResults[i];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  title: Text(
                    v.anywaa,
                    style: TextStyle(
                        color: text, fontSize: 15, height: 1.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${v.book} ${v.chapter}:${v.verse}',
                      style: TextStyle(color: _kGold, fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  onTap: () {
                    _savePosition(v.book, v.chapter);
                    setState(() {
                      _selectedBook    = v.book;
                      _selectedChapter = v.chapter;
                      _searchOpen      = false;
                      _searchQuery     = '';
                      _searchResults   = [];
                      _searchCtrl.clear();
                    });
                  },
                );
              },
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ════════════════════════════════════════════════════════════════════════════

// ── Continue reading banner ──────────────────────────────────────────────────
class _ContinueBanner extends StatelessWidget {
  final String book;
  final int    chapter;
  final bool   night;
  final VoidCallback onTap;

  const _ContinueBanner({
    required this.book,
    required this.chapter,
    required this.night,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1F4D3A), Color(0xFF2D6A4F)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kForest.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark_rounded,
                  color: _kGoldSoft, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Continue reading',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text('$book  $chapter',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Book cell ────────────────────────────────────────────────────────────────
class _BookCell extends StatelessWidget {
  final String book;
  final int    number;
  final int    chapters;
  final Color  card;
  final Color  text;
  final Color  sub;
  final VoidCallback onTap;

  const _BookCell({
    required this.book,
    required this.number,
    required this.chapters,
    required this.card,
    required this.text,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Book number badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _kGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$number',
                  style: TextStyle(
                      color: _kGold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Text(
                book,
                style: GoogleFonts.playfairDisplay(
                    color: text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$chapters ch',
                style: TextStyle(color: sub, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Chapter cell ─────────────────────────────────────────────────────────────
class _ChapterCell extends StatelessWidget {
  final int  chapter;
  final bool isCurrent;
  final bool night;
  final VoidCallback onTap;

  const _ChapterCell({
    required this.chapter,
    required this.isCurrent,
    required this.night,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isCurrent
        ? _kGold
        : night
            ? const Color(0xFF1E2A3A)
            : Colors.white;
    final fg = isCurrent ? Colors.white : (night ? Colors.white : _kInk);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: !isCurrent
              ? Border.all(
                  color: night
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.08))
              : null,
          boxShadow: isCurrent
              ? [BoxShadow(
                  color: _kGold.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3))]
              : null,
        ),
        child: Center(
          child: Text(
            '$chapter',
            style: TextStyle(
                color: fg,
                fontSize: 17,
                fontWeight:
                    isCurrent ? FontWeight.bold : FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

// ── Reading top bar ──────────────────────────────────────────────────────────
class _ReadingTopBar extends StatelessWidget {
  final String   book;
  final int      chapter;
  final int      maxChapter;
  final bool     night;
  final bool     isPlaying;
  final bool     showEng;
  final double   fontSize;
  final VoidCallback onBack;
  final VoidCallback onAudio;
  final VoidCallback onToggleEnglish;
  final ValueChanged<double> onFontSize;
  final VoidCallback onNight;

  const _ReadingTopBar({
    required this.book,
    required this.chapter,
    required this.maxChapter,
    required this.night,
    required this.isPlaying,
    required this.showEng,
    required this.fontSize,
    required this.onBack,
    required this.onAudio,
    required this.onToggleEnglish,
    required this.onFontSize,
    required this.onNight,
  });

  @override
  Widget build(BuildContext context) {
    final bg   = night ? _kInk    : _kParch;
    final text = night ? Colors.white : _kInk;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(
              color: night
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.08)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: back + title + settings
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: text, size: 20),
                  onPressed: onBack,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(book,
                          style: GoogleFonts.playfairDisplay(
                              color: text,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      Text('Chapter $chapter of $maxChapter',
                          style: TextStyle(
                              color: text.withOpacity(0.5),
                              fontSize: 11)),
                    ],
                  ),
                ),
                // Settings icon opens bottom sheet
                IconButton(
                  icon: Icon(Icons.tune_rounded, color: text, size: 22),
                  onPressed: () => _showSettings(context),
                ),
              ],
            ),
          ),
          // Row 2: audio bar
          GestureDetector(
            onTap: onAudio,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isPlaying
                    ? _kForest.withOpacity(0.9)
                    : (night
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.05)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPlaying
                      ? _kForest
                      : text.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: isPlaying ? Colors.white : _kGold,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isPlaying
                        ? 'Listening…'
                        : 'Listen to this chapter',
                    style: TextStyle(
                      color: isPlaying
                          ? Colors.white
                          : text.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isPlaying) ...[
                    const SizedBox(width: 8),
                    _AudioWave(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    final bg   = night ? const Color(0xFF1A2332) : Colors.white;
    final text = night ? Colors.white : _kInk;

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: text.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Reading settings',
                  style: TextStyle(
                      color: text,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Font size
              Text('Font size',
                  style: TextStyle(
                      color: text.withOpacity(0.6), fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.text_fields_rounded,
                      color: text.withOpacity(0.5), size: 18),
                  Expanded(
                    child: Slider(
                      value: fontSize,
                      min: 14,
                      max: 26,
                      divisions: 6,
                      activeColor: _kGold,
                      inactiveColor: text.withOpacity(0.1),
                      onChanged: (v) {
                        setLocal(() {});
                        onFontSize(v);
                      },
                    ),
                  ),
                  Icon(Icons.text_fields_rounded,
                      color: text.withOpacity(0.5), size: 24),
                ],
              ),

              const SizedBox(height: 16),

              // Show English toggle
              _SettingsRow(
                label: 'Show English translation',
                value: showEng,
                text:  text,
                onChanged: (v) {
                  setLocal(() {});
                  onToggleEnglish();
                },
              ),

              const SizedBox(height: 8),

              // Night mode toggle
              _SettingsRow(
                label: 'Night mode',
                value: night,
                text:  text,
                onChanged: (v) {
                  setLocal(() {});
                  onNight();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Settings row ─────────────────────────────────────────────────────────────
class _SettingsRow extends StatelessWidget {
  final String label;
  final bool   value;
  final Color  text;
  final ValueChanged<bool> onChanged;

  const _SettingsRow({
    required this.label,
    required this.value,
    required this.text,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: text, fontSize: 15)),
        Switch(
          value: value,
          activeColor: _kGold,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ── Chapter decorative header ─────────────────────────────────────────────────
class _ChapterHeader extends StatelessWidget {
  final String book;
  final int    chapter;
  final bool   night;

  const _ChapterHeader({
    required this.book,
    required this.chapter,
    required this.night,
  });

  @override
  Widget build(BuildContext context) {
    final text = night ? Colors.white : _kInk;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thin gold divider line with cross icon
          Row(
            children: [
              Expanded(child: Divider(color: _kGold.withOpacity(0.3), height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.add, color: _kGold.withOpacity(0.5), size: 14),
              ),
              Expanded(child: Divider(color: _kGold.withOpacity(0.3), height: 1)),
            ],
          ),
          const SizedBox(height: 20),

          // Book name
          Text(
            book.toUpperCase(),
            style: TextStyle(
              color:         _kGold.withOpacity(0.7),
              fontSize:      11,
              fontWeight:    FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),

          // Chapter number — large and serif
          Text(
            'Chapter $chapter',
            style: GoogleFonts.playfairDisplay(
              color:      text,
              fontSize:   28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Bottom separator
          Row(
            children: [
              Expanded(child: Divider(color: _kGold.withOpacity(0.2), height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color:  _kGold.withOpacity(0.4),
                    shape:  BoxShape.circle,
                  ),
                ),
              ),
              Expanded(child: Divider(color: _kGold.withOpacity(0.2), height: 1)),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Verse item ───────────────────────────────────────────────────────────────
class _VerseItem extends StatelessWidget {
  final BibleVerse verse;
  final Color      textColor;
  final Color      subColor;
  final double     fontSize;
  final bool       showEnglish;
  final bool       night;
  // verse 1 gets a chapter-opening treatment
  final bool       isFirst;

  const _VerseItem({
    required this.verse,
    required this.textColor,
    required this.subColor,
    required this.fontSize,
    required this.showEnglish,
    required this.night,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    // Verse 1: big drop-cap style opener
    if (isFirst) return _buildOpeningVerse(context);
    return _buildNormalVerse(context);
  }

  // ── Verse 1: chapter opener ───────────────────────────────────────────────
  Widget _buildOpeningVerse(BuildContext context) {
    final cardBg = night
        ? const Color(0xFF1E2D40).withOpacity(0.7)
        : _kGold.withOpacity(0.06);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: _kGold.withOpacity(0.25), width: 1),
        boxShadow: night
            ? [BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4))]
            : [BoxShadow(
                color: _kGold.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gold "1" badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kGold, _kGoldSoft],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('1',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
          ),
          const SizedBox(height: 14),

          // Anywaa text — larger for opening verse
          Text(
            verse.anywaa,
            style: GoogleFonts.playfairDisplay(
              color:      textColor,
              fontSize:   fontSize + 2,
              height:     1.8,
              fontWeight: FontWeight.w500,
            ),
          ),

          // English
          if (showEnglish) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: _kGold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(
                      color: _kGold.withOpacity(0.6), width: 3),
                ),
              ),
              child: Text(
                verse.english,
                style: TextStyle(
                  color:      subColor,
                  fontSize:   fontSize - 2,
                  height:     1.65,
                  fontStyle:  FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Normal verse ─────────────────────────────────────────────────────────
  Widget _buildNormalVerse(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verse number column — fixed width, right-aligned
          SizedBox(
            width: 32,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '${verse.verse}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color:      _kGold.withOpacity(0.75),
                  fontSize:   12,
                  fontWeight: FontWeight.bold,
                  height:     fontSize / 12 * 1.75,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Verse text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Anywaa
                SelectableText(
                  verse.anywaa,
                  style: TextStyle(
                    color:      textColor,
                    fontSize:   fontSize,
                    height:     1.8,
                    letterSpacing: 0.1,
                  ),
                ),

                // English (indented, italic, gold border)
                if (showEnglish) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    decoration: BoxDecoration(
                      color: night
                          ? Colors.white.withOpacity(0.04)
                          : _kGold.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topRight:    Radius.circular(8),
                        bottomRight: Radius.circular(8),
                        bottomLeft:  Radius.circular(8),
                      ),
                      border: Border(
                        left: BorderSide(
                            color: _kGold.withOpacity(0.45), width: 2.5),
                      ),
                    ),
                    child: Text(
                      verse.english,
                      style: TextStyle(
                        color:     subColor,
                        fontSize:  fontSize - 2.5,
                        height:    1.65,
                        fontStyle: FontStyle.italic,
                      ),
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

// ── Chapter nav bar ───────────────────────────────────────────────────────────
class _ChapterNavBar extends StatelessWidget {
  final int  chapter;
  final int  maxChapter;
  final bool night;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _ChapterNavBar({
    required this.chapter,
    required this.maxChapter,
    required this.night,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final bg   = night ? const Color(0xFF111822) : Colors.white;
    final text = night ? Colors.white : _kInk;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(
              color: night
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.08)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Previous
          _NavBtn(
            label: 'Previous',
            icon:  Icons.arrow_back_ios_rounded,
            align: MainAxisAlignment.start,
            enabled: chapter > 1,
            text:  text,
            night: night,
            onTap: onPrev,
          ),

          // Chapter indicator
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _kGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$chapter / $maxChapter',
                  style: const TextStyle(
                      color: _kGold,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // Next
          _NavBtn(
            label: 'Next',
            icon:  Icons.arrow_forward_ios_rounded,
            align: MainAxisAlignment.end,
            enabled: chapter < maxChapter,
            text:  text,
            night: night,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String             label;
  final IconData           icon;
  final MainAxisAlignment  align;
  final bool               enabled;
  final Color              text;
  final bool               night;
  final VoidCallback       onTap;

  const _NavBtn({
    required this.label,
    required this.icon,
    required this.align,
    required this.enabled,
    required this.text,
    required this.night,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final col = enabled ? text : text.withOpacity(0.25);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Row(
        mainAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: align == MainAxisAlignment.start
            ? [Icon(icon, color: col, size: 14),
               const SizedBox(width: 6),
               Text(label, style: TextStyle(
                   color: col, fontWeight: FontWeight.w600))]
            : [Text(label, style: TextStyle(
                   color: col, fontWeight: FontWeight.w600)),
               const SizedBox(width: 6),
               Icon(icon, color: col, size: 14)],
      ),
    );
  }
}

// ── Animated audio wave (3 bars) ─────────────────────────────────────────────
class _AudioWave extends StatefulWidget {
  @override
  State<_AudioWave> createState() => _AudioWaveState();
}

class _AudioWaveState extends State<_AudioWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _bar(0.3 + 0.7 * t),
            const SizedBox(width: 2),
            _bar(0.7 - 0.5 * t),
            const SizedBox(width: 2),
            _bar(0.5 + 0.5 * t),
          ],
        );
      },
    );
  }

  Widget _bar(double h) => Container(
        width: 3,
        height: 4 + 10 * h,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
