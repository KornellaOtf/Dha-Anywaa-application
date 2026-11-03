import 'package:dha_anywaaa/components/detail_screen.dart';
import 'package:flutter/material.dart';

class Page2 extends StatelessWidget {
  const Page2({super.key});

  static const List<Map<String, String>> _items = [
    {'anyName': 'Abäc',   'engName': 'Maize',                   'imageLink': 'assets/word_images/maize.png',    'wordSound': 'word_sound/Abac.mp3'},
    {'anyName': 'Ääm',    'engName': 'Thigh',                   'imageLink': 'assets/word_images/thigh.png',    'wordSound': 'word_sound/Aam.mp3'},
    {'anyName': 'Bøøgø',  'engName': 'Leaf',                    'imageLink': 'assets/word_images/leaf.png',     'wordSound': 'word_sound/Boogo.mp3'},
    {'anyName': 'Cöör',   'engName': 'Hat',                     'imageLink': 'assets/word_images/hat.png',      'wordSound': 'word_sound/Coor.mp3'},
    {'anyName': 'Digwey', 'engName': 'Lizard',                  'imageLink': 'assets/word_images/lizard.png',   'wordSound': 'word_sound/Degwey.mp3'},
    {'anyName': 'Dhieng', 'engName': 'Cow',                     'imageLink': 'assets/word_images/cow.png',      'wordSound': 'word_sound/Dhieng.mp3'},
    {'anyName': 'Eel',    'engName': 'Push',                    'imageLink': 'assets/word_images/eel.png',      'wordSound': 'word_sound/Eel.mp3'},
    {'anyName': 'Ëëlï',   'engName': 'Injera making machine',   'imageLink': 'assets/word_images/eeli.png',     'wordSound': 'word_sound/Eeli.mp3'},
    {'anyName': 'Gwienø', 'engName': 'Hen',                     'imageLink': 'assets/word_images/hen.png',      'wordSound': 'word_sound/Gwieno.mp3'},
    {'anyName': 'Iith',   'engName': 'Well',                    'imageLink': 'assets/word_images/iith.png',     'wordSound': 'word_sound/Iith.mp3'},
    {'anyName': 'Ïth',    'engName': 'Ear',                     'imageLink': 'assets/word_images/ear.png',      'wordSound': 'word_sound/Ith.mp3'},
    {'anyName': 'Jääy',   'engName': 'Car',                     'imageLink': 'assets/word_images/car.png',      'wordSound': 'word_sound/Jaay.mp3'},
    {'anyName': 'Køøm',   'engName': 'Chair',                   'imageLink': 'assets/word_images/char.png',     'wordSound': 'word_sound/Koom.mp3'},
    {'anyName': 'Liec',   'engName': 'Elephant',                'imageLink': 'assets/word_images/elephant.png', 'wordSound': 'word_sound/Liec.mp3'},
    {'anyName': 'Maac',   'engName': 'Fire',                    'imageLink': 'assets/word_images/maac.png',     'wordSound': 'word_sound/Maac.mp3'},
    {'anyName': 'Naam',   'engName': 'River',                   'imageLink': 'assets/word_images/river.png',    'wordSound': 'word_sound/Naam.mp3'},
    {'anyName': 'Nhøth',  'engName': 'Suck',                    'imageLink': 'assets/word_images/suck.png',     'wordSound': 'word_sound/Nhoth.mp3'},
    {'anyName': 'Nguu',   'engName': 'Lion',                    'imageLink': 'assets/word_images/lion.png',     'wordSound': 'word_sound/Nguu.mp3'},
    {'anyName': 'Nyaang', 'engName': 'Crocodile',               'imageLink': 'assets/word_images/croc.png',     'wordSound': 'word_sound/Nyaang.mp3'},
    {'anyName': 'Odïëk',  'engName': 'Hyena',                   'imageLink': 'assets/word_images/hayna.png',    'wordSound': 'word_sound/Odiek.mp3'},
    {'anyName': 'Öök',    'engName': '',                        'imageLink': 'assets/word_images/ook.png',      'wordSound': 'word_sound/Ook.mp3'},
    {'anyName': 'Øttø',   'engName': 'House',                   'imageLink': 'assets/word_images/house.png',    'wordSound': 'word_sound/Oto.mp3'},
    {'anyName': 'Pïën',   'engName': 'Carpet',                  'imageLink': 'assets/word_images/pien.png',     'wordSound': 'word_sound/Pien.mp3'},
    {'anyName': 'Rïï',    'engName': 'Giraffe',                 'imageLink': 'assets/word_images/giraffe.png',  'wordSound': 'word_sound/Rii.mp3'},
    {'anyName': 'Tøng',   'engName': 'Arrow',                   'imageLink': 'assets/word_images/tong.png',     'wordSound': 'word_sound/Tong.mp3'},
    {'anyName': 'Thoom',  'engName': 'Guitar',                  'imageLink': 'assets/word_images/quitar.png',   'wordSound': 'word_sound/Thoom.mp3'},
    {'anyName': 'Uudö',   'engName': 'Ostrich',                 'imageLink': 'assets/word_images/ostrich.png',  'wordSound': 'word_sound/Uudo.mp3'},
    {'anyName': 'War',    'engName': 'Shoes',                   'imageLink': 'assets/word_images/shoe.png',     'wordSound': 'word_sound/War.mp3'},
    {'anyName': 'Yiie',   'engName': 'Inside',                  'imageLink': 'assets/word_images/carton.png',   'wordSound': 'word_sound/Yiie.mp3'},
  ];

  @override
  Widget build(BuildContext context) => DetailScreen(
        category: 'word',
        title: 'Words',
        items: _items,
        audioKey: 'wordSound',
      );
}
