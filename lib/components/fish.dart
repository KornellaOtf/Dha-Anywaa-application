import 'package:dha_anywaaa/components/detail_screen.dart';
import 'package:flutter/material.dart';

class Fish extends StatelessWidget {
  const Fish({super.key});

  static const List<Map<String, String>> _items = [
    {'engName': '', 'anyName': 'Odwëëla',  'imageLink': 'assets/fish/adweela.png'},
    {'engName': '', 'anyName': 'Agwiila',  'imageLink': 'assets/fish/agwiila (2).png'},
    {'engName': '', 'anyName': 'Dølø',     'imageLink': 'assets/fish/dolo.png'},
    {'engName': '', 'anyName': 'Guur',     'imageLink': 'assets/fish/guur.png'},
    {'engName': '', 'anyName': 'Jari',     'imageLink': 'assets/fish/jari (2).png'},
    {'engName': '', 'anyName': 'Luuth',    'imageLink': 'assets/fish/luuth.png'},
    {'engName': '', 'anyName': 'Odwäära',  'imageLink': 'assets/fish/odwaara.png'},
    {'engName': '', 'anyName': 'Olwak',    'imageLink': 'assets/fish/olwak.png'},
    {'engName': '', 'anyName': 'Orwëëdhö', 'imageLink': 'assets/fish/rec.png'},
    {'engName': '', 'anyName': 'Wïïth',    'imageLink': 'assets/fish/wiith.png'},
  ];

  @override
  Widget build(BuildContext context) =>
      DetailScreen(category: 'fish', title: 'Fishes', items: _items);
}
