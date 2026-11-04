import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dha_anywaaa/theme/app_theme.dart';

/// The Anywaa AI brand mark: a forest-green disc holding a white speech bubble
/// with a gold spark. Drawn (not an icon) so it scales crisply at any size and
/// reads consistently in light and dark. Optionally shows the wordmark.
class AnywaaAiLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final Color? badgeTop;
  final Color? badgeBottom;

  const AnywaaAiLogo({
    super.key,
    this.size = 40,
    this.showWordmark = false,
    this.badgeTop,
    this.badgeBottom,
  });

  @override
  Widget build(BuildContext context) {
    final top = badgeTop ?? kGreenMid;
    final bottom = badgeBottom ?? kGreen;
    final disc = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
        boxShadow: const [kShadowSoft],
      ),
      child: CustomPaint(
        painter: _MarkPainter(),
        size: Size(size, size),
      ),
    );
    if (!showWordmark) return disc;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        disc,
        SizedBox(width: size * 0.28),
        Text(
          'Anywaa AI',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: size * 0.42,
            color: context.c.text,
          ),
        ),
      ],
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size sz) {
    final s = sz.height;
    // Speech bubble: rounded rect occupying the centre.
    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTRB(s * 0.26, s * 0.26, s * 0.74, s * 0.58),
      Radius.circular(s * 0.12),
    );
    final bubblePaint = Paint()..color = Colors.white;
    canvas.drawRRect(bubble, bubblePaint);

    // Tail: small triangle under the bubble, on the left.
    final bottom = s * 0.58;
    final tail = Path()
      ..moveTo(s * 0.36, bottom - s * 0.01)
      ..lineTo(s * 0.36, s * 0.70)
      ..lineTo(s * 0.50, bottom - s * 0.01)
      ..close();
    canvas.drawPath(tail, bubblePaint);

    // Gold spark (four-point star) centred in the bubble.
    final cx = s * 0.50;
    final cy = s * 0.42;
    final r = s * 0.12;
    final inner = r * 0.34;
    final spark = Path();
    for (var i = 0; i < 8; i++) {
      final ang = (i * 45 - 90) * math.pi / 180.0;
      final rad = i.isEven ? r : inner;
      final p = Offset(cx + rad * math.cos(ang), cy + rad * math.sin(ang));
      if (i == 0) {
        spark.moveTo(p.dx, p.dy);
      } else {
        spark.lineTo(p.dx, p.dy);
      }
    }
    spark.close();
    canvas.drawPath(spark, Paint()..color = kGold);

    // Three tiny dots low in the bubble (a talking / typing cue).
    final dotPaint = Paint()..color = kGreenMid;
    final dy = s * 0.53;
    for (final dx in [0.42, 0.50, 0.58]) {
      canvas.drawCircle(Offset(s * dx, dy), s * 0.018, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => false;
}
