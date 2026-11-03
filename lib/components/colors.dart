import 'package:dha_anywaaa/components/detail_screen.dart';
import 'package:flutter/material.dart';

class Kit extends StatelessWidget {
  const Kit({super.key});

  static const List<Map<String, String>> _items = [
    {'engName': 'Red',      'anyName': 'Kwaar',        'imageLink': 'assets/word_images/red.png'},
    {'engName': 'Yellow',   'anyName': 'Abäga',        'imageLink': 'assets/word_images/yellow.png'},
    {'engName': 'Blue',     'anyName': 'Amïrïga',      'imageLink': 'assets/word_images/blue.png'},
    {'engName': 'Orange',   'anyName': 'Maar odwëëla', 'imageLink': 'assets/word_images/orange.png'},
    {'engName': 'Sky blue', 'anyName': 'Caaro',        'imageLink': 'assets/word_images/sky blue.png'},
    {'engName': 'Green',    'anyName': 'Mar',          'imageLink': 'assets/word_images/green.png'},
    {'engName': 'White',    'anyName': 'Tar',          'imageLink': 'assets/word_images/white.png'},
    {'engName': 'Black',    'anyName': 'Cøl',          'imageLink': 'assets/word_images/black.jpeg'},
  ];

  @override
  Widget build(BuildContext context) =>
      DetailScreen(category: 'colors', title: 'Colors', items: _items);
}
