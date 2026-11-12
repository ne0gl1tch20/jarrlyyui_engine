import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
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

  testWidgets(
    'resolves nested string bindings from host state',
    (tester) async {
      final document = const JuiParser().parse(
        '{"schemaVersion":1,"screen":"home","root":{"type":"text","binding":"player.displayName"}}',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JuiRenderer(
              document: document,
              state: const {
                'player': {'displayName': 'Player One'},
              },
              onAction: (_, __) async {},
            ),
          ),
        ),
      );

      expect(find.text('Player One'), findsOneWidget);
    },
  );

  testWidgets(
    'renders an empty value for missing or non-string bindings',
    (tester) async {
      final document = const JuiParser().parse(
        '{"schemaVersion":1,"screen":"home","root":{"type":"text","binding":"player.displayName"}}',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JuiRenderer(
              document: document,
              state: const {
                'player': {'displayName': 42},
              },
              onAction: (_, __) async {},
            ),
          ),
        ),
      );

      expect(find.text(''), findsOneWidget);
    },
  );

  testWidgets(
    'dispatches input changes through the host callback',
    (tester) async {
      final document = const JuiParser().parse(
        '{"schemaVersion":1,"screen":"settings","root":{"type":"input","id":"settings.player_name","label":"Player name","placeholder":"Enter a name"}}',
      );
      String? changedId;
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JuiRenderer(
              document: document,
              onAction: (_, __) async {},
              onInput: (id, value) async {
                changedId = id;
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Ada');
      expect(changedId, 'settings.player_name');
      expect(changedValue, 'Ada');
    },
  );

  testWidgets('renders bounded collection templates with item bindings', (tester) async {
    final document = const JuiParser().parse(
      '{"schemaVersion":1,"screen":"inventory","root":{"type":"repeat","binding":"inventory.items","children":[{"type":"row","children":[{"type":"text","binding":"item.name"},{"type":"text","binding":"item.quantity"}]}]}}',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JuiRenderer(
            document: document,
            onAction: (_, __) async {},
            state: const {
              'inventory': {
                'items': [
                  {'name': 'Sword', 'quantity': '2'},
                  {'name': 'Shield', 'quantity': '1'},
                ],
              },
            },
          ),
        ),
      ),
    );

    expect(find.text('Sword'), findsOneWidget);
    expect(find.text('Shield'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

}
