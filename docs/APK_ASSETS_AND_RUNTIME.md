# APK assets and runtime loading

The installed APK must contain the complete baseline JUI interface. A network connection is never required to launch the app or render its baseline screens.

Recommended host-app layout:

```text
assets/jui/
  manifest.json
  screens/home.jui
  screens/settings.jui
```

Declare it in the host app's Flutter `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/jui/
```

The host loads documents through Flutter's `AssetBundle` (normally `rootBundle`) and passes validated documents to `JuiRenderer`. This package's parser accepts JSON documents with the `.jui` extension; the extension does not imply executable source.

Remote bundles are an optional override layer. Keep the APK copy untouched as the recovery baseline. Never overwrite bundled assets on disk. Validate remote content completely before switching the active bundle pointer, and preserve a last-known-good copy for rollback.

The renderer emits Flutter widgets. Buttons dispatch a declared action ID and JSON-compatible arguments to the host callback. The host must check the action ID against its own allowlist and validate every argument before performing work.
