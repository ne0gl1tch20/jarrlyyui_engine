# Remote bundle update protocol

Remote UI bundles are optional overrides. The APK-bundled UI is always the offline baseline and remains recoverable.

## Required checks

A remote release manifest must declare bundle schema version, engine API compatibility, JUI schema version, host action API version, bundle version, app compatibility and a hash/size for each file.

The updater must:
1. Fetch a manifest only from a host-configured trusted endpoint.
2. Verify a publisher signature against a public key pinned or otherwise trusted by the application.
3. Enforce bundle version and all compatibility ranges.
4. Reject path traversal, absolute paths, duplicate paths, unknown file types, oversized files and excessive file counts.
5. Verify every file's SHA-256 and byte length.
6. Parse and validate every JUI document before activation.
7. Stage the complete bundle, then atomically switch the active bundle reference.
8. Preserve the last-known-good bundle and APK baseline for rollback.

SHA-256 alone is not publisher authentication. Never treat an unsigned bundle as trusted merely because its hashes match.

## Failure behavior

A network failure, invalid signature, invalid hash, parse failure, unsupported schema, incompatible host API or interrupted write must leave the active bundle unchanged. The app must continue using the current valid bundle or APK assets.

## Current implementation status

The package currently implements local JSON JUI parsing and rendering only. Remote fetching, signature verification, persistent bundle slots and atomic activation are not implemented yet and must not be presented as available functionality.
