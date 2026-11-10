import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:dha_anywaaa/services/analytics_service.dart';
import 'package:dha_anywaaa/services/ota_service.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';

/// Full-screen OTA flow that mirrors the design canvas: a plain "App update"
/// screen, an "Updating" download screen, a "Ready to install" screen and a
/// short error state. No gradients, shadows, pulsing rings or sparkle marks.
class OtaUpdatePage extends StatefulWidget {
  final OtaCheckResult result;
  const OtaUpdatePage({super.key, required this.result});

  @override
  State<OtaUpdatePage> createState() => _OtaUpdatePageState();
}

class _OtaUpdatePageState extends State<OtaUpdatePage> {
  final OtaService _ota = OtaService();
  String _installedLabel = '';

  @override
  void initState() {
    super.initState();
    _ota.download.addListener(_onDownload);
    _loadInstalled();
  }

  @override
  void dispose() {
    _ota.download.removeListener(_onDownload);
    super.dispose();
  }

  Future<void> _loadInstalled() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _installedLabel = '${info.version} (${info.buildNumber})');
  }

  void _onDownload() {
    if (mounted) setState(() {});
  }

  String get _sizeMb {
    final b = widget.result.sizeBytes;
    return b > 0 ? '${(b / 1048576).toStringAsFixed(1)} MB' : 'Unknown size';
  }

  @override
  Widget build(BuildContext context) {
    final dl = _ota.download.value;
    final title = dl.phase == OtaPhase.running || dl.phase == OtaPhase.success
        ? 'Updating'
        : 'App update';

    return Scaffold(
      backgroundColor: context.c.bg,
      appBar: AppBar(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        title: Text(title,
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                child: switch (dl.phase) {
                  OtaPhase.running => _downloading(dl),
                  OtaPhase.success => _ready(dl),
                  OtaPhase.error => _error(dl),
                  _ => _available(),
                },
              ),
            ),
            _actions(dl),
          ],
        ),
      ),
    );
  }

  // ── Available ──────────────────────────────────────────────────────────────
  Widget _available() {
    final c = context.c;
    final r = widget.result;
    final notes = _parseNotes(r.releaseNotes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _display('Version ${r.latestVersion} is available'),
        const SizedBox(height: 18),
        _card([
          _valueRow('Installed', _installedLabel),
          _divider(),
          _valueRow('New version', r.latestVersion),
          _divider(),
          _valueRow('Download size', _sizeMb),
        ]),
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text("WHAT'S NEW",
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                  color: c.textSub)),
          const SizedBox(height: 10),
          for (final n in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(n,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: c.text)),
            ),
        ],
        const SizedBox(height: 18),
        // ── Migration notice (shown for all users who may have old package) ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kGold.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kGold.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: kGold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'If Android says "package invalid" after downloading, '
                  'go to Settings → Apps → find Dha Anywaa → Uninstall, '
                  'then open the downloaded file to install. '
                  'This is a one-time step.',
                  style: TextStyle(fontSize: 13, height: 1.5, color: kGold.withValues(alpha: 0.85)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'You can switch to other apps while the download runs — it will continue in the background.',
          style: TextStyle(fontSize: 14, height: 1.5, color: c.textSub),
        ),
      ],
    );
  }

  // ── Downloading ─────────────────────────────────────────────────────────────
  Widget _downloading(OtaDownloadState dl) {
    final c = context.c;
    final pct = (dl.progress * 100).clamp(0, 100).round();
    final recvMb = (dl.progress * widget.result.sizeBytes / 1048576)
        .toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _display('Downloading ${widget.result.latestVersion}'),
        const SizedBox(height: 6),
        Text('$recvMb of $_sizeMb',
            style: TextStyle(fontSize: 14, color: c.textSub)),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: dl.progress,
            minHeight: 8,
            backgroundColor: c.border,
            valueColor: const AlwaysStoppedAnimation(kGreen),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text('$pct%',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
        ),
        const SizedBox(height: 20),
        _card([
          _stepRow(1, 'Download', active: true),
          _divider(),
          _stepRow(2, 'Check the file'),
          _divider(),
          _stepRow(3, 'Install'),
        ]),
        const SizedBox(height: 18),
        Text(
          'Keep this screen open. If the download stops, you can start again '
          'without losing anything.',
          style: TextStyle(fontSize: 14, height: 1.5, color: c.textSub),
        ),
      ],
    );
  }

  // ── Ready to install ─────────────────────────────────────────────────────────
  Widget _ready(OtaDownloadState dl) {
    final c = context.c;
    final v = widget.result.latestVersion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _display('Ready to install'),
        const SizedBox(height: 6),
        Text('Version $v', style: TextStyle(fontSize: 14, color: c.textSub)),
        const SizedBox(height: 20),
        _card([
          _checkRow('Downloaded, $_sizeMb'),
          _divider(),
          _checkRow('Version is $v'),
          _divider(),
          _checkRow('Same app as the one installed'),
        ]),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kGold.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kGold.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: kGold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'If Android says "package invalid", uninstall the old app first from '
                  'Settings → Apps → Dha Anywaa → Uninstall, then tap Install again.',
                  style: TextStyle(fontSize: 13, height: 1.5, color: kGold.withValues(alpha: 0.85)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Your name and progress stay on this phone.',
          style: TextStyle(fontSize: 14, height: 1.5, color: c.textSub),
        ),
      ],
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────
  Widget _error(OtaDownloadState dl) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _display('Update failed'),
        const SizedBox(height: 14),
        Text(
          dl.message.isEmpty
              ? 'Something went wrong while downloading. Please try again.'
              : dl.message,
          style: TextStyle(fontSize: 15, height: 1.5, color: c.textSub),
        ),
      ],
    );
  }

  // ── Bottom action bar (per phase) ────────────────────────────────────────────
  Widget _actions(OtaDownloadState dl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: switch (dl.phase) {
        OtaPhase.running => _outlined('Cancel download', () {
            Navigator.pop(context);
          }),
        OtaPhase.success => Column(
            children: [
              _primary('Install', () async {
                final p = dl.filePath;
                if (p != null) {
                  // Log install attempt
                  AnalyticsService.instance.logInstallUpdate(widget.result.latestVersion);
                  await OpenFile.open(p);
                }
              }),
              _plain('Later', () => Navigator.pop(context)),
            ],
          ),
        OtaPhase.error => Column(
            children: [
              _primary('Try again', () => _ota.startDownload(widget.result)),
              _plain('Not now', () => Navigator.pop(context)),
            ],
          ),
        _ => Column(
            children: [
              _primary('Download and install',
                  () => _ota.startDownload(widget.result)),
              _plain('Not now', () => Navigator.pop(context)),
            ],
          ),
      },
    );
  }

  // ── Building blocks ──────────────────────────────────────────────────────────
  Widget _display(String text) => Text(
        text,
        style: GoogleFonts.playfairDisplay(
            fontSize: 28, fontWeight: FontWeight.w700, color: context.c.text),
      );

  Widget _card(List<Widget> rows) => Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.c.border),
        ),
        child: Column(children: rows),
      );

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.only(left: 16),
        color: context.c.border,
      );

  Widget _valueRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 15, color: context.c.textSub)),
            Text(value,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
          ],
        ),
      );

  Widget _stepRow(int n, String label, {bool active = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? kGreen : context.c.border,
              ),
              child: active
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : Text('$n',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.c.textSub)),
            ),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(fontSize: 15, color: context.c.text)),
          ],
        ),
      );

  Widget _checkRow(String label) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration:
                  const BoxDecoration(shape: BoxShape.circle, color: kGreen),
              child:
                  const Icon(Icons.check_rounded, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(fontSize: 15, color: context.c.text)),
          ],
        ),
      );

  Widget _primary(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onTap,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      );

  Widget _outlined(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: kGreen,
            side: const BorderSide(color: kGreen),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onTap,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      );

  Widget _plain(String label, VoidCallback onTap) => TextButton(
        style: TextButton.styleFrom(foregroundColor: kGreen),
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      );
}

/// Splits release notes into clean bullet lines. Handles newline, bullet and
/// numbered markers; a single unpunctuated note becomes one entry.
List<String> _parseNotes(String notes) => notes
    .split(RegExp(r'[\r\n]+'))
    .map((s) => s.trim())
    .map((s) => s.replaceFirst(RegExp(r'^[-*•\u2022.\d\)]+\s*'), '').trim())
    .where((s) => s.isNotEmpty)
    .toList();
