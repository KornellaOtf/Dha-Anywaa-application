import 'package:flutter/material.dart';

import 'package:dha_anywaaa/services/anywaa_ai_service.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';

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
  final _ai = AnywaaAiService.instance;
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  bool _loading = true;
  bool _thinking = false;

  static const _examples = [
    'How do you say water in Dha Anywaa?',
    'What does wic mean?',
    'translate house to Anywaa',
    'meaning of cow',
  ];

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _ai.load();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _msgs.add(_Msg.bot(
        'Bare mo! I am the Anywaa helper. Ask me a word in English or in Dha '
        'Anywaa and I will answer from the words stored on your device. I work '
        'fully offline and I never make up a translation.',
      ));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty || _thinking) return;
    setState(() {
      _msgs.add(_Msg.user(text));
      _ctrl.clear();
      _thinking = true;
    });
    _scrollDown();

    // Tiny delay so the "thinking" bubble is visible; the work is instant.
    Future.delayed(const Duration(milliseconds: 320), () {
      final res = _ai.answer(text);
      if (!mounted) return;
      setState(() {
        _thinking = false;
        _msgs.add(_Msg.bot(res.text, res));
      });
      _scrollDown();
    });
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 200,
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
        title: const Text('Anywaa AI'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Icon(Icons.wifi_off_rounded, size: 18, color: c.textSub),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: c.accent),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                    itemCount: _msgs.length + (_thinking ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (_thinking && i == _msgs.length) {
                        return const _ThinkingBubble();
                      }
                      return _Bubble(msg: _msgs[i]);
                    },
                  ),
                ),
                if (_msgs.length <= 1) _examplesRow(c),
                _inputBar(c),
              ],
            ),
    );
  }

  Widget _examplesRow(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _examples
            .map((e) => ActionChip(
                  label: Text(e, style: TextStyle(fontSize: 12, color: c.text)),
                  backgroundColor: c.card,
                  side: BorderSide(color: c.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  onPressed: () => _send(e),
                ))
            .toList(),
      ),
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
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _send(),
                        style: TextStyle(color: c.text, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Ask a word, English or Dha Anywaa',
                          hintStyle: TextStyle(color: c.textSub),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: kGreen,
              shape: const CircleBorder(),
              elevation: 0,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _thinking ? null : () => _send(),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.arrow_upward_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Msg msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final user = msg.fromUser;
    final align = user ? TextAlign.right : TextAlign.left;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment:
            user ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                user ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!user) ...[
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kGreen.withValues(alpha: 0.14),
                  ),
                  child: Icon(Icons.eco_rounded, size: 16, color: c.accent),
                ),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: user ? kGreen : c.card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(user ? 16 : 4),
                      bottomRight: Radius.circular(user ? 4 : 16),
                    ),
                    boxShadow: const [kShadowSoft],
                  ),
                  child: Text(
                    msg.text,
                    textAlign: align,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.35,
                      color: user ? Colors.white : c.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!user && msg.answer != null && msg.answer!.found)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 34),
              child: _ResultList(answer: msg.answer!),
            ),
        ],
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  final AnywaaAnswer answer;
  const _ResultList({required this.answer});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final items = answer.matches;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final m in items)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
              boxShadow: const [kShadowSoft],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.entry.en,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  m.entry.dha,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: c.accent,
                  ),
                ),
                if (m.entry.defs.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    m.entry.defs,
                    style: TextStyle(fontSize: 13, height: 1.4, color: c.textSub),
                  ),
                ],
              ],
            ),
          ),
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 14, color: c.accent),
              const SizedBox(width: 6),
              Text(
                'Answered offline from on-device words',
                style: TextStyle(fontSize: 11, color: c.accent),
              ),
            ],
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
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kGreen.withValues(alpha: 0.14),
            ),
            child: Icon(Icons.eco_rounded, size: 16, color: c.accent),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
