// ignore_for_file: empty_catches
import 'package:audioplayers/audioplayers.dart';
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
    const bg    = Color(0xFFF5F0E8);
    const green = Color(0xFF1B4332);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: green,
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
              _sectionHeader('Göörë moo cwøl ni cwaak ojabø', green),
              const SizedBox(height: 8),
              _vowelGrid(vowelLetters, 0, 5),
              const SizedBox(height: 24),
              _sectionHeader('Göörë moo cwøl ni cwaak odiyyø', green),
              const SizedBox(height: 8),
              _vowelGrid(vowelLetters, 5, 5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color green) {
    return Text(title,
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: green));
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(v.capitalLetter,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1C))),
                Text(v.smallLetter,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
              ],
            ),
          ),
        );
      },
    );
  }
}
