import 'package:flutter/material.dart';

import 'package:dha_anywaaa/theme/app_theme.dart';

/// The app's brand mark: a forest-green disc carrying a white Anywaa leaf.
///
/// Shared by the splash, the welcome/name screen and the drawer header so the
/// leaf reads identically everywhere it appears. Kept as a drawn disc (not a
/// bitmap) so it stays crisp at any size and looks right in light and dark.
class BrandLeaf extends StatelessWidget {
  final double size;
  final Color color;
  final IconData icon;

  const BrandLeaf({
    super.key,
    this.size = 92,
    this.color = kGreenMid,
    this.icon = Icons.eco_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, kGreen],
        ),
        boxShadow: [
          BoxShadow(
            color: kGreen.withValues(alpha: 0.28),
            blurRadius: size * 0.34,
            offset: Offset(0, size * 0.10),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.54),
    );
  }
}
