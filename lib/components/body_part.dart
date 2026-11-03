import 'package:dha_anywaaa/components/detail_screen.dart';
import 'package:flutter/material.dart';

class BodyPart extends StatelessWidget {
  const BodyPart({super.key});

  static const List<Map<String, String>> _items = [
    {'engName': 'Head',     'anyName': 'Wïc',          'imageLink': 'assets/body_part/head.png'},
    {'engName': 'Ankle',    'anyName': 'Adikwala',      'imageLink': 'assets/body_part/ankle.png'},
    {'engName': 'Arm',      'anyName': 'Cinø',          'imageLink': 'assets/body_part/arm.png'},
    {'engName': 'Chest',    'anyName': 'Käw',           'imageLink': 'assets/body_part/chest.png'},
    {'engName': 'Ear',      'anyName': 'Ïth',           'imageLink': 'assets/body_part/ear.png'},
    {'engName': 'Eye',      'anyName': 'Wang',          'imageLink': 'assets/body_part/eye.png'},
    {'engName': 'Finger',   'anyName': 'Lweedø',        'imageLink': 'assets/body_part/finger.png'},
    {'engName': 'Foot',     'anyName': 'Othäny tielø',  'imageLink': 'assets/body_part/foot.png'},
    {'engName': 'Hair',     'anyName': 'Jïër',          'imageLink': 'assets/body_part/hair.png'},
    {'engName': 'Knee',     'anyName': 'Wïcuung',       'imageLink': 'assets/body_part/knee.png'},
    {'engName': 'Leg',      'anyName': 'Tielø',         'imageLink': 'assets/body_part/leg.png'},
    {'engName': 'Mouth',    'anyName': 'Dhøk',          'imageLink': 'assets/body_part/mouth.png'},
    {'engName': 'Neck',     'anyName': 'Ngut',          'imageLink': 'assets/body_part/neck.png'},
    {'engName': 'Nose',     'anyName': 'Um',            'imageLink': 'assets/body_part/nose.png'},
    {'engName': 'Shoulder', 'anyName': 'Göön',          'imageLink': 'assets/body_part/shoulder.png'},
    {'engName': 'Teeth',    'anyName': 'Lak',           'imageLink': 'assets/body_part/theeth.png'},
    {'engName': 'Thigh',    'anyName': 'Ääm',           'imageLink': 'assets/body_part/thigh.png'},
    {'engName': 'Tongue',   'anyName': 'Leep',          'imageLink': 'assets/body_part/toungue.png'},
  ];

  @override
  Widget build(BuildContext context) =>
      DetailScreen(category: 'body', title: 'Body Parts', items: _items);
}
