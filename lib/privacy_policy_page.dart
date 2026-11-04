import 'package:flutter/material.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.bg,
      appBar: AppBar(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _PolicyBody(),
      ),
    );
  }
}

class _PolicyBody extends StatelessWidget {
  const _PolicyBody();

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
          'What this app is',
          'Learn Dha Anywaa is a language learning app for the Anywaa (Anuak) language. '
          'It contains alphabet lessons, vocabulary, reading exercises and a quiz. '
          'It works fully offline. No account is required.',
        ),
        _section(context, 
          'What is stored on your device',
          'The app stores the following data only on your device using Android SharedPreferences:\n\n'
          '  - Your name, so the home screen can greet you.\n'
          '  - Your last visited lesson, so the Continue card shows the right screen.\n'
          '  - Which items you have marked as learned, per category.\n'
          '  - Your sound effects preference (on or off).\n'
          '  - The timestamp of the last update check, to avoid checking more than once every 6 hours.\n\n'
          'None of this data ever leaves your device except as described below.',
        ),
        _section(context, 
          'What leaves your device',
          'The app makes one outbound network request: it checks for app updates by calling the '
          'GitHub Releases API at api.github.com. This request includes your IP address as part '
          'of normal HTTPS communication. No personal data from the app (your name, progress or '
          'preferences) is sent with this request. The request is made at most once every 6 hours '
          'and only when you are online.',
        ),
        _section(context, 
          'Permissions',
          'The app requests these Android permissions:\n\n'
          '  - INTERNET: required to check for app updates (see above).\n'
          '  - ACCESS_NETWORK_STATE: used to check whether your device is online before making '
          'the update request.\n'
          '  - REQUEST_INSTALL_PACKAGES: required to install a downloaded update APK directly '
          'from within the app.',
        ),
        _section(context, 
          'Children',
          'This app is designed to be safe for all ages, including children. '
          'It does not collect personal data, does not require an account, '
          'and does not show advertising.',
        ),
        _section(context, 
          'Analytics and advertising',
          'The app contains no analytics, crash reporting, tracking or advertising of any kind.',
        ),
        _section(context, 
          'Third-party services',
          'The app uses Google Fonts (Nunito) loaded from the app bundle, not from the network. '
          'No other third-party services are used.',
        ),
        _section(context, 
          'Data deletion',
          'To delete all your data, clear the app storage in Android Settings, '
          'or uninstall the app. No data is stored anywhere else.',
        ),
        _section(context, 
          'Contact',
          'If you have questions about this policy, contact:\n'
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
