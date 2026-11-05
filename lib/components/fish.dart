import 'package:dha_anywaaa/components/detail_screen.dart';
import 'package:flutter/material.dart';

class Fish extends StatelessWidget {
  const Fish({super.key});

  static const List<Map<String, String>> _items = [
    {'engName': 'Bichir (Polypterus)', 'anyName': 'Odwëëla',  'imageLink': 'assets/fish/adweela.png'},
    {'engName': 'Catfish',             'anyName': 'Agwiila',  'imageLink': 'assets/fish/agwiila (2).png'},
    {'engName': '',                    'anyName': 'Dølø',     'imageLink': 'assets/fish/dolo.png'},
    {'engName': 'Nile Perch',          'anyName': 'Guur',     'imageLink': 'assets/fish/guur.png'},
    {'engName': 'Vundu (Bagrus docmak)','anyName': 'Jari',    'imageLink': 'assets/fish/jari (2).png'},
    {'engName': 'Lungfish',            'anyName': 'Luuth',    'imageLink': 'assets/fish/luuth.png'},
    {'engName': 'Bagrus bajad',        'anyName': 'Odwäära',  'imageLink': 'assets/fish/odwaara.png'},
    {'engName': 'Heterotis niloticus', 'anyName': 'Olwak',    'imageLink': 'assets/fish/olwak.png'},
    {'engName': 'Tilapia',             'anyName': 'Orwëëdhö', 'imageLink': 'assets/fish/rec.png'},
    {'engName': '',                    'anyName': 'Wïïth',    'imageLink': 'assets/fish/wiith.png'},
  ];

  @override
  Widget build(BuildContext context) =>
      DetailScreen(category: 'fish', title: 'Fishes', items: _items);
}
