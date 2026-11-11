# JUI document format: JSON v1

**Status:** initial implementation contract. This format is intentionally JSON-based so it can be parsed with Dart's standard JSON decoder and validated deterministically. A future human-friendly syntax may compile to this same document model.

## Document envelope

Every document has exactly these fields:

- `schemaVersion`: integer, currently `1`.
- `screen`: non-empty screen identifier, at most 80 characters.
- `root`: one component node.

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
          "id": "navigation.open",
          "arguments": {"route": "game"}
        }
      }
    ]
  }
}
```

## Supported v1 nodes

| Type | Fields | Meaning |
| --- | --- | --- |
| `column` | `type`, `children` | Vertical layout |
| `row` | `type`, `children` | Horizontal layout |
| `padding` | `type`, one `children` entry | 16 logical-pixel inset |
| `text` | `type`, `text`, optional `fontSize` | Text label |
| `button` | `type`, `text`, `action` | Host-dispatched action |
| `spacer` | `type` | Fixed vertical spacing |

Unknown fields and node types are rejected. Text is limited to 4,000 characters. Font size is limited to 8–72. The parser defaults to a 256 KiB document limit, 32 levels of nesting and 2,000 nodes. A container may have at most 200 children.

## Actions

An action has an identifier matching `^[a-z][a-z0-9_.-]{0,79}$` and an optional JSON object of arguments. The renderer only forwards the declared identifier and arguments to the host callback. It does not resolve or execute actions itself.

The host must enforce its own action allowlist, validate argument types and authorize the requested operation. Never trust an action merely because it appears in a valid JUI document.

## Deliberately unsupported

JUI v1 has no expressions, loops, imports, reflection, script evaluation, network access, filesystem access, dynamic component lookup or arbitrary method calls. Data binding and localization will be introduced through typed host-provided values in a later schema revision.
