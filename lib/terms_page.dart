import 'package:flutter/material.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.bg,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
        _section(context, 
          'Last updated: 2026',
          '',
          isHeader: true,
        ),
        _section(context, 
          'Acceptance',
          'By installing or using Learn Dha Anywaa, you agree to these terms. '
          'If you do not agree, do not use the app.',
        ),
        _section(context, 
          'Licence',
          'Learn Dha Anywaa is provided for personal, non-commercial use. '
          'You may not copy, modify, distribute or sell any part of the app '
          'without written permission from the developer.',
        ),
        _section(context, 
          'Content',
          'All Dha Anywaa language content, audio recordings and illustrations '
          'in this app are the property of their respective creators. '
          'They are provided for educational use only.',
        ),
        _section(context, 
          'No warranty',
          'The app is provided "as is". The developer makes no warranty that '
          'the app will be error-free, uninterrupted or suitable for any '
          'particular purpose.',
        ),
        _section(context, 
          'Limitation of liability',
          'To the maximum extent permitted by law, the developer is not liable '
          'for any damages arising from use of the app.',
        ),
        _section(context, 
          'Updates',
          'These terms may be updated at any time. Continued use of the app '
          'after an update means you accept the new terms.',
        ),
        _section(context, 
          'Contact',
          'Questions about these terms:\n'
          'Kornellaotf@gmail.com',
        ),
        const SizedBox(height: 8),
        Text(
          'Developed by Kornella Otf',
          style: TextStyle(fontSize: 12, color: context.c.textSub),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _section(BuildContext context, String title, String body, {bool isHeader = false}) {
    if (isHeader) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          title,
          style: TextStyle(fontSize: 13, color: context.c.textSub),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.c.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              color: context.c.textSub,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
