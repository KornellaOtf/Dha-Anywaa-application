import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dha_anywaaa/services/groq_service.dart';

void main() {
  group('UTF-8 decode path', () {
    test('Anywaa letters survive encode/decode round-trip', () {
      const s = 'Dëëri jööt? Dha Anywaa';
      expect(utf8.decode(utf8.encode(s)), s);
    });

    test('latin1-misdecoded mojibake is repaired', () {
      // Simulate the old bug: UTF-8 bytes decoded as Latin-1.
      final mojibake = latin1.decode(utf8.encode('Dëëri'));
      expect(mojibake, isNot('Dëëri'));
      expect(GroqService.fixMojibake(mojibake), 'Dëëri');
    });

    test('correct text passes through fixMojibake unchanged', () {
      expect(GroqService.fixMojibake('Dha Anywaa'), 'Dha Anywaa');
      // ŋ (U+014B) exceeds Latin-1 → encode throws → returned as-is.
      expect(GroqService.fixMojibake('ŋ'), 'ŋ');
    });
  });

  group('cleanReply', () {
    test('normalizes invisible spaces and dashes', () {
      expect(GroqService.cleanReply('Dha\u202FAnywaa'), 'Dha Anywaa');
      expect(GroqService.cleanReply('a\u00A0b'), 'a b');
      expect(GroqService.cleanReply('well\u2011known'), 'well-known');
      expect(GroqService.cleanReply('x\u200By'), 'xy');
      expect(GroqService.cleanReply('one—two–three'), 'one,two,three');
      expect(GroqService.cleanReply('**bold** `code`'), 'bold code');
    });

    test('leaves normal Anywaa spelling untouched', () {
      const s = 'Dëëri jööt? Dha Anywaa';
      expect(GroqService.cleanReply(s), s);
    });
  });
}
