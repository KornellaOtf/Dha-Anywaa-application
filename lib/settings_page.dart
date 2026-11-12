import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:dha_anywaaa/about.dart';
import 'package:dha_anywaaa/anywaa_ai_page.dart';
import 'package:dha_anywaaa/app_settings.dart';
import 'package:dha_anywaaa/components/savedData.dart';
import 'package:dha_anywaaa/help.dart';
import 'package:dha_anywaaa/privacy_policy_page.dart';
import 'package:dha_anywaaa/ota_update_page.dart';
import 'package:dha_anywaaa/services/ota_service.dart';
import 'package:dha_anywaaa/services/analytics_service.dart';
import 'package:dha_anywaaa/services/retention_engine.dart';
import 'package:dha_anywaaa/services/share_helper.dart';
import 'package:dha_anywaaa/terms_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool   _notificationsEnabled = false;
  int    _reminderHour = 19;

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadVersion();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final stats = await RetentionEngine.instance.getStats();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = stats.notificationsEnabled;
      _reminderHour = stats.preferredHour;
    });
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
      _toast('Up to date ✓');
      return;
    }
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => OtaUpdatePage(result: result),
            settings: const RouteSettings(name: 'ota_update')));
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
              icon: Icons.palette_outlined,
              iconColor: kGreen,
              title: 'Theme',
              trailing: _valueChevron(modeLabel),
              onTap: () => _pickTheme(settings),
            ),
            _row(
              icon: Icons.volume_up_rounded,
              iconColor: kGreenMid,
              title: 'Sound effects',
              trailing: Switch(
                value: settings.soundEnabled,
                onChanged: (enabled) {
                  AnalyticsService.instance.logToggleSound(enabled);
                  settings.setSoundEnabled(enabled);
                },
              ),
            ),
            _row(
              icon: Icons.person_outline_rounded,
              iconColor: kGold,
              title: 'Name',
              trailing: _valueChevron(_name.isEmpty ? 'Not set' : _name),
              onTap: _editName,
            ),
          ]),
          const SizedBox(height: 24),

          _section('Reminders', [
            _row(
              icon: Icons.notifications_outlined,
              iconColor: kGreen,
              title: 'Daily reminder',
              subtitle: _notificationsEnabled
                  ? 'Reminds you at ${_formatHour(_reminderHour)} every day'
                  : 'Off',
              trailing: Switch(
                value: _notificationsEnabled,
                activeColor: kGreen,
                onChanged: (enabled) async {
                  if (enabled) {
                    await RetentionEngine.instance.enableNotifications(
                      preferredHour: _reminderHour,
                    );
                  } else {
                    await RetentionEngine.instance.disableNotifications();
                  }
                  setState(() => _notificationsEnabled = enabled);
                },
              ),
            ),
            if (_notificationsEnabled)
              _row(
                icon: Icons.access_time_rounded,
                iconColor: kGold,
                title: 'Reminder time',
                trailing: _valueChevron(_formatHour(_reminderHour)),
                onTap: _pickReminderTime,
              ),
          ]),
          const SizedBox(height: 24),

          _section('Updates', [
            _row(
              icon: Icons.tag,
              iconColor: kGreenMid,
              title: 'Version',
              trailing: _plainValue(_appVersion),
            ),
            _row(
              icon: Icons.system_update_alt_rounded,
              iconColor: kRust,
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

          _section('Invite Friends', [
            _row(
              icon: Icons.share_outlined,
              iconColor: kGreen,
              title: 'Invite a Friend',
              subtitle: 'Share the app on WhatsApp, Telegram, or SMS',
              trailing: Icon(Icons.chevron_right, color: context.c.border),
              onTap: () => ShareHelper.instance.shareApp(),
            ),
          ]),
          const SizedBox(height: 24),

          _section('Assistant', [
            _row(
              icon: Icons.eco_rounded,
              iconColor: kGreen,
              title: 'Anywaa AI',
              subtitle: 'Offline word helper. Ask a word, a meaning, or a number.',
              trailing: Icon(Icons.chevron_right, color: context.c.border),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AnywaaAiPage(),
                        settings: const RouteSettings(name: 'anywaa_ai')));
              },
            ),
          ]),
          const SizedBox(height: 24),

          _section('About', [
            _row(
                icon: Icons.privacy_tip_outlined,
                iconColor: kGreenMid,
                title: 'Privacy Policy',
                trailing: Icon(Icons.chevron_right, color: context.c.border),
                onTap: () => _push(const PrivacyPolicyPage(), 'privacy_policy')),
            _row(
                icon: Icons.description_outlined,
                iconColor: kGold,
                title: 'Terms of Use',
                trailing: Icon(Icons.chevron_right, color: context.c.border),
                onTap: () => _push(const TermsPage(), 'terms_of_use')),
            _row(
                icon: Icons.help_outline_rounded,
                iconColor: kRust,
                title: 'Help',
                trailing: Icon(Icons.chevron_right, color: context.c.border),
                onTap: () => _push(const Help(), 'help')),
            _row(
                icon: Icons.info_outline_rounded,
                iconColor: kGreen,
                title: 'About',
                trailing: Icon(Icons.chevron_right, color: context.c.border),
                onTap: () => _push(const About(), 'about')),
            _row(
              icon: Icons.code_rounded,
              iconColor: kTextMuted,
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

  void _push(Widget page, String routeName) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => page,
          settings: RouteSettings(name: routeName)));

  // ── Theme picker ────────────────────────────────────────────────────────
  Future<void> _pickTheme(AppSettingsNotifier settings) async {
    final picked = await showDialog<ThemeMode>(
      context: context,
      builder: (ctx) => _BrandedDialog(
        icon: Icons.palette_outlined,
        iconColor: kGreen,
        title: 'Appearance',
        subtitle: 'Choose how Dha Anywaa looks',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in const {
              ThemeMode.system: _Choice('System', 'Match your device', Icons.brightness_auto_rounded),
              ThemeMode.light:  _Choice('Light', 'Bright sand canvas', Icons.wb_sunny_rounded),
              ThemeMode.dark:   _Choice('Dark', 'Deep forest canvas', Icons.nightlight_round),
            }.entries)
              _ChoiceTile(
                choice: e.value,
                selected: settings.themeMode == e.key,
                onTap: () => Navigator.pop(ctx, e.key),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      AnalyticsService.instance.logChangeTheme(picked.name);
      settings.setThemeMode(picked);
    }
  }

  // ── Reminder time picker ──────────────────────────────────────────────────
  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: 0),
      helpText: 'Choose your reminder time',
    );
    if (picked != null && mounted) {
      await RetentionEngine.instance.enableNotifications(
        preferredHour: picked.hour,
      );
      setState(() => _reminderHour = picked.hour);
    }
  }

  String _formatHour(int hour) {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final display = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$display:00 $suffix';
  }

  // ── Name editor ───────────────────────────────────────────────────────────
  Future<void> _editName() async {
    _nameCtrl.text = _name;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _NameDialog(controller: _nameCtrl),
    );
    if (saved == true) {
      final n = _nameCtrl.text.trim();
      await _savedData.setName(n);
      // Update analytics user ID
      await AnalyticsService.instance.setUser(n);
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
            height: 1, margin: const EdgeInsets.only(left: 72), color: context.c.border));
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
    IconData? icon,
    Color iconColor = kGreen,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: icon == null
          ? null
          : _leadingIcon(icon, iconColor),
      title: Text(title,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.c.text)),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(subtitle, style: TextStyle(fontSize: 13, color: context.c.textSub)),
            ),
      trailing: trailing,
    );
  }

  // iOS-style coloured icon chip: solid tinted square with a white glyph.
  Widget _leadingIcon(IconData icon, Color color) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      );

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

