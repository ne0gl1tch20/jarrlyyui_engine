import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarrlyyui_engine/jarrlyyui_engine.dart';

class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(utf8.encode(assets[key]!));
    return ByteData.view(bytes.buffer);
  }
}

void main() {
  const source =
      '{"schemaVersion":1,"screen":"home","root":{"type":"text","text":"Offline"}}';

  test(
    'loads and parses a screen from the supplied Flutter asset bundle',
    () async {
      final loader = JuiAssetLoader(
        basePath: 'assets/jui',
        bundle: _MemoryAssetBundle({'assets/jui/screens/home.jui': source}),
      );

      final document = await loader.loadScreen('home');

      expect(document.screenId, 'home');
      expect(document.root.text, 'Offline');
    },
  );

  test(
    'rejects screen identifiers that could escape the asset directory',
    () async {
      final loader = JuiAssetLoader(
        basePath: 'assets/jui',
        bundle: _MemoryAssetBundle(const {}),
      );

      await expectLater(
        loader.loadScreen('../secrets'),
        throwsA(isA<JuiFormatException>()),
      );
    },
  );

  test(
    'rejects a document whose embedded screen ID differs from its asset name',
    () async {
      final loader = JuiAssetLoader(
        basePath: 'assets/jui',
        bundle: _MemoryAssetBundle({
          'assets/jui/screens/home.jui':
              source.replaceFirst('"home"', '"settings"'),
        }),
      );

      await expectLater(
        loader.loadScreen('home'),
        throwsA(isA<JuiFormatException>()),
      );
    },
  );
}
