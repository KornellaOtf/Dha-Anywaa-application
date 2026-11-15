import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_theme.dart';

/// Animated "thinking orb" loading indicator, ported from the MIT-licensed
/// `thinking-orbs` engine (Jakub Antalik). Two modes are ported:
///
/// - [OrbState.working]  — particles running on tilted orbit paths
/// - [OrbState.breathing] — a dotted ring whose radius slowly morphs
///
/// Dots are depth-shaded: far dots are faint, near dots carry the app accent.
/// Honors MediaQuery.disableAnimations (draws one static frame).
enum OrbState { working, breathing }

class ThinkingOrb extends StatefulWidget {
  final OrbState state;
  final double size;

  const ThinkingOrb({
    super.key,
    this.state = OrbState.working,
    this.size = 56,
  });

  @override
  State<ThinkingOrb> createState() => _ThinkingOrbState();
}

class _ThinkingOrbState extends State<ThinkingOrb>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final _OrbPainter _painter;
  final ValueNotifier<int> _frameTick = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _painter = _OrbPainter(repaint: _frameTick);
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    _painter.t = elapsed.inMicroseconds / 1e6 * _painter.speed;
    _frameTick.value++;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ticker.stop();
      _painter.t = 0.6 * _painter.speed;
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frameTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    _painter.configure(
      state: widget.state,
      isDark: Theme.of(context).brightness == Brightness.dark,
      accent: c.accent,
    );
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(painter: _painter),
    );
  }
}

// ── Engine primitives (ported from thinking-orbs/src/engine/core.ts) ────────

class _Dot {
  double x, y, z, r, white, a;
  _Dot(this.x, this.y, this.z, this.r, this.white, [this.a = 1]);
}

typedef _Projector = List<double> Function(double x, double y, double z);

double _frac(double x) => x - x.floorToDouble();

double _hashD(double a, double b) {
  final h = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
  return _frac(h);
}

final double _golden = math.pi * (3 - math.sqrt(5));

List<double> _fibDir(int i, int n) {
  final golden = _golden;
  final y = 1 - (2 * (i + 0.5)) / n;
  final rad = math.sqrt(1 - y * y);
  final a = i * golden;
  return [rad * math.cos(a), y, rad * math.sin(a)];
}

_Projector _makeProj(double yaw, double tilt, double cx, double cy,
    double scale) {
  final st = math.sin(tilt);
  final ct = math.cos(tilt);
  final sy = math.sin(yaw);
  final cyw = math.cos(yaw);
  return (x, y, z) {
    final x1 = x * cyw + z * sy;
    final z1 = -x * sy + z * cyw;
    final y1 = y * ct - z1 * st;
    final z2 = y * st + z1 * ct;
    return [cx + x1 * scale, cy - y1 * scale, z2];
  };
}

double _radiusScale(double size, double pow) =>
    math.pow(size / 300, pow).toDouble();

/// Drop invisible marks, clamp radii, z-sort far→near into draw order.
List<_Dot> _finalize(List<_Dot> dots, double rMin) {
  final visible = dots.where((d) => d.a >= 0.02).toList();
  for (final d in visible) {
    if (d.r < rMin) d.r = rMin;
  }
  visible.sort((a, b) => a.z.compareTo(b.z));
  return visible;
}

// ── Mode: orbits ("working") ────────────────────────────────────────────────
// Particles on tilted orbit paths. Preset (size 64): speed 1.885, count 1,
// size 1 — so the base profile is used unscaled.

Map<String, double> _orbitsOpts() => const {
      'orbitN': 12,
      'ghostN': 40,
      'ghostR': 0.9,
      'ghostA': 0.5,
      'particles': 3,
      'partR': 1.2,
      'partRDepth': 1.6,
      'rsPow': 0.6,
      'rMin': 0.3,
    };

