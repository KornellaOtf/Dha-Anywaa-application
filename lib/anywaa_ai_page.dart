import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dha_anywaaa/services/anywaa_ai_service.dart';
import 'package:dha_anywaaa/services/groq_service.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';

/// Anywaa AI Chat Interface
///
/// Answers entirely from the on-device dictionary (3,346 words).
/// No network required. No external model. Fast and fully offline.

class AnywaaAiPage extends StatefulWidget {
  const AnywaaAiPage({super.key});
  @override
  State<AnywaaAiPage> createState() => _AnywaaAiPageState();
}

class _Msg {
  final bool fromUser;
  final String text;
  final AnywaaAnswer? answer;
  _Msg.user(this.text) : fromUser = true, answer = null;
  _Msg.bot(this.text, [this.answer]) : fromUser = false;
}

class _AnywaaAiPageState extends State<AnywaaAiPage> {
  final _ai   = AnywaaAiService.instance;
  final _ctrl  = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  final List<Map<String, String>> _history = [];
  bool _loading  = true;
  bool _thinking = false;
  Timer? _rotate;

  List<String> _examples = const [];

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _ai.load();
    if (!mounted) return;
    setState(() {
      _loading  = false;
      _examples = _ai.sampleQuestions(count: 6);
    });
    _rotate = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || _msgs.isNotEmpty) return;
      setState(() => _examples = _ai.sampleQuestions(count: 6));
    });
  }

  @override
  void dispose() {
    _rotate?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty || _thinking) return;
    if (text.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please keep messages under 1000 characters')),
      );
      return;
    }
    setState(() {
      _msgs.add(_Msg.user(text));
      _ctrl.clear();
      _thinking = true;
    });
    _scrollDown();
    _generateReply(text);
  }

  Future<void> _generateReply(String text) async {
    // Groq AI answers first; the offline dictionary engine is the fallback
    // for offline use or any API failure.
    final groq = await GroqService.instance.chat(text, _history);
    if (!mounted) return;

    if (groq != null) {
      _history.add({'role': 'user', 'content': text});
      _history.add({'role': 'assistant', 'content': groq.text});
      if (_history.length > 20) {
        _history.removeRange(0, _history.length - 20);
      }
      setState(() {
        _thinking = false;
        _msgs.add(_Msg.bot(groq.text));
      });
      _scrollDown();
      return;
    }

    final dictResult = _ai.answer(text);
    if (!mounted) return;
    _history.add({'role': 'user', 'content': text});
    _history.add({'role': 'assistant', 'content': dictResult.text});
    if (_history.length > 20) {
      _history.removeRange(0, _history.length - 20);
    }
    setState(() {
      _thinking = false;
      _msgs.add(_Msg.bot(dictResult.text, dictResult));
    });
    _scrollDown();
  }

  void _showCommunitySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CommunitySheet(),
    );
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 240,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const _EcoMark(size: 30, bg: Color(0x33FFFFFF), iconColor: Colors.white),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Anywaa AI',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                Text('Your guide to Anywaa & Gambella',
                    style: TextStyle(
                        fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Community knowledge',
            icon: const Icon(Icons.groups_rounded,
                color: Colors.white, size: 22),
            onPressed: _showCommunitySheet,
          ),
          IconButton(
            tooltip: 'New chat',
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
            onPressed: () {
              _ai.newChat();
              setState(() {
                _msgs.clear();
                _history.clear();
                _examples = _ai.sampleQuestions(count: 6);
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: c.accent))
          : Column(
              children: [
                Expanded(
                  child: _msgs.isEmpty
                      ? _hero(c)
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                          itemCount: _msgs.length + (_thinking ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (_thinking && i == _msgs.length) {
                              return const _ThinkingBubble();
                            }
                            return _Bubble(msg: _msgs[i], onAsk: _send);
                          },
                        ),
                ),
                _inputBar(c),
              ],
            ),
    );
  }

  Widget _hero(AppColors c) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kGreen.withValues(alpha: 0.25), width: 1.5),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1.0),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: const _EcoMark(size: 88),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Dëëri jööt?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: c.text,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'I am Anywaa AI, your guide to the Anywaa people, Gambella, '
          'and their culture. Ask me about traditions, history, words, '
          'quizzes, or the Bible.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.5, height: 1.55, color: c.textSub),
        ),
        const SizedBox(height: 26),
        Text('Try asking',
            style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: c.textSub)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _examples
              .map((e) => Material(
                    color: c.card,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => _send(e),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 14, color: c.accent),
                            const SizedBox(width: 7),
                            Text(e,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: c.text)),
                          ],
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _inputBar(AppColors c) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: c.border),
                  boxShadow: const [kShadowSoft],
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Icon(Icons.chat_bubble_outline_rounded,
                          size: 18, color: c.textSub),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _send(),
                        style: TextStyle(color: c.text, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Ask about Anywaa culture, words, or the app',
                          hintStyle: TextStyle(color: c.textSub),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedScale(
              scale: _thinking ? 0.9 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Material(
                color: kGreen,
                shape: const CircleBorder(),
                elevation: 0,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _thinking ? null : () => _send(),
                  child: const Padding(
                    padding: EdgeInsets.all(13),
                    child: Icon(Icons.arrow_upward_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chat bubbles ──────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final _Msg msg;
  final ValueChanged<String> onAsk;
  const _Bubble({required this.msg, required this.onAsk});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final user = msg.fromUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment:
            user ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!user) ...[
            const _EcoMark(size: 26),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  user ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: user
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [kGreenMid, kGreen],
                          )
                        : null,
                    color: user ? null : c.card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(user ? 16 : 4),
                      bottomRight: Radius.circular(user ? 4 : 16),
                    ),
                    boxShadow: const [kShadowSoft],
                    border: user
                        ? null
                        : Border.all(
                            color: c.border.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    msg.text,
                    textAlign: user ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.35,
                      color: user ? Colors.white : c.text,
                    ),
                  ),
                ),
                if (!user && msg.answer != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 2),
                    child: _AnswerBody(answer: msg.answer!, onAsk: onAsk),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerBody extends StatelessWidget {
  final AnywaaAnswer answer;
  final ValueChanged<String> onAsk;
  const _AnswerBody({required this.answer, required this.onAsk});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (!answer.found) {
      if (answer.suggestions.isEmpty) return const SizedBox.shrink();
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: answer.suggestions
            .map((s) => ActionChip(
                  label: Text(s,
                      style: TextStyle(fontSize: 12.5, color: c.accent)),
                  backgroundColor: c.accent.withValues(alpha: 0.08),
                  side: BorderSide(color: c.accent.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  onPressed: () => onAsk(s),
                ))
            .toList(),
      );
    }
    final items = answer.matches;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final m in items)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border.withValues(alpha: 0.6)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: c.accent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.entry.en,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                  color: c.textSub)),
                          const SizedBox(height: 2),
                          Text(m.entry.dha,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: c.accent)),
                          if (m.entry.pron.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text('/${m.entry.pron}/',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: c.textSub)),
                            ),
                          if (m.entry.defs.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(m.entry.defs,
                                style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: c.textSub)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const _EcoMark(size: 26),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              boxShadow: const [kShadowSoft],
            ),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: c.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _EcoMark extends StatelessWidget {
  final double size;
  final Color? bg;
  final Color? iconColor;
  const _EcoMark({required this.size, this.bg, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg ?? kGreen.withValues(alpha: 0.14),
        boxShadow: const [kShadowSoft],
      ),
      child: Icon(Icons.eco_rounded,
          size: size * 0.6, color: iconColor ?? c.accent),
    );
  }
}


