import 'package:dha_anywaaa/components/detail_screen.dart';
import 'package:flutter/material.dart';

class Bird extends StatelessWidget {
  const Bird({super.key});

  static const List<Map<String, String>> _items = [
    {'engName': 'Hamerkop',          'anyName': 'Aciik',          'imageLink': 'assets/birds/aciik.png'},
    {'engName': 'Village weaver',    'anyName': 'Aleerø',         'imageLink': 'assets/birds/aleero.png'},
    {'engName': 'Butterfly',         'anyName': 'Adeellakwac',    'imageLink': 'assets/birds/butterfly.png'},
    {'engName': 'Duck',              'anyName': 'Badhø',          'imageLink': 'assets/birds/duck.png'},
    {'engName': 'Fish eagle',        'anyName': 'Dibëël',         'imageLink': 'assets/birds/fish_eagle.png'},
    {'engName': 'Hen',               'anyName': 'Gwienø',         'imageLink': 'assets/birds/gwieno.png'},
    {'engName': 'Cattle Egret',      'anyName': 'Okøøk',          'imageLink': 'assets/birds/okook.png'},
    {'engName': 'Plegadis',          'anyName': 'Owaaw',          'imageLink': 'assets/birds/owaaw.png'},
    {'engName': 'Pelican',           'anyName': 'Obööngö',        'imageLink': 'assets/birds/pelican.png'},
    {'engName': 'Standard nightjar', 'anyName': 'Obwölatäämmö',   'imageLink': 'assets/birds/standard_nightjar.png'},
    {'engName': 'Owl',               'anyName': 'Tula',           'imageLink': 'assets/birds/tula.png'},
    {'engName': 'Dove',              'anyName': 'Akuuru',         'imageLink': 'assets/birds/white_dove.png'},
  ];

  @override
  Widget build(BuildContext context) =>
      DetailScreen(category: 'bird', title: 'Birds', items: _items);
}
