import 'package:audioplayers/audioplayers.dart';
import 'package:dha_anywaaa/components/savedData.dart';
import 'package:dha_anywaaa/letters_and_sound.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:flutter/material.dart';

class Page1 extends StatefulWidget {
  const Page1({super.key});
  @override
  State<Page1> createState() => _Page1State();
}

class _Page1State extends State<Page1> with SingleTickerProviderStateMixin {
  late AudioPlayer _player;
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _isPlaying = false;
  bool _zoom = false;
  int _index = 0;
  int _learnedCount = 0;

  final SavedData _savedData = SavedData();

  static const String _category = 'alphabet';

  final List<LetterSound> _letters = [
    LetterSound(capitalLetter: 'A',  smallLetter: 'a',  sound: 'sound/A-1.MP3'),
    LetterSound(capitalLetter: 'Ä',  smallLetter: 'ä',  sound: 'sound/Ä.mp3'),
    LetterSound(capitalLetter: 'B',  smallLetter: 'b',  sound: 'sound/B-1.mp3'),
    LetterSound(capitalLetter: 'C',  smallLetter: 'c',  sound: 'sound/C-1.mp3'),
    LetterSound(capitalLetter: 'D',  smallLetter: 'd',  sound: 'sound/D.mp3'),
    LetterSound(capitalLetter: 'Dh', smallLetter: 'dh', sound: 'sound/Dh.mp3'),
    LetterSound(capitalLetter: 'E',  smallLetter: 'e',  sound: 'sound/E.mp3'),
    LetterSound(capitalLetter: 'Ë',  smallLetter: 'ë',  sound: 'sound/Ë.mp3'),
    LetterSound(capitalLetter: 'G',  smallLetter: 'g',  sound: 'sound/G.mp3'),
    LetterSound(capitalLetter: 'I',  smallLetter: 'i',  sound: 'sound/I.mp3'),
    LetterSound(capitalLetter: 'Ï',  smallLetter: 'ï',  sound: 'sound/Ï.mp3'),
    LetterSound(capitalLetter: 'J',  smallLetter: 'j',  sound: 'sound/J.mp3'),
    LetterSound(capitalLetter: 'K',  smallLetter: 'k',  sound: 'sound/K.mp3'),
    LetterSound(capitalLetter: 'L',  smallLetter: 'l',  sound: 'sound/L.mp3'),
    LetterSound(capitalLetter: 'M',  smallLetter: 'm',  sound: 'sound/M.mp3'),
    LetterSound(capitalLetter: 'N',  smallLetter: 'n',  sound: 'sound/N.mp3'),
    LetterSound(capitalLetter: 'Ng', smallLetter: 'ng', sound: 'sound/Ng.mp3'),
    LetterSound(capitalLetter: 'Nh', smallLetter: 'nh', sound: 'sound/Nh.mp3'),
    LetterSound(capitalLetter: 'Ny', smallLetter: 'ny', sound: 'sound/Ny.mp3'),
    LetterSound(capitalLetter: 'O',  smallLetter: 'o',  sound: 'sound/O.mp3'),
    LetterSound(capitalLetter: 'Ö',  smallLetter: 'ö',  sound: 'sound/Ö.mp3'),
    LetterSound(capitalLetter: 'Ø',  smallLetter: 'ø',  sound: 'sound/Ø.mp3'),
    LetterSound(capitalLetter: 'P',  smallLetter: 'p',  sound: 'sound/P.mp3'),
    LetterSound(capitalLetter: 'R',  smallLetter: 'r',  sound: 'sound/R.mp3'),
    LetterSound(capitalLetter: 'T',  smallLetter: 't',  sound: 'sound/T.mp3'),
    LetterSound(capitalLetter: 'Th', smallLetter: 'th', sound: 'sound/Th.mp3'),
    LetterSound(capitalLetter: 'U',  smallLetter: 'u',  sound: 'sound/U.mp3'),
    LetterSound(capitalLetter: 'W',  smallLetter: 'w',  sound: 'sound/W.mp3'),
    LetterSound(capitalLetter: 'Y',  smallLetter: 'y',  sound: 'sound/Y.mp3'),
  ];

