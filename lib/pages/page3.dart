// ignore_for_file: prefer_const_constructors
import 'package:audioplayers/audioplayers.dart';
import 'package:dha_anywaaa/Sentence.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:flutter/material.dart';

class Page3 extends StatefulWidget {
  const Page3({super.key});
  @override
  State<Page3> createState() => _Page3State();
}

class _Page3State extends State<Page3> {
  late AudioPlayer player;
  bool _isPlaying = false;
  int _playingIndex = -1;

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

  Future<void> _playAudio(int idx, AssetSource src) async {
    try {
      if (_isPlaying && _playingIndex == idx) {
        await player.pause();
        setState(() { _isPlaying = false; _playingIndex = -1; });
      } else {
        setState(() { _isPlaying = true; _playingIndex = idx; });
        await player.play(src);
        final dur = await player.getDuration();
        if (dur != null) await Future.delayed(dur);
        await player.stop();
        setState(() { _isPlaying = false; _playingIndex = -1; });
      }
    } catch (_) {
      setState(() { _isPlaying = false; _playingIndex = -1; });
    }
  }

  // Icons for each reading word
  static final _wordIcons = <String, IconData>{
    'Abäc': Icons.school_rounded,
    'Ääm': Icons.favorite_rounded,
    'Bøøgø': Icons.lock_rounded,
    'Cöör': Icons.lightbulb_rounded,
    'Digwey': Icons.water_drop_rounded,
    'Dhieng': Icons.grass_rounded,
    'Eel': Icons.water_rounded,
    'Ëëli': Icons.waves_rounded,
    'Gwienø': Icons.fast_forward_rounded,
    'Iith': Icons.gavel_rounded,
    'Ïth': Icons.shield_rounded,
    'Jääy': Icons.celebration_rounded,
    'Køøm': Icons.bed_rounded,
    'Liec': Icons.pets_rounded,
    'Maac': Icons.local_fire_department_rounded,
    'Naam': Icons.hotel_rounded,
    'Nhøth': Icons.visibility_rounded,
    'Nguu': Icons.air_rounded,
    'Nyaang': Icons.hearing_rounded,
    'Odïëk': Icons.agriculture_rounded,
    'Öök': Icons.sensor_door_rounded,
    'Øttø': Icons.sensor_door_outlined,
    'Pïën': Icons.menu_book_rounded,
    'Rïï': Icons.pets_rounded,
    'Tøng': Icons.construction_rounded,
    'Thoom': Icons.spa_rounded,
    'Uudö': Icons.cloud_rounded,
    'War': Icons.local_drink_rounded,
    'Yiie': Icons.home_rounded,
  };

