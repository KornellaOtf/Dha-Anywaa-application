import 'package:dha_anywaaa/components/detail_screen.dart';
import 'package:flutter/material.dart';

class Cloth extends StatelessWidget {
  const Cloth({super.key});

  static const List<Map<String, String>> _items = [
    {'engName': 'Belt',        'anyName': 'Kaw',       'imageLink': 'assets/cloth/belt.png'},
    {'engName': 'Cap',         'anyName': 'Cöör',      'imageLink': 'assets/cloth/cap.png'},
    {'engName': 'Dress',       'anyName': 'Araagi',    'imageLink': 'assets/cloth/dress.png'},
    {'engName': 'Eye glasses', 'anyName': 'Lïdhäärë',  'imageLink': 'assets/cloth/glasses.png'},
    {'engName': 'Jacket',      'anyName': 'Koothi',    'imageLink': 'assets/cloth/jacket.png'},
    {'engName': 'Shoes',       'anyName': 'War',       'imageLink': 'assets/cloth/shoess.png'},
    {'engName': 'Shorts',      'anyName': 'Ongølø',    'imageLink': 'assets/cloth/shorts.png'},
    {'engName': 'Skirt',       'anyName': 'Thïnuura',  'imageLink': 'assets/cloth/skirt.png'},
    {'engName': 'Socks',       'anyName': 'Curubathe', 'imageLink': 'assets/cloth/socks.png'},
    {'engName': 'Trouser',     'anyName': 'Marthøa',   'imageLink': 'assets/cloth/trouser.png'},
  ];

  @override
  Widget build(BuildContext context) =>
      DetailScreen(category: 'clothes', title: 'Clothes', items: _items);
}
