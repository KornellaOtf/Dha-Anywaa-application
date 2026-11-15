import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dha_anywaaa/widgets/thinking_orb.dart';

void main() {
  for (final state in OrbState.values) {
    for (final brightness in Brightness.values) {
      testWidgets('orb renders ${state.name} on $brightness', (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(body: Center(child: ThinkingOrb(state: state, size: 64))),
        ));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(ThinkingOrb), findsOneWidget);
      });
    }
  }
}
