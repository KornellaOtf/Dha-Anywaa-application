import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:dha_anywaaa/about.dart';
import 'package:dha_anywaaa/anywaa_ai_page.dart';
import 'package:dha_anywaaa/app_settings.dart';
import 'package:dha_anywaaa/components/savedData.dart';
import 'package:dha_anywaaa/help.dart';
import 'package:dha_anywaaa/privacy_policy_page.dart';
import 'package:dha_anywaaa/ota_update_page.dart';
import 'package:dha_anywaaa/services/ota_service.dart';
import 'package:dha_anywaaa/terms_page.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SavedData _savedData = SavedData();
  final _nameCtrl = TextEditingController();
  final OtaService _ota = OtaService();

  String _appVersion = '';
  String _name       = '';
  bool   _checking   = false;

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadVersion();
  }

  Future<void> _loadName() async {
    final n = await _savedData.getName();
    if (!mounted) return;
    setState(() => _name = n == 'guess' ? '' : n);
    _nameCtrl.text = _name;
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
  Future<void> _checkForUpdates() async {
    setState(() => _checking = true);
    final result = await _ota.checkForUpdate(forceCheck: true);
    if (!mounted) return;
    setState(() => _checking = false);

    if (result == null) {
      _toast('You\'re up to date');
      return;
    }
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => OtaUpdatePage(result: result)));
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);
    final modeLabel = switch (settings.themeMode) {
      ThemeMode.system => 'System',
      ThemeMode.light  => 'Light',
      ThemeMode.dark   => 'Dark',
    };

    return Scaffold(
      backgroundColor: context.c.bg,
      appBar: AppBar(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        title: const Text('Settings',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        children: [
          _section('General', [
            _row(
              title: 'Theme',
              trailing: _valueChevron(modeLabel),
              onTap: () => _pickTheme(settings),
            ),
            _row(
              title: 'Sound effects',
              trailing: Switch(
                value: settings.soundEnabled,
                onChanged: settings.setSoundEnabled,
              ),
            ),
            _row(
              title: 'Name',
              trailing: _valueChevron(_name.isEmpty ? 'Not set' : _name),
              onTap: _editName,
            ),
          ]),
          const SizedBox(height: 24),

          _section('Updates', [
            _row(title: 'Version', trailing: _plainValue(_appVersion)),
            _row(
              title: 'Check for updates',
              trailing: _checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: kGreen))
                  : Icon(Icons.chevron_right, color: context.c.border),
              onTap: _checking ? null : _checkForUpdates,
            ),
          ]),
          const SizedBox(height: 24),

          _section('Assistant', [
            _row(
              title: 'Anywaa AI',
              subtitle: 'Offline word helper. Ask a word, a meaning, or a number.',
              trailing: Icon(Icons.chevron_right, color: context.c.border),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AnywaaAiPage())),
            ),
          ]),
          const SizedBox(height: 24),

          _section('About', [
            _row(
                title: 'Privacy Policy',
                trailing: Icon(Icons.chevron_right, color: context.c.border),
                onTap: () => _push(const PrivacyPolicyPage())),
            _row(
                title: 'Terms of Use',
                trailing: Icon(Icons.chevron_right, color: context.c.border),
                onTap: () => _push(const TermsPage())),
            _row(
                title: 'Help',
                trailing: Icon(Icons.chevron_right, color: context.c.border),
                onTap: () => _push(const Help())),
            _row(
                title: 'About',
                trailing: Icon(Icons.chevron_right, color: context.c.border),
                onTap: () => _push(const About())),
            _row(
              title: 'Open-source licences',
              trailing: Icon(Icons.chevron_right, color: context.c.border),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Learn Dha Anywaa',
                applicationVersion: _appVersion,
              ),
            ),
          ]),

          if (_appVersion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              child: Center(
                child: Text(_appVersion,
                    style: TextStyle(fontSize: 12, color: context.c.textSub)),
              ),
            ),
        ],
      ),
    );
  }

  void _push(Widget page) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => page));

  // ── Theme picker ────────────────────────────────────────────────────────
  Future<void> _pickTheme(AppSettingsNotifier settings) async {
    final picked = await showDialog<ThemeMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Theme'),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (v) => Navigator.pop(ctx, v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final e in const {
                  ThemeMode.system: 'System',
                  ThemeMode.light: 'Light',
                  ThemeMode.dark: 'Dark',
                }.entries)
                  RadioListTile<ThemeMode>(
                    value: e.key,
                    title: Text(e.value),
                    activeColor: kGreen,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked != null) settings.setThemeMode(picked);
  }

  // ── Name editor ───────────────────────────────────────────────────────────
  Future<void> _editName() async {
    _nameCtrl.text = _name;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: _nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (saved == true) {
      final n = _nameCtrl.text.trim();
      await _savedData.setName(n);
      if (!mounted) return;
      setState(() => _name = n);
    }
  }

  // ── Row primitives (plain, hairline dividers, no icon circles) ─────────────
  Widget _section(String title, List<Widget> rows) {
    final withDividers = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        withDividers.add(Container(
            height: 1, margin: const EdgeInsets.only(left: 16), color: context.c.border));
      }
      withDividers.add(rows[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                  color: context.c.textSub)),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.c.border),
          ),
          child: Column(children: withDividers),
        ),
      ],
    );
  }

  Widget _row({
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      title: Text(title,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.c.text)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: TextStyle(fontSize: 13, color: context.c.textSub)),
      trailing: trailing,
    );
  }

  Widget _valueChevron(String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 14, color: context.c.textSub)),
          Icon(Icons.chevron_right, color: context.c.border),
        ],
      );

  Widget _plainValue(String value) => Text(value,
      style: TextStyle(fontSize: 14, color: context.c.textSub));
}
