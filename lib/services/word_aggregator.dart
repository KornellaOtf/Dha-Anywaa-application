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

/// Aggregates all word data from component files into a single unified list
/// for use with Daily 5, Learning Engine, and other features.
class WordAggregator {
  WordAggregator._();
  static final WordAggregator instance = WordAggregator._();

  // All vocabulary data extracted from component files
  static const List<Map<String, String>> _allWordsData = [
    // Animals (14 words)
    {'id': 'animal_cat', 'english': 'Cat', 'anywaa': 'Adhurrï', 'imageUrl': 'assets/animals/cat.png', 'category': 'Animals'},
    {'id': 'animal_chameleons', 'english': 'Chameleons', 'anywaa': 'Ongøønnø', 'imageUrl': 'assets/animals/chem.png', 'category': 'Animals'},
    {'id': 'animal_dog', 'english': 'Dog', 'anywaa': 'Gwök', 'imageUrl': 'assets/animals/dog.png', 'category': 'Animals'},
    {'id': 'animal_donkey', 'english': 'Donkey', 'anywaa': 'Arëën', 'imageUrl': 'assets/animals/donkey.png', 'category': 'Animals'},
    {'id': 'animal_colobus', 'english': 'Black-and-white colobus', 'anywaa': 'Döölö', 'imageUrl': 'assets/animals/doolo.png', 'category': 'Animals'},
    {'id': 'animal_fox', 'english': 'Fox', 'anywaa': 'Othöö', 'imageUrl': 'assets/animals/foox.png', 'category': 'Animals'},
    {'id': 'animal_giraffe', 'english': 'Giraffe', 'anywaa': 'Rïï', 'imageUrl': 'assets/animals/giraffe.png', 'category': 'Animals'},
    {'id': 'animal_goat', 'english': 'Goat', 'anywaa': 'Diel', 'imageUrl': 'assets/animals/goat.png', 'category': 'Animals'},
    {'id': 'animal_warthog', 'english': 'Warthog', 'anywaa': 'Kul', 'imageUrl': 'assets/animals/kuul.png', 'category': 'Animals'},
    {'id': 'animal_rhino', 'english': 'Rhinoceros', 'anywaa': 'Nyigudhwönynya', 'imageUrl': 'assets/animals/ngiguthwonya.png', 'category': 'Animals'},
    {'id': 'animal_lion', 'english': 'Lion', 'anywaa': 'Nguu', 'imageUrl': 'assets/animals/nguu.png', 'category': 'Animals'},
    {'id': 'animal_hippo', 'english': 'Hippopotamus', 'anywaa': 'Ray', 'imageUrl': 'assets/animals/ray.png', 'category': 'Animals'},
    {'id': 'animal_porcupine', 'english': 'Porcupine', 'anywaa': 'Thëëy', 'imageUrl': 'assets/animals/theey.png', 'category': 'Animals'},
    {'id': 'animal_cow', 'english': 'Cow', 'anywaa': 'Dhieng', 'imageUrl': 'assets/animals/white_black_cow.png', 'category': 'Animals'},
    
    // Birds (12 words)
    {'id': 'bird_hamerkop', 'english': 'Hamerkop', 'anywaa': 'Aciik', 'imageUrl': 'assets/birds/aciik.png', 'category': 'Birds'},
    {'id': 'bird_weaver', 'english': 'Village weaver', 'anywaa': 'Aleerø', 'imageUrl': 'assets/birds/aleero.png', 'category': 'Birds'},
    {'id': 'bird_butterfly', 'english': 'Butterfly', 'anywaa': 'Adeellakwac', 'imageUrl': 'assets/birds/butterfly.png', 'category': 'Birds'},
    {'id': 'bird_duck', 'english': 'Duck', 'anywaa': 'Badhø', 'imageUrl': 'assets/birds/duck.png', 'category': 'Birds'},
    {'id': 'bird_eagle', 'english': 'Fish eagle', 'anywaa': 'Dibëël', 'imageUrl': 'assets/birds/fish_eagle.png', 'category': 'Birds'},
    {'id': 'bird_hen', 'english': 'Hen', 'anywaa': 'Gwienø', 'imageUrl': 'assets/birds/gwieno.png', 'category': 'Birds'},
    {'id': 'bird_egret', 'english': 'Cattle Egret', 'anywaa': 'Okøøk', 'imageUrl': 'assets/birds/okook.png', 'category': 'Birds'},
    {'id': 'bird_plegadis', 'english': 'Plegadis', 'anywaa': 'Owaaw', 'imageUrl': 'assets/birds/owaaw.png', 'category': 'Birds'},
    {'id': 'bird_pelican', 'english': 'Pelican', 'anywaa': 'Obööngö', 'imageUrl': 'assets/birds/pelican.png', 'category': 'Birds'},
    {'id': 'bird_nightjar', 'english': 'Standard nightjar', 'anywaa': 'Obwölatäämmö', 'imageUrl': 'assets/birds/standard_nightjar.png', 'category': 'Birds'},
    {'id': 'bird_owl', 'english': 'Owl', 'anywaa': 'Tula', 'imageUrl': 'assets/birds/tula.png', 'category': 'Birds'},
    {'id': 'bird_dove', 'english': 'Dove', 'anywaa': 'Akuuru', 'imageUrl': 'assets/birds/white_dove.png', 'category': 'Birds'},
    
    // Colors (8 words)
    {'id': 'color_red', 'english': 'Red', 'anywaa': 'Kwaar', 'imageUrl': 'assets/word_images/red.png', 'category': 'Colors'},
    {'id': 'color_yellow', 'english': 'Yellow', 'anywaa': 'Abäga', 'imageUrl': 'assets/word_images/yellow.png', 'category': 'Colors'},
    {'id': 'color_blue', 'english': 'Blue', 'anywaa': 'Amïrïga', 'imageUrl': 'assets/word_images/blue.png', 'category': 'Colors'},
    {'id': 'color_orange', 'english': 'Orange', 'anywaa': 'Maar odwëëla', 'imageUrl': 'assets/word_images/orange.png', 'category': 'Colors'},
    {'id': 'color_skyblue', 'english': 'Sky blue', 'anywaa': 'Caaro', 'imageUrl': 'assets/word_images/sky blue.png', 'category': 'Colors'},
    {'id': 'color_green', 'english': 'Green', 'anywaa': 'Mar', 'imageUrl': 'assets/word_images/green.png', 'category': 'Colors'},
    {'id': 'color_white', 'english': 'White', 'anywaa': 'Tar', 'imageUrl': 'assets/word_images/white.png', 'category': 'Colors'},
    {'id': 'color_black', 'english': 'Black', 'anywaa': 'Cøl', 'imageUrl': 'assets/word_images/black.jpeg', 'category': 'Colors'},
    
    // Shapes (4 words)
    {'id': 'shape_rectangle', 'english': 'Rectangle', 'anywaa': 'Atuk ngween', 'imageUrl': 'assets/word_images/rectangle.png', 'category': 'Shapes'},
    {'id': 'shape_triangle', 'english': 'Triangle', 'anywaa': 'Atuk Däk', 'imageUrl': 'assets/word_images/three_angle.png', 'category': 'Shapes'},
    {'id': 'shape_circle', 'english': 'Circle', 'anywaa': 'Lømløma', 'imageUrl': 'assets/word_images/circle.png', 'category': 'Shapes'},
    {'id': 'shape_oval', 'english': 'Oval', 'anywaa': 'Abööth abööth', 'imageUrl': 'assets/word_images/oval.png', 'category': 'Shapes'},
  ];

  /// Get all vocabulary words
  List<WordData> getAllWords() {
    return _allWordsData.map((data) => WordData(
      id: data['id']!,
      english: data['english']!,
      anywaa: data['anywaa']!,
      imageUrl: data['imageUrl']!,
      category: data['category']!,
    )).toList();
  }

  /// Get total vocabulary count
  int getTotalWordCount() => _allWordsData.length;
}
