import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dha_anywaaa/theme/app_theme.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class _DictWord {
  final String dha;
  final String en;
  final String pos;
  final String cat;
  final String pron;
  final String exDha;
  final String exEn;
  final List<String> alt;
  final String note;

  const _DictWord({
    required this.dha,
    required this.en,
    required this.pos,
    required this.cat,
    required this.pron,
    required this.exDha,
    required this.exEn,
    required this.alt,
    required this.note,
  });

  factory _DictWord.fromJson(Map<String, dynamic> j) => _DictWord(
        dha:  (j['dha'] ?? '') as String,
        en:   (j['en']  ?? '') as String,
        pos:  (j['pos'] ?? '') as String,
        cat:  (j['cat'] ?? '') as String,
        pron: (j['pron'] ?? '') as String,
        exDha: (j['ex_dha'] ?? '') as String,
        exEn:  (j['ex_en']  ?? '') as String,
        alt:  ((j['alt'] ?? const []) as List).cast<String>(),
        note: (j['note'] ?? '') as String,
      );

  bool matches(String q) {
    if (q.isEmpty) return true;
    final lo = q.toLowerCase();
    return dha.toLowerCase().contains(lo) ||
        en.toLowerCase().contains(lo) ||
        pos.toLowerCase().contains(lo);
  }
}

class _DictCategory {
  final String key;
  final String label;
  final int count;
  final List<_DictWord> words;

  const _DictCategory({
    required this.key,
    required this.label,
    required this.count,
    required this.words,
  });

  factory _DictCategory.fromJson(Map<String, dynamic> j) => _DictCategory(
        key:   (j['key']   ?? '') as String,
        label: (j['label'] ?? '') as String,
        count: (j['count'] ?? 0) as int,
        words: ((j['words'] ?? const []) as List)
            .map((w) => _DictWord.fromJson(w as Map<String, dynamic>))
            .toList(),
      );
}

// ── Category icon + colour map ────────────────────────────────────────────────

IconData _catIcon(String key) {
  const m = <String, IconData>{
    'greetings':             Icons.waving_hand_rounded,
    'family':                Icons.people_rounded,
    'body_parts':            Icons.accessibility_new_rounded,
    'body':                  Icons.accessibility_new_rounded,
    'food_drink':            Icons.restaurant_rounded,
    'food':                  Icons.restaurant_rounded,
    'animals':               Icons.pets_rounded,
    'animals_mammals':       Icons.pets_rounded,
    'animals_fish':          Icons.set_meal_rounded,
    'animals_reptiles':      Icons.pest_control_rounded,
    'birds':                 Icons.flutter_dash_rounded,
    'insects':               Icons.bug_report_rounded,
    'nature':                Icons.eco_rounded,
    'nature_geography':      Icons.landscape_rounded,
    'plants_trees':          Icons.park_rounded,
    'weather_climate':       Icons.wb_sunny_rounded,
    'celestial':             Icons.nights_stay_rounded,
    'numbers':               Icons.tag_rounded,
    'ordinal_numbers':       Icons.format_list_numbered_rounded,
    'math':                  Icons.calculate_rounded,
    'colors':                Icons.palette_rounded,
    'time':                  Icons.access_time_rounded,
    'days_of_week':          Icons.calendar_today_rounded,
    'directions':            Icons.explore_rounded,
    'navigation':            Icons.map_rounded,
    'verbs':                 Icons.bolt_rounded,
    'verbs_actions':         Icons.bolt_rounded,
    'adjectives':            Icons.star_rounded,
    'adverbs':               Icons.speed_rounded,
    'pronouns':              Icons.person_rounded,
    'possessive_pronouns':   Icons.person_rounded,
    'conjunctions_prepositions': Icons.link_rounded,
    'interjections':         Icons.chat_rounded,
    'interrogatives':        Icons.help_rounded,
    'question_words':        Icons.help_outline_rounded,
    'question_phrases':      Icons.help_outline_rounded,
    'phrases':               Icons.format_quote_rounded,
    'grammar':               Icons.school_rounded,
    'education':             Icons.school_rounded,
    'health_medical':        Icons.local_hospital_rounded,
    'emotions':              Icons.sentiment_satisfied_rounded,
    'feelings_sensations':   Icons.favorite_rounded,
    'culture':               Icons.theater_comedy_rounded,
    'spiritual_cultural':    Icons.auto_awesome_rounded,
    'music_arts':            Icons.music_note_rounded,
    'sports_games':          Icons.sports_soccer_rounded,
    'professions':           Icons.work_rounded,
    'household':             Icons.home_rounded,
    'household_items':       Icons.home_rounded,
    'house_building':        Icons.house_rounded,
    'kitchen_utensils':      Icons.kitchen_rounded,
    'clothing':              Icons.checkroom_rounded,
    'materials':             Icons.texture_rounded,
    'tools':                 Icons.handyman_rounded,
    'transport':             Icons.directions_car_rounded,
    'technology':            Icons.devices_rounded,
    'communication':         Icons.forum_rounded,
    'economics':             Icons.attach_money_rounded,
    'politics_government':   Icons.account_balance_rounded,
    'market':                Icons.storefront_rounded,
    'taste_cooking':         Icons.soup_kitchen_rounded,
    'identity':              Icons.badge_rounded,
  };
  return m[key] ?? Icons.book_rounded;
}

