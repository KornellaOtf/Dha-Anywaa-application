import 'package:dha_anywaaa/about.dart';
import 'package:dha_anywaaa/app_settings.dart';
import 'package:dha_anywaaa/components/savedData.dart';
import 'package:dha_anywaaa/help.dart';
import 'package:dha_anywaaa/services/ota_service.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SavedData _savedData = SavedData();
  final _nameKey = GlobalKey<FormFieldState>();
  late TextEditingController _nameCtrl;
  String _savedName = '';
  String _appVersion = '';
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _loadName();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = '${info.version} (${info.buildNumber})');
  }

  Future<void> _checkForUpdate() async {
    setState(() => _checkingUpdate = true);
    final result = await OtaService().checkForUpdate(forceCheck: true);
    if (!mounted) return;
    setState(() => _checkingUpdate = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You\'re up to date!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show update dialog
    const green = Color(0xFF1B4332);
    const gold  = Color(0xFFC9993A);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.system_update_rounded, color: green),
          const SizedBox(width: 8),
          const Text('Update available',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version ${result.latestVersion} is ready.',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            if (result.releaseNotes.isNotEmpty)
              Text(result.releaseNotes,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF666666), height: 1.5)),
            if (result.sizeBytes > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Size: ${(result.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB',
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: const Color(0xFF1C1C1C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              launchUrl(Uri.parse(result.apkUrl),
                  mode: LaunchMode.externalApplication);
            },
            child: const Text('Download',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadName() async {
    final n = await _savedData.getName();
    if (!mounted) return;
    setState(() {
      _savedName = n == 'guess' ? '' : n;
      _nameCtrl.text = _savedName;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg    = Color(0xFFF5F0E8);
    const green = Color(0xFF1B4332);
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
          // ── Sound ────────────────────────────────────────────────────────
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
                  style: const TextStyle(color: Color(0xFF888888))),
              trailing: Switch(
                value: settings.soundEnabled,
                activeColor: green,
                onChanged: (v) => settings.setSoundEnabled(v),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Profile ──────────────────────────────────────────────────────
          _sectionHeader('Profile'),
          _card(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: TextFormField(
                key: _nameKey,
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Your name',
                  filled: true,
                  fillColor: const Color(0xFFF5F0E8),
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
                      const SnackBar(content: Text('Name saved')),
                    );
                  },
                  child: const Text('Save name',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Info ─────────────────────────────────────────────────────────
          _sectionHeader('Info'),
          _card(children: [
            _navTile(context, Icons.help_outline_rounded, 'Help',
                const Help()),
            const Divider(height: 1, indent: 56),
            _navTile(context, Icons.info_outline_rounded, 'About',
                const About()),
          ]),
          const SizedBox(height: 20),

          // ── App Update ───────────────────────────────────────────────────
          _sectionHeader('App Update'),
          _card(children: [
            ListTile(
              leading: const Icon(Icons.system_update_rounded,
                  color: Color(0xFF1B4332)),
              title: const Text('Check for update',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: _appVersion.isNotEmpty
                  ? Text('Current version: $_appVersion',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF888888)))
                  : null,
              trailing: _checkingUpdate
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF1B4332)))
                  : const Icon(Icons.chevron_right,
                      color: Color(0xFFBBBBBB)),
              onTap: _checkingUpdate ? null : _checkForUpdate,
            ),
          ]),
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
              color: Color(0xFF888888))),
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
      leading: Icon(icon, color: const Color(0xFF1B4332)),
      title: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right,
          color: Color(0xFFBBBBBB)),
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}