// ── Branded dialog primitives ────────────────────────────────────────────────

/// One selectable option in a picker dialog.
class _Choice {
  final String label;
  final String sub;
  final IconData icon;
  const _Choice(this.label, this.sub, this.icon);
}

/// A rounded, on-brand dialog shell: leaf-coloured icon chip + Playfair title,
/// then arbitrary content. Shared by the Theme and Name dialogs.
class _BrandedDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget child;
  const _BrandedDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: c.text)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: TextStyle(fontSize: 13, color: c.textSub)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final _Choice choice;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceTile({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? c.accent.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? c.accent : c.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(choice.icon, color: c.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(choice.label,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: c.text)),
                      const SizedBox(height: 1),
                      Text(choice.sub,
                          style: TextStyle(fontSize: 12.5, color: c.textSub)),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? c.accent : c.border,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  final TextEditingController controller;
  const _NameDialog({required this.controller});
  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  @override
  void initState() {
    super.initState();
    widget.controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    OutlineInputBorder b(Color col, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: col, width: w));
    return _BrandedDialog(
      icon: Icons.person_outline_rounded,
      iconColor: kGold,
      title: 'Your name',
      subtitle: 'Shown on your home greeting',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: c.text),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: c.textSub),
              filled: true,
              fillColor: c.bg,
              prefixIcon: Icon(Icons.person_outline_rounded, color: c.accent),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: b(c.border),
              enabledBorder: b(c.border),
              focusedBorder: b(c.accent, 2),
            ),
            onSubmitted: (_) => Navigator.pop(context, true),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(foregroundColor: c.textSub),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: kGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
