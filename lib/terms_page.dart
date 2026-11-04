import 'package:flutter/material.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Terms of Use',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _TermsBody(),
      ),
    );
  }
}

class _TermsBody extends StatelessWidget {
  const _TermsBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          'Last updated: 2025',
          '',
          isHeader: true,
        ),
        _section(
          'Acceptance',
          'By installing or using Learn Dha Anywaa, you agree to these terms. '
          'If you do not agree, do not use the app.',
        ),
        _section(
          'Licence',
          'Learn Dha Anywaa is provided for personal, non-commercial use. '
          'You may not copy, modify, distribute or sell any part of the app '
          'without written permission from the developer.',
        ),
        _section(
          'Content',
          'All Dha Anywaa language content, audio recordings and illustrations '
          'in this app are the property of their respective creators. '
          'They are provided for educational use only.',
        ),
        _section(
          'No warranty',
          'The app is provided "as is". The developer makes no warranty that '
          'the app will be error-free, uninterrupted or suitable for any '
          'particular purpose.',
        ),
        _section(
          'Limitation of liability',
          'To the maximum extent permitted by law, the developer is not liable '
          'for any damages arising from use of the app.',
        ),
        _section(
          'Updates',
          'These terms may be updated at any time. Continued use of the app '
          'after an update means you accept the new terms.',
        ),
        _section(
          'Contact',
          'Questions about these terms:\n'
          '[CONTACT_EMAIL]',
        ),
        const SizedBox(height: 8),
        const Text(
          'Developed by Kornella Otf',
          style: TextStyle(fontSize: 12, color: kTextMuted),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _section(String title, String body, {bool isHeader = false}) {
    if (isHeader) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          title,
          style: const TextStyle(fontSize: 13, color: kTextMuted),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              color: kTextSub,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
