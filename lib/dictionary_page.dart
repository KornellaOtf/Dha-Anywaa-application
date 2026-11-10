import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dha_anywaaa/theme/app_theme.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class _Word {
  final String dha;
  final String en;
  final String pos;
  final String cat;
  final String pron;
  final String exDha;
  final String exEn;
  final List<String> alt;
  final String note;

  const _Word({
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

  factory _Word.fromJson(Map<String, dynamic> j) => _Word(
        dha:   (j['dha'] ?? '') as String,
        en:    (j['en']  ?? '') as String,
        pos:   (j['pos'] ?? '') as String,
        cat:   (j['cat'] ?? '') as String,
        pron:  (j['pron'] ?? '') as String,
        exDha: (j['ex_dha'] ?? '') as String,
        exEn:  (j['ex_en']  ?? '') as String,
        alt:   ((j['alt'] ?? const []) as List).cast<String>(),
        note:  (j['note'] ?? '') as String,
      );

  bool matches(String q) {
    final lo = q.toLowerCase();
    return dha.toLowerCase().contains(lo) || en.toLowerCase().contains(lo);
  }
}

class _Category {
  final String key;
  final String label;
  final int count;
  final List<_Word> words;

  const _Category({
    required this.key,
    required this.label,
    required this.count,
    required this.words,
  });

  factory _Category.fromJson(Map<String, dynamic> j) => _Category(
        key:   (j['key']   ?? '') as String,
        label: (j['label'] ?? '') as String,
        count: (j['count'] ?? 0) as int,
        words: ((j['words'] ?? const []) as List)
            .map((w) => _Word.fromJson(w as Map<String, dynamic>))
            .toList(),
      );
}

// ── Word emoji icon ───────────────────────────────────────────────────────────
// ── Word icon ─────────────────────────────────────────────────────────────────
// Maps English word/category to a Material icon for the word card header.

IconData _wordIcon(String en, String cat) {
  final w = en.toLowerCase();

  // Word-specific overrides (most specific first)
  const wordMap = <String, IconData>{
    // Body
    'eye': Icons.visibility_rounded,
    'ear': Icons.hearing_rounded,
    'nose': Icons.air_rounded,
    'mouth': Icons.chat_bubble_outline_rounded,
    'hand': Icons.back_hand_rounded,
    'foot': Icons.directions_walk_rounded,
    'head': Icons.face_rounded,
    'hair': Icons.face_retouching_natural_rounded,
    'heart': Icons.favorite_rounded,
    'bone': Icons.healing_rounded,
    'blood': Icons.water_drop_rounded,
    'arm': Icons.sports_handball_rounded,
    'leg': Icons.directions_walk_rounded,
    'finger': Icons.touch_app_rounded,
    'tooth': Icons.sentiment_satisfied_rounded,
    'teeth': Icons.sentiment_satisfied_rounded,
    'tongue': Icons.local_dining_rounded,
    'stomach': Icons.monitor_heart_rounded,
    'chest': Icons.monitor_heart_rounded,
    'shoulder': Icons.accessibility_new_rounded,
    'neck': Icons.accessibility_new_rounded,
    'knee': Icons.accessibility_new_rounded,
    'back': Icons.accessibility_new_rounded,
    'skin': Icons.person_rounded,

    // Nature
    'water': Icons.water_drop_rounded,
    'fire': Icons.local_fire_department_rounded,
    'sun': Icons.wb_sunny_rounded,
    'moon': Icons.nights_stay_rounded,
    'star': Icons.star_rounded,
    'rain': Icons.umbrella_rounded,
    'wind': Icons.air_rounded,
    'cloud': Icons.cloud_rounded,
    'tree': Icons.park_rounded,
    'flower': Icons.local_florist_rounded,
    'grass': Icons.grass_rounded,
    'river': Icons.water_rounded,
    'mountain': Icons.landscape_rounded,
    'sky': Icons.cloud_queue_rounded,
    'earth': Icons.public_rounded,
    'stone': Icons.terrain_rounded,
    'sea': Icons.waves_rounded,
    'lake': Icons.water_rounded,
    'land': Icons.landscape_rounded,

    // Animals
    'cow': Icons.cruelty_free_rounded,
    'goat': Icons.cruelty_free_rounded,
    'sheep': Icons.cruelty_free_rounded,
    'dog': Icons.pets_rounded,
    'cat': Icons.pets_rounded,
    'lion': Icons.pets_rounded,
    'elephant': Icons.pets_rounded,
    'bird': Icons.flutter_dash_rounded,
    'chicken': Icons.egg_rounded,
    'hen': Icons.egg_rounded,
    'fish': Icons.set_meal_rounded,
    'snake': Icons.pest_control_rounded,
    'bee': Icons.bug_report_rounded,
    'ant': Icons.bug_report_rounded,
    'insect': Icons.bug_report_rounded,

    // People & Family
    'man': Icons.person_rounded,
    'woman': Icons.person_rounded,
    'child': Icons.child_care_rounded,
    'boy': Icons.person_rounded,
    'girl': Icons.person_rounded,
    'father': Icons.people_rounded,
    'mother': Icons.people_rounded,
    'brother': Icons.people_rounded,
    'sister': Icons.people_rounded,
    'grandfather': Icons.elderly_rounded,
    'grandmother': Icons.elderly_rounded,
    'family': Icons.family_restroom_rounded,
    'husband': Icons.people_rounded,
    'wife': Icons.people_rounded,
    'friend': Icons.handshake_rounded,
    'baby': Icons.child_care_rounded,

    // Food & Drink
    'food': Icons.restaurant_rounded,
    'eat': Icons.restaurant_rounded,
    'drink': Icons.local_drink_rounded,
    'cook': Icons.soup_kitchen_rounded,
    'milk': Icons.local_drink_rounded,
    'meat': Icons.set_meal_rounded,
    'bread': Icons.bakery_dining_rounded,
    'rice': Icons.rice_bowl_rounded,
    'egg': Icons.egg_rounded,
    'fruit': Icons.eco_rounded,
    'soup': Icons.soup_kitchen_rounded,
    'coffee': Icons.coffee_rounded,
    'tea': Icons.emoji_food_beverage_rounded,

    // House
    'house': Icons.home_rounded,
    'home': Icons.home_rounded,
    'door': Icons.sensor_door_rounded,
    'window': Icons.window_rounded,
    'bed': Icons.bed_rounded,
    'chair': Icons.chair_rounded,
    'table': Icons.table_restaurant_rounded,
    'roof': Icons.roofing_rounded,
    'wall': Icons.foundation_rounded,
    'kitchen': Icons.kitchen_rounded,
    'room': Icons.meeting_room_rounded,
    'garden': Icons.yard_rounded,

    // Education
    'school': Icons.school_rounded,
    'book': Icons.menu_book_rounded,
    'pen': Icons.edit_rounded,
    'pencil': Icons.create_rounded,
    'paper': Icons.description_rounded,
    'teacher': Icons.person_rounded,
    'student': Icons.school_rounded,
    'learn': Icons.auto_stories_rounded,
    'write': Icons.edit_rounded,
    'read': Icons.auto_stories_rounded,
    'number': Icons.tag_rounded,
    'letter': Icons.text_fields_rounded,
    'word': Icons.text_snippet_rounded,
    'language': Icons.translate_rounded,

    // Numbers
    'one': Icons.looks_one_rounded,
    'two': Icons.looks_two_rounded,
    'three': Icons.looks_3_rounded,
    'four': Icons.looks_4_rounded,
    'five': Icons.looks_5_rounded,
    'six': Icons.looks_6_rounded,
    'zero': Icons.exposure_zero_rounded,

    // Time
    'morning': Icons.wb_twilight_rounded,
    'evening': Icons.nights_stay_rounded,
    'night': Icons.bedtime_rounded,
    'day': Icons.wb_sunny_rounded,
    'today': Icons.today_rounded,
    'week': Icons.view_week_rounded,
    'month': Icons.calendar_month_rounded,
    'year': Icons.calendar_today_rounded,
    'time': Icons.access_time_rounded,
    'hour': Icons.schedule_rounded,
    'monday': Icons.today_rounded,
    'tuesday': Icons.today_rounded,
    'wednesday': Icons.today_rounded,
    'thursday': Icons.today_rounded,
    'friday': Icons.today_rounded,
    'saturday': Icons.today_rounded,
    'sunday': Icons.today_rounded,

    // Colors
    'red': Icons.circle_rounded,
    'blue': Icons.circle_rounded,
    'green': Icons.circle_rounded,
    'yellow': Icons.circle_rounded,
    'white': Icons.circle_outlined,
    'black': Icons.circle_rounded,
    'color': Icons.palette_rounded,
    'colour': Icons.palette_rounded,

    // Actions / Verbs
    'walk': Icons.directions_walk_rounded,
    'run': Icons.directions_run_rounded,
    'sit': Icons.chair_rounded,
    'stand': Icons.accessibility_rounded,
    'sleep': Icons.bedtime_rounded,
    'talk': Icons.chat_rounded,
    'listen': Icons.hearing_rounded,
    'see': Icons.visibility_rounded,
    'hear': Icons.hearing_rounded,
    'cry': Icons.sentiment_very_dissatisfied_rounded,
    'laugh': Icons.sentiment_very_satisfied_rounded,
    'sing': Icons.music_note_rounded,
    'dance': Icons.music_note_rounded,
    'pray': Icons.self_improvement_rounded,
    'work': Icons.work_rounded,
    'play': Icons.sports_esports_rounded,
    'fight': Icons.sports_mma_rounded,
    'love': Icons.favorite_rounded,
    'hate': Icons.heart_broken_rounded,
    'help': Icons.handshake_rounded,
    'give': Icons.card_giftcard_rounded,
    'carry': Icons.fitness_center_rounded,
    'build': Icons.construction_rounded,
    'die': Icons.ac_unit_rounded,
    'born': Icons.child_care_rounded,
    'grow': Icons.trending_up_rounded,
    'know': Icons.psychology_rounded,

    // Adjectives
    'good': Icons.thumb_up_rounded,
    'bad': Icons.thumb_down_rounded,
    'big': Icons.open_in_full_rounded,
    'small': Icons.close_fullscreen_rounded,
    'hot': Icons.thermostat_rounded,
    'cold': Icons.ac_unit_rounded,
    'fast': Icons.speed_rounded,
    'slow': Icons.hourglass_bottom_rounded,
    'strong': Icons.fitness_center_rounded,
    'old': Icons.elderly_rounded,
    'new': Icons.new_releases_rounded,
    'clean': Icons.cleaning_services_rounded,
    'happy': Icons.sentiment_very_satisfied_rounded,
    'sad': Icons.sentiment_very_dissatisfied_rounded,
    'angry': Icons.mood_bad_rounded,
    'afraid': Icons.warning_rounded,
    'tired': Icons.hotel_rounded,
    'beautiful': Icons.auto_awesome_rounded,

    // Professions
    'doctor': Icons.medical_services_rounded,
    'nurse': Icons.local_hospital_rounded,
    'farmer': Icons.agriculture_rounded,
    'soldier': Icons.military_tech_rounded,
    'chief': Icons.star_rounded,
    'king': Icons.emoji_events_rounded,
    'judge': Icons.gavel_rounded,
    'driver': Icons.drive_eta_rounded,
    'builder': Icons.engineering_rounded,
    'teacher prof': Icons.school_rounded,
    'priest': Icons.church_rounded,

    // Transport
    'car': Icons.directions_car_rounded,
    'boat': Icons.directions_boat_rounded,
    'plane': Icons.flight_rounded,
    'bicycle': Icons.pedal_bike_rounded,
    'road': Icons.add_road_rounded,
    'bridge': Icons.settings_ethernet_rounded,

    // Tech & Communication
    'phone': Icons.phone_android_rounded,
    'radio': Icons.radio_rounded,
    'television': Icons.tv_rounded,
    'computer': Icons.computer_rounded,
    'money': Icons.attach_money_rounded,
    'market': Icons.storefront_rounded,
    'shop': Icons.store_rounded,
    'price': Icons.sell_rounded,

    // Misc
    'god': Icons.self_improvement_rounded,
    'church': Icons.church_rounded,
    'war': Icons.gavel_rounded,
    'peace': Icons.handshake_rounded,
    'government': Icons.account_balance_rounded,
    'law': Icons.balance_rounded,
    'hello': Icons.waving_hand_rounded,
    'goodbye': Icons.waving_hand_rounded,
    'yes': Icons.check_circle_rounded,
    'no': Icons.cancel_rounded,
    'name': Icons.badge_rounded,
  };

  // Check exact then prefix
  if (wordMap.containsKey(w)) return wordMap[w]!;
  for (final e in wordMap.entries) {
    if (w.startsWith(e.key)) return e.value;
  }

  // Category fallback
  return _catIcon(cat);
}

// ── Category colour ───────────────────────────────────────────────────────────

Color _catColor(String key) {
  const colors = [
    kGold, kRust, kGreen, kGreenMid,

    Color(0xFF7C6AF7), Color(0xFFE05C97),
    Color(0xFF3BA5C8), Color(0xFFE08B2A),
    Color(0xFF4CAF50), Color(0xFFFF5722),
    Color(0xFF9C27B0), Color(0xFF2196F3),
  ];
  final idx = key.codeUnits.fold(0, (a, b) => a + b) % colors.length;
  return colors[idx];
}

// ── POS colour ────────────────────────────────────────────────────────────────

Color _posColor(String pos) {
  switch (pos.toLowerCase()) {
    case 'noun':      return kGreen;
    case 'verb':      return kRust;
    case 'adjective': return kGold;
    case 'adverb':    return const Color(0xFF3BA5C8);
    case 'pronoun':   return const Color(0xFF7C6AF7);
    case 'phrase':    return kGreenMid;
    default:          return kTextMuted;
  }
}

// ── Category icon ─────────────────────────────────────────────────────────────

IconData _catIcon(String key) {
  const m = <String, IconData>{
    'greetings': Icons.waving_hand_rounded,
    'family': Icons.people_rounded,
    'body_parts': Icons.accessibility_new_rounded,
    'body': Icons.accessibility_new_rounded,
    'food_drink': Icons.restaurant_rounded,
    'food': Icons.restaurant_rounded,
    'animals': Icons.pets_rounded,
    'animals_mammals': Icons.pets_rounded,
    'animals_fish': Icons.set_meal_rounded,
    'animals_reptiles': Icons.pest_control_rounded,
    'birds': Icons.flutter_dash_rounded,
    'insects': Icons.bug_report_rounded,
    'nature': Icons.eco_rounded,
    'nature_geography': Icons.landscape_rounded,
    'plants_trees': Icons.park_rounded,
    'weather_climate': Icons.wb_sunny_rounded,
    'celestial': Icons.nights_stay_rounded,
    'numbers': Icons.tag_rounded,
    'ordinal_numbers': Icons.format_list_numbered_rounded,
    'math': Icons.calculate_rounded,
    'colors': Icons.palette_rounded,
    'time': Icons.access_time_rounded,
    'days_of_week': Icons.calendar_today_rounded,
    'directions': Icons.explore_rounded,
    'verbs': Icons.bolt_rounded,
    'verbs_actions': Icons.bolt_rounded,
    'adjectives': Icons.star_rounded,
    'adverbs': Icons.speed_rounded,
    'pronouns': Icons.person_rounded,
    'possessive_pronouns': Icons.person_rounded,
    'conjunctions_prepositions': Icons.link_rounded,
    'interjections': Icons.chat_rounded,
    'interrogatives': Icons.help_rounded,
    'question_words': Icons.help_outline_rounded,
    'question_phrases': Icons.help_outline_rounded,
    'phrases': Icons.format_quote_rounded,
    'grammar': Icons.school_rounded,
    'education': Icons.school_rounded,
    'health_medical': Icons.local_hospital_rounded,
    'emotions': Icons.sentiment_satisfied_rounded,
    'feelings_sensations': Icons.favorite_rounded,
    'culture': Icons.theater_comedy_rounded,
    'spiritual_cultural': Icons.auto_awesome_rounded,
    'music_arts': Icons.music_note_rounded,
    'sports_games': Icons.sports_soccer_rounded,
    'professions': Icons.work_rounded,
    'household': Icons.home_rounded,
    'household_items': Icons.home_rounded,
    'house_building': Icons.house_rounded,
    'kitchen_utensils': Icons.kitchen_rounded,
    'clothing': Icons.checkroom_rounded,
    'materials': Icons.texture_rounded,
    'tools': Icons.handyman_rounded,
    'transport': Icons.directions_car_rounded,
    'technology': Icons.devices_rounded,
    'communication': Icons.forum_rounded,
    'economics': Icons.attach_money_rounded,
    'politics_government': Icons.account_balance_rounded,
    'market': Icons.storefront_rounded,
    'taste_cooking': Icons.soup_kitchen_rounded,
    'identity': Icons.badge_rounded,
    'navigation': Icons.map_rounded,
  };
  return m[key] ?? Icons.book_rounded;
}

// ── Page ──────────────────────────────────────────────────────────────────────

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  List<_Category> _categories = [];
  int _total = 0;
  bool _loaded = false;

  _Category? _currentCat;
  String _search = '';
  bool _searching = false;
  int? _expandedIdx;

  final _searchCtrl = TextEditingController();

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
        .map((c) => _Category.fromJson(c as Map<String, dynamic>))
        .toList();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _total = (map['total'] ?? 0) as int;
      _loaded = true;
    });
  }

  List<_Word> get _allWords => _categories.expand((c) => c.words).toList();

  List<_Word> get _searchResults {
    final q = _search.trim();
    if (q.isEmpty) return [];
    return _allWords.where((w) => w.matches(q)).toList();
  }

  List<_Word> get _catWords {
    final cat = _currentCat;
    if (cat == null) return [];
    final q = _search.trim();
    if (q.isEmpty) return cat.words;
    return cat.words.where((w) => w.matches(q)).toList();
  }

  void _openCat(_Category cat) => setState(() {
        _currentCat = cat;
        _search = '';
        _searchCtrl.clear();
        _expandedIdx = null;
        _searching = false;
      });

  void _back() => setState(() {
        _currentCat = null;
        _search = '';
        _searchCtrl.clear();
        _expandedIdx = null;
        _searching = false;
      });

  void _startSearch() => setState(() {
        _searching = true;
        _currentCat = null;
        _expandedIdx = null;
      });

  void _stopSearch() => setState(() {
        _searching = false;
        _search = '';
        _searchCtrl.clear();
        _expandedIdx = null;
      });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _currentCat != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _back,
              )
            : _searching
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: _stopSearch,
                  )
                : null,
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: 'Search ${_total.toString()} words…',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() {
                  _search = v;
                  _expandedIdx = null;
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
              onPressed: _startSearch,
            ),
        ],
      ),
      body: !_loaded
          ? Center(child: CircularProgressIndicator(color: c.accent))
          : _searching
              ? _buildSearchResults()
              : _currentCat == null
                  ? _buildCategoryGrid()
                  : _buildWordList(),
    );
  }

  // ── Category grid ─────────────────────────────────────────────────────────

  Widget _buildCategoryGrid() {
    final c = context.c;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kGreen, kGreenMid],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Dha Anywaa Dictionary',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('$_total words · ${_categories.length} categories',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12)),
              ]),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _CategoryTile(
                cat: _categories[i],
                color: _catColor(_categories[i].key),
                onTap: () => _openCat(_categories[i]),
              ),
              childCount: _categories.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ── Word list ─────────────────────────────────────────────────────────────

  Widget _buildWordList() {
    final c = context.c;
    final cat = _currentCat!;
    final color = _catColor(cat.key);
    final words = _catWords;

    return Column(children: [
      // Filter bar
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Icon(Icons.search_rounded, color: c.textSub, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() {
                  _search = v;
                  _expandedIdx = null;
                }),
                style: TextStyle(color: c.text, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Filter ${cat.label.toLowerCase()}…',
                  hintStyle: TextStyle(color: c.textSub),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_search.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() { _search = ''; _expandedIdx = null; });
                },
                child: Icon(Icons.close_rounded, color: c.textSub, size: 18),
              ),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Row(children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: color,
                  borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          Text('${words.length} words',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: c.textSub)),
        ]),
      ),
      Expanded(
        child: words.isEmpty
            ? Center(child: Text('No words found',
                style: TextStyle(color: c.textSub)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                itemCount: words.length,
                itemBuilder: (_, i) => _WordCard(
                  word: words[i],
                  color: color,
                  expanded: _expandedIdx == i,
                  onTap: () => setState(() =>
                      _expandedIdx = _expandedIdx == i ? null : i),
                ),
              ),
      ),
    ]);
  }

  // ── Search results ────────────────────────────────────────────────────────

  Widget _buildSearchResults() {
    final c = context.c;
    final words = _searchResults;
    final q = _search.trim();

    if (q.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_rounded, size: 52, color: c.textSub),
        const SizedBox(height: 12),
        Text('Type to search all $_total words',
            style: TextStyle(color: c.textSub, fontSize: 15)),
      ]));
    }
    if (words.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off_rounded, size: 52, color: c.textSub),
        const SizedBox(height: 12),
        Text('No results for "$q"',
            style: TextStyle(color: c.textSub, fontSize: 15)),
      ]));
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Align(alignment: Alignment.centerLeft,
            child: Text('${words.length} results for "$q"',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: c.textSub))),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          itemCount: words.length,
          itemBuilder: (_, i) => _WordCard(
            word: words[i],
            color: _catColor(words[i].cat),
            expanded: _expandedIdx == i,
            onTap: () => setState(() =>
                _expandedIdx = _expandedIdx == i ? null : i),
            showCat: true,
          ),
        ),
      ),
    ]);
  }
}

