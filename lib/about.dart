import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final Uri _privacyUrl = Uri.parse('https://dha-anywaa-privacy.netlify.app/');
final Uri _moreUrl    = Uri.parse('https://dha-anywaa-app.netlify.app/');

class About extends StatelessWidget {
  const About({super.key});

  Future<void> _launch(Uri url) async {
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _email() {
    launchUrl(Uri(scheme: 'mailto', path: 'Kornellaotf@gmail.com'));
  }

  @override
  Widget build(BuildContext context) {
    const bg    = Color(0xFFF6EFE3);
    const green = Color(0xFF1F4D3A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('About', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App identity card ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                SizedBox(
                  height: 80,
                  child: Image.asset(
                    'assets/word_images/awal_icon.jpeg',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.eco_rounded, color: Color(0xFF1F4D3A), size: 64),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Dha Anywaa',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1C))),
                const SizedBox(height: 4),
                const Text('Version: 1.0.3',
                    style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
              ]),
            ),
            const SizedBox(height: 16),
            // ── Description card ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Text(
                'This is a Dha Anywaa app designed to assist individuals in learning to read the Anywaa language. '
                'It is user-friendly, featuring both pictures and audio elements to enhance the learning experience. '
                'Geared towards absolute beginners, the app guides users through each step, facilitating the process '
                'of reading in Dha Anywaa.',
                style: TextStyle(fontSize: 15, color: Color(0xFF444444), height: 1.6),
              ),
            ),
            const SizedBox(height: 16),
            // ── Links card ──────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _linkTile(Icons.privacy_tip_outlined, 'Privacy Policy',
                    () => _launch(_privacyUrl), green),
                const Divider(height: 1, indent: 56),
                _linkTile(Icons.email_outlined, 'Contact Us', _email, green),
                const Divider(height: 1, indent: 56),
                _linkTile(Icons.open_in_browser_outlined, 'Read More',
                    () => _launch(_moreUrl), green),
              ]),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text('Developed by Kornella Otf',
                  style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _linkTile(IconData icon, String label, VoidCallback onTap, Color green) {
    return ListTile(
      leading: Icon(icon, color: green),
      title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFBBBBBB)),
      onTap: onTap,
    );
  }
}
