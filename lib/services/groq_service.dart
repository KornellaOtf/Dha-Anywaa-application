import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dha_anywaaa/secrets.dart';
import 'package:dha_anywaaa/services/anywaa_ai_service.dart';
import 'package:dha_anywaaa/services/gamification_service.dart';
import 'package:dha_anywaaa/services/groq_prompts.dart';
import 'package:dha_anywaaa/services/learning_engine.dart';
import 'package:dha_anywaaa/services/word_aggregator.dart';

/// Result of a Groq chat call. [text] is display-ready (tags stripped,
/// dashes cleaned). [contribution] is a non-null community note captured
/// from a [[SAVE: ...]] tag that the app should store for review.
class GroqReply {
  final String text;
  final String? contribution;
  const GroqReply(this.text, [this.contribution]);
}

/// Groq-powered Anywaa AI. Falls back gracefully: returns null on any
/// failure so the caller can use the offline dictionary engine instead.
class GroqService {
  GroqService._();
  static final GroqService instance = GroqService._();

  static const _timeout = Duration(seconds: 25);

  /// Provider chain, tried in order. NVIDIA Nemotron is the default;
  /// Groq remains as a free fallback when its key is configured.
  static const _providers = [
    (
      endpoint: 'https://integrate.api.nvidia.com/v1/chat/completions',
      model: 'nvidia/nemotron-3.5-lightning-30b-a3b',
      key: '', // resolved from Secrets at call time
      reasoningOff: true,
    ),
    (
      endpoint: 'https://api.groq.com/openai/v1/chat/completions',
      model: 'openai/gpt-oss-120b',
      key: '',
      reasoningOff: false,
    ),
  ];

  static const _kCommunityNotes = 'groq_community_notes';
  static const _maxNotes = 200;

  List<Map<String, dynamic>>? _facts;
  List<Map<String, String>>? _bible;
  Future<void>? _bibleLoad;

  bool get isConfigured =>
      _nvidiaKey.isNotEmpty ||
      (Secrets.groqApiKey.isNotEmpty &&
          !Secrets.groqApiKey.startsWith('gsk_xxx'));

  String get _nvidiaKey => Secrets.nvidiaApiKey;

