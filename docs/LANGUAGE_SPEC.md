# JUI document format: JSON v1

**Status:** initial implementation contract. This format is intentionally JSON-based so it can be parsed with Dart's standard JSON decoder and validated deterministically. A future human-friendly syntax may compile to this same document model without creating a second runtime.

## Document envelope

Every document has exactly these fields:

- schemaVersion: integer, currently 1.
- screen: non-empty screen identifier, at most 80 characters.
- root: one component node.

Example:

```json
{
  "schemaVersion": 1,
  "screen": "home",
  "root": {
    "type": "column",
    "children": [
      {"type": "text", "text": "Welcome"},
      {
        "type": "button",
        "text": "Play",
        "action": {
          "id": "game.start",
          "arguments": {}
        }
      }
    ]
  }
}
```

## Supported v1 nodes

| Type | Fields | Meaning |
| --- | --- | --- |
| column | type, children | Vertical layout |
| row | type, children | Horizontal layout |
| padding | type, one children entry | 16 logical-pixel inset |
| text | type, exactly one of text or binding, optional fontSize | Static label or read-only string binding |
| button | type, text, action | Host-dispatched action |
| spacer | type | Fixed vertical spacing |

Unknown fields and node types are rejected. Literal text is limited to 4,000 characters. A text node may instead declare a `binding` path such as `player.displayName`; paths use dot-separated identifier segments only. The Dart host supplies the state map to the renderer. JUI can read only string values through text nodes. Missing paths and non-string values render as an empty string. Binding values are never evaluated as expressions and cannot invoke host methods. Font size is limited to 8–72. The parser defaults to a 256 KiB document limit, 32 levels of nesting and 2,000 nodes. A container may have at most 200 children.

## Actions

An action has an identifier matching ^[a-z][a-z0-9_.-]{0,79}$ and an optional JSON object of arguments. The renderer only forwards the declared identifier and arguments to the host callback. It does not resolve or execute actions itself.

The host must enforce its own action allowlist, validate argument types and authorize the requested operation. Never trust an action merely because it appears in a valid JUI document. The parser also applies its configured depth and node limits recursively to action arguments and freezes nested maps and lists before exposing them to the renderer. A JUI button is a request to the host, not permission to perform the operation.

## GTN2 examples

The examples/gtn2/ directory contains static screen shells for Home, More, Settings, Save Slots, Traits, Talents, Mutators, Relics, Home Base and Results. They establish candidate screen IDs and action IDs for host integration.

These examples do not fabricate live game data. The text explicitly marks where the host must provide real state. Until typed bindings and input controls exist, they are navigation/action prototypes rather than complete replacements for the corresponding GTN2 screens.

## Deliberately unsupported in v1

JUI v1 has no expressions, loops, imports, reflection, script evaluation, network access, filesystem access, dynamic component lookup, arbitrary method calls, editable input controls, localization lookup, scrolling lists or theme tokens. Read-only string text bindings are supported; typed numeric/boolean formatting and collection bindings are not. These are not silently emulated. Future capabilities require an explicit schema/API revision, tests and backward-compatibility rules.

Gameplay rules, save formats, economy, rewards, RNG, validation and progression remain Dart responsibilities in every version.