List<_Dot> _frameOrbits(double size, double t, Map<String, double> o) {
  final cx = size / 2;
  final cy = size / 2;
  final R = (size / 2) * 0.82;
  final pt = _makeProj(t * 0.12, 0.3, cx, cy, 1);
  final rs = _radiusScale(size, o['rsPow'] ?? 0.6);

  final dots = <_Dot>[];
  final orbitN = (o['orbitN'] ?? 12).round();
  final ghostN = (o['ghostN'] ?? 40).round();
  final particles = (o['particles'] ?? 3).round();

  for (var orb = 0; orb < orbitN; orb++) {
    final h1 = _hashD(orb.toDouble(), 1.7);
    final h2 = _hashD(orb.toDouble(), 5.2);
    final h3 = _hashD(orb.toDouble(), 8.9);
    final ro = R * (0.45 + 0.52 * h1);
    final th = h1 * 2 * math.pi;
    final phi = math.acos(2 * h2 - 1);
    final nx = math.sin(phi) * math.cos(th);
    final ny = math.cos(phi);
    final nz = math.sin(phi) * math.sin(th);
    var ux = -ny;
    var uy = nx;
    const uz = 0.0;
    final ul = math.max(1e-6, math.sqrt(ux * ux + uy * uy));
    ux /= ul;
    uy /= ul;
    final vx = ny * uz - nz * uy;
    final vy = nz * ux - nx * uz;
    final vz = nx * uy - ny * ux;
    final speed = (0.25 + 0.55 * h3) * (h3 > 0.5 ? 1 : -1);

    // ghost path
    for (var k = 0; k < ghostN; k++) {
      final a = (k / ghostN) * 2 * math.pi;
      final p = pt(
        (ux * math.cos(a) + vx * math.sin(a)) * ro,
        (uy * math.cos(a) + vy * math.sin(a)) * ro,
        (uz * math.cos(a) + vz * math.sin(a)) * ro,
      );
      final depth = (p[2] / ro + 1) / 2;
      dots.add(_Dot(p[0], p[1], p[2], (o['ghostR'] ?? 0.9) * rs, 0.72,
          (o['ghostA'] ?? 0.5) * (0.4 + 0.6 * depth)));
    }
    // the particles doing the work
    for (var m = 0; m < particles; m++) {
      final a = t * speed + (m / particles) * 2 * math.pi + h2 * 6;
      final p = pt(
        (ux * math.cos(a) + vx * math.sin(a)) * ro,
        (uy * math.cos(a) + vy * math.sin(a)) * ro,
        (uz * math.cos(a) + vz * math.sin(a)) * ro,
      );
      final depth = (p[2] / ro + 1) / 2;
      dots.add(_Dot(
          p[0],
          p[1],
          p[2],
          ((o['partR'] ?? 1.2) + (o['partRDepth'] ?? 1.6) * depth) * rs,
          0.3 - 0.22 * depth));
    }
  }
  return _finalize(dots, o['rMin'] ?? 0.3);
}

// ── Mode: ring ("breathing") — ribbon geometry with faceOn=1 ────────────────
// Preset (size 64): speed 3.24, count 0.25, size 0.956,
// extra {spin:0, bandMul:3.627, wobMul:0.368}.

Map<String, double> _ringOpts() {
  // base ring profile, then count=0.25 → sqrt=.5 on (lanes,segs);
  // ghostN=0 stays 0; size=0.956 scales radii.
  const base = {
    'lanes': 5.0,
    'segs': 88.0,
    'ghostN': 0.0,
    'faceOn': 1.0,
    'rBase': 1.1,
    'rDepth': 1.7,
    'rsPow': 0.6,
    'rMin': 0.3,
  };
  final lanes = math.max(2, (5 * 0.5).round()).toDouble();
  final segs = math.max(2, (88 * 0.5).round()).toDouble();
  return {
    ...base,
    'lanes': lanes,
    'segs': segs,
    'rBase': 1.1 * 0.956,
    'rDepth': 1.7 * 0.956,
    'spin': 0,
    'bandMul': 3.627,
    'wobMul': 0.368,
  };
}

