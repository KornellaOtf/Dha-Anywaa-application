import 'package:flutter/material.dart';
import 'dart:math';

/// The celebration system: visual rewards that trigger dopamine.
///
/// This makes learning feel AMAZING.
/// Every correct answer, completed lesson, or milestone gets celebrated.

class CelebrationOverlay extends StatefulWidget {
  final CelebrationType type;
  final String? message;
  final VoidCallback? onComplete;

  const CelebrationOverlay({
    Key? key,
    required this.type,
    this.message,
    this.onComplete,
  }) : super(key: key);

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          widget.onComplete?.call();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti particles
        if (widget.type == CelebrationType.confetti) ...[
          ...List.generate(30, (i) => _ConfettiParticle(index: i)),
        ],

        // Center message
        Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _getIcon(),
                    const SizedBox(height: 16),
                    Text(
                      _getMessage(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.message!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
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
      ],
    );
  }

  Widget _getIcon() {
    switch (widget.type) {
      case CelebrationType.correct:
        return const Icon(Icons.check_circle, size: 64, color: Colors.green);
      case CelebrationType.levelUp:
        return const Icon(Icons.emoji_events, size: 64, color: Colors.amber);
      case CelebrationType.streakMilestone:
        return const Icon(Icons.local_fire_department, size: 64, color: Colors.orange);
      case CelebrationType.confetti:
        return const Icon(Icons.celebration, size: 64, color: Color(0xFF2D5016));
    }
  }

  String _getMessage() {
    switch (widget.type) {
      case CelebrationType.correct:
        return 'Perfect!';
      case CelebrationType.levelUp:
        return 'Level Up!';
      case CelebrationType.streakMilestone:
        return 'Streak Master!';
      case CelebrationType.confetti:
        return 'Amazing!';
    }
  }
}

class _ConfettiParticle extends StatefulWidget {
  final int index;

  const _ConfettiParticle({required this.index});

  @override
  State<_ConfettiParticle> createState() => _ConfettiParticleState();
}

class _ConfettiParticleState extends State<_ConfettiParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _rotationAnimation;
  late Color _color;
  late double _size;
  late double _startX;

  @override
  void initState() {
    super.initState();
    final random = Random(widget.index);

    _controller = AnimationController(
      duration: Duration(milliseconds: 1500 + random.nextInt(1000)),
      vsync: this,
    );

    _startX = random.nextDouble() * 2 - 1; // -1 to 1
    _positionAnimation = Tween<Offset>(
      begin: Offset(_startX, -0.1),
      end: Offset(_startX + (random.nextDouble() - 0.5) * 0.3, 1.5),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: random.nextDouble() * 4 * pi,
    ).animate(_controller);

    _color = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      const Color(0xFF2D5016),
    ][random.nextInt(7)];

    _size = 8 + random.nextDouble() * 12;

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * (_positionAnimation.value.dx + 1) / 2,
          top: MediaQuery.of(context).size.height * _positionAnimation.value.dy,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: _color,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum CelebrationType {
  correct,
  levelUp,
  streakMilestone,
  confetti,
}

/// Helper to show celebrations easily
class CelebrationHelper {
  static void show(
    BuildContext context, {
    required CelebrationType type,
    String? message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => CelebrationOverlay(
        type: type,
        message: message,
        onComplete: () => Navigator.of(context).pop(),
      ),
    );
  }

  static void showCorrectAnswer(BuildContext context) {
    show(context, type: CelebrationType.correct);
  }

  static void showLevelUp(BuildContext context, int newLevel) {
    show(
      context,
      type: CelebrationType.levelUp,
      message: 'You reached level $newLevel!',
    );
  }

  static void showStreakMilestone(BuildContext context, int days) {
    show(
      context,
      type: CelebrationType.streakMilestone,
      message: '$days days in a row!',
    );
  }

  static void showQuizComplete(BuildContext context, int score, int total) {
    show(
      context,
      type: CelebrationType.confetti,
      message: 'You got $score out of $total!',
    );
  }
}
