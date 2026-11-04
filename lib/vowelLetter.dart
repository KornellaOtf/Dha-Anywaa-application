// ignore_for_file: empty_catches
import 'package:audioplayers/audioplayers.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:dha_anywaaa/vowel.dart';
import 'package:flutter/material.dart';

class VowelLetter extends StatefulWidget {
  const VowelLetter({super.key});
  @override
  State<VowelLetter> createState() => _VowelLetterState();
}

class _VowelLetterState extends State<VowelLetter> {
  late AudioPlayer player;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> _play(String soundPath) async {
    try {
      final src = AssetSource(soundPath);
      await player.play(src);
      final dur = await player.getDuration();
      if (dur != null) await Future.delayed(dur);
      await player.stop();
    } catch (_) {}
  }

  final List<Vowel> vowelLetters = [
    Vowel(capitalLetter: 'Ä', smallLetter: 'ä', sound: 'sound/Ä.mp3'),
    Vowel(capitalLetter: 'Ë', smallLetter: 'ë', sound: 'sound/Ë.mp3'),
    Vowel(capitalLetter: 'Ï', smallLetter: 'ï', sound: 'sound/Ï.mp3'),
    Vowel(capitalLetter: 'Ö', smallLetter: 'ö', sound: 'sound/Ö.mp3'),
    Vowel(capitalLetter: 'U', smallLetter: 'u', sound: 'sound/U.mp3'),
    Vowel(capitalLetter: 'A', smallLetter: 'a', sound: 'sound/A-1.MP3'),
    Vowel(capitalLetter: 'E', smallLetter: 'e', sound: 'sound/E.mp3'),
    Vowel(capitalLetter: 'I', smallLetter: 'i', sound: 'sound/I.mp3'),
    Vowel(capitalLetter: 'O', smallLetter: 'o', sound: 'sound/O.mp3'),
    Vowel(capitalLetter: 'Ø', smallLetter: 'ø', sound: 'sound/Ø.mp3'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.bg,
      appBar: AppBar(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Göörë moo cïp dwøl',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('Göörë moo cwøl ni cwaak ojabø'),
              const SizedBox(height: 8),
              _vowelGrid(vowelLetters, 0, 5),
              const SizedBox(height: 24),
              _sectionHeader('Göörë moo cwøl ni cwaak odiyyø'),
              const SizedBox(height: 8),
              _vowelGrid(vowelLetters, 5, 5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title,
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.c.accent));
  }

  Widget _vowelGrid(List<Vowel> items, int offset, int count) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.0,
      ),
      itemBuilder: (_, i) {
        final v = items[offset + i];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _play(v.sound),
          child: Container(
            decoration: BoxDecoration(
              color: context.c.card,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(v.capitalLetter,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.c.text)),
                Text(v.smallLetter,
                    style: TextStyle(fontSize: 14, color: context.c.textSub)),
              ],
            ),
          ),
        );
      },
    );
  }
}
