import 'package:dha_anywaaa/privacy_policy_page.dart';
import 'package:dha_anywaaa/terms_page.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class About extends StatefulWidget {
  const About({super.key});
  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = 'v${info.version} (build ${info.buildNumber})');
  }

  void _email() {
    launchUrl(Uri(scheme: 'mailto', path: 'Kornellaotf@gmail.com'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('About',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App identity card ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                SizedBox(
                  height: 80,
                  child: Image.asset(
                    'assets/word_images/awal_icon.jpeg',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.eco_rounded,
                        color: kGreen,
                        size: 64),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Learn Dha Anywaa',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kText)),
                const SizedBox(height: 4),
                if (_version.isNotEmpty)
                  Text(_version,
                      style: const TextStyle(
                          fontSize: 14, color: kTextSub)),
              ]),
            ),
            const SizedBox(height: 16),
            // ── Description card ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: const Text(
                'Learn Dha Anywaa is a language learning app for the Anywaa (Anuak) language. '
                'It contains alphabet lessons, vocabulary with audio, reading exercises and a quiz. '
                'All content works fully offline.',
                style: TextStyle(
                    fontSize: 15, color: kTextSub, height: 1.6),
              ),
            ),
            const SizedBox(height: 16),
            // ── Links card ────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _navTile(
                  context,
                  Icons.privacy_tip_outlined,
                  'Privacy Policy',
                  const PrivacyPolicyPage(),
                ),
                const Divider(height: 1, indent: 56),
                _navTile(
                  context,
                  Icons.gavel_outlined,
                  'Terms of Use',
                  const TermsPage(),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading:
                      const Icon(Icons.email_outlined, color: kGreen),
                  title: const Text('Contact',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                  subtitle: const Text('Kornellaotf@gmail.com',
                      style: TextStyle(fontSize: 12, color: kTextMuted)),
                  trailing: const Icon(Icons.chevron_right,
                      color: kBorder),
                  onTap: _email,
                ),
              ]),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text('Developed by Kornella Otf',
                  style: TextStyle(fontSize: 13, color: kTextMuted)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _navTile(
      BuildContext context, IconData icon, String label, Widget page) {
    return ListTile(
      leading: Icon(icon, color: kGreen),
      title: Text(label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500)),
      trailing:
          const Icon(Icons.chevron_right, color: kBorder),
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}
