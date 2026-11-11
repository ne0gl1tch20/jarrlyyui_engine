# jarrlyyui_engine

A versioned, declarative UI language and Flutter runtime for applications that need remotely updatable interfaces without moving application logic into a scripting VM.

**Status:** early foundation / API design in progress.

## Design boundary

- The engine owns UI documents, parsing, schema validation, rendering primitives, bundle metadata and update compatibility.
- The host application owns business logic, persistence, permissions, navigation policy, rewards, economy and all authoritative state.
- UI documents describe layout, styles, localization keys and allowlisted host actions. They cannot execute arbitrary Dart, Lua, JavaScript or native code.
- Updates are data bundles. A downloaded bundle is never trusted merely because its checksum matches.

## Repository layout

- `docs/LANGUAGE_SPEC.md` — initial JUI document format and validation rules.
- `docs/ARCHITECTURE.md` — engine/host boundary and runtime architecture.
- `docs/REMOTE_BUNDLES.md` — signed bundle and rollback design.
- `packages/jarrlyyui_engine/` — Dart + Flutter package.
- `examples/` — sample UI documents.

## Current implementation

The first milestone establishes a JSON-based `.jui` document format, a strict parser/validator and a Flutter renderer. The format is deliberately declarative. A future textual syntax can compile into the same document model without changing the host API.

## Development

Requires Flutter stable and Dart 3.

```sh
cd packages/jarrlyyui_engine
flutter pub get
flutter test
flutter analyze
```

## Compatibility policy

The document schema, engine API and bundle format have independent versions. Hosts declare supported schema and action capabilities. Unknown required features fail closed; optional unknown metadata may be ignored only where the specification explicitly permits it.

## Security

Remote bundle authenticity must be established with a trusted signature verification key or equivalent authenticated release channel. SHA-256 provides integrity after authenticity is established, not publisher authentication. Keep a last-known-good bundle and activate updates transactionally.
