import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'document.dart';
import 'parser.dart';

/// Loads the APK-bundled JUI baseline through Flutter's asset system.
///
/// The host app should declare its JUI directory in pubspec.yaml. This loader
/// performs no network requests and cannot modify the packaged assets.
class JuiAssetLoader {
  JuiAssetLoader({
    required this.basePath,
    AssetBundle? bundle,
    JuiParser parser = const JuiParser(),
  })  : _bundle = bundle ?? rootBundle,
        _parser = parser;

  final String basePath;
  final AssetBundle _bundle;
  final JuiParser _parser;

  Future<JuiDocument> loadScreen(String screenId) async {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(screenId)) {
      throw const JuiFormatException('Invalid screen asset identifier');
    }
    final normalizedBase = basePath.endsWith('/')
        ? basePath.substring(0, basePath.length - 1)
        : basePath;
    final source = await _bundle.loadString(
      '$normalizedBase/screens/$screenId.jui',
    );
    final document = _parser.parse(source);
    if (document.screenId != screenId) {
      throw JuiFormatException(
        'Asset screen ID does not match requested screen "$screenId"',
      );
    }
    return document;
  }
}

/// Utility for tests and host integrations that already hold UTF-8 bytes.
Uint8List juiUtf8Bytes(String source) => Uint8List.fromList(utf8.encode(source));
