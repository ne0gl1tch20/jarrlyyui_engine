import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jarrlyyui_engine/jarrlyyui_engine.dart';

void main() {
  test('all GTN2 example screens parse and match their filenames', () {
    final examples = Directory('../../examples/gtn2');
    expect(examples.existsSync(), isTrue);

    final files = examples
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.jui'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    expect(files, hasLength(10));
    const parser = JuiParser();

    for (final file in files) {
      final filename = file.uri.pathSegments.last;
      final expectedScreenId = filename.substring(0, filename.length - 4);
      final document = parser.parse(file.readAsStringSync());

      expect(document.screenId, expectedScreenId, reason: filename);
    }
  });
}
