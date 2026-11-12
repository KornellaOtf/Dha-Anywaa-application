import 'package:audioplayers/audioplayers.dart';
import 'package:dha_anywaaa/components/savedData.dart';
import 'package:dha_anywaaa/services/analytics_service.dart';
import 'package:dha_anywaaa/services/gamification_service.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:dha_anywaaa/widgets/celebration_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable detail + grid screen for every vocabulary category.
/// Pass [category] (matches SavedData keys), [title], and [items] list.
/// Each item must have 'anyName', 'engName', 'imageLink' keys.
/// Optionally supply [audioKey] to read item[audioKey] for audio playback.
class DetailScreen extends StatefulWidget {
  final String category;
  final String title;
  final List<Map<String, String>> items;
  final String? audioKey;

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
    
    // Log lesson completion and award XP when marking as learned
    if (val) {
      final itemId = widget.items[i]['engName'] ?? 'item_$i';
      AnalyticsService.instance.logCompleteLesson(widget.category, itemId);
      final gam = await GamificationService.instance.onLessonComplete();
      if (mounted) {
        // Streak milestone takes priority over level up
        if (gam.streakBonus > 0) {
          AnalyticsService.instance.logStreakMilestone(gam.streakDays);
          CelebrationHelper.showStreakMilestone(context, gam.streakDays);
        } else if (gam.leveledUp) {
          CelebrationHelper.showLevelUp(context, gam.level);
        } else {
          // Quick "correct" flash on every lesson marked
          CelebrationHelper.showCorrectAnswer(context);
        }
      }
    }
    
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
    
    // Log audio play event
    final itemId = widget.items[i]['engName'] ?? 'item_$i';
    AnalyticsService.instance.logPlayAudio(widget.category, itemId);
    
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
        title: Text(widget.title,
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
                  color: context.c.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: context.c.accent.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '$_learnedCount/${widget.items.length}',
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
      // AnimatedSwitcher for grid ↔ detail transition
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
            ? _DetailPanel(
                key: ValueKey('detail_$_index'),
                item: widget.items[_index],
                learned: _learned[_index],
                isPlaying: _isPlaying,
                hasAudio: widget.audioKey != null &&
                    (widget.items[_index][widget.audioKey!]?.isNotEmpty ??
                        false),
                index: _index,
                total: widget.items.length,
                onPrev: _index > 0
                    ? () => setState(() => _index--)
                    : null,
                onNext: _index < widget.items.length - 1
                    ? () => setState(() => _index++)
                    : null,
                onPlay: () => _playAudio(_index),
                onToggleLearned: () => _toggleLearned(_index),
                onClose: () => setState(() => _zoom = false),
              )
            : _GridView(
                key: const ValueKey('grid'),
                items: widget.items,
                learned: _learned,
                onSelect: (i) => setState(() {
                  _zoom = true;
                  _index = i;
                }),
              ),
      ),
    );
  }
}

// ── Grid sub-widget ───────────────────────────────────────────────────────────
class _GridView extends StatelessWidget {
  final List<Map<String, String>> items;
  final List<bool> learned;
  final ValueChanged<int> onSelect;

  const _GridView({
    super.key,
    required this.items,
    required this.learned,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (_, i) {
        final item    = items[i];
        final isLearn = learned[i];
        return _GridCell(
          item: item,
          learned: isLearn,
          onTap: () => onSelect(i),
        );
      },
    );
  }
}

class _GridCell extends StatefulWidget {
  final Map<String, String> item;
  final bool learned;
  final VoidCallback onTap;

  const _GridCell(
      {required this.item, required this.learned, required this.onTap});

  @override
  State<_GridCell> createState() => _GridCellState();
}

class _GridCellState extends State<_GridCell> {
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
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: gridCellDeco(context, learned: widget.learned),
          child: Stack(children: [
            Column(children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                  child: Image.asset(widget.item['imageLink']!,
                      fit: BoxFit.contain,
                      cacheWidth: 240,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: Color(0xFFCCCCCC), size: 40)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item['anyName']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: context.c.text)),
                    if ((widget.item['engName'] ?? '').isNotEmpty)
                      Text(widget.item['engName']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 12, color: context.c.textSub)),
                  ],
                ),
              ),
            ]),
            if (widget.learned)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: context.c.accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.check_rounded, color: context.c.accent, size: 14),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ── Detail sub-widget ─────────────────────────────────────────────────────────
class _DetailPanel extends StatelessWidget {
  final Map<String, String> item;
  final bool learned;
  final bool isPlaying;
  final bool hasAudio;
  final int index;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onPlay;
  final VoidCallback onToggleLearned;
  final VoidCallback onClose;

  const _DetailPanel({
    super.key,
    required this.item,
    required this.learned,
    required this.isPlaying,
    required this.hasAudio,
    required this.index,
    required this.total,
    required this.onPrev,
    required this.onNext,
    required this.onPlay,
    required this.onToggleLearned,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(children: [
        const SizedBox(height: 12),
        // ── Image + name card ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: detailCardDeco(context, learned: learned),
            child: Column(children: [
              // Subtle bg tint behind image
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: (learned ? kGreen : kGold).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(item['imageLink']!,
                    height: 200,
                    fit: BoxFit.contain,
                    cacheHeight: 400,
                    errorBuilder: (_, __, ___) => const SizedBox(
                          height: 200,
                          child: Icon(Icons.image_not_supported_outlined,
                              color: Color(0xFFCCCCCC), size: 72),
                        )),
              ),
              const SizedBox(height: 16),
              Text(item['anyName']!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: learned ? context.c.accent : context.c.text)),
              if ((item['engName'] ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(item['engName']!,
                    style: TextStyle(fontSize: 16, color: context.c.textSub)),
              ],
              if (learned) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.c.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: context.c.accent.withValues(alpha: 0.25)),
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
        ),
        const SizedBox(height: 24),

        // ── Navigation + play ────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NavButton(
              icon: Icons.chevron_left_rounded,
              onPressed: onPrev,
            ),
            if (hasAudio) ...[
              const SizedBox(width: 16),
              // Play button (terracotta) shown only when this word has audio
              Material(
                elevation: 6,
                shape: const CircleBorder(),
                color: kRust,
                shadowColor: kRust.withValues(alpha: 0.4),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: isPlaying
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
                          onPressed: onPlay,
                        ),
                ),
              ),
              const SizedBox(width: 16),
            ] else ...[
              const SizedBox(width: 24),
            ],
            _NavButton(
              icon: Icons.chevron_right_rounded,
              onPressed: onNext,
            ),
          ],
        ),

        // Position indicator
        const SizedBox(height: 12),
        Text('${index + 1} / $total',
            style: TextStyle(fontSize: 12, color: context.c.textSub)),
        const SizedBox(height: 20),

        // ── Mark as learned ──────────────────────────────────────────────────
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
                              color: kGreen.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ]),
                    child: ElevatedButton.icon(
                      onPressed: onToggleLearned,
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
                      onPressed: onToggleLearned,
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
        const SizedBox(height: 32),
      ]),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _NavButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      elevation: enabled ? 4 : 0,
      shape: const CircleBorder(),
      color: context.c.card,
      shadowColor: kGreen.withValues(alpha: 0.2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
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
