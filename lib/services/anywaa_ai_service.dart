import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;

/// One dictionary entry loaded from the bundled local data.
class DictEntry {
  final String en;   // English word
  final String dha;  // Dha Anywaa term (may contain comma separated synonyms)
  final String defs; // English definition
  final List<String> syn; // split synonyms

  const DictEntry({
    required this.en,
    required this.dha,
    required this.defs,
    required this.syn,
  });

  factory DictEntry.fromJson(Map<String, dynamic> j) => DictEntry(
        en: (j['en'] ?? '') as String,
        dha: (j['dha'] ?? '') as String,
        defs: (j['defs'] ?? '') as String,
        syn: ((j['syn'] ?? const []) as List).cast<String>(),
      );
}

/// A single matched dictionary entry with the score that produced it.
class AnywaaMatch {
  final DictEntry entry;
  final double score;
  final String source; // 'en' matched on English side, 'dha' on Anywaa side
  const AnywaaMatch(this.entry, this.score, this.source);
}

/// The assistant's reply to a query.
class AnywaaAnswer {
  final String text;               // short natural-language reply
  final List<AnywaaMatch> matches; // grounded entries (empty if none)
  final List<String> suggestions;  // near words when nothing was found
  bool get found => matches.isNotEmpty;
  const AnywaaAnswer({
    required this.text,
    required this.matches,
    this.suggestions = const [],
  });
}

/// A fully offline "Anywaa AI" assistant. It answers only from the local
/// dictionary bundled in `assets/data/anywaa_dictionary.json`. No network,
/// no model download, nothing leaves the device. It is grounded: it never
/// invents a translation; if a word is not in the data it says so.
class AnywaaAiService {
  AnywaaAiService._();
  static final AnywaaAiService instance = AnywaaAiService._();

  static const String _asset = 'assets/data/anywaa_dictionary.json';

  List<DictEntry> _words = const [];
  bool get ready => _words.isNotEmpty;
  int get wordCount => _words.length;

  /// The entry from the last successful lookup. Short follow-ups resolve
  /// against it so the chat behaves like a conversation. Cleared by [newChat].
  _Context? _last;

  /// Forgets the current conversational subject (start a fresh thread).
  void newChat() => _last = null;

  // ── Dynamic hero suggestions ───────────────────────────────────────────────
  static const _enAskTemplates = [
    'How do you say %s in Dha Anywaa?',
    'Translate %s to Anywaa',
    'How do you say %s?',
    'What is %s in Dha Anywaa?',
  ];
  static const _dhaAskTemplates = [
    'What does %s mean?',
    'Meaning of %s',
  ];

  /// A fresh, shuffled set of example questions drawn from the real bundled
  /// dictionary. It mixes English->Dha lookups, Dha->English lookups and a
  /// number so every call (and every 10s rotation) shows different prompts that
  /// are always answerable, because they are built from entries that exist.
  List<String> sampleQuestions({int count = 6, math.Random? rng}) {
    if (!ready) return const [];
    final r = rng ?? math.Random();
    // English labels: strip any parenthetical, keep short single/two-word ones.
    final enLabels = _words
        .map((e) => e.en.split('(').first.trim())
        .where(_cleanEnglishLabel)
        .toSet()
        .toList();
    final dhaLabels = _words
        .map((e) => e.dha.trim())
        .where(_cleanDhaLabel)
        .toSet()
        .toList();

    final out = <String>[];
    void addFrom(List<String> pool, List<String> templates) {
      if (pool.isEmpty) return;
      final w = pool[r.nextInt(pool.length)];
      out.add(templates[r.nextInt(templates.length)].replaceAll('%s', w));
    }

    // Balanced mix: 2 English, 2 Dha, 1 number, then top up randomly.
    for (var i = 0; i < 2; i++) {
      addFrom(enLabels, _enAskTemplates);
    }
    for (var i = 0; i < 2; i++) {
      addFrom(dhaLabels, _dhaAskTemplates);
    }
    out.add('Say ${1 + r.nextInt(9998)} in Dha Anywaa');
    while (out.length < count) {
      addFrom(r.nextBool() ? enLabels : dhaLabels,
          r.nextBool() ? _enAskTemplates : _dhaAskTemplates);
    }

    out.shuffle(r);
    final seen = <String>{};
    final dedup = <String>[];
    for (final q in out) {
      if (seen.add(q)) dedup.add(q);
    }
    return dedup.take(count).toList();
  }