Color _catColor(String key, bool dark) {
  final colors = [
    kGold, kRust, kGreen, kGreenMid,
    const Color(0xFF7C6AF7), const Color(0xFFE05C97),
    const Color(0xFF3BA5C8), const Color(0xFFE08B2A),
  ];
  final idx = key.codeUnits.fold(0, (a, b) => a + b) % colors.length;
  return colors[idx];
}

// ── POS badge colours ─────────────────────────────────────────────────────────

Color _posColor(String pos) {
  switch (pos.toLowerCase()) {
    case 'noun':        return kGreen;
    case 'verb':        return kRust;
    case 'adjective':   return kGold;
    case 'adverb':      return const Color(0xFF3BA5C8);
    case 'pronoun':     return const Color(0xFF7C6AF7);
    case 'phrase':      return kGreenMid;
    default:            return kTextMuted;
  }
}

// ── Main page ─────────────────────────────────────────────────────────────────

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage>
    with SingleTickerProviderStateMixin {
  // data
  List<_DictCategory> _categories = [];
  int _total = 0;
  bool _loaded = false;

  // navigation state
  _DictCategory? _currentCat; // null = category grid
  String _search = '';
  final _searchCtrl = TextEditingController();
  bool _searching = false; // global search mode

  // expanded word card
  int? _expandedIdx;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/data/dictionary_full.json');
    final map = json.decode(raw) as Map<String, dynamic>;
    final cats = ((map['categories'] ?? const []) as List)
        .map((c) => _DictCategory.fromJson(c as Map<String, dynamic>))
        .toList();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _total = (map['total'] ?? 0) as int;
      _loaded = true;
    });
  }

  // All words flat — used for global search
  List<_DictWord> get _allWords =>
      _categories.expand((c) => c.words).toList();

  List<_DictWord> get _filteredWords {
    final q = _search.trim();
    if (q.isEmpty) return _allWords;
    return _allWords.where((w) => w.matches(q)).toList();
  }

  List<_DictWord> get _filteredCatWords {
    final cat = _currentCat;
    if (cat == null) return [];
    final q = _search.trim();
    if (q.isEmpty) return cat.words;
    return cat.words.where((w) => w.matches(q)).toList();
  }

  void _openCategory(_DictCategory cat) {
    setState(() {
      _currentCat = cat;
      _search = '';
      _searchCtrl.clear();
      _expandedIdx = null;
      _searching = false;
    });
  }

  void _backToGrid() {
    setState(() {
      _currentCat = null;
      _search = '';
      _searchCtrl.clear();
      _expandedIdx = null;
      _searching = false;
    });
  }

  void _startSearch() {
    setState(() {
      _searching = true;
      _currentCat = null;
      _expandedIdx = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _currentCat != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _backToGrid,
              )
            : null,
        title: _searching
            ? _SearchField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() {
                  _search = v;
                  _expandedIdx = null;
                }),
                onClose: () => setState(() {
                  _searching = false;
                  _search = '';
                  _searchCtrl.clear();
                }),
              )
            : Text(
                _currentCat != null ? _currentCat!.label : 'Dictionary',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 20),
              ),
        actions: [
          if (!_searching)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Search all words',
              onPressed: _startSearch,
            ),
        ],
      ),
      body: !_loaded
          ? Center(child: CircularProgressIndicator(color: c.accent))
          : _searching
              ? _SearchResults(
                  words: _filteredWords,
                  query: _search,
                  expandedIdx: _expandedIdx,
                  onExpand: (i) =>
                      setState(() => _expandedIdx = _expandedIdx == i ? null : i),
                  dark: dark,
                )
              : _currentCat == null
                  ? _CategoryGrid(
                      categories: _categories,
                      total: _total,
                      onTap: _openCategory,
                      dark: dark,
                    )
                  : _WordList(
                      words: _filteredCatWords,
                      category: _currentCat!,
                      expandedIdx: _expandedIdx,
                      onExpand: (i) =>
                          setState(() => _expandedIdx = _expandedIdx == i ? null : i),
                      dark: dark,
                      searchCtrl: _searchCtrl,
                      onSearch: (v) => setState(() {
                        _search = v;
                        _expandedIdx = null;
                      }),
                    ),
    );
  }
}

