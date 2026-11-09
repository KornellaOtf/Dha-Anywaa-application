import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Body extends StatelessWidget {
  const Body({super.key});

  // Chip palette cycled down the list for a bit of life, matching the
  // coloured icon chips used on the Settings rows.
  static const List<Color> _chips = [kGreen, kGreenMid, kGold];

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Jap dëël',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero: clean body diagram ───────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: c.card,
                border: Border.all(color: c.border.withValues(alpha: 0.5)),
                boxShadow: const [kShadowCard],
              ),
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: kGreen.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Nying thäk dëër dhaanhø',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: kGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Clean SVG body illustration
                    Container(
                      constraints: const BoxConstraints(maxHeight: 450),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            kGreen.withValues(alpha: 0.05),
                            c.bg.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.asset(
                        'assets/word_images/body_clean.svg',
                        fit: BoxFit.contain,
                        placeholderBuilder: (_) => const Center(
                          child: Icon(
                            Icons.accessibility_new_rounded,
                            size: 180,
                            color: Color(0xFFBFD0C7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Attribution
                    Text(
                      'Dha-Anywaa GDAT',
                      style: TextStyle(
                        fontSize: 10,
                        color: c.textSub,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Section header + count ────────────────────────────────────
            Row(children: [
              Text('Body parts',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: c.text)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_parts.length}',
                    style: const TextStyle(
                        color: kGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 12),

            // ── Body-part rows ─────────────────────────────────────────────
            ..._parts.asMap().entries.map((entry) {
              final p = entry.value;
              final chipColor = _chips[entry.key % _chips.length];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: c.border.withValues(alpha: 0.5)),
                  boxShadow: const [kShadowSoft],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      color: chipColor.withValues(alpha: 0.14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        p['img']!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                            Icons.accessibility_new_rounded,
                            color: chipColor,
                            size: 22),
                      ),
                    ),
                  ),
                  title: Text(p['anyName']!,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: c.text)),
                  subtitle: Text(p['engName']!,
                      style: TextStyle(fontSize: 13, color: c.textSub)),
                ),
              );
            }),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  static const List<Map<String, String>> _parts = [
    {'anyName': 'Wïc',          'engName': 'Head',     'img': 'assets/body_part/head.png'},
    {'anyName': 'Ïth',           'engName': 'Ear',      'img': 'assets/body_part/ear.png'},
    {'anyName': 'Wang',          'engName': 'Eye',      'img': 'assets/body_part/eye.png'},
    {'anyName': 'Um',            'engName': 'Nose',     'img': 'assets/body_part/nose.png'},
    {'anyName': 'Dhøk',          'engName': 'Mouth',    'img': 'assets/body_part/mouth.png'},
    {'anyName': 'Lak',           'engName': 'Teeth',    'img': 'assets/body_part/theeth.png'},
    {'anyName': 'Leep',          'engName': 'Tongue',   'img': 'assets/body_part/toungue.png'},
    {'anyName': 'Ngut',          'engName': 'Neck',     'img': 'assets/body_part/neck.png'},
    {'anyName': 'Göön',          'engName': 'Shoulder', 'img': 'assets/body_part/shoulder.png'},
    {'anyName': 'Käw',           'engName': 'Chest',    'img': 'assets/body_part/chest.png'},
    {'anyName': 'Cinø',          'engName': 'Arm',      'img': 'assets/body_part/arm.png'},
    {'anyName': 'Lweedø',        'engName': 'Finger',   'img': 'assets/body_part/finger.png'},
    {'anyName': 'Ääm',           'engName': 'Thigh',    'img': 'assets/body_part/thigh.png'},
    {'anyName': 'Tielø',         'engName': 'Leg',      'img': 'assets/body_part/leg.png'},
    {'anyName': 'Wïcuung',       'engName': 'Knee',     'img': 'assets/body_part/knee.png'},
    {'anyName': 'Adikwala',      'engName': 'Ankle',    'img': 'assets/body_part/ankle.png'},
    {'anyName': 'Othäny tielø',  'engName': 'Foot',     'img': 'assets/body_part/foot.png'},
    {'anyName': 'Jïër',          'engName': 'Hair',     'img': 'assets/body_part/hair.png'},
  ];
}
