import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:dha_anywaaa/about.dart';
import 'package:dha_anywaaa/app_settings.dart';
import 'package:dha_anywaaa/components/savedData.dart';
import 'package:dha_anywaaa/help.dart';
import 'package:dha_anywaaa/privacy_policy_page.dart';
import 'package:dha_anywaaa/services/ota_service.dart';
import 'package:dha_anywaaa/terms_page.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SavedData _savedData = SavedData();
  final _nameCtrl            = TextEditingController();
  String _appVersion         = '';

  // OTA state. The download itself lives in the OtaService singleton so it
  // keeps running when this screen is left, rebuilt, or a progress tick fires.
  final OtaService _ota = OtaService();
  bool   _checkingUpdate = false;
  String _otaStatus      = '';   // transient "checking / up to date" message
  bool   _apkOpened      = false;

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadVersion();
    _ota.download.addListener(_onDownloadChanged);
  }

  // Auto-launch the installer the moment a download completes.
  void _onDownloadChanged() {
    final s = _ota.download.value;
    if (s.phase == OtaPhase.success && s.filePath != null && !_apkOpened) {
      _apkOpened = true;
      OpenFile.open(s.filePath!);
    }
  }

  Future<void> _loadName() async {
    final n = await _savedData.getName();
    if (!mounted) return;
    _nameCtrl.text = n == 'guess' ? '' : n;
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = 'v${info.version} (build ${info.buildNumber})');
  }

  @override
  void dispose() {
    _ota.download.removeListener(_onDownloadChanged);
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── OTA ──────────────────────────────────────────────────────────────────

  Future<void> _checkForUpdate() async {
    setState(() { _checkingUpdate = true; _otaStatus = 'Checking…'; });
    final result = await OtaService().checkForUpdate(forceCheck: true);
    if (!mounted) return;

    if (result == null) {
      setState(() { _checkingUpdate = false; _otaStatus = 'You\'re up to date'; });
      return;
    }

    setState(() { _checkingUpdate = false; _otaStatus = ''; });
    _showUpdateDialog(result);
  }

  void _showUpdateDialog(OtaCheckResult result) {
    const green = Color(0xFF1F4D3A);
    const gold  = Color(0xFFC9993A);

    showDialog(
      context: context,
      barrierDismissible: !result.mandatory,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.system_update_rounded, color: green),
          const SizedBox(width: 8),
          const Flexible(
            child: Text('Update available',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version ${result.latestVersion} is ready.',
                style: const TextStyle(fontSize: 14)),
            if (result.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(result.releaseNotes,
                  style: TextStyle(
                      fontSize: 13, color: context.c.textSub, height: 1.5)),
            ],
            if (result.sizeBytes > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Size: ${(result.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB',
                style: TextStyle(fontSize: 12, color: context.c.textSub)),
            ],
            if (result.mandatory) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('This update is required.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8B3A2A),
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
        actions: [
          if (!result.mandatory)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Later',
                  style: TextStyle(color: context.c.textSub)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: kText,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _startDownload(result);
            },
            child: const Text('Update now',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _startDownload(OtaCheckResult result) {
    _apkOpened = false;
    _ota.startDownload(result);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bg    = context.c.bg;
    const green = Color(0xFF1F4D3A);
    final settings = AppSettings.of(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Audio ───────────────────────────────────────────────────────
          _sectionHeader('Audio'),
          _card(children: [
            ListTile(
              leading: Icon(
                settings.soundEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: context.c.accent,
              ),
              title: const Text('Sound effects',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(settings.soundEnabled ? 'On' : 'Off',
                  style: TextStyle(color: context.c.textSub)),
              trailing: Switch(
                value: settings.soundEnabled,
                activeThumbColor: context.c.accent,
                onChanged: (v) => settings.setSoundEnabled(v),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Appearance ──────────────────────────────────────────────────
          _sectionHeader('Appearance'),
          _card(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.dark_mode_rounded, color: context.c.accent),
                      const SizedBox(width: 12),
                      Text('Theme',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: context.c.text)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto_outlined),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_outlined),
                        ),
                      ],
                      selected: {settings.themeMode},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) =>
                          settings.setThemeMode(s.first),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Profile ────────────────────────────────────────────────────
          _sectionHeader('Profile'),
          _card(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Your name',
                  filled: true,
                  fillColor: bg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: context.c.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: context.c.accent, width: 2)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    final n = _nameCtrl.text.trim();
                    if (n.isEmpty) return;
                    await _savedData.setName(n);
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Name saved'),
                          behavior: SnackBarBehavior.floating),
                    );
                  },
                  child: const Text('Save name',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ── App Update ──────────────────────────────────────────────────
          _sectionHeader('App Update'),
          _card(children: [
            ValueListenableBuilder<OtaDownloadState>(
              valueListenable: _ota.download,
              builder: (context, dl, _) {
                final showDl = dl.phase == OtaPhase.running ||
                    dl.phase == OtaPhase.success ||
                    dl.phase == OtaPhase.error;
                final status = showDl ? dl.message : _otaStatus;
                final busy = _checkingUpdate || dl.phase == OtaPhase.running;
                final failed = status.contains('failed') ||
                    status.contains('incomplete') ||
                    status.contains('verification');
                return ListTile(
                  leading: Icon(Icons.system_update_rounded,
                      color: context.c.accent),
                  title: Text(
                      dl.phase == OtaPhase.success
                          ? 'Install update'
                          : 'Check for update',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_appVersion.isNotEmpty)
                        Text(_appVersion,
                            style: TextStyle(
                                fontSize: 12, color: context.c.textSub)),
                      if (status.isNotEmpty)
                        Text(status,
                            style: TextStyle(
                                fontSize: 12,
                                color: failed
                                    ? const Color(0xFF8B3A2A)
                                    : (status.contains('up to date') ||
                                            status.contains('complete'))
                                        ? context.c.accent
                                        : context.c.textSub)),
                      if (dl.phase == OtaPhase.running) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: dl.progress,
                            minHeight: 4,
                            backgroundColor: context.c.border,
                            color: green,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: green))
                      : Icon(Icons.chevron_right,
                          color: context.c.border),
                  onTap: busy
                      ? null
                      : () {
                          if (dl.phase == OtaPhase.success &&
                              dl.filePath != null) {
                            _apkOpened = false;
                            OpenFile.open(dl.filePath!);
                          } else if (dl.phase == OtaPhase.error) {
                            _ota.clearDownload();
                          } else {
                            _checkForUpdate();
                          }
                        },
                );
              },
            ),
          ]),
          const SizedBox(height: 20),

          // ── Info ────────────────────────────────────────────────────────
          _sectionHeader('Info'),
          _card(children: [
            _navTile(context, Icons.privacy_tip_outlined, 'Privacy Policy',
                const PrivacyPolicyPage()),
            const Divider(height: 1, indent: 56),
            _navTile(context, Icons.gavel_outlined, 'Terms of Use',
                const TermsPage()),
            const Divider(height: 1, indent: 56),
            _navTile(context, Icons.help_outline_rounded, 'Help',
                const Help()),
            const Divider(height: 1, indent: 56),
            _navTile(context, Icons.info_outline_rounded, 'About',
                const About()),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: Icon(Icons.source_outlined,
                  color: context.c.accent),
              title: const Text('Open-source licences',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: Icon(Icons.chevron_right,
                  color: context.c.border),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Learn Dha Anywaa',
                applicationVersion: _appVersion,
              ),
            ),
          ]),
          if (_appVersion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Text(_appVersion,
                    style: TextStyle(
                        fontSize: 12, color: context.c.textSub)),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.bold,
              color: context.c.textSub)),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
          color: context.c.card, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _navTile(
      BuildContext context, IconData icon, String label, Widget page) {
    return ListTile(
      leading: Icon(icon, color: context.c.accent),
      title: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: context.c.border),
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}