// ── Search field widget ───────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: 'Search Anywaa or English…',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        border: InputBorder.none,
        suffixIcon: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: onClose,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

// ── Category grid ─────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final List<_DictCategory> categories;
  final int total;
  final void Function(_DictCategory) onTap;
  final bool dark;

  const _CategoryGrid({
    required this.categories,
    required this.total,
    required this.onTap,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return CustomScrollView(
      slivers: [
        // ── Header banner ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kGreen.withValues(alpha: 0.85),
                  kGreenMid.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: kGreen.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dha Anywaa Dictionary',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      '$total words · ${categories.length} categories',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),

        // ── Section label ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'BROWSE BY CATEGORY',
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                  color: c.textSub),
            ),
          ),
        ),

        // ── Grid ───────────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final cat = categories[i];
                final color = _catColor(cat.key, dark);
                return _CategoryCard(
                  cat: cat,
                  color: color,
                  onTap: () => onTap(cat),
                );
              },
              childCount: categories.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final _DictCategory cat;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.cat,
    required this.color,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = widget.color;

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
        child: Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
            boxShadow: const [kShadowSoft],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon chip
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(_catIcon(widget.cat.key), color: color, size: 22),
                ),
                const Spacer(),
                // Label
                Text(
                  widget.cat.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                      height: 1.25),
                ),
                const SizedBox(height: 3),
                // Count pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.cat.count} words',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Word list (inside a category) ─────────────────────────────────────────────

class _WordList extends StatelessWidget {
  final List<_DictWord> words;
  final _DictCategory category;
  final int? expandedIdx;
  final void Function(int) onExpand;
  final bool dark;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;

