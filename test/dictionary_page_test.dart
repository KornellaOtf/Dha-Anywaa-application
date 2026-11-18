import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/real_assets.dart';

import 'package:dha_anywaaa/dictionary_page.dart';
import 'package:dha_anywaaa/services/anywaa_ai_service.dart';

void main() {
  enableRealEncryptedAssets();
  testWidgets('dictionary page loads the bundled dictionary and searches a word',
      (tester) async {
    final ai = AnywaaAiService.instance;
    await ai.load();
    expect(ai.answer('water').found, isTrue);

    await tester.pumpWidget(const MaterialApp(home: DictionaryPage()));
    // Real async (asset decrypt) can't advance under FakeAsync —
    // runAsync() escapes it so the load future can complete.
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 2)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Dictionary'), findsWidgets);

    // Current UI: search is a mode toggled by the app-bar search icon.
    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'water');
    for (var attempt = 0;
        attempt < 20 && find.textContaining('Pïï').evaluate().isEmpty;
        attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('Pïï'), findsWidgets);
    expect(find.textContaining('water'), findsWidgets);
  });
}
