import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_theme.dart';

/// Animated "thinking orb" loading indicators, ported from the MIT-licensed
/// `thinking-orbs` engine (Jakub Antalik). All nine states are ported:
///
/// - [OrbState.working]     — particles on tilted orbit paths
/// - [OrbState.searching]   — a scan meridian sweeps a dotted globe
/// - [OrbState.solving]     — bands scramble, then click back solved
/// - [OrbState.listening]   — a waveform rolls through the rings
/// - [OrbState.connecting]  — a constellation wires itself
/// - [OrbState.weaving]     — three strands plait around the sphere
/// - [OrbState.composing]   — an undulating multi-band sash
/// - [OrbState.breathing]   — a ring slowly morphing
/// - [OrbState.shaping]     — dotted outline: circle → triangle → square
///
/// Dots are depth-shaded: far dots are faint, near dots carry the app accent.
/// Honors MediaQuery.disableAnimations (draws one static frame).
enum OrbState {
  working,
  searching,
  solving,
  listening,
  connecting,
  weaving,
  composing,
  breathing,
  shaping,
}

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
    _painter.configure(
      state: widget.state,
      isDark: Theme.of(context).brightness == Brightness.dark,
      accent: context.c.accent,
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

class _Line {
  double x1, y1, x2, y2, white, a, w;
  _Line(this.x1, this.y1, this.x2, this.y2, this.white, this.a, this.w);
}

class _Frame {
  final List<_Dot> dots;
  final List<_Line> lines;
  _Frame(this.dots, this.lines);
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

_Projector _makeProj(
    double yaw, double tilt, double cx, double cy, double scale) {
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

double _angleDelta(double a, double b) =>
    math.atan2(math.sin(a - b), math.cos(a - b));

double _radiusScale(double size, double pow) =>
    math.pow(size / 300, pow).toDouble();

double _lerp(double a, double b, double f) => a + (b - a) * f;

double _vnoise(double x, double y) {
  final xi = x.floor();
  final yi = y.floor();
  var fx = x - xi;
  var fy = y - yi;
  fx = fx * fx * (3 - 2 * fx);
  fy = fy * fy * (3 - 2 * fy);
  final a = _hashD(xi.toDouble(), yi.toDouble());
  final b = _hashD((xi + 1).toDouble(), yi.toDouble());
  final c = _hashD(xi.toDouble(), (yi + 1).toDouble());
  final d = _hashD((xi + 1).toDouble(), (yi + 1).toDouble());
  return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy;
}

/// Drop invisible marks, clamp radii, z-sort far→near into draw order.
_Frame _finalize(List<_Dot> dots, List<_Line> lines, double rMin) {
  final visible = dots.where((d) => d.a >= 0.02).toList();
  for (final d in visible) {
    if (d.r < rMin) d.r = rMin;
  }
  visible.sort((a, b) => a.z.compareTo(b.z));
  return _Frame(
      visible, lines.where((l) => l.a >= 0.02).toList());
}

// ── Preset resolution (ported from presets.ts + profiles.ts) ────────────────

typedef _Opts = Map<String, double>;

const _countPairs = [
  ['latRings', 'lonDensity'],
  ['rings', 'lonDensity'],
  ['lanes', 'segs'],
];
const _countKeys = ['orbitN', 'ghostN', 'nodeN', 'strandN', 'signals'];
const _iconDensityKeys = ['iconD'];
const _radiusKeys = [
  'rBase', 'rDepth', 'rActive', 'rDot', 'ghostR', 'partR', 'partRDepth',
  'nodeR', 'nodeRDepth'
];

_Opts _scaleCounts(_Opts o, double scale) {
  final out = Map<String, double>.of(o);
  final done = <String>{};
  final rt = math.sqrt(scale);
  for (final pair in _countPairs) {
    final va = out[pair[0]];
    final vb = out[pair[1]];
    if (va != null &&
        vb != null &&
        !done.contains(pair[0]) &&
        !done.contains(pair[1])) {
      out[pair[0]] = math.max(2, (va * rt).round()).toDouble();
      out[pair[1]] = math.max(2, (vb * rt).round()).toDouble();
      done.add(pair[0]);
      done.add(pair[1]);
    }
  }
  for (final k in _countKeys) {
    final v = out[k];
    if (v != null && v != 0 && !done.contains(k)) {
      out[k] = math.max(1, (v * scale).round()).toDouble();
    }
  }
  for (final k in _iconDensityKeys) {
    final v = out[k];
    if (v != null) out[k] = math.max(0.02, v * scale);
  }
  return out;
}

_Opts _scaleRadii(_Opts o, double scale) {
  final out = Map<String, double>.of(o);
  for (final k in _radiusKeys) {
    final v = out[k];
    if (v != null) out[k] = v * scale;
  }
  out['rSizeMul'] = (out['rSizeMul'] ?? 1) * scale;
  return out;
}

const _baseProfiles = <String, _Opts>{
  'globe': {
    'latRings': 17, 'lonDensity': 44, 'rBase': 0.6, 'rDepth': 1.7,
    'rBoost': 1.0, 'inkFar': 0.62, 'inkSpan': 0.54, 'rsPow': 0.6, 'rMin': 0.3,
  },
  'orbits': {
    'orbitN': 12, 'ghostN': 40, 'ghostR': 0.9, 'ghostA': 0.5, 'particles': 3,
    'partR': 1.2, 'partRDepth': 1.6, 'rsPow': 0.6, 'rMin': 0.3,
  },
  'rubik': {
    'latRings': 15, 'lonDensity': 40, 'moveCount': 14, 'rBase': 0.6,
    'rDepth': 1.7, 'rActive': 0.3, 'inkFar': 0.62, 'inkSpan': 0.54,
    'rsPow': 0.6, 'rMin': 0.3,
  },
  'wave': {
    'rings': 15, 'lonDensity': 40, 'rBase': 0.6, 'rDepth': 1.7,
    'rsPow': 0.6, 'rMin': 0.3,
  },
  'web': {
    'nodeN': 30, 'thr': 0.72, 'signals': 5, 'nodeR': 1.4, 'nodeRDepth': 1.8,
    'lineW': 0.8, 'rsPow': 0.6, 'rMin': 0.3,
  },
  'braid': {
    'strandN': 52, 'turns': 3.0, 'ghostN': 150, 'rBase': 1.2, 'rDepth': 1.8,
    'rsPow': 0.6, 'rMin': 0.3,
  },
  'ribbon': {
    'lanes': 5, 'segs': 88, 'ghostN': 150, 'rBase': 1.1, 'rDepth': 1.7,
    'rsPow': 0.6, 'rMin': 0.3,
  },
  'ring': {
    'lanes': 5, 'segs': 88, 'ghostN': 0, 'faceOn': 1, 'rBase': 1.1,
    'rDepth': 1.7, 'rsPow': 0.6, 'rMin': 0.3,
  },
  'morph': {'rDot': 0.021, 'iconD': 1, 'rMin': 0.25},
};

class _Preset {
  final double speed, count, size;
  final _Opts? extra;
  const _Preset(this.speed, this.count, this.size, [this.extra]);
}

// state → mode
const _stateMode = <OrbState, String>{
  OrbState.working: 'orbits',
  OrbState.searching: 'globe',
  OrbState.solving: 'rubik',
  OrbState.listening: 'wave',
  OrbState.connecting: 'web',
  OrbState.weaving: 'braid',
  OrbState.composing: 'ribbon',
  OrbState.breathing: 'ring',
  OrbState.shaping: 'morph',
};

// mode → preset for the 64px size class
const _presets64 = <String, _Preset>{
  'orbits': _Preset(1.885, 1, 1),
  'globe': _Preset(2.015, 0.42, 1.15, {'scanMul': 4.08, 'dimBase': 0.45}),
  'rubik': _Preset(1.82, 0.35, 1.05),
  'wave': _Preset(4.388, 0.341, 1),
  'web': _Preset(3.315, 1.35, 0.95),
  'braid': _Preset(1.625, 0.5, 1),
  'ribbon': _Preset(2.34, 0.25, 0.85,
      {'spin': 0, 'bandMul': 3.9, 'wobMul': 1}),
  'ring': _Preset(3.24, 0.25, 0.956,
      {'spin': 0, 'bandMul': 3.627, 'wobMul': 0.368}),
  'morph': _Preset(2.405, 0.702, 0.395, {'spread': 1.45}),
};

({double speed, _Opts opts}) _resolve(OrbState state) {
  final mode = _stateMode[state]!;
  final p = _presets64[mode]!;
  var opts = Map<String, double>.of(_baseProfiles[mode]!);
  if (p.count != 1) opts = _scaleCounts(opts, p.count);
  if (p.size != 1) opts = _scaleRadii(opts, p.size);
  if (p.extra != null) opts = {...opts, ...p.extra!};
  return (speed: p.speed, opts: opts);
}

// ── Mode: orbits ("working") ────────────────────────────────────────────────

_Frame _frameOrbits(double size, double t, _Opts o) {
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
    final spd = (0.25 + 0.55 * h3) * (h3 > 0.5 ? 1 : -1);

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
    for (var m = 0; m < particles; m++) {
      final a = t * spd + (m / particles) * 2 * math.pi + h2 * 6;
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
  return _finalize(dots, const [], o['rMin'] ?? 0.3);
}

// ── Mode: ribbon / ring ("composing" / "breathing") ─────────────────────────

_Frame _frameRibbon(double size, double t, _Opts o) {
  final cx = size / 2;
  final cy = size / 2;
  final R = (size / 2) * 0.78;
  final spin = o['spin'] ?? 1;
  const camTilt = 0.3;
  final pt = _makeProj(t * 0.1 * spin, camTilt, cx, cy, 1);
  final rs = _radiusScale(size, o['rsPow'] ?? 0.6);
  final faceOn = o['faceOn'] == 1;

  final dots = <_Dot>[];
  final ghostN = (o['ghostN'] ?? 150).round();
  for (var i = 0; i < ghostN; i++) {
    final d = _fibDir(i, ghostN);
    final p = pt(d[0] * R, d[1] * R, d[2] * R);
    final depth = (p[2] / R + 1) / 2;
    dots.add(_Dot(p[0], p[1], p[2], 0.8 * rs, 0.78, 0.1 + 0.22 * depth));
  }

  final ya = t * 0.24 * spin;
  final ta = faceOn ? -camTilt : 0.55 + 0.3 * math.sin(t * 0.18) * spin;
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
  final baseR = faceOn ? R / (1 + 0.85 * wobAmp) : R;

  final baseLanes = o['lanes'] ?? 5;
  final segs = (o['segs'] ?? 88).round();
  final lanes = math.max(1, (baseLanes * (o['bandMul'] ?? 1)).round());
  for (var w = 0; w < lanes; w++) {
    final laneOff = (w - (lanes - 1) / 2) * 0.075;
    final edge =
        ((w - (lanes - 1) / 2).abs()) / math.max(1, (lanes - 1) / 2);
    for (var k = 0; k < segs; k++) {
      final a = (k / segs) * 2 * math.pi;
      final wob = (0.16 * math.sin(a * 3 - t * 1.7 + w * 0.22) +
              0.07 * math.sin(a * 5 + t * 1.1)) *
          (o['wobMul'] ?? 1);
      final radial = faceOn ? 1 + wob : 1.0;
      final off = faceOn ? laneOff : laneOff + wob;
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
  return _finalize(dots, const [], o['rMin'] ?? 0.3);
}

// ── Mode: lattice family ("searching" / "solving" / "listening") ────────────

_Frame _frameGlobe(double size, double t, _Opts o) {
  const spin = 0.5;
  final cx = size / 2;
  final cy = size / 2;
  final radius = (size / 2) * 0.82;
  final tilt = 0.4 + 0.06 * math.sin(t * 0.35);
  final pt = _makeProj(t * spin, tilt, cx, cy, radius);
  final scan = t * (spin + (1.7 - spin) * (o['scanMul'] ?? 1));
  final rs = _radiusScale(size, o['rsPow'] ?? 0.6);
  final dimBase = o['dimBase'] ?? 1;

  final dots = <_Dot>[];
  final latRings = (o['latRings'] ?? 17).round();
  final lonDensity = (o['lonDensity'] ?? 44).round();
  for (var li = 0; li <= latRings; li++) {
    final lat = -math.pi / 2 + (li / latRings) * math.pi;
    final cosLat = math.cos(lat);
    final sinLat = math.sin(lat);
    final lonCount =
        math.max(1, (cosLat.abs() * lonDensity).round());
    for (var lj = 0; lj < lonCount; lj++) {
      final lon = (lj / lonCount) * 2 * math.pi;
      final p = pt(cosLat * math.cos(lon), sinLat, cosLat * math.sin(lon));
      final depth = (p[2] + 1) / 2;
      final d = _angleDelta(lon + t * spin, scan);
      final boost =
          math.exp(-(d * d) / 0.18) * math.max(0, p[2]);
      dots.add(_Dot(
          p[0],
          p[1],
          p[2],
          ((o['rBase'] ?? 0.6) +
                  (o['rDepth'] ?? 1.7) * depth +
                  (o['rBoost'] ?? 1) * boost) *
              rs,
          (o['inkFar'] ?? 0.62) - (o['inkSpan'] ?? 0.54) * depth,
          dimBase + (1 - dimBase) * math.min(1, boost)));
    }
  }
  return _finalize(dots, const [], o['rMin'] ?? 0.3);
}

class _Move {
  final int axis;
  final double lo, hi, ang;
  const _Move(this.axis, this.lo, this.hi, this.ang);
}

List<_Move> _makeMoves(int count) {
  final moves = <_Move>[];
  for (var i = 0; i < count; i++) {
    final axis = math.min(2, (_hashD(i.toDouble(), 2.3) * 3).floor());
    final lo = -1.0 + 0.5 * math.min(3, (_hashD(i.toDouble(), 5.9) * 4).floor());
    final dir = _hashD(i.toDouble(), 7.7) < 0.5 ? 1 : -1;
    moves.add(_Move(axis, lo, lo + 0.5, (dir * math.pi) / 2));
  }
  return moves;
}

({List<double> amount, int active}) _solveCycle(
    double time, int count, double slotDur, double rest) {
  final cyc = 2 * count * slotDur + rest;
  final tc = time % cyc;
  final amount = List<double>.filled(count, 0);
  var active = -1;
  if (tc < 2 * count * slotDur) {
    final slot = (tc / slotDur).floor();
    final p = (tc - slot * slotDur) / slotDur;
    final cl = math.min(1, p / 0.7);
    final ep = 1 - math.pow(1 - cl, 3).toDouble();
    if (slot < count) {
      for (var i = 0; i < slot; i++) {
        amount[i] = 1;
      }
      amount[slot] = ep;
      active = slot;
    } else {
      final u = 2 * count - 1 - slot;
      for (var i = 0; i < u; i++) {
        amount[i] = 1;
      }
      amount[u] = 1 - ep;
      active = u;
    }
  }
  return (amount: amount, active: active);
}

({double x, double y, double z, bool inActive}) _applyMoves(
    double x, double y, double z, List<_Move> moves,
    ({List<double> amount, int active}) sc) {
  var inActive = false;
  for (var i = 0; i < moves.length; i++) {
    if (sc.amount[i] <= 0) continue;
    final mv = moves[i];
    final coord = mv.axis == 0 ? x : mv.axis == 1 ? y : z;
    if (coord < mv.lo || coord >= mv.hi) continue;
    if (i == sc.active) inActive = true;
    final a = mv.ang * sc.amount[i];
    final ca = math.cos(a);
    final sa = math.sin(a);
    if (mv.axis == 0) {
      final y2 = y * ca - z * sa;
      z = y * sa + z * ca;
      y = y2;
    } else if (mv.axis == 1) {
      final x2 = x * ca + z * sa;
      z = -x * sa + z * ca;
      x = x2;
    } else {
      final x2 = x * ca - y * sa;
      y = x * sa + y * ca;
      x = x2;
    }
  }
  return (x: x, y: y, z: z, inActive: inActive);
}

_Frame _frameRubik(double size, double t, _Opts o) {
  final cx = size / 2;
  final cy = size / 2;
  final R = (size / 2) * 0.82;
  final pt = _makeProj(t * 0.55, 0.35 + 0.1 * math.sin(t * 0.9), cx, cy, R);
  final rs = _radiusScale(size, o['rsPow'] ?? 0.6);
  final moveCount = (o['moveCount'] ?? 14).round();
  final moves = _makeMoves(moveCount);
  final sc = _solveCycle(t, moveCount, 0.42, 1.2);

  final dots = <_Dot>[];
  final latRings = (o['latRings'] ?? 15).round();
  final lonDensity = (o['lonDensity'] ?? 40).round();
  for (var li = 0; li <= latRings; li++) {
    final lat = -math.pi / 2 + (li / latRings) * math.pi;
    final cosLat = math.cos(lat);
    final sinLat = math.sin(lat);
    final lonCount =
        math.max(1, (cosLat.abs() * lonDensity).round());
    for (var lj = 0; lj < lonCount; lj++) {
      final lon = (lj / lonCount) * 2 * math.pi;
      final mv = _applyMoves(
          cosLat * math.cos(lon), sinLat, cosLat * math.sin(lon), moves, sc);
      final p = pt(mv.x, mv.y, mv.z);
      final depth = (p[2] + 1) / 2;
      dots.add(_Dot(
          p[0],
          p[1],
          p[2],
          ((o['rBase'] ?? 0.6) +
                  (o['rDepth'] ?? 1.7) * depth +
                  (mv.inActive ? (o['rActive'] ?? 0.3) : 0)) *
              rs,
          (o['inkFar'] ?? 0.62) -
              (o['inkSpan'] ?? 0.54) * depth -
              (mv.inActive ? 0.14 : 0)));
    }
  }
  return _finalize(dots, const [], o['rMin'] ?? 0.3);
}

_Frame _frameWave(double size, double t, _Opts o) {
  final cx = size / 2;
  final cy = size / 2;
  final R = (size / 2) * 0.874;
  final pt = _makeProj(t * 0.18, 0.38, cx, cy, 1);
  final rs = _radiusScale(size, o['rsPow'] ?? 0.6);

  final dots = <_Dot>[];
  final rings = (o['rings'] ?? 15).round();
  final lonDensity = (o['lonDensity'] ?? 40).round();
  for (var ri = 0; ri <= rings; ri++) {
    final lat = -math.pi / 2 + (ri / rings) * math.pi;
    final cosLat = math.cos(lat);
    final sinLat = math.sin(lat);
    final w = 0.62 * math.sin(t * 2.1 - ri * 0.52) +
        0.38 * math.sin(t * 1.27 + ri * 0.83);
    final rr = R * (0.88 + 0.105 * w);
    final lonCount =
        math.max(1, (cosLat.abs() * lonDensity).round());
    for (var lj = 0; lj < lonCount; lj++) {
      final lon = (lj / lonCount) * 2 * math.pi;
      final p = pt(
          cosLat * math.cos(lon) * rr, sinLat * rr, cosLat * math.sin(lon) * rr);
      final depth = (p[2] / R + 1) / 2;
      final crest = math.max(0, w);
      dots.add(_Dot(
          p[0],
          p[1],
          p[2],
          ((o['rBase'] ?? 0.6) + (o['rDepth'] ?? 1.7) * depth) *
              (1 + 0.4 * crest) *
              rs,
          0.66 - 0.56 * depth - 0.1 * crest));
    }
  }
  return _finalize(dots, const [], o['rMin'] ?? 0.3);
}

// ── Mode: web ("connecting") ────────────────────────────────────────────────

_Frame _frameWeb(double size, double t, _Opts o) {
  final cx = size / 2;
  final cy = size / 2;
  final R = (size / 2) * 0.8 * (o['spread'] ?? 1);
  final pt = _makeProj(t * 0.12, 0.32, cx, cy, R);
  final rs = _radiusScale(size, o['rsPow'] ?? 0.6);

  final nodeN = (o['nodeN'] ?? 30).round();
  final thr = o['thr'] ?? 0.72;
  final nodeR = o['nodeR'] ?? 1.4;
  final nodeRDepth = o['nodeRDepth'] ?? 1.8;

  final nodes = <List<double>>[];
  for (var i = 0; i < nodeN; i++) {
    final d = _fibDir(i, nodeN);
    final x = d[0] +
        0.3 * (_vnoise(i * 0.31 + 9, t * 0.24) - 0.5) * 2;
    final y = d[1] +
        0.3 * (_vnoise(i * 0.53 + 27, t * 0.21) - 0.5) * 2;
    final z = d[2] +
        0.3 * (_vnoise(i * 0.77 + 55, t * 0.27) - 0.5) * 2;
    final l = math.sqrt(x * x + y * y + z * z);
    nodes.add([x / l, y / l, z / l]);
  }

  final lines = <_Line>[];
  final dots = <_Dot>[];

  for (var i = 0; i < nodeN; i++) {
    for (var j = i + 1; j < nodeN; j++) {
      final dx = nodes[i][0] - nodes[j][0];
      final dy = nodes[i][1] - nodes[j][1];
      final dz = nodes[i][2] - nodes[j][2];
      final dist = math.sqrt(dx * dx + dy * dy + dz * dz);
      if (dist >= thr) continue;
      final p1 = pt(nodes[i][0], nodes[i][1], nodes[i][2]);
      final p2 = pt(nodes[j][0], nodes[j][1], nodes[j][2]);
      final depth = ((p1[2] + p2[2]) / 2 + 1) / 2;
      lines.add(_Line(p1[0], p1[1], p2[0], p2[1], 0.42,
          (1 - dist / thr) * (0.3 + 0.55 * depth),
          math.max(0.6, (o['lineW'] ?? 0.8) * rs)));
    }
  }

  for (var i = 0; i < nodeN; i++) {
    final p = pt(nodes[i][0], nodes[i][1], nodes[i][2]);
    final depth = (p[2] + 1) / 2;
    final pulse = 1 + 0.25 * math.sin(t * 1.4 + i * 2.7);
    dots.add(_Dot(p[0], p[1], p[2],
        (nodeR + nodeRDepth * depth) * pulse * rs, 0.55 - 0.45 * depth));
  }

  final signals = (o['signals'] ?? 5).round();
  for (var s = 0; s < signals; s++) {
    final seg = (t * 0.55 + s * 7.31).floor();
    final a = (_hashD(seg.toDouble(), s * 3.1 + 1.7) * nodeN).floor();
    final b = (_hashD(seg.toDouble(), s * 5.7 + 4.2) * nodeN).floor();
    if (a == b) continue;
    final f = _frac(t * 0.55 + s * 7.31);
    final x = _lerp(nodes[a][0], nodes[b][0], f);
    final y = _lerp(nodes[a][1], nodes[b][1], f);
    final z = _lerp(nodes[a][2], nodes[b][2], f);
    final l = math.max(1e-6, math.sqrt(x * x + y * y + z * z));
    final p = pt(x / l, y / l, z / l);
    final depth = (p[2] + 1) / 2;
    dots.add(_Dot(p[0], p[1], p[2],
        (nodeR * 1.5 + nodeRDepth * depth) * rs, 0.05, 0.5 + 0.5 * depth));
  }

  return _finalize(dots, lines, o['rMin'] ?? 0.3);
}

// ── Mode: braid ("weaving") ────────────────────────────────────────────────

_Frame _frameBraid(double size, double t, _Opts o) {
  final cx = size / 2;
  final cy = size / 2;
  final R = (size / 2) * 0.76;
  final pt = _makeProj(t * 0.4, 0.3, cx, cy, 1);
  final rs = _radiusScale(size, o['rsPow'] ?? 0.6);

  final dots = <_Dot>[];
  final ghostN = (o['ghostN'] ?? 150).round();
  for (var i = 0; i < ghostN; i++) {
    final d = _fibDir(i, ghostN);
    final p = pt(d[0] * R, d[1] * R, d[2] * R);
    final depth = (p[2] / R + 1) / 2;
    dots.add(_Dot(p[0], p[1], p[2], 0.8 * rs, 0.78, 0.1 + 0.22 * depth));
  }

  final strandN = (o['strandN'] ?? 52).round();
  final turns = o['turns'] ?? 3;
  for (var s = 0; s < 3; s++) {
    final phase = (s / 3) * 2 * math.pi;
    for (var i = 0; i < strandN; i++) {
      final u = (_frac(i / strandN + t * 0.045) * 2 - 1) * 0.96;
      final surf = math.sqrt(math.max(0, 1 - u * u));
      final endFade = math.min(1, (1 - u.abs()) / 0.1);
      final a = u * math.pi * turns + phase;
      final weave =
          1 + 0.075 * math.sin(u * math.pi * turns * 2 + phase * 2 + t * 0.8);
      final rr = surf * R * weave;
      final p = pt(math.cos(a) * rr, u * R * weave, math.sin(a) * rr);
      final depth = (p[2] / R + 1) / 2;
      dots.add(_Dot(
          p[0],
          p[1],
          p[2],
          ((o['rBase'] ?? 1.2) + (o['rDepth'] ?? 1.8) * depth) * rs,
          0.55 - 0.45 * depth,
          endFade * (0.45 + 0.55 * depth)));
    }
  }
  return _finalize(dots, const [], o['rMin'] ?? 0.3);
}

// ── Mode: morph ("shaping") ────────────────────────────────────────────────

typedef _Path = List<double> Function(double f);

double _smoothE(double x) => x * x * (3 - 2 * x);

_Path _polyPath(List<List<double>> verts) {
  final v = verts.length;
  final l = <double>[];
  var total = 0.0;
  for (var i = 0; i < v; i++) {
    final a = verts[i];
    final b = verts[(i + 1) % v];
    final len = math.sqrt(math.pow(b[0] - a[0], 2) + math.pow(b[1] - a[1], 2));
    l.add(len);
    total += len;
  }
  return (f) {
    var target = f * total;
    var i = 0;
    while (target > l[i] && i < v - 1) {
      target -= l[i];
      i++;
    }
    final a = verts[i];
    final b = verts[(i + 1) % v];
    final ff = l[i] != 0 ? math.min(1, target / l[i]) : 0.0;
    return [a[0] + (b[0] - a[0]) * ff, a[1] + (b[1] - a[1]) * ff];
  };
}

List<double> _circlePath(double f) {
  final a = -math.pi / 2 + f * 2 * math.pi;
  return [math.cos(a) * 0.24, math.sin(a) * 0.24];
}
final _trianglePath = _polyPath([
  [0.0, -0.26],
  [0.24, 0.16],
  [-0.24, 0.16],
]);
final _squarePath = _polyPath([
  [0, -0.2],
  [0.2, -0.2],
  [0.2, 0.2],
  [-0.2, 0.2],
  [-0.2, -0.2],
]);
final _cycle = [_circlePath, _trianglePath, _squarePath];

int _morphN(double d) => math.max(6, (34 * d).round());

const _morphHold = 1.4;
const _morphDur = 0.9;
const _morphSeg = _morphHold + _morphDur;

_Frame _frameMorph(double size, double t, _Opts o) {
  const k = 3;
  final tc = t % (_morphSeg * k);
  final ki = (tc / _morphSeg).floor();
  final local = tc - ki * _morphSeg;
  final m = local > _morphHold
      ? _smoothE((local - _morphHold) / _morphDur)
      : 0.0;
  final sprd = o['spread'] ?? 1;

  final pa = _cycle[ki % k];
  final pb = _cycle[(ki + 1) % k];
  const mSamples = 160;
  final pts = <List<double>>[];
  for (var i = 0; i < mSamples; i++) {
    final f = i / mSamples;
    final a = pa(f);
    final b = pb(f);
    pts.add([
      (a[0] + (b[0] - a[0]) * m) * sprd,
      (a[1] + (b[1] - a[1]) * m) * sprd,
    ]);
  }
  final l = <double>[];
  var total = 0.0;
  for (var i = 0; i < mSamples; i++) {
    final a = pts[i];
    final b = pts[(i + 1) % mSamples];
    final len = math.sqrt(math.pow(b[0] - a[0], 2) + math.pow(b[1] - a[1], 2));
    l.add(len);
    total += len;
  }

  final n = _morphN(o['iconD'] ?? 1);
  final re = (o['rDot'] ?? 0.021) * 1.35 * sprd;
  final pulse = 1 + 0.02 * math.sin(local * 3.1);

  final dots = <_Dot>[];
  final c2 = size / 2;
  var seg = 0;
  var acc = 0.0;
  for (var k2 = 0; k2 < n; k2++) {
    final target = (k2 / n) * total;
    while (acc + l[seg] < target && seg < mSamples - 1) {
      acc += l[seg];
      seg++;
    }
    final a = pts[seg];
    final b = pts[(seg + 1) % mSamples];
    final f = l[seg] != 0 ? math.min(1, (target - acc) / l[seg]) : 0.0;
    final x = (a[0] + (b[0] - a[0]) * f) * pulse;
    final y = (a[1] + (b[1] - a[1]) * f) * pulse;
    dots.add(_Dot(c2 + x * size, c2 + y * size, 0,
        math.max(0.35, re * size), 0.1));
  }
  return _finalize(dots, const [], o['rMin'] ?? 0.25);
}

// ── Frame dispatch + painter ────────────────────────────────────────────────

_Frame _frameFor(OrbState state, double size, double t, _Opts o) {
  switch (state) {
    case OrbState.working:
      return _frameOrbits(size, t, o);
    case OrbState.searching:
      return _frameGlobe(size, t, o);
    case OrbState.solving:
      return _frameRubik(size, t, o);
    case OrbState.listening:
      return _frameWave(size, t, o);
    case OrbState.connecting:
      return _frameWeb(size, t, o);
    case OrbState.weaving:
      return _frameBraid(size, t, o);
    case OrbState.composing:
    case OrbState.breathing:
      return _frameRibbon(size, t, o);
    case OrbState.shaping:
      return _frameMorph(size, t, o);
  }
}

class _OrbConfig {
  OrbState state = OrbState.working;
  Color accent = const Color(0xFF1F7A4D);
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({super.repaint});

  final _cfg = _OrbConfig();
  double t = 0;
  double speed = 1.885;
  _Opts? _opts;

  void configure({
    required OrbState state,
    required bool isDark,
    required Color accent,
  }) {
    if (_cfg.state != state || _cfg.accent != accent || _opts == null) {
      _cfg
        ..state = state
        ..accent = accent;
      final r = _resolve(state);
      speed = r.speed;
      _opts = r.opts;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    if (s <= 0 || _opts == null) return;
    final frame = _frameFor(_cfg.state, s, t, _opts!);

    final linePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;
    for (final l in frame.lines) {
      final alpha = (0.08 + 0.85 * (1 - l.white)) * l.a;
      linePaint
        ..color = _cfg.accent.withValues(alpha: alpha.clamp(0.0, 1.0))
        ..strokeWidth = l.w;
      canvas.drawLine(Offset(l.x1, l.y1), Offset(l.x2, l.y2), linePaint);
    }

    final dotPaint = Paint()..isAntiAlias = true;
    for (final d in frame.dots) {
      final alpha = ((0.08 + 0.85 * (1 - d.white)) * d.a).clamp(0.0, 1.0);
      dotPaint.color = _cfg.accent.withValues(alpha: alpha);
      canvas.drawCircle(Offset(d.x, d.y), d.r, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) => false;
}
