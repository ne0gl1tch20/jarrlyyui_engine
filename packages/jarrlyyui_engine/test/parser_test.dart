import 'package:flutter_test/flutter_test.dart';
import 'package:jarrlyyui_engine/jarrlyyui_engine.dart';

void main() {
  const parser = JuiParser();

  test('parses a valid screen tree', () {
    final document = parser.parse('''
      {"schemaVersion":1,"screen":"home","root":{
        "type":"column","children":[
          {"type":"text","text":"Hello"},
          {"type":"button","text":"Play","action":{"id":"navigation.open","arguments":{"route":"game"}}}
        ]
      }}
    ''');

    expect(document.screenId, 'home');
    expect(document.root.children, hasLength(2));
    expect(document.root.children.last.actionId, 'navigation.open');
    expect(document.root.children.last.actionArguments['route'], 'game');
  });

  test('rejects unknown node types', () {
    expect(
      () => parser.parse(
        '{"schemaVersion":1,"screen":"x","root":{"type":"script"}}',
      ),
      throwsA(isA<JuiFormatException>()),
    );
  });

  test('rejects unknown properties rather than silently accepting them', () {
    expect(
      () => parser.parse(
        '{"schemaVersion":1,"screen":"x","root":{"type":"text","onTap":"evil"}}',
      ),
      throwsA(isA<JuiFormatException>()),
    );
  });

  test('rejects buttons without a registered action identifier shape', () {
    expect(
      () => parser.parse(
        '{"schemaVersion":1,"screen":"x","root":{"type":"button","text":"Go"}}',
      ),
      throwsA(isA<JuiFormatException>()),
    );
  });

  test('requires exactly one child in padding nodes', () {
    expect(
      () => parser.parse(
        '{"schemaVersion":1,"screen":"x","root":{"type":"padding","children":[]}}',
      ),
      throwsA(isA<JuiFormatException>()),
    );
  });

  test('rejects excessive document size', () {
    const limited = JuiParser(maxDocumentBytes: 20);
    expect(
      () => limited.parse(
        '{"schemaVersion":1,"screen":"home","root":{"type":"text","text":"too long"}}',
      ),
      throwsA(isA<JuiFormatException>()),
    );
  });

  test('bounds nested action argument depth', () {
    const limited = JuiParser(maxDepth: 2);
    expect(
      () => limited.parse(
        '{"schemaVersion":1,"screen":"x","root":{"type":"button","text":"Go","action":{"id":"game.submit","arguments":{"nested":{"value":"x"}}}}}',
      ),
      throwsA(isA<JuiFormatException>()),
    );
  });

  test('deeply freezes nested action arguments', () {
    final document = parser.parse(
      '{"schemaVersion":1,"screen":"x","root":{"type":"button","text":"Go","action":{"id":"game.submit","arguments":{"nested":{"value":"x"}}}}}',
    );
    final nested = document.root.actionArguments['nested'] as Map;

    expect(
      () => nested['value'] = 'changed',
      throwsUnsupportedError,
    );
  });

}
