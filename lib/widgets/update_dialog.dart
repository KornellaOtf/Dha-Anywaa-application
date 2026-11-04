import 'package:flutter/material.dart';

import 'package:dha_anywaaa/services/ota_service.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';

/// The shared "Update available" dialog. Used both by the automatic check on
/// launch (home) and the manual "Check for update" tile (settings) so the two
/// never drift apart. [onUpdate] is invoked when the user taps the primary
/// action; the caller decides whether to start the in-app download.
Future<void> showAnywaaUpdateDialog(
  BuildContext context,
  OtaCheckResult result, {
  required VoidCallback onUpdate,
}) {
  return showDialog(
    context: context,
    barrierDismissible: !result.mandatory,
    builder: (_) => _UpdateDialog(result: result, onUpdate: onUpdate),
  );
}

class _UpdateDialog extends StatefulWidget {
  final OtaCheckResult result;
  final VoidCallback onUpdate;
  const _UpdateDialog({required this.result, required this.onUpdate});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog>
    with TickerProviderStateMixin {
  late final AnimationController _entry =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final Animation<double> _scale = Tween<double>(begin: 0.84, end: 1.0).animate(
      CurvedAnimation(parent: _entry, curve: Curves.easeOutBack));
  late final Animation<double> _fade =
      CurvedAnimation(parent: _entry, curve: const Interval(0, 0.6, curve: Curves.easeOut));
  late final Animation<Offset> _slide = Tween<Offset>(
          begin: const Offset(0, 0.07), end: Offset.zero)
      .animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));

  // Gentle, endless pulse behind the hero icon.
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))
        ..repeat(reverse: true);

  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _entry.forward());
  }

  @override
  void dispose() {
    _entry.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final r = widget.result;
    final sizeMb = r.sizeBytes > 0
        ? '${(r.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB'
        : '';
    final notes = _parseNotes(r.releaseNotes);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [kShadowCard],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _hero(r, c),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          r.mandatory ? 'Critical update' : 'A new update is ready',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: c.text,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Version ${r.latestVersion} is available for Dha Anywaa.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 14, height: 1.5, color: c.textSub),
                        ),
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _whatsNew(c, notes),
                        ],
                        if (sizeMb.isNotEmpty || r.mandatory) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              if (sizeMb.isNotEmpty)
                                _pill(c, Icons.download_rounded, sizeMb, c.textSub,
                                    c.bg, c.border),
                              if (r.mandatory)
                                _pill(c, Icons.priority_high_rounded,
                                    'Required update', kRust,
                                    kRust.withValues(alpha: 0.12),
                                    kRust.withValues(alpha: 0.22)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 22),
                        _cta(),
                        if (!r.mandatory) ...[
                          const SizedBox(height: 4),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: c.textSub,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Not now',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Gradient hero band with pulsing rings and floating download badge ──────
  Widget _hero(OtaCheckResult r, AppColors c) {
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kGreenMid, kGreen],
              ),
            ),
          ),
          // Concentric rings behind the badge.
          ...List.generate(3, (i) {
            final base = 78.0 + i * 34;
            return Container(
              width: base,
              height: base,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10 - i * 0.025)),
              ),
            );
          }),
          // The animated pulse ring.
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) => Transform.scale(
              scale: 1 + _pulse.value * 0.28,
              child: Opacity(opacity: (1 - _pulse.value) * 0.5, child: child),
            ),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
              ),
            ),
          ),
          // Solid white badge holding the up-arrow.
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_upward_rounded,
                color: kGreen, size: 30),
          ),
          if (!r.mandatory)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          Positioned(
            top: 14,
            left: 16,
            child: _chip('OTA'),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── "What's new" panel ─────────────────────────────────────────────────────
  Widget _whatsNew(AppColors c, List<String> notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 15, color: c.accent),
              const SizedBox(width: 7),
              Text("What's new",
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: c.text)),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 168),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in notes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(right: 10, top: 1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.accent.withValues(alpha: 0.14),
                            ),
                            child: Icon(Icons.check_rounded,
                                size: 13, color: c.accent),
                          ),
                          Expanded(
                            child: Text(
                              line,
                              style: TextStyle(
                                  fontSize: 13.5, height: 1.45, color: c.textSub),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pressable gradient primary action ──────────────────────────────────────
  Widget _cta() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Navigator.pop(context);
        widget.onUpdate();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.965 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [kGreenMid, kGreen],
            ),
            boxShadow: const [kShadowBtn],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.system_update_alt_rounded, color: Colors.white, size: 21),
              SizedBox(width: 10),
              Text('Update now',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16.5)),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _pill(AppColors c, IconData icon, String label, Color fg, Color bg,
    Color border) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: fg),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
      ],
    ),
  );
}

/// Splits release notes into clean bullet lines. Handles newline, bullet and
/// numbered markers; a single unpunctuated note becomes one entry.
List<String> _parseNotes(String notes) {
  final raw = notes
      .split(RegExp(r'[\r\n]+'))
      .map((s) => s.trim())
      .map((s) => s.replaceFirst(RegExp(r'^[-*•\u2022.\d\)]+\s*'), '').trim())
      .where((s) => s.isNotEmpty)
      .toList();
  return raw;
}
