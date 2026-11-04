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

  // OTA state
  bool   _checkingUpdate  = false;
  bool   _downloading     = false;
  double _downloadProgress = 0;
  String _otaStatus       = '';          // shown under the tile

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadVersion();
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
                  style: const TextStyle(
                      fontSize: 13, color: kTextSub, height: 1.5)),
            ],
            if (result.sizeBytes > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Size: ${(result.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB',
                style: const TextStyle(fontSize: 12, color: kTextSub)),
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
              child: const Text('Later',
                  style: TextStyle(color: kTextSub)),
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
              _downloadAndInstall(result);
            },
            child: const Text('Update now',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndInstall(OtaCheckResult result) async {
    setState(() {
      _downloading      = true;
      _downloadProgress = 0;
      _otaStatus        = 'Downloading…';
    });

    final file = await OtaService().downloadApk(
      result,
      onProgress: (p) {
        if (!mounted) return;
        setState(() {
          _downloadProgress = p;
          _otaStatus =
              'Downloading… ${(p * 100).toStringAsFixed(0)}%';
        });
      },
    );

    if (!mounted) return;

    if (file == null) {
      setState(() {
        _downloading = false;
        _otaStatus   = 'Download failed. Try again.';
      });
      return;
    }

    setState(() {
      _downloading = false;
      _otaStatus   = 'Download complete. Tap to install.';
    });

    // Open the APK. Android will prompt the user to install it
    await OpenFile.open(file.path);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const bg    = Color(0xFFF6EFE3);
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
                color: green,
              ),
              title: const Text('Sound effects',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(settings.soundEnabled ? 'On' : 'Off',
                  style: TextStyle(color: kTextSub)),
              trailing: Switch(
                value: settings.soundEnabled,
                activeThumbColor: green,
                onChanged: (v) => settings.setSoundEnabled(v),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Profile ─────────────────────────────────────────────────────
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
                          const BorderSide(color: Color(0xFFE0E0E0))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: green, width: 2)),
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
            ListTile(
              leading: const Icon(Icons.system_update_rounded,
                  color: green),
              title: const Text('Check for update',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_appVersion.isNotEmpty)
                    Text(_appVersion,
                        style: const TextStyle(
                            fontSize: 12, color: kTextSub)),
                  if (_otaStatus.isNotEmpty)
                    Text(_otaStatus,
                        style: TextStyle(
                            fontSize: 12,
                            color: _otaStatus.contains('failed')
                                ? const Color(0xFF8B3A2A)
                                : _otaStatus.contains('up to date') ||
                                        _otaStatus.contains('complete')
                                    ? green
                                    : kTextSub)),
                  if (_downloading) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _downloadProgress,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFE0E0E0),
                        color: green,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: _checkingUpdate || _downloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: green))
                  : const Icon(Icons.chevron_right,
                      color: kBorder),
              onTap: (_checkingUpdate || _downloading)
                  ? null
                  : _checkForUpdate,
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
              leading: const Icon(Icons.source_outlined,
                  color: Color(0xFF1F4D3A)),
              title: const Text('Open-source licences',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.chevron_right,
                  color: kBorder),
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
                    style: const TextStyle(
                        fontSize: 12, color: kTextSub)),
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
          style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.bold,
              color: kTextSub)),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _navTile(
      BuildContext context, IconData icon, String label, Widget page) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1F4D3A)),
      title: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: kBorder),
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}
