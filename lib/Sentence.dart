class Sentence {
  String letter;
  String word;
  String sentence;
  String audioUrl;
  String? imageAsset;

  Sentence(
      {required this.letter,
      required this.word,
      required this.sentence,
      required this.audioUrl,
      this.imageAsset});
}
