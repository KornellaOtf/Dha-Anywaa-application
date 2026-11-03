import 'package:dha_anywaaa/components/detail_screen.dart';
import 'package:flutter/material.dart';

class Animal extends StatelessWidget {
  const Animal({super.key});

  static const List<Map<String, String>> _items = [
    {'engName': 'Cat',                     'anyName': 'Adhurrï',        'imageLink': 'assets/animals/cat.png'},
    {'engName': 'Chameleons',              'anyName': 'Ongøønnø',       'imageLink': 'assets/animals/chem.png'},
    {'engName': 'Dog',                     'anyName': 'Gwök',           'imageLink': 'assets/animals/dog.png'},
    {'engName': 'Donkey',                  'anyName': 'Arëën',          'imageLink': 'assets/animals/donkey.png'},
    {'engName': 'Black-and-white colobus', 'anyName': 'Döölö',          'imageLink': 'assets/animals/doolo.png'},
    {'engName': 'Fox',                     'anyName': 'Othöö',          'imageLink': 'assets/animals/foox.png'},
    {'engName': 'Giraffe',                 'anyName': 'Rïï',            'imageLink': 'assets/animals/giraffe.png'},
    {'engName': 'Goat',                    'anyName': 'Diel',           'imageLink': 'assets/animals/goat.png'},
    {'engName': 'Warthog',                 'anyName': 'Kul',            'imageLink': 'assets/animals/kuul.png'},
    {'engName': 'Rhinoceros',              'anyName': 'Nyigudhwönynya', 'imageLink': 'assets/animals/ngiguthwonya.png'},
    {'engName': 'Lion',                    'anyName': 'Nguu',           'imageLink': 'assets/animals/nguu.png'},
    {'engName': 'Hippopotamus',            'anyName': 'Ray',            'imageLink': 'assets/animals/ray.png'},
    {'engName': 'Porcupine',               'anyName': 'Thëëy',          'imageLink': 'assets/animals/theey.png'},
    {'engName': 'Cow',                     'anyName': 'Dhieng',         'imageLink': 'assets/animals/white_black_cow.png'},
  ];

  @override
  Widget build(BuildContext context) =>
      DetailScreen(category: 'animal', title: 'Animals', items: _items);
}
