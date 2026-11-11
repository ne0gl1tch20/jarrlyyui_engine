# jarrlyyui_engine

A Flutter package for parsing and rendering declarative JUI v1 documents.

## Host APK setup

Put the baseline UI files in the host application's assets:

```text
assets/jui/
  screens/
    home.jui
    settings.jui
```

Declare the directory in the host app's `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/jui/
```

This packages the scripts into the APK. The app can render them offline and on first launch.

## Load and render a screen

```dart
import 'package:flutter/material.dart';
import 'package:jarrlyyui_engine/jarrlyyui_engine.dart';

final loader = JuiAssetLoader(basePath: 'assets/jui');
final document = await loader.loadScreen('home');

JuiRenderer(
  document: document,
  onAction: (actionId, arguments) async {
    // Check actionId against the host app's allowlist.
    // Validate arguments and invoke existing Dart application logic.
  },
);
```

The loader uses Flutter's `AssetBundle` and performs no network requests. The renderer does not execute actions; it forwards declared action IDs to the host callback. The host owns authorization and all application state.

## Current v1 nodes

`column`, `row`, `padding`, `text`, `button`, `spacer`.

See [the language specification](../../docs/LANGUAGE_SPEC.md). Remote bundle updates are not implemented in this package version.
