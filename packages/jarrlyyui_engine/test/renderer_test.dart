import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarrlyyui_engine/jarrlyyui_engine.dart';

void main() {
  testWidgets(
    'renders JUI text and dispatches only declared host actions',
    (tester) async {
      final document = const JuiParser().parse('''
      {"schemaVersion":1,"screen":"home","root":{"type":"column","children":[
        {"type":"text","text":"Welcome"},
        {"type":"button","text":"Play","action":{"id":"navigation.open","arguments":{"route":"game"}}}
      ]}}
    ''');
      String? invoked;
      Map<String, Object?>? arguments;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JuiRenderer(
              document: document,
              onAction: (id, args) async {
                invoked = id;
                arguments = args;
              },
            ),
          ),
        ),
      );

      expect(find.text('Welcome'), findsOneWidget);
      await tester.tap(find.text('Play'));
      await tester.pump();
      expect(invoked, 'navigation.open');
      expect(arguments?['route'], 'game');
    },
  );
}
