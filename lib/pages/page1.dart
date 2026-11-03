import 'package:audioplayers/audioplayers.dart';
import 'package:dha_anywaaa/components/savedData.dart';
import 'package:dha_anywaaa/letters_and_sound.dart';
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

  // per-letter learned state (loaded from prefs)
  late List<bool> _learned;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _learned = List.filled(_letters.length, false);
    _flipCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
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
      final src = AssetSource(_letters[i].sound);
      await _player.play(src);
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
    const bg    = Color(0xFFF5F0E8);
    const green = Color(0xFF1B4332);
    const rust  = Color(0xFF8B3A2A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Color(0xFF1C1C1C)),
              onPressed: () {
                if (_zoom) setState(() => _zoom = false);
                else Navigator.pop(context);
              },
            ),
          ),
        ),
        title: const Text('Alphabet'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_learnedCount/${_letters.length}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: green),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _zoom ? _buildDetail(green, rust) : _buildGrid(green),
    );
  }

  Widget _buildDetail(Color green, Color rust) {
    final letter  = _letters[_index];
    final learned = _learned[_index];

    return Column(
      children: [
        const SizedBox(height: 16),
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
                    color: learned
                        ? green.withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: learned
                        ? Border.all(color: green, width: 1.5)
                        : null,
                  ),
                  child: Column(children: [
                    Text(
                      '${letter.capitalLetter}${letter.smallLetter}',
                      style: TextStyle(
                          fontSize: 96,
                          fontWeight: FontWeight.bold,
                          color: learned ? green : const Color(0xFF1C1C1C)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${letter.capitalLetter} / ${letter.smallLetter}',
                      style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
                    ),
                    if (learned) ...[
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.check_circle_rounded, color: green, size: 18),
                        const SizedBox(width: 4),
                        Text('Learned',
                            style: TextStyle(
                                fontSize: 13, color: green, fontWeight: FontWeight.w600)),
                      ]),
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
          CircleAvatar(
            radius: 28, backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Color(0xFF1C1C1C)),
              onPressed: () {
                if (_index > 0) {
                  _flipCtrl.forward(from: 0);
                  setState(() => _index--);
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 36, backgroundColor: rust,
            child: _isPlaying
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.play_arrow,
                        color: Colors.white, size: 28),
                    onPressed: () => _playAudio(_index),
                  ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 28, backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.chevron_right, color: Color(0xFF1C1C1C)),
              onPressed: () {
                if (_index < _letters.length - 1) {
                  _flipCtrl.forward(from: 0);
                  setState(() => _index++);
                }
              },
            ),
          ),
        ]),
        const SizedBox(height: 16),
        // ── Mark as learned ───────────────────────────────────────────────
        learned
            ? ElevatedButton.icon(
                onPressed: () => _toggleLearned(_index),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Learned'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
              )
            : OutlinedButton.icon(
                onPressed: () => _toggleLearned(_index),
                icon: const Icon(Icons.radio_button_unchecked, size: 18),
                label: const Text('Mark as learned'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: green,
                  side: BorderSide(color: green),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
              ),
        const SizedBox(height: 24),
        // ── "All letters" grid below ──────────────────────────────────────
        const Padding(
          padding: EdgeInsets.only(left: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('All letters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildGrid(green, compact: true)),
      ],
    );
  }

  Widget _buildGrid(Color green, {bool compact = false}) {
    return GridView.count(
      crossAxisCount: 6,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: List.generate(_letters.length, (i) {
        final selected = _zoom && i == _index;
        final learned  = _learned[i];
        return GestureDetector(
          onTap: () => _openDetail(i),
          child: Container(
            decoration: BoxDecoration(
              color: selected
                  ? green
                  : (learned ? green.withOpacity(0.12) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: learned && !selected
                  ? Border.all(color: green.withOpacity(0.4))
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    _letters[i].capitalLetter,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF1C1C1C),
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                if (learned && !selected)
                  Positioned(
                    top: 3, right: 3,
                    child: Icon(Icons.check_circle_rounded,
                        color: green, size: 10),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
