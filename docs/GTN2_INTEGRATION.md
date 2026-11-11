# GTN2 JUI integration plan

## Objective

Move GTN2 presentation into versioned JUI documents gradually while keeping Flutter/Dart as the authority for game behavior. The engine is a UI-definition runtime, not a replacement for the game runtime.

## Screen inventory

The examples in examples/gtn2/ establish the initial screen IDs and action names:

| JUI screen | Intended GTN2 area | Current example status |
| --- | --- | --- |
| home | Main menu | Static layout and navigation actions |
| more | Secondary navigation | Static navigation shell |
| settings | Settings entry points | Section actions only; actual controls stay host-owned |
| save_slots | Save selection | Slot selection requests; real slot data must come from Dart |
| traits | Trait catalog | Opens host-owned trait catalog |
| talents | Talent tree | Opens host-owned talent tree |
| mutators | Mutator catalog | Opens host-owned mutator list |
| relics | Relic inventory | Opens host-owned relic inventory |
| home_base | Home Base | Opens host-owned Home Base screen/services |
| results | Round results | Requests replay or home navigation; result values come from Dart |

These are examples of the proposed screen contract, not a claim that every screen is production-ready.

## Current limitations that block full screen migration

JUI v1 currently supports only column, row, padding, text, button and spacer. It does not yet support:

- Typed live-state bindings for balances, progress, selected items, scores or round state.
- Editable text/number input and validated input events for the number-guessing screen.
- Repeating collections for save slots, traits, talents, mutators and relic inventories.
- Localization key lookup and locale fallback.
- Scroll containers, responsive layout constraints, visual themes or reusable components.

Do not work around these gaps by embedding changing values in scripts, adding game rules to JUI, or generating large fixed button lists. Add the missing capabilities as explicit, typed engine features with parser, renderer and compatibility tests.

## Migration sequence

1. Keep the current GTN2 Flutter UI working as the fallback. Add the engine as a pinned dependency and package baseline JUI assets in the APK only after the package API is stable.
2. Add host-side screen routing and a strict action registry. Each action ID must map to one host-owned function with typed argument validation. Unknown actions fail closed.
3. Introduce typed read-only state bindings first. Dart supplies a snapshot/view model; JUI only selects and formats declared values. No JUI mutation of authoritative state.
4. Add typed input controls and host events. The number guess is validated by existing Dart gameplay logic; JUI only collects and forwards the candidate value.
5. Add safe repeated collections, scrolling and localization, then port low-risk screens before gameplay-critical screens.
6. Port Home/More/Settings and verify navigation. Next port Save Slots and secondary systems. Port the active game screen only after input, state and validation paths are tested end to end.
7. Keep the native Flutter screen available as a rollback path until the JUI screen passes parity tests on Android and Windows.
8. Package all baseline .jui files as Flutter assets so the APK can render without a network connection. Remote updates, when implemented, are a separate signed layer with atomic activation and last-known-good rollback.

## Non-negotiable ownership

| Concern | Owner |
| --- | --- |
| Random number generation and target | Dart gameplay service |
| Guess validation and round transitions | Dart gameplay service |
| Currency, rewards, progression and purchases | Dart domain services |
| Save serialization, migration and integrity | Dart save system |
| Permissions and action authorization | GTN2 host |
| Layout tree, text, spacing and declared action requests | JUI |
| Rendering validated JUI nodes | jarrlyyui_engine |

## Acceptance gates for each migrated screen

- Existing GTN2 behavior and visual intent are recorded before replacing the screen.
- All dynamic values are supplied by typed host bindings, never hardcoded as live state.
- Every action ID is registered and its arguments are validated by the host.
- Parser, renderer and host integration tests cover success and invalid inputs.
- The screen works from APK-bundled assets in airplane mode and on first launch.
- Android and Windows parity is checked before the Flutter fallback is removed.
