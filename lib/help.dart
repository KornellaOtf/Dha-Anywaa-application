import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:flutter/material.dart';

class Help extends StatelessWidget {
  const Help({super.key});

  @override
  Widget build(BuildContext context) {
    const bg    = Color(0xFFF6EFE3);
    const green = Color(0xFF1F4D3A);

    const sections = [
      _HelpSection(
        icon: Icons.abc,
        title: 'Alphabet (Göörë)',
        body: 'The first page contains Dha Anywaa alphabets, both small and capital letters. '
              'Tap any letter and the app will read it aloud.',
      ),
      _HelpSection(
        icon: Icons.image_outlined,
        title: 'Words (Dööttï)',
        body: 'The second page shows words with matching images. Tap an image to hear the app read the word.',
      ),
      _HelpSection(
        icon: Icons.menu_book_outlined,
        title: 'Reading (Lup)',
        body: 'The third page contains Dha Anywaa sentences. Tap a sentence to have it read aloud.',
      ),
      _HelpSection(
        icon: Icons.quiz_outlined,
        title: 'Quiz (Päärö)',
        body: 'The fourth page tests comprehension. Choose an answer. '
              'Correct answers show a check mark and the word "Correct". '
              'Wrong answers show a cross and the words "Not quite". '
              'Tap "Next question" to advance.',
      ),
      _HelpSection(
        icon: Icons.menu_outlined,
        title: 'Sidebar',
        body: 'The sidebar (hamburger menu) gives access to Dha Anywaa vowels (Göörë moo cïp dwøl), '
              'Privacy Policy, Terms of Use, Help, About and Settings.',
      ),
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Help', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final s = sections[i];
          return Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE8F0EB),
                  child: Icon(s.icon, color: green, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                              color: kText)),
                      const SizedBox(height: 6),
                      Text(s.body,
                          style: const TextStyle(fontSize: 14, color: kTextSub, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HelpSection {
  final IconData icon;
  final String title;
  final String body;
  const _HelpSection({required this.icon, required this.title, required this.body});
}
