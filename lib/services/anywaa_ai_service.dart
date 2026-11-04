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
      final sugg = _suggest(term);
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

  List<AnywaaMatch> _lookup(String term, _Parsed p) {
    final q = fold(term);
    final qTokens = q.split(' ').toList();
    final scored = <AnywaaMatch>[];

    for (final e in _words) {
      final enF = fold(e.en);
      double best = 0;
      String src = p.wantsEnglish ? 'dha' : 'en';

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
              } else if (qt.length >= 4 &&
                  ht.length >= 4 &&
                  (qt.startsWith(ht) || ht.startsWith(qt))) {
                t = 1.5; // partial typing of a longer word
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

      consider(enF, 'en');
      // also score each synonym on the Anywaa side
      for (final s in (e.syn.isEmpty ? [e.dha] : e.syn)) {
        consider(fold(s), 'dha');
      }

      if (best >= 0.8) scored.add(AnywaaMatch(e, best, src));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(6).toList();
  }

  List<String> _suggest(String term) {
    final q = fold(term);
    final near = <String>{};
    for (final e in _words) {
      final enF = fold(e.en);
      final dhaF = fold(e.dha);
      if (enF.contains(q) || dhaF.contains(q)) near.add(e.en);
    }
    return near.take(8).toList();
  }

  String _compose(List<AnywaaMatch> m, _Parsed p) {
    final top = m.first;
    String lead;
    if (p.wantsEnglish) {
      lead = '${top.entry.dha} means "${top.entry.en}" in English.';
    } else if (p.wantsAnywaa) {
      lead = '"${top.entry.en}" in Dha Anywaa is ${top.entry.dha}.';
    } else {
      // no explicit direction: present the pair both ways
      lead = '${top.entry.en} is ${top.entry.dha} in Dha Anywaa.';
    }
    return lead;
  }
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