/// Anywaa AI Chat Interface
///
/// RESPONSE PIPELINE:
/// 1. Dictionary lookup (AnywaaAiService) always runs first — grounded facts.
/// 2. If Anywaa-LM is loaded (fllama), it generates a conversational reply:
///    - Translation queries: model rephrases the dictionary result (RAG).
///    - General questions: model answers freely from its own knowledge.
/// 3. If the model is not loaded, the dictionary result is shown directly.
///
/// Anywaa-LM STATUS: ✅ Integrated via fllama (llama.cpp)


// ── Community knowledge sheet ────────────────────────────────────────────────
// Shows what people have shared with Anywaa AI (captured via [[SAVE: ...]]
// tags). Unverified until reviewed; feeds the COMMUNITY NOTES block.

class _CommunitySheet extends StatefulWidget {
  const _CommunitySheet();

  @override
  State<_CommunitySheet> createState() => _CommunitySheetState();
}

class _CommunitySheetState extends State<_CommunitySheet> {
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notes = await GroqService.instance.communityNotes();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _delete(int i) async {
    await GroqService.instance.deleteCommunityNote(i);
    _load();
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = ctx.c;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Clear all notes?',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: c.text)),
                const SizedBox(height: 8),
                Text('Every shared contribution will be removed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: c.textSub)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kRust,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok == true) {
      await GroqService.instance.clearCommunityNotes();
      _load();
    }
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Community knowledge',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: c.text)),
                        const SizedBox(height: 2),
                        Text(
                          'What people have shared with Anywaa AI. '
                          'Reviewed before it becomes verified knowledge.',
                          style: TextStyle(
                              fontSize: 12, height: 1.4, color: c.textSub),
                        ),
                      ],
                    ),
                  ),
                  if (_notes.isNotEmpty)
                    TextButton(
                      onPressed: _clearAll,
                      child: Text('Clear all',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: kRust)),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _notes.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.groups_outlined,
                                  size: 44, color: c.textSub),
                              const SizedBox(height: 10),
                              Text(
                                'Nothing shared yet. When someone teaches '
                                'Anywaa AI something new, it appears here '
                                'for you to review.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13.5,
                                    height: 1.5,
                                    color: c.textSub),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                          itemCount: _notes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final n = _notes[i];
                            return Container(
                              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                              decoration: BoxDecoration(
                                color: c.bg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: c.border.withValues(alpha: 0.6)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n['text']?.toString() ?? '',
                                          style: TextStyle(
                                              fontSize: 13.5,
                                              height: 1.45,
                                              color: c.text),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Unverified · ${_formatDate(n['ts']?.toString() ?? '')}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: c.textSub),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded,
                                        size: 18, color: c.textSub),
                                    onPressed: () => _delete(i),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
