// Regression test for the fully offline "Anywaa AI" assistant.
// It loads the bundled dictionary asset and checks grounded answers:
// an English query returns the Dha term, an Anywaa query returns the
// English meaning, and an unknown word is refused rather than invented.

import 'package:flutter_test/flutter_test.dart';

import 'package:dha_anywaaa/services/anywaa_ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('offline assistant answers only from the bundled dictionary', () async {
    final ai = AnywaaAiService.instance;
    await ai.load();
    expect(ai.ready, isTrue);
    expect(ai.wordCount, greaterThan(600));

    // English -> Dha Anywaa, with phrasing noise stripped.
    final en = ai.answer('How do you say abandon in Dha Anywaa?');
    expect(en.found, isTrue);
    expect(en.matches.first.entry.en.toLowerCase(), 'abandon');
    expect(en.matches.first.entry.dha.toLowerCase(), contains('wic'));

    // Dha Anywaa -> English meaning.
    final dha = ai.answer('what does wic mean');
    expect(dha.found, isTrue);
    expect(dha.matches.first.entry.en.toLowerCase(), 'abandon');

    // Accent folding: user types a plain-letter form of an accented term.
    final folded = ai.answer('goore');
    expect(folded.found, isTrue);

    // Unknown words are refused, never hallucinated.
    final miss = ai.answer('zzqxv nothinghere');
    expect(miss.found, isFalse);
    expect(miss.text, contains('local Anywaa dictionary'));
  });
}
