import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dha_anywaaa/dictionary_page.dart';
import 'package:dha_anywaaa/services/anywaa_ai_service.dart';

void main() {
  testWidgets('dictionary page loads the bundled dictionary and searches a word',
      (tester) async {
    final ai = AnywaaAiService.instance;
    await ai.load();
    expect(ai.answer('water').found, isTrue);

    await tester.pumpWidget(const MaterialApp(home: DictionaryPage()));
    await tester.pump();

    expect(find.text('Dictionary'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'water');
    await tester.pump();
    await tester.tap(find.text('Search'));
    for (var attempt = 0;
        attempt < 20 && find.textContaining('Pïï').evaluate().isEmpty;
        attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('Pïï'), findsOneWidget);
    expect(find.textContaining('water'), findsWidgets);
  });
}