  List<({String endpoint, String model, String key, bool reasoningOff})>
      get _activeProviders {
    final out = <({String endpoint, String model, String key, bool reasoningOff})>[];
    if (_nvidiaKey.isNotEmpty && !_nvidiaKey.startsWith('nvapi-xxx')) {
      out.add((
        endpoint: _providers[0].endpoint,
        model: _providers[0].model,
        key: _nvidiaKey,
        reasoningOff: true,
      ));
    }
    if (Secrets.groqApiKey.isNotEmpty &&
        !Secrets.groqApiKey.startsWith('gsk_xxx')) {
      out.add((
        endpoint: _providers[1].endpoint,
        model: _providers[1].model,
        key: Secrets.groqApiKey,
        reasoningOff: false,
      ));
    }
    return out;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Send a user message. [history] is the recent chat as
  /// {'role': 'user'|'assistant', 'content': ...} maps (max ~10).
  /// Returns null when the API is unreachable or errors — caller falls back.
  Future<GroqReply?> chat(
    String userText,
    List<Map<String, String>> history,
  ) async {
    if (!isConfigured) return null;

    // Fast identity answers don't need the API at all.
    if (_isIdentityQuestion(userText)) {
      return const GroqReply(
        'I am Anywaa AI, your guide to the Anywaa people, Gambella, and their culture. '
        'What would you like to explore today?',
      );
    }

    try {
      final verified   = await _verifiedEntries(userText);
      final community  = await _communityNotes();
      final localBlock = GroqPrompts.localData(verified, community);

      final messages = <Map<String, String>>[
        {'role': 'system', 'content': GroqPrompts.main},
        {'role': 'system', 'content': localBlock},
        // Few-shot identity examples make the name stick.
        {'role': 'user', 'content': 'Who are you?'},
        {'role': 'assistant',
         'content': 'I am Anywaa AI, your guide to the Anywaa people, Gambella, and their culture. What would you like to explore today?'},
        {'role': 'user', 'content': 'What is your name?'},
        {'role': 'assistant',
         'content': 'My name is Anywaa AI. I am here to help you learn about the Anywaa heritage and practice Dha Anywaa.'},
        ...history,
        {'role': 'user', 'content': userText},
      ];

      final providers = _activeProviders;
      if (providers.isEmpty) return null;

      for (final prov in providers) {
        final reply = await _request(prov, messages, userText);
        if (reply != null) return reply;
      }
      return null;
    } catch (e) {
      debugPrint('Groq: request failed: $e');
      return null;
    }
  }

  /// Streaming variant of [chat]. [onDelta] receives the accumulated,
  /// display-cleaned text on every chunk so the UI can render tokens as
  /// they arrive. Falls back to the non-stream request per provider when
  /// the stream cannot be established.
  Future<GroqReply?> chatStream(
    String userText,
    List<Map<String, String>> history, {
    void Function(String accumulated)? onDelta,
  }) async {
    if (!isConfigured) return null;

    if (_isIdentityQuestion(userText)) {
      const reply = GroqReply(
        'I am Anywaa AI, your guide to the Anywaa people, Gambella, and their culture. '
        'What would you like to explore today?',
      );
      onDelta?.call(reply.text);
      return reply;
    }

    try {
      final verified   = await _verifiedEntries(userText);
      final community  = await _communityNotes();
      final localBlock = GroqPrompts.localData(verified, community);

      final messages = <Map<String, String>>[
        {'role': 'system', 'content': GroqPrompts.main},
        {'role': 'system', 'content': localBlock},
        {'role': 'user', 'content': 'Who are you?'},
        {'role': 'assistant',
         'content': 'I am Anywaa AI, your guide to the Anywaa people, Gambella, and their culture. What would you like to explore today?'},
        {'role': 'user', 'content': 'What is your name?'},
        {'role': 'assistant',
         'content': 'My name is Anywaa AI. I am here to help you learn about the Anywaa heritage and practice Dha Anywaa.'},
        ...history,
        {'role': 'user', 'content': userText},
      ];

      final providers = _activeProviders;
      if (providers.isEmpty) return null;

      for (final prov in providers) {
        final streamed = await _requestStream(prov, messages, onDelta);
        if (streamed != null) return streamed;
        // Stream failed before producing anything — try non-stream once.
        final reply = await _request(prov, messages, userText);
        if (reply != null) {
          onDelta?.call(reply.text);
          return reply;
        }
      }
      return null;
    } catch (e) {
      debugPrint('AI stream: request failed: $e');
      return null;
    }
  }

  /// POST with `stream: true`, parsing OpenAI-style SSE chunks.
  /// Returns the post-processed reply, or null if nothing usable arrived.
  Future<GroqReply?> _requestStream(
    ({String endpoint, String model, String key, bool reasoningOff}) prov,
    List<Map<String, String>> messages,
    void Function(String accumulated)? onDelta,
  ) async {
    final client = http.Client();
    try {
      final body = <String, dynamic>{
        'model': prov.model,
        'messages': messages,
        'temperature': 0.3,
        'max_tokens': 512,
        'stream': true,
      };
      if (prov.reasoningOff) {
        body['chat_template_kwargs'] = {'enable_thinking': false};
      }
      final req = http.Request('POST', Uri.parse(prov.endpoint))
        ..headers.addAll({
          'Authorization': 'Bearer ${prov.key}',
          'Content-Type': 'application/json; charset=utf-8',
        })
        ..bodyBytes = utf8.encode(jsonEncode(body));

      final res = await client.send(req).timeout(_timeout);
      if (res.statusCode != 200) {
        debugPrint('AI stream: HTTP ${res.statusCode} from ${prov.endpoint}');
        await res.stream.drain<void>();
        return null;
      }

      var acc = '';
      await for (final line in res.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (!line.startsWith('data:')) continue;
        final payload = line.substring(5).trim();
        if (payload == '[DONE]') break;
        try {
          final j = jsonDecode(payload) as Map<String, dynamic>;
          final choices = j['choices'] as List?;
          if (choices == null || choices.isEmpty) continue;
          final delta = (choices.first as Map?)?['delta'];
          final piece = delta is Map ? delta['content'] as String? : null;
          if (piece != null && piece.isNotEmpty) {
            acc += piece;
            onDelta?.call(cleanReply(acc));
          }
        } catch (_) {}
      }

      if (acc.trim().isEmpty) return null;
      return _postProcess(acc);
    } catch (e) {
      debugPrint('AI stream failed (${prov.endpoint}): $e');
      return null;
    } finally {
      client.close();
    }
  }

  Future<GroqReply?> _request(
    ({String endpoint, String model, String key, bool reasoningOff}) prov,
    List<Map<String, String>> messages,
    String userText) async {
    try {
      final body = <String, dynamic>{
        'model': prov.model,
        'messages': messages,
        'temperature': 0.3,
        'max_tokens': 512,
      };
      if (prov.reasoningOff) {
        // Nemotron is a reasoning model — keep thinking off so the token
        // budget goes to the answer, not hidden reasoning.
        body['chat_template_kwargs'] = {'enable_thinking': false};
      }
      final res = await http
          .post(
            Uri.parse(prov.endpoint),
            headers: {
              'Authorization': 'Bearer ${prov.key}',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: utf8.encode(jsonEncode(body)),
          )
          .timeout(_timeout);

      if (res.statusCode != 200) {
        debugPrint('AI: HTTP ${res.statusCode} from ${prov.endpoint}');
        return null;
      }

      // Responses carry no charset header — decode raw bytes as UTF-8
      // or ë/ö/curly quotes arrive as mojibake.
      final data =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;
      final first = choices.first;
      if (first is! Map<String, dynamic>) return null;
      final message = first['message'];
      if (message is! Map<String, dynamic>) return null;
      final content = message['content'] as String?;
      if (content == null || content.trim().isEmpty) return null;

      return _postProcess(content);
    } catch (e) {
      debugPrint('AI: request failed (${prov.endpoint}): $e');
      return null;
    }
  }

  /// Store a community contribution captured via [[SAVE: ...]].
  Future<void> saveContribution(String text) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kCommunityNotes) ?? '[]';
    List<dynamic> list;
    try {
      final d = jsonDecode(raw);
      list = d is List ? d : <dynamic>[];
    } catch (_) {
      list = <dynamic>[];
    }
    list.add({
      'text': text,
      'ts': DateTime.now().toIso8601String(),
    });
    if (list.length > _maxNotes) {
      list.removeRange(0, list.length - _maxNotes);
    }
    await p.setString(_kCommunityNotes, jsonEncode(list));
  }

