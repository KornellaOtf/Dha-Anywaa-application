import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:flutter/material.dart';

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
            // ── Hero: the standing figure on a soft tinted panel ──────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    kGreen.withValues(alpha: 0.12),
                    c.card,
                  ],
                ),
                border: Border.all(color: c.border.withValues(alpha: 0.5)),
                boxShadow: const [kShadowCard],
              ),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: Image.asset(
                  'assets/word_images/body.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 240,
                    child: Center(
                      child: Icon(Icons.accessibility_new_rounded,
                          size: 120, color: Color(0xFFBFD0C7)),
                    ),
                  ),
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
                      color: chipColor,
                      boxShadow: [
                        BoxShadow(
                          color: chipColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.accessibility_new_rounded,
                        color: Colors.white, size: 24),
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
    {'letter': 'Wïc',  'anyName': 'Wïc',          'engName': 'Head'},
    {'letter': 'Ïth',  'anyName': 'Ïth',           'engName': 'Ear'},
    {'letter': 'Wang', 'anyName': 'Wang',          'engName': 'Eye'},
    {'letter': 'Um',   'anyName': 'Um',            'engName': 'Nose'},
    {'letter': 'Dhøk', 'anyName': 'Dhøk',          'engName': 'Mouth'},
    {'letter': 'Lak',  'anyName': 'Lak',           'engName': 'Teeth'},
    {'letter': 'Leep', 'anyName': 'Leep',          'engName': 'Tongue'},
    {'letter': 'Ngut', 'anyName': 'Ngut',          'engName': 'Neck'},
    {'letter': 'Göön', 'anyName': 'Göön',          'engName': 'Shoulder'},
    {'letter': 'Käw',  'anyName': 'Käw',           'engName': 'Chest'},
    {'letter': 'Cinø', 'anyName': 'Cinø',          'engName': 'Arm'},
    {'letter': 'Lweedø','anyName': 'Lweedø',       'engName': 'Finger'},
    {'letter': 'Ääm',  'anyName': 'Ääm',           'engName': 'Thigh'},
    {'letter': 'Tielø','anyName': 'Tielø',         'engName': 'Leg'},
    {'letter': 'Wïcuung','anyName': 'Wïcuung',     'engName': 'Knee'},
    {'letter': 'Adikwala','anyName': 'Adikwala',   'engName': 'Ankle'},
    {'letter': 'Othäny','anyName': 'Othäny tielø', 'engName': 'Foot'},
    {'letter': 'Jïër', 'anyName': 'Jïër',          'engName': 'Hair'},
  ];
}
