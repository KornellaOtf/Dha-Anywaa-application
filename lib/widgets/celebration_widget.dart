import 'dart:math';
import 'package:flutter/material.dart';
import 'package:dha_anywaaa/theme/app_fonts.dart';

/// Clean celebration popup — appears when marking a word as learned.
/// Smooth spring animation, respects dark mode, lightweight confetti.

// ─── Colors ───────────────────────────────────────────────────────────────────
const _kGreen     = Color(0xFF1F4D3A);
const _kGold      = Color(0xFFC9993A);
const _kAmber     = Color(0xFFFFB300);
const _kOrange    = Color(0xFFE65100);
const _kDark       = Color(0xFF0F1923);
const _kSurface    = Color(0xFF1A2535);

class CelebrationOverlay extends StatefulWidget {
  final CelebrationType type;
  final String? message;
  final VoidCallback? onComplete;

  const CelebrationOverlay({
    super.key,
    required this.type,
    this.message,
    this.onComplete,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final AnimationController _fadeCtrl;
  late final AnimationController _ringCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _ring;
  late final Animation<Offset> _slide;

  static const _confettiColors = [
    _kGreen, _kGold, _kAmber, _kOrange,
    Color(0xFF2D6A4F), Color(0xFFE8C87A),
  ];

  @override
  void initState() {
    super.initState();

    // Scale — spring pop
    _scaleCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutBack),
    );

    // Fade + slide — smooth entrance and exit
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));

    // Expanding ring pulse behind the badge
    _ringCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _ring = Tween<double>(begin: 0.6, end: 1.6).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut),
    );

    _scaleCtrl.forward();
    _fadeCtrl.forward();
    _ringCtrl.forward();

    // Auto dismiss after a short beat
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) {
        _fadeCtrl.reverse().then((_) {
          if (mounted) widget.onComplete?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? _kSurface : Colors.white;
    final textColor = isDark ? Colors.white : _kDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dimmed backdrop — tap to dismiss
          GestureDetector(
            onTap: () {
              _fadeCtrl.reverse().then((_) {
                if (mounted) widget.onComplete?.call();
              });
            },
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),

          // Lightweight confetti — every celebration gets a small burst
          ...List.generate(
            widget.type == CelebrationType.correct ||
                    widget.type == CelebrationType.quickWin
                ? 8
                : 14,
            (i) => _Confetti(
              index: i,
              color: _confettiColors[i % _confettiColors.length],
            ),
          ),

          // Center card
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 48),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 28),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Expanding ring pulse behind the badge
                        SizedBox(
                          width: 76,
                          height: 76,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _ring,
                                builder: (_, __) => Transform.scale(
                                  scale: _ring.value,
                                  child: Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _badgeColor().withValues(
                                            alpha: (0.4 *
                                                    (1.6 - _ring.value) /
                                                    1.0)
                                                .clamp(0.0, 0.4)),
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              _buildIcon(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _getMessage(),
                          style: AppFonts.playfair(
                            fontSize:   26,
                            fontWeight:  FontWeight.w700,
                            color:      textColor,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.message != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.message!,
                            style: TextStyle(
                              fontSize: 15,
                              color: textColor.withValues(alpha: 0.55),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _badgeColor() {
    switch (widget.type) {
      case CelebrationType.correct:
      case CelebrationType.quickWin:
        return _kGreen;
      case CelebrationType.levelUp:
        return _kAmber;
      case CelebrationType.streakMilestone:
        return _kOrange;
      case CelebrationType.confetti:
        return _kGold;
    }
  }

  Widget _buildIcon() {
    switch (widget.type) {
      case CelebrationType.correct:
      case CelebrationType.quickWin:
        return Container(
          width: 76, height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E7D5B), _kGreen],
            ),
            boxShadow: [
              BoxShadow(
                color: _kGreen.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
            ),
            child: const Icon(Icons.check_rounded, size: 38, color: Colors.white),
          ),
        );
      case CelebrationType.levelUp:
        return _filledBadge(_kAmber, Icons.emoji_events_rounded);
      case CelebrationType.streakMilestone:
        return _filledBadge(_kOrange, Icons.local_fire_department_rounded);
      case CelebrationType.confetti:
        return _filledBadge(_kGold, Icons.celebration_rounded);
    }
  }

  /// Filled circular badge with a soft glow and inner ring — used by the
  /// level-up, streak and confetti celebrations.
  Widget _filledBadge(Color color, IconData icon) {
    return Container(
      width: 76, height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.25)!,
            color,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Icon(icon, size: 36, color: Colors.white),
      ),
    );
  }

  String _getMessage() {
    switch (widget.type) {
      case CelebrationType.correct:
        return 'Perfect!';
      case CelebrationType.levelUp:
        return 'Level Up!';
      case CelebrationType.streakMilestone:
        return 'Streak!';
      case CelebrationType.confetti:
        return 'Amazing!';
      case CelebrationType.quickWin:
        return 'Great!';
    }
  }
}

// ─── Single-controller confetti particle ─────────────────────────────────────
class _Confetti extends StatefulWidget {
  final int index;
  final Color color;
  const _Confetti({required this.index, required this.color});

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;
  late final double _startX;
  late final double _drift;
  late final double _rotation;
  late final double _size;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.index * 7 + 13);
    _startX = rng.nextDouble();
    _drift = (rng.nextDouble() - 0.5) * 0.15;
    _rotation = rng.nextDouble() * 3 * pi;
    _size = 6 + rng.nextDouble() * 8;

    _ctrl = AnimationController(
      duration: Duration(milliseconds: 1200 + rng.nextInt(600)),
      vsync: this,
    );
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final screenH = MediaQuery.sizeOf(context).height;

    return AnimatedBuilder(
      animation: _progress,
      builder: (_, __) {
        final t = _progress.value;
        return Positioned(
          left: screenW * (_startX + _drift * t),
          top:  screenH * 0.3 * t,
          child: Transform.rotate(
            angle: _rotation * t,
            child: Opacity(
              opacity: (1 - t).clamp(0.0, 1.0),
              child: Container(
                width:  _size,
                height: _size * 0.6,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Types & helper ───────────────────────────────────────────────────────────
enum CelebrationType {
  correct,
  levelUp,
  streakMilestone,
  confetti,
  quickWin,
}

class CelebrationHelper {
  static void show(
    BuildContext context, {
    required CelebrationType type,
    String? message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (_) => CelebrationOverlay(
        type: type,
        message: message,
        onComplete: () {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        },
      ),
    );
  }

  static void showCorrectAnswer(BuildContext context) {
    show(context, type: CelebrationType.correct);
  }

  static void showLevelUp(BuildContext context, int newLevel) {
    show(context, type: CelebrationType.levelUp, message: 'You reached level $newLevel!');
  }

  static void showStreakMilestone(BuildContext context, int days) {
    show(context, type: CelebrationType.streakMilestone, message: '$days days in a row!');
  }

  static void showQuizComplete(BuildContext context, int score, int total) {
    show(context, type: CelebrationType.confetti, message: 'You got $score out of $total!');
  }
}