  const _WordList({
    required this.words,
    required this.category,
    required this.expandedIdx,
    required this.onExpand,
    required this.dark,
    required this.searchCtrl,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = _catColor(category.key, dark);

    return Column(
      children: [
        // ── Category search bar ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: c.textSub, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: onSearch,
                    style: TextStyle(color: c.text, fontSize: 15),
                    decoration: InputDecoration(
                      hintText:
                          'Filter ${category.label.toLowerCase()}…',
                      hintStyle: TextStyle(color: c.textSub),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      searchCtrl.clear();
                      onSearch('');
                    },
                    child: Icon(Icons.close_rounded,
                        color: c.textSub, size: 18),
                  ),
              ],
            ),
          ),
        ),

        // ── Count bar ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 8),
            Text(
              '${words.length} words',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.textSub),
            ),
          ]),
        ),

        // ── Words ──────────────────────────────────────────────────────
        Expanded(
          child: words.isEmpty
              ? Center(
                  child: Text('No words found',
                      style: TextStyle(color: c.textSub)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: words.length,
                  itemBuilder: (_, i) => _WordCard(
                    word: words[i],
                    expanded: expandedIdx == i,
                    onTap: () => onExpand(i),
                    color: color,
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Global search results ─────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final List<_DictWord> words;
  final String query;
  final int? expandedIdx;
  final void Function(int) onExpand;
  final bool dark;

  const _SearchResults({
    required this.words,
    required this.query,
    required this.expandedIdx,
    required this.onExpand,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 48, color: c.textSub),
            const SizedBox(height: 12),
            Text('Type to search all 3,304 words',
                style: TextStyle(color: c.textSub, fontSize: 15)),
          ],
        ),
      );
    }
    if (words.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: c.textSub),
            const SizedBox(height: 12),
            Text('No results for "$query"',
                style: TextStyle(color: c.textSub, fontSize: 15)),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${words.length} results for "$query"',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.textSub),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            itemCount: words.length,
            itemBuilder: (_, i) => _WordCard(
              word: words[i],
              expanded: expandedIdx == i,
              onTap: () => onExpand(i),
              color: _catColor(words[i].cat, dark),
              showCatChip: true,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Word card ─────────────────────────────────────────────────────────────────

class _WordCard extends StatelessWidget {
  final _DictWord word;
  final bool expanded;
  final VoidCallback onTap;
  final Color color;
  final bool showCatChip;

  const _WordCard({
    required this.word,
    required this.expanded,
    required this.onTap,
    required this.color,
    this.showCatChip = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final posColor = _posColor(word.pos);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: expanded ? color.withValues(alpha: 0.5) : c.border,
            width: expanded ? 1.5 : 1.0,
          ),
          boxShadow: const [kShadowSoft],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Main row ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left colour accent bar
                  Container(
                    width: 3,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Anywaa word
                        Text(
                          word.dha,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: c.text,
                              height: 1.2),
                        ),
                        const SizedBox(height: 3),
                        // English
                        Text(
                          word.en,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: color),
                        ),
                        if (word.pron.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            '/${word.pron}/',
                            style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: c.textSub),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // POS badge
                      if (word.pos.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: posColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            word.pos,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: posColor),
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Category chip (global search only)
                      if (showCatChip)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            word.cat.replaceAll('_', ' '),
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: color),
                          ),
                        ),
                      // Expand chevron
                      const SizedBox(height: 4),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: c.textSub,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Expanded details ───────────────────────────────────────
            if (expanded) ...[
              Container(height: 1, color: c.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alternative meanings
                    if (word.alt.isNotEmpty) ...[
                      _detailLabel('Also means'),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: word.alt.map((a) => _chip(a, c)).toList(),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Example sentence
                    if (word.exDha.isNotEmpty) ...[
                      _detailLabel('Example'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: color.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              word.exDha,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: c.text,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4),
                            ),
                            if (word.exEn.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                word.exEn,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: c.textSub,
                                    height: 1.4),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Cultural note
                    if (word.note.isNotEmpty) ...[
                      _detailLabel('Note'),
                      Text(
                        word.note,
                        style: TextStyle(
                            fontSize: 13, color: c.textSub, height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: kTextMuted),
        ),
      );

  Widget _chip(String label, AppColors c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 11, color: c.textSub)),
      );
}