  final List<Sentence> wordAndSentence = [
    Sentence(letter: "A",  word: "Abäc",   sentence: 'Obang nyämö ka abäc mo nyaaththa.',          audioUrl: "sentence_sound/Voice1.mp3"),
    Sentence(letter: "Ä",  word: "Ääm",    sentence: 'Oriemmi äämë di pöö.',                        audioUrl: "sentence_sound/Voice2.mp3"),
    Sentence(letter: "B",  word: "Bøøgø",  sentence: "Bääla bøøgø mare dwøng døc.",                 audioUrl: "sentence_sound/Voice3.mp3"),
    Sentence(letter: "C",  word: "Cöör",   sentence: "Cöör kunynyö kiper cäng.",                    audioUrl: "sentence_sound/Voice4.mp3"),
    Sentence(letter: "D",  word: "Digwey", sentence: " Digwey muulö bäät liel.",                    audioUrl: "sentence_sound/Voice5.mp3"),
    Sentence(letter: "Dh", word: "Dhieng", sentence: "Dhieng nyämö ki lum yi bäp.",                 audioUrl: "sentence_sound/Voice7.mp3", imageAsset: 'assets/word_images/leaf.png'),
    Sentence(letter: "E",  word: "Eel",    sentence: "Omøt cwaal mo dwøng a eel wïïë.",             audioUrl: "sentence_sound/Voice8.mp3", imageAsset: 'assets/word_images/eel.png'),
    Sentence(letter: "Ë",  word: "Ëëli",   sentence: "Ariet tëëdö bäät ëëli ka araapraapi.",        audioUrl: "sentence_sound/Voice9.mp3", imageAsset: 'assets/word_images/eeli.png'),
    Sentence(letter: "G",  word: "Gwienø", sentence: "Gwienø nywøla tøøngø.",                       audioUrl: "sentence_sound/Voice10.mp3"),
    Sentence(letter: "I",  word: "Iith",   sentence: " Acala töömö ki pïï yi iith.",                audioUrl: "sentence_sound/Voice11.mp3", imageAsset: 'assets/word_images/iith.png'),
    Sentence(letter: "Ï",  word: "Ïth",    sentence: " Ïth kunynyï kiper winynyö.",                 audioUrl: "sentence_sound/Voice12.mp3"),
    Sentence(letter: "J",  word: "Jääy",   sentence: "Okëëlö a yaa øt göör ki jääy ya dïïttï.",    audioUrl: "sentence_sound/Voice13.mp3"),
    Sentence(letter: "K",  word: "Køøm",   sentence: " Awïïllï opï piny bäät køøm.",               audioUrl: "sentence_sound/Voice14.mp3"),
    Sentence(letter: "L",  word: "Liec",   sentence: " Liec ena lääy mo dwøng døc.",                audioUrl: "sentence_sound/Voice15.mp3"),
    Sentence(letter: "M",  word: "Maac",   sentence: "Maac liel tier dak.",                         audioUrl: "sentence_sound/Voice16.mp3", imageAsset: 'assets/word_images/maac.png'),
    Sentence(letter: "N",  word: "Naam",   sentence: " Opëënö ena naam mo dwøng døc.",              audioUrl: "sentence_sound/Voice17.mp3"),
    Sentence(letter: "Nh", word: "Nhøth",  sentence: " Cwaa mara a nhøth nyilaal.",                 audioUrl: "sentence_sound/Voice18.mp3"),
    Sentence(letter: "Ng", word: "Nguu",   sentence: "Nguu ena kwääny paap.",                       audioUrl: "sentence_sound/Voice19.mp3"),
    Sentence(letter: "Ny", word: "Nyaang", sentence: "Nyaang obuttö ya cuula.",                     audioUrl: "sentence_sound/Voice20.mp3"),
    Sentence(letter: "O",  word: "Odïëk",  sentence: "Odïëk a nyämmö ki diel ya wïtïnnï.",          audioUrl: "sentence_sound/Voice21.mp3"),
    Sentence(letter: "Ö",  word: "Öök",    sentence: "Öök ena nyi jaath mo di camø.",               audioUrl: "sentence_sound/Voice22.mp3", imageAsset: 'assets/word_images/ook.png'),
    Sentence(letter: "Ø",  word: "Øttø",   sentence: "Ochään rwädhö ki øttø.",                      audioUrl: "sentence_sound/Voice23.mp3"),
    Sentence(letter: "P",  word: "Pïën",   sentence: "Pïën kunynyö kiper bëëttö.",                  audioUrl: "sentence_sound/Voice24.mp3", imageAsset: 'assets/word_images/pien.png'),
    Sentence(letter: "R",  word: "Rïï",    sentence: "Rïï ena lääy mo nguttë bäär døc.",            audioUrl: "sentence_sound/Voice25.mp3"),
    Sentence(letter: "T",  word: "Tøng",   sentence: "Tøng kunynyö kiper dwaar.",                   audioUrl: "sentence_sound/Voice26.mp3", imageAsset: 'assets/word_images/tong.png'),
    Sentence(letter: "Th", word: "Thoom",  sentence: "Okëëlö pöödö ki thoom bäät ajwöma.",          audioUrl: "sentence_sound/Voice27.mp3", imageAsset: 'assets/word_images/thoom.png'),
    Sentence(letter: "U",  word: "Uudö",   sentence: "Tøng uudö dwøng døc.",                        audioUrl: "sentence_sound/Voice28.mp3"),
    Sentence(letter: "W",  word: "War",    sentence: "Omään tiette di war mo nyärö.",               audioUrl: "sentence_sound/Voice29.mp3"),
    Sentence(letter: "Y",  word: "Yiie",   sentence: "Acamduk man yiie ngaam.",                     audioUrl: "sentence_sound/Voice30.mp3", imageAsset: 'assets/word_images/house.png'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            elevation: 3,
            shape: const CircleBorder(),
            color: context.c.card,
            child: IconButton(
              icon: Icon(Icons.chevron_left_rounded, color: context.c.text),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text('Reading',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: context.c.text)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: kRust.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kRust.withValues(alpha: 0.2)),
                ),
                child: Row(children: const [
                  Icon(Icons.record_voice_over_outlined,
                      size: 14, color: kRust),
                  SizedBox(width: 5),
                  Text('Audio',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: kRust)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: wordAndSentence.length,
        itemBuilder: (context, idx) {
          final s        = wordAndSentence[idx];
          final isActive = _playingIndex == idx && _isPlaying;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => _playAudio(idx, AssetSource(s.audioUrl)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: isActive
                      ? kGreen.withValues(alpha: 0.06)
                      : context.c.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive
                        ? kGreen.withValues(alpha: 0.4)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
                        color: kGreen.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    else
                      kShadowSoft,
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Letter badge (or image if available)
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isActive
                              ? kGreen
                              : kRust.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          image: s.imageAsset != null
                              ? DecorationImage(
                                  image: AssetImage(s.imageAsset!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: s.imageAsset == null
                            ? Center(
                                child: Text(
                                  s.letter,
                                  style: TextStyle(
                                    fontSize: s.letter.length > 1 ? 15 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? Colors.white : kRust,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _wordIcons[s.word] ?? Icons.text_fields_rounded,
                                  size: 18,
                                  color: isActive ? context.c.accent : kRust.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 6),
                                Text(s.word,
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: isActive ? context.c.accent : context.c.text)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(s.sentence.trim(),
                                style: TextStyle(
                                    fontSize: 14,
                                    color: context.c.textSub,
                                    height: 1.5)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Play/Pause icon
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isActive
                              ? kGreen.withValues(alpha: 0.15)
                              : kGreen.withValues(alpha: 0.07),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isActive
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: context.c.accent,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
