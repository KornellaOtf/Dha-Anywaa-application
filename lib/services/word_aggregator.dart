/// Unified word data model for learning features
class WordData {
  final String id;
  final String english;
  final String anywaa;
  final String imageUrl;
  final String category;
  final String? audioPath;

  const WordData({
    required this.id,
    required this.english,
    required this.anywaa,
    required this.imageUrl,
    required this.category,
    this.audioPath,
  });
}

/// Complete vocabulary — all categories used by Daily 5 and FSRS engine.
/// Sourced directly from each component file so the data stays in sync.
class WordAggregator {
  WordAggregator._();
  static final WordAggregator instance = WordAggregator._();

  static const List<Map<String, String>> _allWordsData = [

    // ── Animals (14) ──────────────────────────────────────────────────────
    {'id': 'animal_cat',      'english': 'Cat',                     'anywaa': 'Adhurrï',        'imageUrl': 'assets/animals/cat.png',               'category': 'Animals'},
    {'id': 'animal_chameleon','english': 'Chameleons',               'anywaa': 'Ongøønnø',       'imageUrl': 'assets/animals/chem.png',              'category': 'Animals'},
    {'id': 'animal_dog',      'english': 'Dog',                     'anywaa': 'Gwök',            'imageUrl': 'assets/animals/dog.png',               'category': 'Animals'},
    {'id': 'animal_donkey',   'english': 'Donkey',                  'anywaa': 'Arëën',           'imageUrl': 'assets/animals/donkey.png',            'category': 'Animals'},
    {'id': 'animal_colobus',  'english': 'Black-and-white colobus', 'anywaa': 'Döölö',           'imageUrl': 'assets/animals/doolo.png',             'category': 'Animals'},
    {'id': 'animal_fox',      'english': 'Fox',                     'anywaa': 'Othöö',           'imageUrl': 'assets/animals/foox.png',              'category': 'Animals'},
    {'id': 'animal_giraffe',  'english': 'Giraffe',                 'anywaa': 'Rïï',             'imageUrl': 'assets/animals/giraffe.png',           'category': 'Animals'},
    {'id': 'animal_goat',     'english': 'Goat',                    'anywaa': 'Diel',            'imageUrl': 'assets/animals/goat.png',              'category': 'Animals'},
    {'id': 'animal_warthog',  'english': 'Warthog',                 'anywaa': 'Kul',             'imageUrl': 'assets/animals/kuul.png',              'category': 'Animals'},
    {'id': 'animal_rhino',    'english': 'Rhinoceros',              'anywaa': 'Nyigudhwönynya',  'imageUrl': 'assets/animals/ngiguthwonya.png',      'category': 'Animals'},
    {'id': 'animal_lion',     'english': 'Lion',                    'anywaa': 'Nguu',            'imageUrl': 'assets/animals/nguu.png',              'category': 'Animals'},
    {'id': 'animal_hippo',    'english': 'Hippopotamus',            'anywaa': 'Ray',             'imageUrl': 'assets/animals/ray.png',               'category': 'Animals'},
    {'id': 'animal_porcupine','english': 'Porcupine',               'anywaa': 'Thëëy',           'imageUrl': 'assets/animals/theey.png',             'category': 'Animals'},
    {'id': 'animal_cow',      'english': 'Cow',                     'anywaa': 'Dhieng',          'imageUrl': 'assets/animals/white_black_cow.png',   'category': 'Animals'},

    // ── Birds (12) ────────────────────────────────────────────────────────
    {'id': 'bird_hamerkop',   'english': 'Hamerkop',          'anywaa': 'Aciik',         'imageUrl': 'assets/birds/aciik.png',              'category': 'Birds'},
    {'id': 'bird_weaver',     'english': 'Village weaver',    'anywaa': 'Aleerø',        'imageUrl': 'assets/birds/aleero.png',             'category': 'Birds'},
    {'id': 'bird_butterfly',  'english': 'Butterfly',         'anywaa': 'Adeellakwac',   'imageUrl': 'assets/birds/butterfly.png',          'category': 'Birds'},
    {'id': 'bird_duck',       'english': 'Duck',              'anywaa': 'Badhø',         'imageUrl': 'assets/birds/duck.png',               'category': 'Birds'},
    {'id': 'bird_eagle',      'english': 'Fish eagle',        'anywaa': 'Dibëël',        'imageUrl': 'assets/birds/fish_eagle.png',         'category': 'Birds'},
    {'id': 'bird_hen',        'english': 'Hen',               'anywaa': 'Gwienø',        'imageUrl': 'assets/birds/gwieno.png',             'category': 'Birds'},
    {'id': 'bird_egret',      'english': 'Cattle Egret',      'anywaa': 'Okøøk',         'imageUrl': 'assets/birds/okook.png',              'category': 'Birds'},
    {'id': 'bird_plegadis',   'english': 'Plegadis',          'anywaa': 'Owaaw',         'imageUrl': 'assets/birds/owaaw.png',              'category': 'Birds'},
    {'id': 'bird_pelican',    'english': 'Pelican',           'anywaa': 'Obööngö',       'imageUrl': 'assets/birds/pelican.png',            'category': 'Birds'},
    {'id': 'bird_nightjar',   'english': 'Standard nightjar', 'anywaa': 'Obwölatäämmö',  'imageUrl': 'assets/birds/standard_nightjar.png', 'category': 'Birds'},
    {'id': 'bird_owl',        'english': 'Owl',               'anywaa': 'Tula',          'imageUrl': 'assets/birds/tula.png',               'category': 'Birds'},
    {'id': 'bird_dove',       'english': 'Dove',              'anywaa': 'Akuuru',        'imageUrl': 'assets/birds/white_dove.png',         'category': 'Birds'},

    // ── Colors (8) ────────────────────────────────────────────────────────
    {'id': 'color_red',      'english': 'Red',      'anywaa': 'Kwaar',        'imageUrl': 'assets/word_images/red.png',       'category': 'Colors'},
    {'id': 'color_yellow',   'english': 'Yellow',   'anywaa': 'Abäga',        'imageUrl': 'assets/word_images/yellow.png',    'category': 'Colors'},
    {'id': 'color_blue',     'english': 'Blue',     'anywaa': 'Amïrïga',      'imageUrl': 'assets/word_images/blue.png',      'category': 'Colors'},
    {'id': 'color_orange',   'english': 'Orange',   'anywaa': 'Maar odwëëla', 'imageUrl': 'assets/word_images/orange.png',    'category': 'Colors'},
    {'id': 'color_skyblue',  'english': 'Sky blue', 'anywaa': 'Caaro',        'imageUrl': 'assets/word_images/sky blue.png',  'category': 'Colors'},
    {'id': 'color_green',    'english': 'Green',    'anywaa': 'Mar',          'imageUrl': 'assets/word_images/green.png',     'category': 'Colors'},
    {'id': 'color_white',    'english': 'White',    'anywaa': 'Tar',          'imageUrl': 'assets/word_images/white.png',     'category': 'Colors'},
    {'id': 'color_black',    'english': 'Black',    'anywaa': 'Cøl',          'imageUrl': 'assets/word_images/black.jpeg',    'category': 'Colors'},

    // ── Shapes (4) ────────────────────────────────────────────────────────
    {'id': 'shape_rectangle','english': 'Rectangle', 'anywaa': 'Atuk ngween',   'imageUrl': 'assets/word_images/rectangle.png',   'category': 'Shapes'},
    {'id': 'shape_triangle', 'english': 'Triangle',  'anywaa': 'Atuk Däk',      'imageUrl': 'assets/word_images/three_angle.png', 'category': 'Shapes'},
    {'id': 'shape_circle',   'english': 'Circle',    'anywaa': 'Lømløma',       'imageUrl': 'assets/word_images/circle.png',      'category': 'Shapes'},
    {'id': 'shape_oval',     'english': 'Oval',      'anywaa': 'Abööth abööth', 'imageUrl': 'assets/word_images/oval.png',        'category': 'Shapes'},

    // ── Body Parts (18) ───────────────────────────────────────────────────
    {'id': 'body_head',     'english': 'Head',     'anywaa': 'Wïc',         'imageUrl': 'assets/body_part/head.png',     'category': 'Body'},
    {'id': 'body_ear',      'english': 'Ear',      'anywaa': 'Ïth',         'imageUrl': 'assets/body_part/ear.png',      'category': 'Body'},
    {'id': 'body_eye',      'english': 'Eye',      'anywaa': 'Wang',        'imageUrl': 'assets/body_part/eye.png',      'category': 'Body'},
    {'id': 'body_nose',     'english': 'Nose',     'anywaa': 'Um',          'imageUrl': 'assets/body_part/nose.png',     'category': 'Body'},
    {'id': 'body_mouth',    'english': 'Mouth',    'anywaa': 'Dhøk',        'imageUrl': 'assets/body_part/mouth.png',    'category': 'Body'},
    {'id': 'body_teeth',    'english': 'Teeth',    'anywaa': 'Lak',         'imageUrl': 'assets/body_part/theeth.png',   'category': 'Body'},
    {'id': 'body_tongue',   'english': 'Tongue',   'anywaa': 'Leep',        'imageUrl': 'assets/body_part/toungue.png',  'category': 'Body'},
    {'id': 'body_neck',     'english': 'Neck',     'anywaa': 'Ngut',        'imageUrl': 'assets/body_part/neck.png',     'category': 'Body'},
    {'id': 'body_shoulder', 'english': 'Shoulder', 'anywaa': 'Göön',        'imageUrl': 'assets/body_part/shoulder.png', 'category': 'Body'},
    {'id': 'body_chest',    'english': 'Chest',    'anywaa': 'Käw',         'imageUrl': 'assets/body_part/chest.png',    'category': 'Body'},
    {'id': 'body_arm',      'english': 'Arm',      'anywaa': 'Cinø',        'imageUrl': 'assets/body_part/arm.png',      'category': 'Body'},
    {'id': 'body_finger',   'english': 'Finger',   'anywaa': 'Lweedø',      'imageUrl': 'assets/body_part/finger.png',   'category': 'Body'},
    {'id': 'body_thigh',    'english': 'Thigh',    'anywaa': 'Ääm',         'imageUrl': 'assets/body_part/thigh.png',    'category': 'Body'},
    {'id': 'body_leg',      'english': 'Leg',      'anywaa': 'Tielø',       'imageUrl': 'assets/body_part/leg.png',      'category': 'Body'},
    {'id': 'body_knee',     'english': 'Knee',     'anywaa': 'Wïcuung',     'imageUrl': 'assets/body_part/knee.png',     'category': 'Body'},
    {'id': 'body_ankle',    'english': 'Ankle',    'anywaa': 'Adikwala',    'imageUrl': 'assets/body_part/ankle.png',    'category': 'Body'},
    {'id': 'body_foot',     'english': 'Foot',     'anywaa': 'Othäny tielø','imageUrl': 'assets/body_part/foot.png',     'category': 'Body'},
    {'id': 'body_hair',     'english': 'Hair',     'anywaa': 'Jïër',        'imageUrl': 'assets/body_part/hair.png',     'category': 'Body'},

    // ── Clothes (10) ──────────────────────────────────────────────────────
    {'id': 'cloth_belt',    'english': 'Belt',        'anywaa': 'Kaw',       'imageUrl': 'assets/cloth/belt.png',    'category': 'Clothes'},
    {'id': 'cloth_cap',     'english': 'Cap',         'anywaa': 'Cöör',      'imageUrl': 'assets/cloth/cap.png',     'category': 'Clothes'},
    {'id': 'cloth_dress',   'english': 'Dress',       'anywaa': 'Araagi',    'imageUrl': 'assets/cloth/dress.png',   'category': 'Clothes'},
    {'id': 'cloth_glasses', 'english': 'Eye glasses', 'anywaa': 'Lïdhäärë',  'imageUrl': 'assets/cloth/glasses.png', 'category': 'Clothes'},
    {'id': 'cloth_jacket',  'english': 'Jacket',      'anywaa': 'Koothi',    'imageUrl': 'assets/cloth/jacket.png',  'category': 'Clothes'},
    {'id': 'cloth_shoes',   'english': 'Shoes',       'anywaa': 'War',       'imageUrl': 'assets/cloth/shoess.png',  'category': 'Clothes'},
    {'id': 'cloth_shorts',  'english': 'Shorts',      'anywaa': 'Ongølø',    'imageUrl': 'assets/cloth/shorts.png',  'category': 'Clothes'},
    {'id': 'cloth_skirt',   'english': 'Skirt',       'anywaa': 'Thïnuura',  'imageUrl': 'assets/cloth/skirt.png',   'category': 'Clothes'},
    {'id': 'cloth_socks',   'english': 'Socks',       'anywaa': 'Curubathe', 'imageUrl': 'assets/cloth/socks.png',   'category': 'Clothes'},
    {'id': 'cloth_trouser', 'english': 'Trouser',     'anywaa': 'Marthøa',   'imageUrl': 'assets/cloth/trouser.png', 'category': 'Clothes'},

    // ── Fish (10) ─────────────────────────────────────────────────────────
    {'id': 'fish_bichir',   'english': 'Bichir',           'anywaa': 'Odwëëla',  'imageUrl': 'assets/fish/adweela.png',     'category': 'Fish'},
    {'id': 'fish_catfish',  'english': 'Catfish',          'anywaa': 'Agwiila',  'imageUrl': 'assets/fish/agwiila (2).png', 'category': 'Fish'},
    {'id': 'fish_dolo',     'english': 'Dølø',             'anywaa': 'Dølø',     'imageUrl': 'assets/fish/dolo.png',        'category': 'Fish'},
    {'id': 'fish_perch',    'english': 'Nile Perch',       'anywaa': 'Guur',     'imageUrl': 'assets/fish/guur.png',        'category': 'Fish'},
    {'id': 'fish_vundu',    'english': 'Vundu',            'anywaa': 'Jari',     'imageUrl': 'assets/fish/jari (2).png',    'category': 'Fish'},
    {'id': 'fish_lungfish', 'english': 'Lungfish',         'anywaa': 'Luuth',    'imageUrl': 'assets/fish/luuth.png',       'category': 'Fish'},
    {'id': 'fish_bagrus',   'english': 'Bagrus bajad',     'anywaa': 'Odwäära',  'imageUrl': 'assets/fish/odwaara.png',     'category': 'Fish'},
    {'id': 'fish_heterotis','english': 'Heterotis',        'anywaa': 'Olwak',    'imageUrl': 'assets/fish/olwak.png',       'category': 'Fish'},
    {'id': 'fish_tilapia',  'english': 'Tilapia',          'anywaa': 'Orwëëdhö', 'imageUrl': 'assets/fish/rec.png',         'category': 'Fish'},
    {'id': 'fish_wiith',    'english': 'Wïïth',            'anywaa': 'Wïïth',    'imageUrl': 'assets/fish/wiith.png',       'category': 'Fish'},

    // ── Numbers (10) ──────────────────────────────────────────────────────
    {'id': 'num_1',  'english': 'One',   'anywaa': 'Aciel',    'imageUrl': 'assets/category_image/numbers_2.png', 'category': 'Numbers'},
    {'id': 'num_2',  'english': 'Two',   'anywaa': 'Ariew',    'imageUrl': 'assets/category_image/numbers_2.png', 'category': 'Numbers'},
    {'id': 'num_3',  'english': 'Three', 'anywaa': 'Adäk',     'imageUrl': 'assets/category_image/numbers_2.png', 'category': 'Numbers'},
    {'id': 'num_4',  'english': 'Four',  'anywaa': 'Angween',  'imageUrl': 'assets/category_image/numbers_2.png', 'category': 'Numbers'},
    {'id': 'num_5',  'english': 'Five',  'anywaa': 'Abïc',     'imageUrl': 'assets/category_image/numbers_2.png', 'category': 'Numbers'},
    {'id': 'num_6',  'english': 'Six',   'anywaa': 'Abïciel',  'imageUrl': 'assets/category_image/numbers_2.png', 'category': 'Numbers'},
    {'id': 'num_7',  'english': 'Seven', 'anywaa': 'Abïriø',   'imageUrl': 'assets/category_image/numbers_2.png', 'category': 'Numbers'},
    {'id': 'num_8',  'english': 'Eight', 'anywaa': 'Abära',    'imageUrl': 'assets/category_image/numbers_2.png', 'category': 'Numbers'},
    {'id': 'num_9',  'english': 'Nine',  'anywaa': 'Abïngween','imageUrl': 'assets/category_image/numbers_2.png', 'category': 'Numbers'},
    {'id': 'num_10', 'english': 'Ten',   'anywaa': 'Apaar',    'imageUrl': 'assets/category_image/numbers_2.png', 'category': 'Numbers'},

    // ── Words / Vocabulary (29) ───────────────────────────────────────────
    {'id': 'word_abac',    'english': 'Maize',                  'anywaa': 'Abäc',   'imageUrl': 'assets/word_images/maize.png',    'category': 'Words'},
    {'id': 'word_aam',     'english': 'Thigh',                  'anywaa': 'Ääm',    'imageUrl': 'assets/word_images/thigh.png',    'category': 'Words'},
    {'id': 'word_boogo',   'english': 'Leaf',                   'anywaa': 'Bøøgø',  'imageUrl': 'assets/word_images/leaf.png',     'category': 'Words'},
    {'id': 'word_coor',    'english': 'Hat',                    'anywaa': 'Cöör',   'imageUrl': 'assets/word_images/hat.png',      'category': 'Words'},
    {'id': 'word_digwey',  'english': 'Lizard',                 'anywaa': 'Digwey', 'imageUrl': 'assets/word_images/lizard.png',   'category': 'Words'},
    {'id': 'word_dhieng',  'english': 'Cow',                    'anywaa': 'Dhieng', 'imageUrl': 'assets/word_images/cow.png',      'category': 'Words'},
    {'id': 'word_eel',     'english': 'Push',                   'anywaa': 'Eel',    'imageUrl': 'assets/word_images/eel.png',      'category': 'Words'},
    {'id': 'word_eeli',    'english': 'Injera making machine',  'anywaa': 'Ëëlï',   'imageUrl': 'assets/word_images/eeli.png',     'category': 'Words'},
    {'id': 'word_gwieno',  'english': 'Hen',                    'anywaa': 'Gwienø', 'imageUrl': 'assets/word_images/hen.png',      'category': 'Words'},
    {'id': 'word_iith',    'english': 'Well',                   'anywaa': 'Iith',   'imageUrl': 'assets/word_images/iith.png',     'category': 'Words'},
    {'id': 'word_ith',     'english': 'Ear',                    'anywaa': 'Ïth',    'imageUrl': 'assets/word_images/ear.png',      'category': 'Words'},
    {'id': 'word_jaay',    'english': 'Car',                    'anywaa': 'Jääy',   'imageUrl': 'assets/word_images/car.png',      'category': 'Words'},
    {'id': 'word_koom',    'english': 'Chair',                  'anywaa': 'Køøm',   'imageUrl': 'assets/word_images/char.png',     'category': 'Words'},
    {'id': 'word_liec',    'english': 'Elephant',               'anywaa': 'Liec',   'imageUrl': 'assets/word_images/elephant.png', 'category': 'Words'},
    {'id': 'word_maac',    'english': 'Fire',                   'anywaa': 'Maac',   'imageUrl': 'assets/word_images/maac.png',     'category': 'Words'},
    {'id': 'word_naam',    'english': 'River',                  'anywaa': 'Naam',   'imageUrl': 'assets/word_images/river.png',    'category': 'Words'},
    {'id': 'word_nhoth',   'english': 'Suck',                   'anywaa': 'Nhøth',  'imageUrl': 'assets/word_images/suck.png',     'category': 'Words'},
    {'id': 'word_nguu',    'english': 'Lion',                   'anywaa': 'Nguu',   'imageUrl': 'assets/word_images/lion.png',     'category': 'Words'},
    {'id': 'word_nyaang',  'english': 'Crocodile',              'anywaa': 'Nyaang', 'imageUrl': 'assets/word_images/croc.png',     'category': 'Words'},
    {'id': 'word_odiek',   'english': 'Hyena',                  'anywaa': 'Odïëk',  'imageUrl': 'assets/word_images/hyena.png',    'category': 'Words'},
    {'id': 'word_ook',     'english': 'Öök',                    'anywaa': 'Öök',    'imageUrl': 'assets/word_images/ook.png',      'category': 'Words'},
    {'id': 'word_oto',     'english': 'House',                  'anywaa': 'Øttø',   'imageUrl': 'assets/word_images/house.png',    'category': 'Words'},
    {'id': 'word_pien',    'english': 'Carpet',                 'anywaa': 'Pïën',   'imageUrl': 'assets/word_images/pien.png',     'category': 'Words'},
    {'id': 'word_rii',     'english': 'Giraffe',                'anywaa': 'Rïï',    'imageUrl': 'assets/word_images/giraffe.png',  'category': 'Words'},
    {'id': 'word_tong',    'english': 'Arrow',                  'anywaa': 'Tøng',   'imageUrl': 'assets/word_images/tong.png',     'category': 'Words'},
    {'id': 'word_thoom',   'english': 'Guitar',                 'anywaa': 'Thoom',  'imageUrl': 'assets/word_images/guitar.png',   'category': 'Words'},
    {'id': 'word_uudo',    'english': 'Ostrich',                'anywaa': 'Uudö',   'imageUrl': 'assets/word_images/ostrich.png',  'category': 'Words'},
    {'id': 'word_war',     'english': 'Shoes',                  'anywaa': 'War',    'imageUrl': 'assets/word_images/shoe.png',     'category': 'Words'},
    {'id': 'word_yiie',    'english': 'Inside',                 'anywaa': 'Yiie',   'imageUrl': 'assets/word_images/carton.png',   'category': 'Words'},
  ];

  /// All vocabulary words as typed objects.
  List<WordData> getAllWords() => _allWordsData
      .map((d) => WordData(
            id:       d['id']!,
            english:  d['english']!,
            anywaa:   d['anywaa']!,
            imageUrl: d['imageUrl']!,
            category: d['category']!,
          ))
      .toList();

  /// Words filtered by category name.
  List<WordData> getByCategory(String category) =>
      getAllWords().where((w) => w.category == category).toList();

  /// All distinct category names.
  List<String> getCategories() =>
      _allWordsData.map((d) => d['category']!).toSet().toList();

  /// Total word count.
  int get totalWordCount => _allWordsData.length;
}