  /// Preloads local knowledge (facts, Bible index) after first frame so
  /// the first AI reply isn't delayed by asset parsing.
  Future<void> warmUp() async {
    await Future.wait([_ensureFacts(), _ensureBible()]);
  }

  // ── Bible grounding ───────────────────────────────────────────────────────
  // assets/bible.json is ~11 MB / 31k verses. Parsed once, cached for the
  // session. Only the English text is injected — the Anywaa text stays out
  // of prompts to respect the no-Dha-Anywaa-speech rule.

  static const _bibleAsset = 'assets/bible.json';

  Future<void> _ensureBible() {
    return _bibleLoad ??= _loadBible();
  }

  Future<void> _loadBible() async {
    try {
      final raw = await rootBundle.loadString(_bibleAsset);
      final list = jsonDecode(raw) as List;
      _bible = list
          .whereType<Map<String, dynamic>>()
          .map((v) => {
                'ref': '${v['book']} ${v['chapter']}:${v['verse']}',
                'en': (v['english'] ?? '').toString(),
                'hay':
                    '${v['book']} ${v['chapter']} ${v['verse']} ${v['english'] ?? ''}'
                        .toLowerCase(),
              })
          .where((v) => (v['en'] as String).isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('AI: bible load failed: $e');
      _bible = const [];
    }
  }

  static const _bibleKeywords =
      r'\b(bible|god|jesus|christ|lord|verse|verses|chapter|scripture|'
      r'genesis|exodus|psalm|psalms|proverb|proverbs|gospel|testament|'
      r'faith|pray|prayer|church|adam|eve|noah|abraham|moses|david|'
      r'solomon|cross|resurrection|holy spirit|sin|heaven|hell|angel|'
      r'creation|ten commandments|ark|egypt|israel)\b';

  static const _queryStopwords = {
    'the', 'and', 'for', 'are', 'but', 'not', 'you', 'your', 'yours',
    'what', 'when', 'where', 'which', 'who', 'whom', 'how', 'why',
    'can', 'could', 'would', 'should', 'tell', 'about', 'with', 'from',
    'that', 'this', 'have', 'has', 'had', 'does', 'did', 'was', 'were',
    'anywaa', 'gambella', 'dha',
  };

  /// Keyword-scored Bible verse search. Returns up to 4 matching verses
  /// with references, or '' when the query isn't Bible-related.
  Future<String> _bibleVerses(String query) async {
    await _ensureBible();
    final verses = _bible;
    if (verses == null || verses.isEmpty) return '';
    final q = query.toLowerCase();
    if (!RegExp(_bibleKeywords).hasMatch(q)) return '';

    final terms = q
        .split(RegExp('[^a-zA-Z]+'))
        .where((t) => t.length >= 3 && !_queryStopwords.contains(t))
        .toSet()
        .toList();
    if (terms.isEmpty) return '';

    final scored = <MapEntry<int, Map<String, String>>>[];
    for (final v in verses) {
      final hay = v['hay']!;
      var score = 0;
      for (final t in terms) {
        if (hay.contains(t)) score++;
      }
      // Exact book-name hit (e.g. "psalm 23") scores heavily.
      for (final book in const [
        'genesis', 'exodus', 'leviticus', 'numbers', 'deuteronomy',
        'joshua', 'judges', 'ruth', 'samuel', 'kings', 'chronicles',
        'ezra', 'nehemiah', 'esther', 'job', 'psalm', 'proverbs',
        'ecclesiastes', 'song of solomon', 'isaiah', 'jeremiah',
        'lamentations', 'ezekiel', 'daniel', 'hosea', 'joel', 'amos',
        'obadiah', 'jonah', 'micah', 'nahum', 'habakkuk', 'zephaniah',
        'haggai', 'zechariah', 'malachi', 'matthew', 'mark', 'luke',
        'john', 'acts', 'romans', 'corinthians', 'galatians',
        'ephesians', 'philippians', 'colossians', 'thessalonians',
        'timothy', 'titus', 'philemon', 'hebrews', 'james', 'peter',
        'jude', 'revelation',
      ]) {
        if (hay.startsWith(book) && q.contains(book)) score += 10;
      }
      if (score > 0) scored.add(MapEntry(score, v));
    }
    if (scored.isEmpty) return '';
    scored.sort((a, b) => b.key.compareTo(a.key));

    final buf = StringBuffer();
    for (final e in scored.take(4)) {
      buf.writeln('- ${e.value['ref']}: ${e.value['en']}');
    }
    return buf.toString().trimRight();
  }

  /// One-line learner status so answers can be personal and encouraging.
  Future<String> _learnerStatus() async {
    try {
      final g = await GamificationService.instance.load();
      final words = WordAggregator.instance.getAllWords();
      final due = await LearningEngine.instance
          .getDueCount(words.map((w) => w.id).toList());
      final parts = <String>[
        'level ${GamificationService.levelFromXp(g.xp)}',
        '${g.streakDays}-day streak',
        '${g.todayXp}/${g.dailyGoalXp} XP today',
      ];
      if (due > 0) parts.add('$due words due for review');
      return '- LEARNER: ${parts.join(', ')}';
    } catch (_) {
      return '';
    }
  }

  // ── Local data for the knowledge block ────────────────────────────────────

  Future<void> _ensureFacts() async {
    if (_facts != null) return;
    try {
      final raw = await rootBundle.loadString('assets/data/cultural_facts.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _facts = (map['facts'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (_) {
      _facts = const [];
    }
  }

  /// 3–5 most relevant verified entries for this question.
  Future<String> _verifiedEntries(String query) async {
    await _ensureFacts();
    final q = query.toLowerCase();
    final lines = <String>[];

    // Cultural facts scored by keyword hits.
    final scored = <MapEntry<int, Map<String, dynamic>>>[];
    for (final f in _facts ?? const <Map<String, dynamic>>[]) {
      final kws = (f['keywords'] as List? ?? const [])
          .map((k) => k.toString().toLowerCase());
      final hits = kws.where((k) => q.contains(k)).length;
      if (hits > 0) scored.add(MapEntry(hits, f));
    }
    scored.sort((a, b) => b.key.compareTo(a.key));
    for (final e in scored.take(3)) {
      lines.add('- ${e.value['fact']}');
    }

    // Grounded dictionary entries for word/meaning questions.
    try {
      final ans = AnywaaAiService.instance.answer(query);
      if (ans.found) {
        for (final m in ans.matches.take(2)) {
          final e = m.entry;
          final buf = StringBuffer('- ${e.en} = ${e.dha}');
          if (e.pron.isNotEmpty) buf.write(' (${e.pron})');
          if (e.defs.isNotEmpty) buf.write(': ${e.defs}');
          lines.add(buf.toString());
        }
      }
    } catch (_) {}

    // Bible verses for faith/scripture questions.
    final bible = await _bibleVerses(query);
    if (bible.isNotEmpty) {
      lines.add('- BIBLE VERSES (quote exactly, do not change wording):');
      lines.add(bible);
    }

    // Personalised learner status.
    final status = await _learnerStatus();
    if (status.isNotEmpty) lines.add(status);

    return lines.isEmpty ? '(none)' : lines.join('\n');
  }

  // ── Community notes (for the review UI) ───────────────────────────────────

  /// All saved community contributions, newest first.
  /// Each item: {'text': String, 'ts': String(ISO8601)}.
  Future<List<Map<String, dynamic>>> communityNotes() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kCommunityNotes) ?? '[]';
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((n) => Map<String, dynamic>.from(n))
          .toList()
          .reversed
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Delete one community note by its index in the stored list
  /// (oldest-first order, matching communityNotes() reversed output).
  Future<void> deleteCommunityNote(int reversedIndex) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kCommunityNotes) ?? '[]';
    List<dynamic> list;
    try {
      final d = jsonDecode(raw);
      list = d is List ? d : <dynamic>[];
    } catch (_) {
      return;
    }
    final realIndex = list.length - 1 - reversedIndex;
    if (realIndex < 0 || realIndex >= list.length) return;
    list.removeAt(realIndex);
    await p.setString(_kCommunityNotes, jsonEncode(list));
  }

  Future<void> clearCommunityNotes() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kCommunityNotes);
  }

  Future<String> _communityNotes() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kCommunityNotes) ?? '[]';
      final list = jsonDecode(raw);
      if (list is! List || list.isEmpty) return '(none yet)';
      final recent = list.reversed.take(10);
      return recent
          .map((n) => '- ${(n as Map)['text']}')
          .join('\n');
    } catch (_) {
      return '(none yet)';
    }
  }

  // ── Post-processing ───────────────────────────────────────────────────────

  static final _saveTag = RegExp(r'\[\[SAVE:\s*(.*?)\]\]', dotAll: true);

  GroqReply _postProcess(String raw) {
    String? contribution;
    var text = raw;

    // Strip ALL save tags from display text; only the first becomes a note.
    final all = _saveTag.allMatches(text).toList();
    if (all.isNotEmpty) {
      contribution = all.first.group(1)?.trim();
      // Cap length and strip bracket/instruction-like content.
      if (contribution != null) {
        contribution = contribution
            .replaceAll(RegExp(r'[\[\]{}<>]'), '')
            .trim();
        if (contribution.length > 300) {
          contribution = contribution.substring(0, 300);
        }
      }
      text = text.replaceAll(_saveTag, '').trim();
      if (contribution != null && contribution.isNotEmpty) {
        unawaited(saveContribution(contribution));
      }
    }

    return GroqReply(cleanReply(text), contribution);
  }

  /// Repairs text that was UTF-8 decoded as Latin-1 (mojibake), e.g.
  /// "DÃ«Ã«ri" -> "Dëëri". Safe no-op on already-correct or unrepairable
  /// text (Anywaa letters like ŋ exceed Latin-1 and are returned as-is).
  static String fixMojibake(String s) {
    try {
      return utf8.decode(latin1.encode(s));
    } catch (_) {
      return s;
    }
  }

  /// Cosmetic cleaning safe to run on partial streamed text: no em/en
  /// dashes, no markdown, no emoji or arrow glyphs, no leaked model names.
  /// Does NOT touch [[SAVE: ...]] tags — that only happens once, at the
  /// end, in [_postProcess].
  static String cleanReply(String text) => text
        .replaceAll('\u202F', ' ') // narrow no-break space
        .replaceAll('\u00A0', ' ') // no-break space
        .replaceAll('\u2011', '-') // non-breaking hyphen
        .replaceAll('\u200B', '') // zero-width space
        .replaceAll('—', ',')
        .replaceAll('–', ',')
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll('`', '')
        .replaceAll(RegExp(r'\n#{1,6}\s*'), '\n')
        .replaceAll(RegExp(
            '[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}'
            '\u{FE0F}\u{2190}-\u{21FF}\u{2300}-\u{23FF}]',
            unicode: true),
            '')
        .replaceAll(RegExp(r'\bLlama\b', caseSensitive: false), 'Anywaa AI')
        .replaceAll(RegExp(r'\bMeta AI\b', caseSensitive: false), 'Anywaa AI')
        .replaceAll(RegExp(r'\bGroq\b', caseSensitive: false), 'Anywaa AI')
        .replaceAll(RegExp(r'\bChatGPT\b', caseSensitive: false), 'Anywaa AI')
        .replaceAll(RegExp(r'\bClaude\b', caseSensitive: false), 'Anywaa AI');

  bool _isIdentityQuestion(String q) {
    final l = q.toLowerCase();
    return RegExp(r'\b(who are you|what are you|your name|who made you|'
            r'what is your name|introduce yourself)\b')
        .hasMatch(l);
  }
}
