import 'dart:convert';
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

    // Conversational intents (identity, capability, origin, bare greeting)
    // run first so they read like a chat, not a failed lookup.
    final intent = _intent(p);
    if (intent != null) return intent;

    // Numbers are generated from the taught rules (grounded, deterministic).
    final number = _numberAnswer(p);
    if (number != null) return number;

    final term = p.corePhrase.isEmpty ? p.raw : p.corePhrase;
    if (term.isEmpty) {
      return const AnywaaAnswer(
        text: 'Ask me about a word, for example: "how do you say water in '
            'Dha Anywaa" or "what does wic mean".',
        matches: [],
      );
    }

    final matches = _lookup(term, p);

    if (matches.isEmpty) {
      final sugg = _suggest(term, p);
      final buf = StringBuffer(
          'I only know the words in the local Anywaa dictionary, and I '
          'could not find "$term".');
      if (sugg.isNotEmpty) {
        buf.write(' Did you mean: ${sugg.take(5).join(', ')}?');
      } else {
        buf.write(' Try a single word in English or Dha Anywaa.');
      }
      return AnywaaAnswer(text: buf.toString(), matches: [], suggestions: sugg);
    }

    return AnywaaAnswer(text: _compose(matches, p), matches: matches);
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

  String _compose(List<AnywaaMatch> m, _Parsed p) {
    final top = m.first;
    String lead;
    if (p.wantsEnglish) {
      lead = '${top.entry.dha} means "${top.entry.en}" in English.';
    } else if (p.wantsAnywaa) {
      lead = '"${top.entry.en}" in Dha Anywaa is ${top.entry.dha}.';
    } else if (top.source == 'dha') {
      // No explicit direction, but the hit came from the Anywaa side, so the
      // user most likely typed a Dha word and wants the English meaning.
      lead = '${top.entry.dha} means "${top.entry.en}" in English.';
    } else {
      // Hit came from the English side: give the Dha translation.
      lead = '${top.entry.en} is ${top.entry.dha} in Dha Anywaa.';
    }
    return lead;
  }

  // ── Conversational intents ──────────────────────────────────────────────
  AnywaaAnswer? _intent(_Parsed p) {
    final raw = p.raw;
    bool has(String s) => raw.contains(s);
    if (has('who are you') || has('what are you') || has('your name')) {
      return const AnywaaAnswer(
        text: 'Nyëënga Anywaa AI. I am Anywaa AI, an offline helper that '
            'answers from Dha Anywaa words stored on your device.',
        matches: [],
      );
    }
    if (has('where are you from') || has('where do you come')) {
      return const AnywaaAnswer(
        text: 'I run entirely on your device, built for the Anywaa people '
            'along the rivers of South Sudan and Ethiopia. No internet needed.',
        matches: [],
      );
    }
    if (has('what can you do') ||
        has('how can you help') ||
        has('what do you do')) {
      return const AnywaaAnswer(
        text: 'I translate between English and Dha Anywaa, explain a word '
            'meaning, and tell you how to say a number up to 9999. Every '
            'answer comes from the on-device dictionary, and I never invent '
            'one.',
        matches: [],
      );
    }
    const greetings = {'hi', 'hey', 'yo', 'sasa', 'moring'};
    if (p.core.length == 1 && greetings.contains(p.core.first)) {
      return const AnywaaAnswer(
        text: 'Määdhe! Ask me a word in English or Dha Anywaa, or give me a '
            'number up to 9999.',
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
      text: '$n in Dha Anywaa is $word.',
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
