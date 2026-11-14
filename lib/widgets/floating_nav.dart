import 'package:flutter/material.dart';

/// A single destination in [FloatingNav].
class NavItem {
  final IconData icon;
  final String label;
  const NavItem(this.icon, this.label);
}

/// Floating pill-style bottom navigation, shared by the Practice/Learn hub
/// and the home screen. Colors default to the Practice/Learn palette; pass
/// theme-aware colors to adapt to light/dark mode.
class FloatingNav extends StatefulWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<NavItem> items;
  final Color backgroundColor;
  final Color selectedColor;
  final Color activeColor;
  final Color inactiveColor;

  const FloatingNav({
    super.key,
    required this.index,
    required this.onTap,
    required this.items,
    this.backgroundColor = const Color(0xFFECEAE6),
    this.selectedColor = const Color(0xFFD9D5CD),
    this.activeColor = const Color(0xFF1B1B1B),
    this.inactiveColor = const Color(0xFF6E6E6E),
  });

  @override
  State<FloatingNav> createState() => _FloatingNavState();
}

class _FloatingNavState extends State<FloatingNav> {
  int? _pressed;

  void _handleTap(int n) {
    setState(() => _pressed = null);
    widget.onTap(n);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedColor;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var n = 0; n < widget.items.length; n++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => setState(() => _pressed = n),
                onTapUp: (_) => _handleTap(n),
                onTapCancel: () => setState(() => _pressed = null),
                child: AnimatedScale(
                  scale: _pressed == n ? 0.88 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: n == widget.index ? selected : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      // Icon pops slightly when its tab becomes active.
                      AnimatedScale(
                        scale: n == widget.index ? 1.12 : 1.0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          widget.items[n].icon,
                          size: 22,
                          color: n == widget.index
                              ? widget.activeColor
                              : widget.inactiveColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: n == widget.index
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: n == widget.index
                              ? widget.activeColor
                              : widget.inactiveColor,
                        ),
                        child: Text(widget.items[n].label),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
