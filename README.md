# jarrlyyui_engine

A versioned, declarative UI language and Flutter runtime for applications that need updatable interfaces without moving application logic into a scripting VM.

**Status:** early foundation. JUI v1 parsing, Flutter rendering, offline asset loading, read-only string bindings, host-dispatched text inputs and bounded repeat collections are implemented. It is not yet a complete replacement for GTN2's current UI.

## Design boundary

- The engine owns UI documents, parsing, schema validation, rendering primitives, bundle metadata and update compatibility.
- The host application owns gameplay, business logic, persistence, permissions, navigation policy, rewards, economy and all authoritative state.
- JUI documents are declarative data. They cannot execute arbitrary Dart, Lua, JavaScript or native code.
- The host validates every action against an explicit allowlist and validates its arguments before calling application services.
- Bundled .jui assets are the offline baseline. Remote updates must never be required to launch or render the app.

## Repository layout

- docs/LANGUAGE_SPEC.md — JUI JSON v1 format and validation rules.
- docs/ARCHITECTURE.md — engine/host boundary and runtime architecture.
- docs/GTN2_INTEGRATION.md — planned GTN2 screen migration and current v1 limitations.
- docs/REMOTE_BUNDLES.md — signed bundle and rollback design.
- packages/jarrlyyui_engine/ — Dart + Flutter package.
- examples/gtn2/ — GTN2-oriented screen-shell examples.

## Current implementation

JUI v1 provides a strict JSON-based .jui format, parser/validator, Flutter renderer and AssetBundle loader. Current nodes are intentionally small: column, row, padding, text, button, input, repeat and spacer.

The GTN2 examples establish screen IDs and host action contracts. They are integration scaffolding, not a claim that dynamic gameplay UI is already implemented. V1 supports read-only string bindings, text inputs dispatched to a typed host callback and bounded rendering of host-provided map collections. It does not yet provide typed numeric/boolean formatting, localization lookup, virtualized scrolling or visual themes. Those capabilities must be added deliberately with compatibility tests before replacing interactive GTN2 screens.

A future human-friendly syntax may compile into the same document model; it must not become a second runtime or move game logic out of Dart.

## Development

Requires Flutter stable and Dart 3.

```sh
cd packages/jarrlyyui_engine
flutter pub get
flutter test
flutter analyze
```

## Compatibility and security

The document schema, engine API and bundle format have independent versions. Hosts declare supported schema and action capabilities. Unknown required features fail closed.

Remote bundle authenticity must be established with a trusted signature verification key or equivalent authenticated release channel. SHA-256 provides integrity after authenticity is established, not publisher authentication. Keep a last-known-good bundle and activate updates transactionally.
