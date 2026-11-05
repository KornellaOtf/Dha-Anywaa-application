// Regression test for the fully offline "Anywaa AI" assistant.
// It loads the bundled dictionary asset and checks grounded answers:
// an English query returns the Dha term, an Anywaa query returns the
// English meaning, and an unknown word is refused rather than invented.

import 'package:flutter_test/flutter_test.dart';

import 'package:dha_anywaaa/services/anywaa_ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Each test starts a fresh thread so conversational context never leaks
  // from one test into the next.
  setUp(() => AnywaaAiService.instance.newChat());

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

  test('curated vocabulary (phrases, numbers, symbols) is answerable', () async {
    final ai = AnywaaAiService.instance;
    await ai.load();

    // Multi-word greeting phrase (a stop-word-only phrase resolves via its
    // exact whole-phrase form, so it is queried directly).
    final greet = ai.answer('how are you');
    expect(greet.found, isTrue);
    expect(greet.matches.first.entry.en.toLowerCase(), 'how are you');

    // Number system beyond the old 1-10 (tens).
    final num = ai.answer('what is twenty in dha anywaa');
    expect(num.found, isTrue);
    expect(num.matches.first.entry.dha, 'Piariew');

    // Hundreds resolve as their own entries.
    final hundred = ai.answer('three hundred');
    expect(hundred.found, isTrue);
    expect(hundred.matches.first.entry.dha, 'Dipedak');

    // Insect vocabulary.
    final insect = ai.answer('spider');
    expect(insect.found, isTrue);
    expect(insect.matches.first.entry.dha, 'Othïënø');

    // Math symbol reachable via its English name.
    final math = ai.answer('how do you say plus in dha anywaa');
    expect(math.found, isTrue);
    expect(math.matches.first.entry.dha, 'Dwal');
  });

  test('seed vocabulary is layered in without overriding curated forms',
      () async {
    final ai = AnywaaAiService.instance;
    await ai.load();

    // Brand-new domain terms (were absent from the original 710 data).
    final milk = ai.answer('milk');
    expect(milk.found, isTrue);
    expect(milk.matches.first.entry.dha, 'Caak');

    final water = ai.answer('what is the word for water');
    expect(water.found, isTrue);
    expect(water.matches.first.entry.dha, 'Pïï');

    final ours = ai.answer('ours');
    expect(ours.found, isTrue);
    expect(ours.matches.first.entry.dha, 'Marwa');

    // Curated spelling stays the displayed answer even though the dataset
    // added a competing synonym (to speak: primary 'Chaano').
    final speak = ai.answer('to speak');
    expect(speak.found, isTrue);
    expect(speak.matches.first.entry.dha, 'Chaano');

    // ...but a dataset alternate spelling is still findable as a synonym.
    final cigira = ai.answer('cigira');
    expect(cigira.found, isTrue);
    expect(cigira.matches.any((m) => m.entry.en == 'lion'), isTrue);
  });

  test('smarter matching: plurals, typos, and wrapped phrases', () async {
    final ai = AnywaaAiService.instance;
    await ai.load();

    // Plural resolves to the singular headword via light stemming.
    final plural = ai.answer('spiders');
    expect(plural.found, isTrue);
    expect(plural.matches.first.entry.en, 'spider');

    // A typo still resolves to the closest real word.
    final typo = ai.answer('waterr');
    expect(typo.found, isTrue);
    expect(typo.matches.first.entry.dha, 'Pïï');

    // A stop-word phrase nested in a longer sentence still resolves via
    // phrase containment (this used to be lost after stop-word stripping).
    final wrapped =
        ai.answer('how do you say how are you in Dha Anywaa');
    expect(wrapped.found, isTrue);
    expect(wrapped.matches.first.entry.en, 'how are you');

    // Junk with a near-miss must still be refused, not guessed.
    final miss = ai.answer('qqzzx');
    expect(miss.found, isFalse);
  });

  test('machine-readable dataset domains are answerable (v4 coverage)',
      () async {
    final ai = AnywaaAiService.instance;
    await ai.load();
    expect(ai.wordCount, greaterThan(1300));

    // Newly added body / animal / food / nature domains.
    expect(ai.answer('tongue').matches.first.entry.dha, 'Lep');
    expect(ai.answer('what is crocodile').matches.first.entry.dha, 'Nyaang');
    expect(ai.answer('honey').matches.first.entry.dha, contains('Maar'));
    expect(ai.answer('rain').matches.first.entry.dha, 'Koth');

    // Adjectives by color.
    expect(ai.answer('black').matches.first.entry.dha, 'Macól');

    // Curated spelling stays primary even though the dataset added a variant
    // (lion: dataset 'Nguu' primary with synonym 'Cigïïra').
    final lion = ai.answer('lion');
    expect(lion.found, isTrue);
    expect(lion.matches.first.entry.dha, contains('Nguu'));

    // Dataset term findable through its alternate spelling as a synonym.
    final koom = ai.answer('koom');
    expect(koom.found, isTrue);
    expect(koom.matches.any((m) => m.entry.en == 'chair'), isTrue);
  });

  test('conversational intents answer like a chat, not a failed lookup',
      () async {
    final ai = AnywaaAiService.instance;
    await ai.load();

    // Identity.
    final who = ai.answer('who are you?');
    expect(who.found, isFalse);
    expect(who.text, contains('Anywaa AI'));

    // Capability.
    final cap = ai.answer('what can you do');
    expect(cap.text, contains('translate'));

    // Origin.
    final from = ai.answer('where are you from');
    expect(from.text, contains('device'));

    // A bare greeting is recognised (and is not mistaken for a word lookup).
    final hi = ai.answer('hi');
    expect(hi.found, isFalse);
    expect(hi.text, contains('Ask me'));
  });

  test('number generator spells 1-9999 from the taught rules', () async {
    final ai = AnywaaAiService.instance;
    await ai.load();

    // Teen: "Apar ka <unit>".
    expect(ai.answer('how do you say 11').text,
        contains('Apar ka aciel'));
    // Compound tens + unit.
    expect(ai.answer('what is 55').text,
        contains('Piarabich ka ab'));
    // Round hundred with a trailing ten.
    expect(ai.answer('say 110 in Dha Anywaa').text,
        contains('Dipa ka apar'));
    // Thousands.
    expect(ai.answer('say 2026').text,
        contains('Kumme ariew ka piariew ka ab'));
    // Out of range is refused, never fabricated.
    expect(ai.answer('say 99999').found, isFalse);
  });

  test('direction auto-detected when the query gives no explicit hint',
      () async {
    final ai = AnywaaAiService.instance;
    await ai.load();

    // A Dha Anywaa word typed alone (no "english"/"dha" cue) is understood as
    // asking for the English meaning.
    final dhaOnly = ai.answer('wic');
    expect(dhaOnly.found, isTrue);
    expect(dhaOnly.text, contains('English'));
    expect(dhaOnly.text.toLowerCase(), contains('abandon'));

    // An English word typed alone returns the Dha translation.
    final enOnly = ai.answer('water');
    expect(enOnly.found, isTrue);
    expect(enOnly.text, contains('Dha Anywaa'));
  });

  test('conversation: follow-ups resolve against the last word', () async {
    final ai = AnywaaAiService.instance;
    await ai.load();

    final t1 = ai.answer('How do you say water');
    expect(t1.found, isTrue);
    expect(t1.text, contains('Pïï'));

    // "and the plural?" is about the same word. No plural data exists, so it
    // must say so honestly instead of inventing one.
    final t2 = ai.answer('and the plural?');
    expect(t2.found, isFalse);
    expect(t2.text, contains('plural'));
    expect(t2.text, contains('Pïï'));

    // "say it again" replays the last translation (still about water).
    final t3 = ai.answer('say it again');
    expect(t3.found, isTrue);
    expect(t3.text, contains('Pïï'));
    expect(t3.text, contains('Dha Anywaa'));
  });

  test('conversation: example sentence is refused, not invented', () async {
    final ai = AnywaaAiService.instance;
    await ai.load();

    expect(ai.answer('What does wic mean').found, isTrue);
    final ex = ai.answer('use it in a sentence');
    expect(ex.found, isFalse);
    expect(ex.text, "I don't have an example sentence for that word yet.");
  });

  test('conversation: "what about X" runs a new lookup in the same direction',
      () async {
    final ai = AnywaaAiService.instance;
    await ai.load();

    final t1 = ai.answer('translate house');
    expect(t1.found, isTrue);
    expect(t1.text, contains('Dha Anywaa'));

    final t2 = ai.answer('what about spider?');
    expect(t2.found, isTrue);
    expect(t2.matches.first.entry.en, 'spider');
    expect(t2.matches.first.entry.dha, 'Othïënø');
    // Same kind of question as "translate house": answered in Dha Anywaa.
    expect(t2.text, contains('Dha Anywaa'));
  });

  test('conversation: a follow-up with no subject asks which word', () async {
    final ai = AnywaaAiService.instance;
    await ai.load();

    final first = ai.answer('and the plural?');
    expect(first.found, isFalse);
    expect(first.text, contains('Which word'));
  });

  test('exact-phrase search returns only the match, no slop', () async {
    final ai = AnywaaAiService.instance;
    await ai.load();

    // "teek ec" is itself the dictionary entry for Doubt. The old matcher also
    // returned every long sentence that merely contained "teek" or "ec".
    final doubt = ai.answer('teek ec');
    expect(doubt.found, isTrue);
    expect(doubt.matches.length, 1);
    expect(doubt.matches.first.entry.en, 'Doubt');
    final heads = doubt.matches.map((m) => m.entry.en).toList();
    for (final junk in ['Belt', 'Coerce', 'Forgive', 'Backstroke']) {
      expect(heads, isNot(contains(junk)));
    }

    // A multi-word query must match the whole phrase, not one shared word.
    final partial = ai.answer('teek cwïny');
    expect(partial.matches.map((m) => m.entry.en), isNot(contains('Belt')));

    // A single-word exact hit stays focused (Abdomen == "ec").
    final ec = ai.answer('ec');
    expect(ec.found, isTrue);
    expect(ec.matches.first.entry.en.toLowerCase(), 'abdomen');
  });

  test('hero suggestions are dynamic and always answerable', () async {
    final ai = AnywaaAiService.instance;
    await ai.load();

    final first = ai.sampleQuestions(count: 6);
    expect(first.length, greaterThanOrEqualTo(5));
    // Every generated prompt resolves against the real dictionary (words) or
    // the number rules, so no chip can dead-end on the hero screen.
    for (final q in first) {
      final res = ai.answer(q);
      expect(res.found || res.text.contains('Dha Anywaa'), isTrue,
          reason: 'unanswerable suggestion: $q');
      ai.newChat();
    }

    // Across many draws the pool is not a fixed set: it must vary.
    final seen = <String>{};
    for (var i = 0; i < 12; i++) {
      seen.addAll(ai.sampleQuestions(count: 6));
    }
    expect(seen.length, greaterThan(first.length),
        reason: 'suggestions never change between draws');
  });
}
