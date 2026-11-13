import 'package:flutter/material.dart';

/// Custom page route transitions for smooth, modern navigation.
/// Replaces the default MaterialPageRoute fade/slide with polished animations.

// ─── Slide from right (default for forward navigation) ────────────────────────
class SlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final String? name;

  SlideRoute({
    required this.page,
    this.name,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          settings: RouteSettings(name: name),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(curve),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
        );
}

// ─── Slide up from bottom (for modals, drawers, detail screens) ───────────────
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final String? name;

  SlideUpRoute({
    required this.page,
    this.name,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          settings: RouteSettings(name: name),
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          transitionsBuilder: (_, animation, __, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(curve),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
        );
}

// ─── Scale + fade (for dialogs, celebrations, centered content) ──────────────
class ScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final String? name;

  ScaleRoute({
    required this.page,
    this.name,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          settings: RouteSettings(name: name),
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (_, animation, __, child) {
            final scale = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeInCubic,
            );
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
              reverseCurve: Curves.easeIn,
            );
            return ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(scale),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(fade),
                child: child,
              ),
            );
          },
        );
}

// ─── Fade (for tabs, same-level switches) ─────────────────────────────────────
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final String? name;

  FadeRoute({
    required this.page,
    this.name,
  }) : super(
          pageBuilder: (_, __, ___) => page,
          settings: RouteSettings(name: name),
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
                reverseCurve: Curves.easeIn,
              ),
              child: child,
            );
          },
        );
}

// ─── Helper: pick the right transition for the route ─────────────────────────
/// Use in MaterialApp's onGenerateRoute or inline push calls.
/// Default: SlideRoute (slide from right).
/// Pass `transition: RouteTransition.scale` for dialogs/celebrations.
/// Pass `transition: RouteTransition.slideUp` for bottom sheets/modals.
/// Pass `transition: RouteTransition.fade` for tab switches.
enum RouteTransition { slide, slideUp, scale, fade }

PageRoute<T> buildRoute<T>({
  required Widget page,
  String? name,
  RouteTransition transition = RouteTransition.slide,
}) {
  switch (transition) {
    case RouteTransition.slideUp:
      return SlideUpRoute<T>(page: page, name: name);
    case RouteTransition.scale:
      return ScaleRoute<T>(page: page, name: name);
    case RouteTransition.fade:
      return FadeRoute<T>(page: page, name: name);
    case RouteTransition.slide:
      return SlideRoute<T>(page: page, name: name);
  }
}