  static bool _cleanEnglishLabel(String s) {
    final t = s.trim();
    if (t.isEmpty || t.length > 16) return false;
    if (t.contains('(') || t.contains(')') || t.contains(',')) return false;
    final words = t.split(RegExp(r'\s+'));
    if (words.length > 2) return false;
    return words.every((w) => RegExp("^[A-Za-z']+\$").hasMatch(w));
  }

  static bool _cleanDhaLabel(String s) {
    final t = s.trim();
    if (t.isEmpty || t.length > 14) return false;
    if (t.contains('(') || t.contains(')') || t.contains(',') || t.contains('.')) {
      return false;
    }
    return t.split(' ').length <= 2;
  }

  /// Loads the bundled dictionary once. Safe to call repeatedly.
  Future<void> load() async {
    if (ready) return;
    final raw = await rootBundle.loadString(_asset);
    final map = json.decode(raw) as Map<String, dynamic>;
    _words = ((map['words'] ?? const []) as List)
        .map((e) => DictEntry.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  // ── Text normalisation ──────────────────────────────────────────────────
  static const _foldMap = {
    'ä': 'a', 'ë': 'e', 'ï': 'i', 'ö': 'o', 'ø': 'o',
    'à': 'a', 'è': 'e', 'ù': 'u', 'â': 'a', 'ê': 'e', 'î': 'i',
    'ô': 'o', 'û': 'u', 'ç': 'c', 'ñ': 'n',
  };

  /// Lowercase, strip accents and punctuation, collapse whitespace.
  static String fold(String s) {
    var t = s.toLowerCase();
    _foldMap.forEach((k, v) => t = t.replaceAll(k, v));
    t = t.replaceAll(RegExp(r"[^a-z0-9\s']"), ' ');
    return t.replaceAll(RegExp(r"\s+"), ' ').trim();
  }

  // Words that are phrasing, not the target term.
  static const _stop = {
    'how', 'do', 'you', 'i', 'we', 'they', 'say', 'spell', 'in', 'into',
    'english', 'anywaa', 'anuak', 'dha', 'the', 'a', 'an', 'word', 'words',
    'what', 'is', 'are', 'means', 'meaning', 'of', 'to', 'for', 'please',
    'can', 'tell', 'me', 'this', 'that', 'translate', 'translation', 'call',
    'called', 'would', 'will', 'did', 'does',
  };

  /// Extracts the meaningful search terms and a direction hint from a query.
  _Parsed _parse(String query) {
    final folded = fold(query);
    final tokens = folded.split(' ').where((t) => t.isNotEmpty).toList();

    // Direction: asking for English means the input is an Anywaa word.
    final wantsEnglish = folded.contains('english');
    final wantsAnywaa =
        folded.contains('anywaa') || folded.contains('anuak') || folded.contains('dha');

    final core = tokens.where((t) => !_stop.contains(t)).toList();
    return _Parsed(
      raw: folded,
      core: core,
      corePhrase: core.join(' '),
      wantsEnglish: wantsEnglish && !wantsAnywaa,
      wantsAnywaa: wantsAnywaa && !wantsEnglish,
    );
  }

  /// The single entry point: give it a user question, get a grounded answer.
  AnywaaAnswer answer(String query) {
    if (!ready) {
      return const AnywaaAnswer(
        text: 'The Anywaa word data is still loading. Try again in a moment.',
        matches: [],
      );
    }
    final p = _parse(query);

    // Follow-ups resolve against the last looked-up entry first, so the chat
    // reads as a conversation. Returns null for a fresh question.
    final follow = _followUp(p);
    if (follow != null) return follow;

    // Conversational intents (identity, capability, origin, bare greeting)
    // run next so they read like a chat, not a failed lookup.
    final intent = _intent(p);
    if (intent != null) return intent;

    // Numbers are generated from the taught rules (grounded, deterministic).
    final number = _numberAnswer(p);
    if (number != null) return number;

    final term = p.corePhrase.isEmpty ? p.raw : p.corePhrase;
    if (term.isEmpty) {
      return const AnywaaAnswer(
        text: 'Ask me about a word, for example: "how do you say water in '
            'Dha Anywaa" or "what does Wich mean".',
        matches: [],
      );
    }

    // Dictionary first; the taught memory (numbers) was handled above.
    return _translate(term, p);
  }

  /// Runs a dictionary lookup and, on a hit, remembers the entry as the current
  /// conversational subject so short follow-ups can resolve against it.
  AnywaaAnswer _translate(String term, _Parsed p) {
    final matches = _lookup(term, p);
    if (matches.isEmpty) {
      final sugg = _suggest(term, p);
      final buf = StringBuffer(
          'I looked through the local Anywaa dictionary on your device, but '
          'I could not find "$term".');
      if (sugg.isNotEmpty) {
        buf.write(' Did you mean: ${sugg.take(5).join(', ')}?');
      } else {
        buf.write(' Try asking about a single word in English or Dha Anywaa.');
      }
      return AnywaaAnswer(text: buf.toString(), matches: [], suggestions: sugg);
    }
    final text = _compose(matches, p);
    _last = _Context(
      match: matches.first,
      matches: matches,
      toEnglish: _direction(matches.first, p),
      replyText: text,
    );
    return AnywaaAnswer(text: text, matches: matches);
  }

  /// Which way the user is asking: true = give the English meaning.
  bool _direction(AnywaaMatch top, _Parsed p) {
    if (p.wantsEnglish) return true;
    if (p.wantsAnywaa) return false;
    // No explicit hint: a hit on the Anywaa side means they want English, and a
    // hit on the English side means they want the Dha word.
    return top.source == 'dha';
  }

  // ── Matching ────────────────────────────────────────────────────────────────

  List<AnywaaMatch> _lookup(String term, _Parsed p) {
    final q = fold(term);
    final qTokens = q.split(' ').where((t) => t.isNotEmpty).toList();
    final rawTokens = p.raw.split(' ').where((t) => t.isNotEmpty).toList();
    final scored = <AnywaaMatch>[];

    for (final e in _words) {
      double best = 0;
      String src = p.wantsEnglish ? 'dha' : 'en';

      // 1. Whole-word, stem, prefix and typo tolerance on each side.
      void consider(String hay, String side) {
        if (hay.isEmpty) return;
        final hayTokens = hay.split(' ');
        double s = 0;
        if (hay == q) {
          s = 3; // whole string exact
        } else {
          // Compare on word boundaries only. This stops a short term like
          // "here" from matching inside "nothinghere".
          for (final qt in qTokens) {
            for (final ht in hayTokens) {
              double t = 0;
              if (qt == ht) {
                t = 2.4; // same whole word
              } else if (qt.length > 3 &&
                  ht.length > 3 &&
                  _stem(qt) == _stem(ht)) {
                t = 2.2; // same word, different plural form
              } else if (qt.length >= 4 &&
                  ht.length >= 4 &&
                  (qt.startsWith(ht) || ht.startsWith(qt))) {
                t = 1.5; // partial typing of a longer word
              } else if (_isClose(qt, ht)) {
                t = 1.4; // typo of a real word
              }
              if (t > s) s = t;
            }
          }
        }
        if (s > best) {
          best = s;
          src = side;
        }
      }

      consider(fold(e.en), 'en');
      // also score each synonym on the Anywaa side
      for (final s in (e.syn.isEmpty ? [e.dha] : e.syn)) {
        consider(fold(s), 'dha');
      }

      // 2. Phrase containment: a multi-word key found as a contiguous run in
      //    the raw question. This lets "how do you say how are you in Dha
      //    Anywaa" still resolve, even though its content words are all stop
      //    words that the core parser strips away.
      final phrase = _phraseScore([fold(e.en), ...e.syn.map(fold)], rawTokens);
      if (phrase > best) {
        best = phrase;
        src = 'en';
      }

      if (best >= 0.8) scored.add(AnywaaMatch(e, best, src));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(6).toList();
  }

  /// Highest score for any multi-word key appearing contiguously in the query.
  /// Longer keys are more specific, so they rank higher.
  double _phraseScore(List<String> keys, List<String> queryTokens) {
    double best = 0;
    for (final key in keys) {
      final kt = key.split(' ').where((t) => t.isNotEmpty).toList();
      if (kt.length < 2) continue; // single words are handled by token matching
      if (_isContiguous(kt, queryTokens)) {
        final s = 2.6 + 0.2 * kt.length;
        if (s > best) best = s;
      }
    }
    return best;
  }

  static bool _isContiguous(List<String> needle, List<String> hay) {
    if (needle.length > hay.length) return false;
    for (var i = 0; i <= hay.length - needle.length; i++) {
      var ok = true;
      for (var j = 0; j < needle.length; j++) {
        if (hay[i + j] != needle[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }

  /// Typo tolerance. The length floor (min 5) stops short fragments matching by
  /// accident, which is what keeps unknown words refused rather than guessed.
  static bool _isClose(String a, String b) {
    if (a.length < 5 || b.length < 5) return false;
    final max = (a.length >= 7 || b.length >= 7) ? 2 : 1;
    return _editDistance(a, b) <= max;
  }

  static int _editDistance(String a, String b) {
    final m = a.length, n = b.length;
    if ((m - n).abs() > 2) return 99; // cheap reject
    var prev = List<int>.generate(n + 1, (i) => i);
    var cur = List<int>.filled(n + 1, 0);
    for (var i = 1; i <= m; i++) {
      cur[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        cur[j] = _min3(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost);
      }
      final tmp = prev;
      prev = cur;
      cur = tmp;
    }
    return prev[n];
  }

  static int _min3(int a, int b, int c) {
    var m = a;
    if (b < m) m = b;
    if (c < m) m = c;
    return m;
  }

  /// Very light English stemming, just enough to bridge plural forms.
  static String _stem(String t) {
    if (t.length > 4 && t.endsWith('ies')) {
      return '${t.substring(0, t.length - 3)}y';
    }
    if (t.length > 3 &&
        t.endsWith('s') &&
        !t.endsWith('ss') &&
        !t.endsWith('us')) {
      return t.substring(0, t.length - 1);
    }
    return t;
  }

  List<String> _suggest(String term, _Parsed p) {
    final qTokens =
        (p.core.isEmpty ? fold(term) : p.core.join(' '))
            .split(' ')
            .where((t) => t.length >= 3)
            .toList();
    if (qTokens.isEmpty) return const [];
    final best = <String, int>{};
    for (final e in _words) {
      final cands = <String>[fold(e.en), fold(e.dha)];
      var minDist = 99;
      for (final qt in qTokens) {
        for (final cand in cands) {
          for (final ct in cand.split(' ')) {
            if (ct.length < 3) continue;
            final d = _editDistance(qt, ct);
            if (d < minDist) minDist = d;
          }
        }
      }
      if (minDist <= 2) best[e.en] = minDist;
    }
    final entries = best.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries.map((e) => e.key).take(5).toList();
  }

  // ── Conversational follow-ups ──────────────────────────────────────────────

  /// Resolves short follow-up questions against the last looked-up entry.
  /// Returns null when the query is a fresh question, so the caller continues
  /// through intents, numbers and a normal dictionary lookup.
  AnywaaAnswer? _followUp(_Parsed p) {
    final raw = p.raw;
    bool has(String s) => raw.contains(s);

    final isPlural = has('plural');
    final isPossessive = has('possessive');
    final isRepeat = has('again') || has('repeat') || has('once more');
    final isExample = has('example') || has('in a sentence') || has('use it');
    final isMeaning = has('it mean') || has('its meaning') ||
        has('meaning of it') || has('what does it mean');
    final isAbout = has('what about') || has('how about');
    // "and <word>" is a follow-up only when it is not one of the specific
    // field questions above (those also begin with "and the").
    final isAndWord = raw.startsWith('and ') && !isPlural && !isPossessive;

    final needsSubject = isPlural || isPossessive || isRepeat ||
        isExample || isMeaning;
    if (needsSubject && _last == null) {
      return const AnywaaAnswer(
        text: 'Which word do you mean? Ask me about a word first, then you '
            'can follow up on it.',
        matches: [],
      );
    }

    if (isPlural) return _fieldFallback('plural');
    if (isPossessive) return _fieldFallback('possessive');
    if (isRepeat) return _repeatLast();
    if (isExample) {
      return const AnywaaAnswer(
        text: "I don't have an example sentence for that word yet.",
        matches: [],
      );
    }
    if (isMeaning) return _meaning();

    if (isAbout || isAndWord) {
      final term = _extractTerm(raw, isAbout: isAbout);
      if (term.isEmpty) return null; // fall through as a normal query
      // A new lookup asked in the same direction as the previous one.
      final p2 = _Parsed(
        raw: term,
        core: term.split(' '),
        corePhrase: term,
        wantsEnglish: _last?.toEnglish == true,
        wantsAnywaa: _last != null && _last!.toEnglish == false,
      );
      return _translate(term, p2);
    }
    return null;
  }

  /// The data has no plural or possessive field, and we never invent one, so
  /// report the gap honestly while re-grounding on the base word we do have.
  AnywaaAnswer _fieldFallback(String field) {
    final c = _last!;
    final en = c.match.entry.en;
    final dha = c.match.entry.dha;
    return AnywaaAnswer(
      text: 'I don\'t have a separate $field form for "$en" in the local '
          'dictionary. Its base Dha Anywaa word is $dha.',
      matches: const [],
    );
  }

  AnywaaAnswer _repeatLast() {
    final c = _last!;
    // There is no per-word audio in the local data, so "say it again" repeats
    // the last translation verbatim rather than inventing a recording.
    return AnywaaAnswer(text: c.replyText, matches: c.matches);
  }

  AnywaaAnswer _meaning() {
    final c = _last!;
    final defs = c.match.entry.defs.trim();
    if (defs.isEmpty) {
      return const AnywaaAnswer(
        text: "I don't have a stored meaning for that word yet.",
        matches: [],
      );
    }
    return AnywaaAnswer(
      text: '"${c.match.entry.dha}" means $defs',
      matches: [c.match],
    );
  }

  String _extractTerm(String raw, {required bool isAbout}) {
    var s = raw;
    if (isAbout) {
      final i = s.indexOf('about');
      if (i >= 0) s = s.substring(i + 'about'.length);
    } else if (s.startsWith('and ')) {
      s = s.substring(4);
    }
    return fold(s).trim();
  }

  String _compose(List<AnywaaMatch> m, _Parsed p) {
    final top = m.first;
    final en = top.entry.en;
    final dha = top.entry.dha;

    // Work out which way the user is asking, then phrase it like a helpful
    // assistant instead of a dictionary line. The pick is deterministic (seeded
    // by the question) so it adds variety without ever changing the answer.
    final toEnglish = _direction(top, p);

    final toDha = [
      'Sure! The Dha Anywaa word for "$en" is $dha.',
      'In Dha Anywaa, "$en" is $dha.',
      'You can say $dha in Dha Anywaa for "$en".',
      'Good question! "$en" becomes $dha in Dha Anywaa.',
    ];
    final toEng = [
      'Sure! "$dha" means "$en" in English.',
      'That one means "$en" in English.',
      '"$dha" translates to "$en" in English.',
      'In English, "$dha" means "$en".',
    ];
    final opts = toEnglish ? toEng : toDha;
    return opts[_pick(p.raw, opts.length)];
  }

  /// Stable hash so the same question always gets the same friendly wording.
  static int _pick(String seed, int n) {
    var h = 0;
    for (final cu in seed.codeUnits) {
      h = (h * 31 + cu) & 0x7fffffff;
    }
    return h % n;
  }

  // ── Conversational intents ──────────────────────────────────────────────
  AnywaaAnswer? _intent(_Parsed p) {
    final raw = p.raw;
    bool has(String s) => raw.contains(s);
    if (has('who are you') || has('what are you') || has('your name')) {
      return const AnywaaAnswer(
        text: "I'm Anywaa AI, your offline Dha Anywaa helper. I answer using "
            'words stored right here on your device, so I never guess or make '
            'up a translation.',
        matches: [],
      );
    }
    if (has('where are you from') || has('where do you come')) {
      return const AnywaaAnswer(
        text: 'I live entirely on your device, made for the Anywaa community '
            'along the rivers of South Sudan and Ethiopia. No internet needed, '
            'and nothing ever leaves your phone.',
        matches: [],
      );
    }
    if (has('what can you do') ||
        has('how can you help') ||
        has('what do you do')) {
      return const AnywaaAnswer(
        text: 'I can translate between English and Dha Anywaa, tell you what a '
            'word means, and show how to say any number up to 9999. Try '
            '"how do you say water" or "what does Wich mean".',
        matches: [],
      );
    }
    const greetings = {'hi', 'hey', 'yo', 'sasa', 'moring'};
    if (p.core.length == 1 && greetings.contains(p.core.first)) {
      return const AnywaaAnswer(
        text: 'Hey there! Ask me any word in English or Dha Anywaa, or give '
            'me a number up to 9999 and I will tell you how to say it.',
        matches: [],
      );
    }
    return null;
  }

  // ── Number generation (0-9999) from the taught rules ────────────────────
  static const _numUnits = <int, String>{
    1: 'Aciel', 2: 'Ariew', 3: 'Adäk', 4: 'Angween', 5: 'Abïc',
    6: 'Abïciel', 7: 'Abiriö', 8: 'Abära', 9: 'Abungween', 10: 'Apar',
  };
  static const _numTens = <int, String>{
    2: 'Piariew', 3: 'Piaradek', 4: 'Piarangwen', 5: 'Piarabich',
    6: 'Piarabichiel', 7: 'Piarabiriyo', 8: 'Piarabara', 9: 'Pierabungween',
  };
  static const _numHundreds = <int, String>{
    1: 'Dipa', 2: 'Diperiew', 3: 'Dipedak', 4: 'Dipangwen', 5: 'Dipabich',
    6: 'Dipabichiel', 7: 'Dipabiriyo', 8: 'Dipabara', 9: 'Dipabungween',
  };

  AnywaaAnswer? _numberAnswer(_Parsed p) {
    final m = RegExp(r'\d+').firstMatch(p.raw);
    if (m == null) return null;
    final digits = m.group(0)!;
    // A run longer than four digits can never be spoken by the taught rules,
    // so refuse rather than answer a truncated value.
    if (digits.length > 4) {
      return const AnywaaAnswer(
        text: 'I can say numbers up to 9999 in Dha Anywaa. Try a smaller one.',
        matches: [],
      );
    }
    final n = int.parse(digits);
    final word = _number(n);
    if (word == null) {
      return const AnywaaAnswer(
        text: 'I can say counting numbers from 1 up to 9999 in Dha Anywaa.',
        matches: [],
      );
    }
    return AnywaaAnswer(
      text: 'Sure! $n in Dha Anywaa is $word.',
      matches: const [],
    );
  }

  /// Deterministic Dha Anywaa for 1-9999, or null when out of range.
  static String? _number(int n) {
    if (n <= 0 || n > 9999) return null;
    return _capitaliseFirst(_numberSpelled(n).toLowerCase());
  }

  static String _numberSpelled(int n) {
    if (n < 1000) return _below1000(n);
    final th = n ~/ 1000, r = n % 1000;
    final head = th == 1 ? 'Kumma' : 'Kumme ${_numUnits[th]}';
    return r == 0 ? head : '$head ka ${_below1000(r)}';
  }

  static String _below1000(int n) {
    if (n < 100) return _below100(n);
    final h = n ~/ 100, r = n % 100;
    final hw = _numHundreds[h]!;
    if (r == 0) return hw;
    if (h == 1) return '$hw ka ${_below100(r)}';
    return '$hw ${_below100(r)}';
  }

  static String _below100(int n) {
    if (n <= 10) return _numUnits[n] ?? '';
    if (n < 20) return 'Apar ka ${_numUnits[n - 10]}';
    final d = n ~/ 10, u = n % 10;
    final t = _numTens[d] ?? '';
    return u == 0 ? t : '$t ka ${_numUnits[u]}';
  }

  static String _capitaliseFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Context {
  final AnywaaMatch match;
  final List<AnywaaMatch> matches;
  final bool toEnglish;
  final String replyText;
  const _Context({
    required this.match,
    required this.matches,
    required this.toEnglish,
    required this.replyText,
  });
}

class _Parsed {
  final String raw;
  final List<String> core;
  final String corePhrase;
  final bool wantsEnglish;
  final bool wantsAnywaa;
  const _Parsed({
    required this.raw,
    required this.core,
    required this.corePhrase,
    required this.wantsEnglish,
    required this.wantsAnywaa,
  });
}
