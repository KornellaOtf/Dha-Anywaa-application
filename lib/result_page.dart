import 'package:dha_anywaaa/services/analytics_service.dart';
import 'package:dha_anywaaa/services/gamification_service.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:dha_anywaaa/widgets/celebration_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Result extends StatefulWidget {
  final int finalResult;
  final int total;

  const Result({super.key, required this.finalResult, required this.total});

  @override
  State<Result> createState() => _ResultState();
}

class _ResultState extends State<Result> {
  GamState? _gam;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logFinishQuiz(widget.finalResult, widget.total);
    _awardXp();
    // Fire confetti for a good score (7+ out of 10, or 70%+)
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCelebrate());
  }

  void _maybeCelebrate() {
    final pct = widget.total > 0 ? widget.finalResult / widget.total : 0.0;
    if (pct >= 0.7) {
      CelebrationHelper.showQuizComplete(context, widget.finalResult, widget.total);
    }
  }

  Future<void> _awardXp() async {
    final gam = await GamificationService.instance
        .onQuizFinish(widget.finalResult);
    if (mounted) setState(() => _gam = gam);
  }

  String _message() {
    final pct = widget.total > 0 ? (widget.finalResult / widget.total * 100).round() : 0;
    if (pct < 40) return "Keep practising.\nYou'll get there!";
    if (pct < 60) return 'Good effort!\nKeep going.';
    if (pct < 80) return 'Well done!\nAlmost there.';
    return 'Excellent!\nYou nailed it.';
  }

  IconData _icon() {
    final pct = widget.total > 0 ? (widget.finalResult / widget.total * 100).round() : 0;
    if (pct < 40) return Icons.sentiment_dissatisfied_rounded;
    if (pct < 60) return Icons.sentiment_neutral_rounded;
    if (pct < 80) return Icons.sentiment_satisfied_rounded;
    return Icons.emoji_events_rounded;
  }

  Color _iconColor() {
    final pct = widget.total > 0 ? (widget.finalResult / widget.total * 100).round() : 0;
    if (pct < 40) return kRust;
    if (pct < 60) return kGold;
    if (pct < 80) return kGreenMid;
    return kGold;
  }

  Color _ringColor() {
    final pct = widget.total > 0 ? (widget.finalResult / widget.total * 100).round() : 0;
    if (pct < 40) return kRust;
    if (pct < 60) return kGold;
    return kGreen;
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.total > 0 ? (widget.finalResult / widget.total * 100).round() : 0;

    return Scaffold(
      backgroundColor: context.c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // ── Bounce-in mood icon ──────────────────────────────────────
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _iconColor().withValues(alpha: 0.12),
                    boxShadow: [
                      BoxShadow(
                        color: _iconColor().withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(_icon(), size: 48, color: _iconColor()),
                ),
              ),
              const SizedBox(height: 20),

              // ── Message ───────────────────────────────────────────────────
              Text(
                _message(),
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.c.text,
                    height: 1.3),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // ── XP earned ─────────────────────────────────────────────────
              if (_gam != null && _gam!.awardedXp > 0)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: kGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: kGold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 18, color: kGold),
                        const SizedBox(width: 6),
                        Text(
                          '+${_gam!.awardedXp} XP  ·  Level ${_gam!.level}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kGold),
                        ),
                        if (_gam!.streakBonus > 0) ...[
                          const SizedBox(width: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department_rounded,
                                  size: 14, color: kRust),
                              const SizedBox(width: 4),
                              Text('${_gam!.streakDays} day streak!',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: kRust)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // ── Score ring ────────────────────────────────────────────────
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _ringColor(),
                    boxShadow: [
                      BoxShadow(
                        color: _ringColor().withValues(alpha: 0.40),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${widget.finalResult} / ${widget.total}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 34),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$pct%',
                        style: const TextStyle(
                            color: Color(0xCCFFFFFF),
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // ── Share button ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [kShadowSoft]),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share score'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.c.accent,
                      side: BorderSide(color: context.c.accent, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text:
                              'I scored ${widget.finalResult}/${widget.total} ($pct%) on the Dha Anywaa quiz!'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Score copied to clipboard'),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Try again ─────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: kGold.withValues(alpha: 0.40),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGold,
                      foregroundColor: kText,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () =>
                        Navigator.pushNamedAndRemoveUntil(
                            context, 'quiz', ModalRoute.withName('home_page')),
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Try again',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ]),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Back home ─────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, 'home_page', (_) => false),
                  style: TextButton.styleFrom(
                    foregroundColor: context.c.textSub,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Back to home',
                      style: TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
