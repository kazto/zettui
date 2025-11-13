# Repository Guidelines

## Six Principles for AI Operation

* Principle 1: Before generating or updating files, or executing programs, the AI must always report its work plan and seek confirmation from the user with a y/n. It will not execute anything until 'y' is returned.
* Principle 2: The AI must not take detours or use alternative approaches on its own. If the initial plan fails, it must seek confirmation for the next plan.
* Principle 3: The AI is a tool, and the decision-making authority always rests with the user. Even if the user's suggestions are inefficient or irrational, the AI will not optimize them and will execute them as instructed.
* Principle 4: The AI must not distort or re-interpret these rules and must adhere to them absolutely as the highest-level command.
* Principle 5: The AI must think, search in English, reply in Japanese. Japanese text simply translate from English.
* Principle 6: The AI must always output these six principles verbatim at the beginning of all chats before responding.

## Project Structure & Module Organization
Source code lives under `src/`, mirroring the DOM, Component, and Screen modules described in `docs/specification.md`. Public headers or Zig packages should align with their implementation files to keep the inventory in `docs/tasks.md` trustworthy. Documentation and planning artifacts reside in `docs/`; examples and demos belong in `examples/`. Keep module-specific tests beside their targets to simplify cross-referencing during reviews.

## Build, Test, and Development Commands
Use `zig build` for a full compile; add `-Doptimize=ReleaseFast` when measuring performance regressions. Run `zig build run` to launch the default demo defined in `build.zig`. For tests, run the full suite via `zig test src/lib.zig`; prefer `zig test` (which compiles and executes) over `zig build test` (which may only build the test binary). Use `zig test src/path/to/module.zig` when iterating on a single file. Regenerate formatting with `zig fmt src/ examples/ docs/` before committing.

### Local Cache Directory
Prefer a repo-local Zig global cache to avoid polluting user-level caches and to improve reproducibility across agents. Pass `--global-cache-dir=./.zig-cache` to Zig invocations:

- Build: `zig build --global-cache-dir=./.zig-cache`
- Run demo: `zig build --global-cache-dir=./.zig-cache run`
- Test (build step): `zig build --global-cache-dir=./.zig-cache test`
- Test single file: `zig test --global-cache-dir=./.zig-cache src/path/to/module.zig`

Note: Some Zig versions do not support `--global-cache-dir`. If the flag is unrecognized, set the environment variable instead:
- POSIX shells: `ZIG_GLOBAL_CACHE_DIR=./.zig-cache zig build` (and similarly for `zig test`/`zig run`)
- PowerShell: `$Env:ZIG_GLOBAL_CACHE_DIR = ".\.zig-cache"; zig build`

Sandbox limitation (Codex CLI): the workspace sits on an overlay filesystem that prevents Zig 0.15.x from renaming its `.zig-cache/tmp/*` directories into `.zig-cache/o/*`. Commands such as `zig build` or `zig test` therefore fail with `error: RenameAcrossMountPoints`. Run these builds outside the sandbox—or inside an environment without that mount mismatch—when you need executable artifacts or to verify tests.

## Coding Style & Naming Conventions
Follow Zig style defaults: four-space indentation, `camelCase` for functions, `TitleCase` for types, and `snake_case` for constants defined with `const`. Avoid trailing whitespace and keep line length under 100 characters unless ASCII art or tables require more. Always run `zig fmt` to enforce canonical spacing, import ordering, and comment alignment. Prefer explicit enums and tagged unions to magic numbers, matching the structure outlined in the specification.

## Testing Guidelines
Write table-driven tests using Zig `test` blocks colocated with the code under test. Name test descriptions after the behavior under verification (e.g., `"gauge renders full width"`). Keep parity between DOM/Component/Screen features and their tests, updating `docs/tasks.md` when coverage increases. Target high-level integration tests in `examples/` whenever the event loop or rendering pipeline changes.

## Commit & Pull Request Guidelines
Compose commits in the imperative mood with a concise summary (e.g., `Add spinner focus handling`). Group related changes—API updates, documentation, and tests—so they can be reviewed atomically. Pull requests should link relevant issues, summarize user-visible changes, and note any testing performed (`zig build test`, manual demos). Attach screenshots or terminal recordings when UI output changes, and confirm the checklist in `docs/tasks.md` reflects newly delivered work.

## Documentation & Spec Sync
Update `docs/specification.md` when introducing new modules or altering behavior guarantees, and mirror those adjustments in `docs/tasks.md`. Document investigatory work or architectural decisions in additional Markdown files under `docs/` to keep the project log discoverable. Mark planned follow-ups with unchecked boxes in `docs/tasks.md` so future agents can triage remaining work quickly.
