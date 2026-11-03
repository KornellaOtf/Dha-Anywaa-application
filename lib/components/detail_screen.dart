import 'package:audioplayers/audioplayers.dart';
import 'package:dha_anywaaa/components/savedData.dart';
import 'package:flutter/material.dart';

/// Reusable detail + grid screen for every vocabulary category.
/// Pass [category] (matches SavedData keys), [title], and [items] list.
/// Each item must have 'anyName', 'engName', 'imageLink' keys.
/// Optionally supply [audioKey] to read item[audioKey] for audio playback.
class DetailScreen extends StatefulWidget {
  final String category;
  final String title;
  final List<Map<String, String>> items;
  final String? audioKey; // e.g. 'wordSound'; null = no audio

  const DetailScreen({
    super.key,
    required this.category,
    required this.title,
    required this.items,
    this.audioKey,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _zoom = false;
  int _index = 0;
  int _learnedCount = 0;
  late List<bool> _learned;
  late AudioPlayer _player;
  bool _isPlaying = false;
  final SavedData _savedData = SavedData();

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _learned = List.filled(widget.items.length, false);
    _loadProgress();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    int count = 0;
    final loaded = <bool>[];
    for (int i = 0; i < widget.items.length; i++) {
      final v = await _savedData.isLearned(widget.category, i);
      loaded.add(v);
      if (v) count++;
    }
    if (!mounted) return;
    setState(() {
      _learned = loaded;
      _learnedCount = count;
    });
  }

  Future<void> _toggleLearned(int i) async {
    final val = !_learned[i];
    await _savedData.setLearned(widget.category, i, value: val);
    final count =
        await _savedData.learnedCount(widget.category, widget.items.length);
    if (!mounted) return;
    setState(() {
      _learned[i] = val;
      _learnedCount = count;
    });
  }

  Future<void> _playAudio(int i) async {
    final key = widget.audioKey;
    if (key == null) return;
    final path = widget.items[i][key];
    if (path == null || path.isEmpty) return;
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    try {
      await _player.play(AssetSource(path));
      final dur = await _player.getDuration();
      if (dur != null) await Future.delayed(dur);
      await _player.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _isPlaying = false);
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
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_learnedCount/${widget.items.length}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: green),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _zoom
          ? _buildDetail(green, rust)
          : _buildGrid(),
    );
  }

  // ── Detail view ──────────────────────────────────────────────────────────

  Widget _buildDetail(Color green, Color rust) {
    final item    = widget.items[_index];
    final learned = _learned[_index];
    final hasAudio = widget.audioKey != null &&
        (item[widget.audioKey!]?.isNotEmpty ?? false);

    return SingleChildScrollView(
      child: Column(children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: learned ? green.withOpacity(0.06) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: learned ? Border.all(color: green, width: 1.5) : null,
            ),
            child: Column(children: [
              Image.asset(item['imageLink']!, height: 220, fit: BoxFit.contain),
              const SizedBox(height: 14),
              Text(item['anyName']!,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: green)),
              if ((item['engName'] ?? '').isNotEmpty)
                Text(item['engName']!,
                    style: const TextStyle(
                        fontSize: 16, color: Color(0xFF666666))),
              if (learned) ...[
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle_rounded, color: green, size: 16),
                  const SizedBox(width: 4),
                  Text('Learned',
                      style: TextStyle(
                          fontSize: 13,
                          color: green,
                          fontWeight: FontWeight.w600)),
                ]),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircleAvatar(
            radius: 28, backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Color(0xFF1C1C1C)),
              onPressed: () {
                if (_index > 0) setState(() => _index--);
              },
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 36,
            backgroundColor: hasAudio ? rust : Colors.grey[300],
            child: _isPlaying
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : IconButton(
                    icon: Icon(Icons.play_arrow,
                        color: hasAudio ? Colors.white : Colors.grey[500],
                        size: 28),
                    onPressed: hasAudio ? () => _playAudio(_index) : null,
                  ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 28, backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.chevron_right, color: Color(0xFF1C1C1C)),
              onPressed: () {
                if (_index < widget.items.length - 1) setState(() => _index++);
              },
            ),
          ),
        ]),
        const SizedBox(height: 16),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                ),
              ),
        const SizedBox(height: 24),
      ]),
    );
  }

  // ── Grid view ─────────────────────────────────────────────────────────────

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85),
      itemBuilder: (_, i) {
        final item    = widget.items[i];
        final learned = _learned[i];
        const green   = Color(0xFF1B4332);
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() { _zoom = true; _index = i; }),
          child: Container(
            decoration: BoxDecoration(
              color: learned ? green.withOpacity(0.06) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: learned
                  ? Border.all(color: green.withOpacity(0.4))
                  : null,
            ),
            child: Stack(children: [
              Column(children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(item['imageLink']!, fit: BoxFit.contain),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['anyName']!,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1C1C1C))),
                      if ((item['engName'] ?? '').isNotEmpty)
                        Text(item['engName']!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666666))),
                    ],
                  ),
                ),
              ]),
              if (learned)
                Positioned(
                  top: 8, right: 8,
                  child: Icon(Icons.check_circle_rounded,
                      color: green, size: 18),
                ),
            ]),
          ),
        );
      },
    );
  }
}
