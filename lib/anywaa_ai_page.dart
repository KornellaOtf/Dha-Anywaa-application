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
    'meaning of spider',
    'Say 2026 in Dha Anywaa',
    'How do you say thank you?',
  ];

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _ai.load();
    if (!mounted) return;
    setState(() => _loading = false);
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

    // Tiny delay so the "thinking" bubble reads; the lookup itself is instant.
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
            const _EcoMark(
                size: 30,
                bg: Color(0x33FFFFFF),
                iconColor: Colors.white),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Anywaa AI',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                Text('on-device helper',
                    style: TextStyle(
                        fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New chat',
            icon: const Icon(Icons.add_rounded,
                color: Colors.white, size: 24),
            onPressed: () {
              _ai.newChat();
              setState(() => _msgs.clear());
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 13, color: Colors.white.withValues(alpha: 0.9)),
                  const SizedBox(width: 5),
                  Text('Offline',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9))),
                ],
              ),
            ),
          ),
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
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      children: [
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1.0),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: const _EcoMark(size: 92),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Bare mo! Ask me anything in Dha Anywaa',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: c.text,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'I translate words, explain meanings, and say numbers. Everything '
          'comes from the dictionary on your device. I work fully offline and '
          'I never make up a translation.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5, color: c.textSub),
        ),
        const SizedBox(height: 22),
        Text('Try asking',
            style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: c.textSub)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _examples
              .map((e) => ActionChip(
                    label: Text(e,
                        style: TextStyle(fontSize: 12.5, color: c.text)),
                    avatar: Icon(Icons.arrow_forward_rounded,
                        size: 15, color: c.accent),
                    backgroundColor: c.card,
                    side: BorderSide(color: c.border),
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onPressed: () => _send(e),
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
                          hintText: 'Ask a word or a number',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        : Border.all(color: c.border.withValues(alpha: 0.6)),
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
      return Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Wrap(
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
        ),
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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(color: c.accent, width: 3),
                top: BorderSide(color: c.border.withValues(alpha: 0.6)),
                right: BorderSide(color: c.border.withValues(alpha: 0.6)),
                bottom: BorderSide(color: c.border.withValues(alpha: 0.6)),
              ),
              boxShadow: const [kShadowSoft],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.entry.en,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    letterSpacing: 0.4,
                    color: c.textSub,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  m.entry.dha,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: c.accent,
                  ),
                ),
                if (m.entry.defs.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    m.entry.defs,
                    style:
                        TextStyle(fontSize: 13, height: 1.4, color: c.textSub),
                  ),
                ],
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_outlined, size: 13, color: c.textSub),
              const SizedBox(width: 6),
              Text(
                'From the on-device dictionary',
                style: TextStyle(fontSize: 11, color: c.textSub),
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
          const _EcoMark(size: 26),
          const SizedBox(width: 8),
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
              child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// The screen's mark: the leaf badge this chat used before the redesign,
/// restored. Drawn as a soft circle with the Material `eco` leaf so it stays
/// crisp and legible in both light and dark themes.
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
      child: Icon(Icons.eco_rounded, size: size * 0.6, color: iconColor ?? c.accent),
    );
  }
}