  late List<bool> _learned;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _learned = List.filled(_letters.length, false);
    _flipCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final loaded = <bool>[];
    int count = 0;
    for (int i = 0; i < _letters.length; i++) {
      final v = await _savedData.isLearned(_category, i);
      loaded.add(v);
      if (v) count++;
    }
    if (!mounted) return;
    setState(() {
      _learned = loaded;
      _learnedCount = count;
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _flipCtrl.dispose();
    super.dispose();
  }

  Future<void> _playAudio(int i) async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    try {
      await _player.play(AssetSource(_letters[i].sound));
      final dur = await _player.getDuration();
      if (dur != null) await Future.delayed(dur);
      await _player.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _isPlaying = false);
  }

  Future<void> _toggleLearned(int i) async {
    final newVal = !_learned[i];
    await _savedData.setLearned(_category, i, value: newVal);
    final count = await _savedData.learnedCount(_category, _letters.length);
    if (!mounted) return;
    setState(() {
      _learned[i] = newVal;
      _learnedCount = count;
    });
  }

  void _openDetail(int i) {
    _flipCtrl.forward(from: 0);
    setState(() {
      _zoom = true;
      _index = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            elevation: 3,
            shape: const CircleBorder(),
            color: context.c.card,
            child: IconButton(
              icon: Icon(Icons.chevron_left_rounded, color: context.c.text),
              onPressed: () {
                if (_zoom) {
                  setState(() => _zoom = false);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ),
        title: Text('Alphabet',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: context.c.text)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: kGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kGreen.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '$_learnedCount/${_letters.length}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.c.accent),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: _zoom
            ? _buildDetail(key: ValueKey('alpha_detail_$_index'))
            : _buildGrid(key: const ValueKey('alpha_grid')),
      ),
    );
  }

  // ── Detail view ─────────────────────────────────────────────────────────────

  Widget _buildDetail({Key? key}) {
    final letter  = _letters[_index];
    final learned = _learned[_index];

    return KeyedSubtree(
      key: key,
      child: Column(
        children: [
          const SizedBox(height: 12),
          // ── Animated flip card ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedBuilder(
              animation: _flipAnim,
              builder: (_, __) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY((1 - _flipAnim.value) * 3.14159),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    decoration: BoxDecoration(
                      color: learned ? kGreen.withValues(alpha: 0.07) : context.c.card,
                      borderRadius: BorderRadius.circular(24),
                      border: learned
                          ? Border.all(color: context.c.accent, width: 1.5)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (learned ? kGreen : kGold).withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(children: [
                      // Large letter display
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: (learned ? kGreen : kGold).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            letter.capitalLetter,
                            style: TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: learned ? context.c.accent : context.c.text),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Upper + lower
                      Text(
                        '${letter.capitalLetter}  /  ${letter.smallLetter}',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: context.c.text),
                      ),
                      const SizedBox(height: 6),
                      Text('Sound: ${letter.sound.split('/').last}',
                          style: TextStyle(
                              fontSize: 12, color: context.c.textSub)),
                      if (learned) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: kGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: kGreen.withValues(alpha: 0.25)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.check_circle_rounded,
                                color: context.c.accent, size: 15),
                            const SizedBox(width: 5),
                            Text('Learned',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: context.c.accent,
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ],
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // ── Navigation + play ─────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _AlphaNavBtn(
              icon: Icons.chevron_left_rounded,
              enabled: _index > 0,
              onTap: () {
                _flipCtrl.forward(from: 0);
                setState(() => _index--);
              },
            ),
            const SizedBox(width: 16),
            // Play button
            Material(
              elevation: 6,
              shape: const CircleBorder(),
              color: kRust,
              shadowColor: kRust.withValues(alpha: 0.4),
              child: SizedBox(
                width: 72,
                height: 72,
                child: _isPlaying
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                            backgroundColor: Colors.white24),
                      )
                    : IconButton(
                        icon: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 32),
                        onPressed: () => _playAudio(_index),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            _AlphaNavBtn(
              icon: Icons.chevron_right_rounded,
              enabled: _index < _letters.length - 1,
              onTap: () {
                _flipCtrl.forward(from: 0);
                setState(() => _index++);
              },
            ),
          ]),
          const SizedBox(height: 12),
          Text('${_index + 1} of ${_letters.length}',
              style: TextStyle(fontSize: 12, color: context.c.textSub)),
          const SizedBox(height: 16),

          // ── Mark as learned ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: learned
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: kGreen.withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ]),
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleLearned(_index),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Learned'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [kShadowSoft]),
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleLearned(_index),
                        icon: const Icon(Icons.add_task_outlined, size: 18),
                        label: const Text('Mark as learned'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.c.accent,
                          side: BorderSide(color: context.c.accent, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // ── All letters strip ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24),
            child: Row(
              children: [
                const Text('All letters',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _zoom = false),
                  child: const Text('View all', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildLetterStrip()),
        ],
      ),
    );
  }

  // ── Horizontal scrollable letter strip (in detail view) ────────────────────
  Widget _buildLetterStrip() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: _letters.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (_, i) {
        final selected = i == _index;
        final learned  = _learned[i];
        return GestureDetector(
          onTap: () {
            _flipCtrl.forward(from: 0);
            setState(() => _index = i);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected
                  ? kGreen
                  : (learned ? kGreen.withValues(alpha: 0.12) : context.c.card),
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: kGreen.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ]
                  : const [kShadowSoft],
              border: learned && !selected
                  ? Border.all(color: kGreen.withValues(alpha: 0.35))
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    _letters[i].capitalLetter,
                    style: TextStyle(
                      color: selected ? Colors.white : context.c.text,
                      fontWeight: FontWeight.bold,
                      fontSize: _letters[i].capitalLetter.length > 1 ? 14 : 18,
                    ),
                  ),
                ),
                if (learned && !selected)
                  Positioned(
                    top: 3,
                    right: 3,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: context.c.accent,
                          borderRadius: BorderRadius.circular(5)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Grid view ───────────────────────────────────────────────────────────────

  Widget _buildGrid({Key? key}) {
    return KeyedSubtree(
      key: key,
      child: GridView.count(
        crossAxisCount: 6,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: List.generate(_letters.length, (i) {
          final learned = _learned[i];
          return _LetterCell(
            letter: _letters[i].capitalLetter,
            learned: learned,
            onTap: () => _openDetail(i),
          );
        }),
      ),
    );
  }
}

// ── Grid letter cell ──────────────────────────────────────────────────────────
class _LetterCell extends StatefulWidget {
  final String letter;
  final bool learned;
  final VoidCallback onTap;

  const _LetterCell(
      {required this.letter, required this.learned, required this.onTap});

  @override
  State<_LetterCell> createState() => _LetterCellState();
}

class _LetterCellState extends State<_LetterCell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: widget.learned ? kGreen.withValues(alpha: 0.12) : context.c.card,
            borderRadius: BorderRadius.circular(14),
            border: widget.learned
                ? Border.all(color: kGreen.withValues(alpha: 0.35))
                : null,
            boxShadow: const [kShadowSoft],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  widget.letter,
                  style: TextStyle(
                    color: widget.learned ? context.c.accent : context.c.text,
                    fontWeight: FontWeight.bold,
                    fontSize: widget.letter.length > 1 ? 14 : 18,
                  ),
                ),
              ),
              if (widget.learned)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: context.c.accent,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav button for alphabet detail ────────────────────────────────────────────
class _AlphaNavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _AlphaNavBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: enabled ? 4 : 0,
      shape: const CircleBorder(),
      color: context.c.card,
      shadowColor: kGreen.withValues(alpha: 0.2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon,
              color: enabled ? context.c.text : Colors.grey[400], size: 26),
        ),
      ),
    );
  }
}
