import 'package:flutter/material.dart';

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1B4332);
    const bg    = Color(0xFFF5F0E8);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Jap dëël',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              'assets/body_part/body.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 300,
                child: Center(
                  child: Icon(Icons.person_outline,
                      size: 120, color: Color(0xFFCCCCCC)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._parts.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: green.withOpacity(0.1),
                    child: Text(p['letter']!,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: green,
                            fontSize: 13)),
                  ),
                  title: Text(p['anyName']!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  trailing: Text(p['engName']!,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF888888))),
                ),
              )),
        ]),
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