// ── Category tile ─────────────────────────────────────────────────────────────

class _CategoryTile extends StatefulWidget {
  final _Category cat;
  final Color color;
  final VoidCallback onTap;
  const _CategoryTile({required this.cat, required this.color, required this.onTap});

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = widget.color;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
            boxShadow: const [kShadowSoft],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_catIcon(widget.cat.key), color: color, size: 22),
            ),
            const Spacer(),
            Text(widget.cat.label,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: c.text, height: 1.25)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${widget.cat.count} words',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: color)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Word card ─────────────────────────────────────────────────────────────────

class _WordCard extends StatelessWidget {
  final _Word word;
  final Color color;
  final bool expanded;
  final VoidCallback onTap;
  final bool showCat;

  const _WordCard({
    required this.word,
    required this.color,
    required this.expanded,
    required this.onTap,
    this.showCat = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final posCol = _posColor(word.pos);
    final wordIcon = _wordIcon(word.en, word.cat);
    final hasDetail = word.exDha.isNotEmpty || word.alt.isNotEmpty || word.note.isNotEmpty;

    return GestureDetector(
      onTap: hasDetail ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: expanded ? color.withValues(alpha: 0.6) : c.border,
            width: expanded ? 1.5 : 1.0,
          ),
          boxShadow: const [kShadowSoft],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Main row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // Icon bubble
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(wordIcon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              // Words
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Anywaa word
                  Text(word.dha,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: c.text,
                          height: 1.2)),
                  const SizedBox(height: 2),
                  // English
                  Text(word.en,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: color)),
                  if (word.pron.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('/${word.pron}/',
                        style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: c.textSub)),
                  ],
                ]),
              ),
              // Right side: POS badge + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (word.pos.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: posCol.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(word.pos,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: posCol)),
                    ),
                  if (showCat) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        word.cat.replaceAll('_', ' '),
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: color),
                      ),
                    ),
                  ],
                  if (hasDetail) ...[
                    const SizedBox(height: 4),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: c.textSub, size: 18,
                    ),
                  ],
                ],
              ),
            ]),
          ),

          // ── Expanded detail ──────────────────────────────────────────────
          if (expanded && hasDetail) ...[
            Divider(height: 1, color: c.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (word.alt.isNotEmpty) ...[
                  _label('Also means'),
                  Wrap(spacing: 6, runSpacing: 6,
                      children: word.alt
                          .map((a) => _chip(a, c))
                          .toList()),
                  const SizedBox(height: 10),
                ],
                if (word.exDha.isNotEmpty) ...[
                  _label('Example'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.15)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(word.exDha,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              color: c.text, height: 1.5)),
                      if (word.exEn.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(word.exEn,
                            style: TextStyle(
                                fontSize: 12,
                                color: c.textSub, height: 1.4)),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 10),
                ],
                if (word.note.isNotEmpty) ...[
                  _label('Note'),
                  Text(word.note,
                      style: TextStyle(
                          fontSize: 12, color: c.textSub, height: 1.5)),
                ],
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                fontSize: 9,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w700,
                color: kTextMuted)),
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
