import 'package:dha_anywaaa/components/detail_screen.dart';
import 'package:flutter/material.dart';

class Shpae extends StatelessWidget {
  const Shpae({super.key});

  static const List<Map<String, String>> _items = [
    {'engName': 'Rectangle',   'anyName': 'Atuk ngween',   'imageLink': 'assets/word_images/rectangle.png'},
    {'engName': 'Triangle', 'anyName': 'Atuk Däk',      'imageLink': 'assets/word_images/three_angle.png'},
    {'engName': 'Circle',      'anyName': 'Lømløma',       'imageLink': 'assets/word_images/circle.png'},
    {'engName': 'Oval',        'anyName': 'Abööth abööth', 'imageLink': 'assets/word_images/oval.png'},
  ];

  @override
  Widget build(BuildContext context) =>
      DetailScreen(category: 'shape', title: 'Shapes', items: _items);
}
