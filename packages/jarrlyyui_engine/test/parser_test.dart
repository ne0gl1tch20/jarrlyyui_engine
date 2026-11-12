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

  test('validates repeat nodes with one item template', () {
    final document = parser.parse(
      '{"schemaVersion":1,"screen":"inventory","root":{"type":"repeat","binding":"inventory.items","children":[{"type":"text","binding":"item.name"}]}}',
    );
    expect(document.root.bindingPath, 'inventory.items');
    expect(document.root.children, hasLength(1));
    expect(document.root.children.single.bindingPath, 'item.name');
  });

  test('rejects repeat nodes without exactly one template child', () {
    for (final children in ['[]', '[{"type":"text","text":"A"},{"type":"text","text":"B"}]']) {
      expect(
        () => parser.parse(
          '{"schemaVersion":1,"screen":"x","root":{"type":"repeat","binding":"items","children":$children}}',
        ),
        throwsA(isA<JuiFormatException>()),
      );
    }
  });

  test('validates declarative text input nodes', () {
    final document = parser.parse(
      '{"schemaVersion":1,"screen":"x","root":{"type":"input","id":"player.name","label":"Player name","placeholder":"Enter a name","binding":"player.name"}}',
    );
    expect(document.root.inputId, 'player.name');
    expect(document.root.label, 'Player name');
    expect(document.root.placeholder, 'Enter a name');
    expect(document.root.bindingPath, 'player.name');
  });

  test('rejects invalid input identifiers and missing labels', () {
    for (final node in [
      '{"type":"input","id":"Bad ID","label":"Name"}',
      '{"type":"input","id":"player.name"}',
    ]) {
      expect(
        () => parser.parse(
          '{"schemaVersion":1,"screen":"x","root":$node}',
        ),
        throwsA(isA<JuiFormatException>()),
      );
    }
  });

  test('accepts a typed read-only text binding path', () {
    final document = parser.parse(
      '{"schemaVersion":1,"screen":"x","root":{"type":"text","binding":"player.displayName"}}',
    );
    expect(document.root.bindingPath, 'player.displayName');
    expect(document.root.text, isNull);
  });

  test('rejects malformed and ambiguous text bindings', () {
    for (final node in [
      '{"type":"text","binding":"player..name"}',
      '{"type":"text","text":"literal","binding":"player.name"}',
    ]) {
      expect(
        () => parser.parse(
          '{"schemaVersion":1,"screen":"x","root":$node}',
        ),
        throwsA(isA<JuiFormatException>()),
      );
    }
  });
}
