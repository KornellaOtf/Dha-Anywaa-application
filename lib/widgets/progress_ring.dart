import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Circular progress indicator for level, mastery, and daily goals
/// Elegant, minimal design that shows progress at a glance
class ProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String centerText;
  final String? subtitle;
  final Color progressColor;
  final Color backgroundColor;
  final double size;
  final double strokeWidth;

  const ProgressRing({
    Key? key,
    required this.progress,
    required this.centerText,
    this.subtitle,
    this.progressColor = Colors.blue,
    this.backgroundColor = Colors.grey,
    this.size = 120,
    this.strokeWidth = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              progress: 1.0,
              color: backgroundColor.withOpacity(0.2),
              strokeWidth: strokeWidth,
            ),
          ),
          
          // Progress circle
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              progress: progress.clamp(0.0, 1.0),
              color: progressColor,
              strokeWidth: strokeWidth,
            ),
          ),
          
          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                centerText,
                style: TextStyle(
                  fontSize: size * 0.25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: size * 0.12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw arc from top (-90°) clockwise
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Level progress card with XP details
class LevelProgressCard extends StatelessWidget {
  final int level;
  final String levelTitle;
  final int currentXP;
  final int xpToNext;
  final double progress;

  const LevelProgressCard({
    Key? key,
    required this.level,
    required this.levelTitle,
    required this.currentXP,
    required this.xpToNext,
    required this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6a11cb),
            const Color(0xFF2575fc),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ProgressRing(
            progress: progress,
            centerText: 'Lvl $level',
            progressColor: Colors.white,
            backgroundColor: Colors.white,
            size: 80,
            strokeWidth: 6,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  levelTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$xpToNext XP to level ${level + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mastery progress indicator for categories
class MasteryProgressCard extends StatelessWidget {
  final String categoryName;
  final int masteredWords;
  final int totalWords;
  final double masteryPercentage;
  final String masteryLevel;

  const MasteryProgressCard({
    Key? key,
    required this.categoryName,
    required this.masteredWords,
    required this.totalWords,
    required this.masteryPercentage,
    required this.masteryLevel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          ProgressRing(
            progress: masteryPercentage,
            centerText: '${(masteryPercentage * 100).round()}%',
            progressColor: _getMasteryColor(masteryPercentage),
            backgroundColor: Colors.white,
            size: 60,
            strokeWidth: 5,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$masteredWords/$totalWords words · $masteryLevel',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getMasteryColor(double mastery) {
    if (mastery >= 0.90) return Colors.purple;
    if (mastery >= 0.75) return Colors.blue;
    if (mastery >= 0.60) return Colors.green;
    if (mastery >= 0.40) return Colors.orange;
    return Colors.red;
  }
}

/// Daily goal progress (e.g., "Complete Daily 5")
class DailyGoalCard extends StatelessWidget {
  final String goalText;
  final bool completed;
  final VoidCallback? onTap;

  const DailyGoalCard({
    Key? key,
    required this.goalText,
    required this.completed,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: completed ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: completed
              ? Colors.green.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: completed
                ? Colors.green.withOpacity(0.5)
                : Colors.white.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: completed ? Colors.green : Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed ? Icons.check_circle : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goalText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    completed ? 'Completed! 🎉' : 'Tap to start',
                    style: TextStyle(
                      fontSize: 14,
                      color: completed ? Colors.green : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            if (!completed)
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
