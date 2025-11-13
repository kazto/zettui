# Tools

This directory hosts lightweight automation helpers for the Zettui workspace.

## Formatting

Run `tools/fmt.sh [paths...]` to format sources with `zig fmt`. Without arguments, it processes `src`, `examples`, `docs`, and `build.zig`.

## Linting

`zig run tools/lint.zig` performs a read-only formatting dry-run and reports any files that need attention. It exits non-zero if the tree is not clean.