List<_Dot> _frameRing(double size, double t, Map<String, double> o) {
  final cx = size / 2;
  final cy = size / 2;
  final R = (size / 2) * 0.78;
  final spin = o['spin'] ?? 1;
  const camTilt = 0.3;
  final pt = _makeProj(t * 0.1 * spin, camTilt, cx, cy, 1);
  final rs = _radiusScale(size, o['rsPow'] ?? 0.6);

  final dots = <_Dot>[];
  final ghostN = (o['ghostN'] ?? 150).round();
  for (var i = 0; i < ghostN; i++) {
    final d = _fibDir(i, ghostN);
    final p = pt(d[0] * R, d[1] * R, d[2] * R);
    final depth = (p[2] / R + 1) / 2;
    dots.add(_Dot(p[0], p[1], p[2], 0.8 * rs, 0.78, 0.1 + 0.22 * depth));
  }

  final ya = t * 0.24 * spin;
  final ta = o['faceOn'] == 1 ? -camTilt : 0.55 + 0.3 * math.sin(t * 0.18) * spin;
  final ux = math.cos(ya);
  const uy = 0.0;
  final uz = math.sin(ya);
  final vx = -uz * math.sin(ta);
  final vy = math.cos(ta);
  final vz = ux * math.sin(ta);
  final nx = uy * vz - uz * vy;
  final ny = uz * vx - ux * vz;
  final nz = ux * vy - uy * vx;

  final wobAmp = 0.23 * (o['wobMul'] ?? 1);
  final baseR = o['faceOn'] == 1 ? R / (1 + 0.85 * wobAmp) : R;

  final baseLanes = o['lanes'] ?? 5;
  final segs = (o['segs'] ?? 88).round();
  final lanes =
      math.max(1, (baseLanes * (o['bandMul'] ?? 1)).round());
  for (var w = 0; w < lanes; w++) {
    final laneOff = (w - (lanes - 1) / 2) * 0.075;
    final edge =
        ((w - (lanes - 1) / 2).abs()) / math.max(1, (lanes - 1) / 2);
    for (var k = 0; k < segs; k++) {
      final a = (k / segs) * 2 * math.pi;
      final wob = (0.16 * math.sin(a * 3 - t * 1.7 + w * 0.22) +
              0.07 * math.sin(a * 5 + t * 1.1)) *
          (o['wobMul'] ?? 1);
      final radial = o['faceOn'] == 1 ? 1 + wob : 1.0;
      final off = o['faceOn'] == 1 ? laneOff : laneOff + wob;
      final x = ux * math.cos(a) + vx * math.sin(a) + nx * off;
      final y = uy * math.cos(a) + vy * math.sin(a) + ny * off;
      final z = uz * math.cos(a) + vz * math.sin(a) + nz * off;
      final l = math.sqrt(x * x + y * y + z * z);
      final rr = baseR * radial;
      final p = pt((x / l) * rr, (y / l) * rr, (z / l) * rr);
      final depth = (p[2] / R + 1) / 2;
      dots.add(_Dot(
          p[0],
          p[1],
          p[2],
          ((o['rBase'] ?? 1.1) + (o['rDepth'] ?? 1.7) * depth) *
              (1 - 0.25 * edge) *
              rs,
          0.52 - 0.44 * depth + 0.18 * edge,
          0.4 + 0.6 * depth));
    }
  }
  return _finalize(dots, o['rMin'] ?? 0.3);
}

// ── Painter ─────────────────────────────────────────────────────────────────

class _OrbConfig {
  OrbState state = OrbState.working;
  bool isDark = false;
  Color accent = const Color(0xFF1F7A4D);
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({super.repaint});

  final _cfg = _OrbConfig();
  double t = 0;
  double speed = 1.885;

  Map<String, double>? _opts;

  void configure({
    required OrbState state,
    required bool isDark,
    required Color accent,
  }) {
    final changed = _cfg.state != state ||
        _cfg.isDark != isDark ||
        _cfg.accent != accent;
    _cfg
      ..state = state
      ..isDark = isDark
      ..accent = accent;
    if (changed || _opts == null) {
      if (state == OrbState.working) {
        speed = 1.885;
        _opts = _orbitsOpts();
      } else {
        speed = 3.24;
        _opts = _ringOpts();
      }
    }
  }

  List<_Dot> _frame(double size, double tt) {
    if (_opts == null) return const [];
    return _cfg.state == OrbState.working
        ? _frameOrbits(size, tt, _opts!)
        : _frameRing(size, tt, _opts!);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    if (s <= 0) return;
    final dots = _frame(s, t);
    final paint = Paint()..isAntiAlias = true;

    for (final d in dots) {
      // white≈0 is the strongest ink (near dots), white≈1 the faintest —
      // the same depth language in both themes.
      final alpha = (0.08 + 0.85 * (1 - d.white)).clamp(0.04, 1.0);
      paint.color = _cfg.accent.withValues(alpha: alpha);
      canvas.drawCircle(Offset(d.x, d.y), d.r, paint);
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) => false;
}
