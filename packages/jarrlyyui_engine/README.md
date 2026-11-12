# jarrlyyui_engine

A Flutter package for parsing and rendering declarative JUI v1 documents.

## Host APK setup

Copy the selected baseline UI files into the host application's assets:

```text
assets/jui/
  screens/
    home.jui
    more.jui
    settings.jui
```

Declare the directory in the host app's pubspec.yaml:

```yaml
flutter:
  assets:
    - assets/jui/
```

This packages the scripts into the APK. The app can render them offline and on first launch. Keep these bundled files as the immutable fallback even after remote bundle support is added.

## Load and render a screen

```dart
import 'package:jarrlyyui_engine/jarrlyyui_engine.dart';

final loader = JuiAssetLoader(basePath: 'assets/jui');
final document = await loader.loadScreen('home');

JuiRenderer(
  document: document,
  state: const {
    'player': {'displayName': 'Player One'},
  },
  onAction: (actionId, arguments) async {
    // Check actionId against the host app's allowlist.
    // Validate argument names, types and values.
    // Call existing Dart application/gameplay services.
  },
);
```

The loader uses Flutter's AssetBundle and performs no network requests. The renderer does not execute actions; it forwards declared action IDs to the host callback. The host owns authorization and all application state.

## GTN2 example screens

See examples/gtn2/ and docs/GTN2_INTEGRATION.md. These are screen-shell examples using only the current v1 feature set. They are not yet full replacements for GTN2's dynamic or interactive screens.

## Current v1 nodes

column, row, padding, text, button, input, repeat and spacer.

Read-only string text bindings are supported through dot-separated paths such as `player.displayName`, resolved from the host-provided `state` map. Missing or non-string values render as empty text. Text inputs dispatch edits through an optional `JuiInputHandler`; without a host callback, inputs are disabled. `repeat` renders at most 100 host-provided map entries and exposes string fields as `item.fieldName`. Numeric/boolean formatting, localization lookup, virtualized scrolling and theme tokens are not implemented yet. Do not hardcode changing game values into JUI files to work around those limitations.

Remote bundle updates are not implemented in this package version.
