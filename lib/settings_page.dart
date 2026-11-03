import 'package:dha_anywaaa/about.dart';
import 'package:dha_anywaaa/app_settings.dart';
import 'package:dha_anywaaa/components/savedData.dart';
import 'package:dha_anywaaa/help.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _loadName();
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
