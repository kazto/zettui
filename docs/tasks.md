# Zettui Task Breakdown

Tasks derived from `docs/specification.md` to track coverage and implementation of documented features.

## Overview
- [x] Mirror `src/` package structure across `dom`, `component`, and `screen`, ensuring public Zig namespaces (e.g., `zet.dom`) re-export the intended API surface.
- [x] Keep `build.zig` targets current for library, examples, docs, tests, fuzzers, and benchmarks; document standard `zig build` invocations.
- [ ] Curate `examples/` alongside documentation in `docs/` so demos track the latest module capabilities.
- [ ] Enforce formatting via `zig fmt` and maintain helper scripts in `tools/` for linting or automation.
- [ ] Ensure `zig build test`, `zig build fuzz`, and `zig build bench` cover all modules and report coverage gaps.

## DOM Module
### Core
- [x] Implement `Node` tagged union APIs for layout (`computeRequirement`, `setBox`), validation (`check`), rendering (`render`), and selection (`select`, `getSelectedContent`).
- [x] Maintain `Requirement` struct fields for minimum sizes, flex factors, and focus metadata.
- [ ] Keep `Selection` records wired into focus, cursor, and accessibility flows.

### Layout & Widgets
- [ ] Provide element builders in `elements.zig` (`text`, `paragraph*`, `window`, `gauge*`, `spinner`, `graph`, `canvas`, border and separator helpers`).
- [ ] Support container combinators (`hbox`, `vbox`, `dbox`, `flexbox`) plus flow utilities (`flex*`, `filler`, `size`, `frame`, `focus`, cursor modifiers) returning fully configured `Node` values.

### Styling
- [ ] Maintain decorators for typography, color/gradient layers, selection styling, hyperlinks, centering helpers, and `automerge`.
- [ ] Expose viewport tuning via `FocusPosition` enums and scroll indicator helpers.

### Advanced
- [ ] Keep `Canvas` drawing APIs (pixel/point/block modes) rendering lines, circles, ellipses, text, and bitmap data.
- [ ] Preserve `Table` features for cell selection, decoration, borders, and alternating styles.
- [ ] Align `FlexboxConfig`, `Direction`, `Axis`, and `Constraint` enums with expected layout overrides.

## Component Module
### Component Base & Composition
- [x] Uphold `ComponentBase` struct hooks for render, event handling, animation, child management, and focus navigation.
- [ ] Maintain `Component` factory helpers and `ComponentDecorator` wrappers for composition patterns.

### Widgets
- [ ] Deliver interactive widgets (buttons, checkboxes, text inputs with placeholder/password/multiline, sliders, radio boxes, dropdowns, toggles, menus including animated, resizable splits, modals, collapsibles, hover wrappers, windows).
- [ ] Support renderer bridges and conditional presentation via `maybe` wrappers.

### Configuration
- [ ] Keep option structs (`ButtonOptions`, `MenuOptions`, `InputOptions`, `SliderOptions`, `WindowOptions`, etc.) current with animation settings (`UnderlineOption`, `AnimatedColorOption`) and callback hooks.

### Events & Looping
- [ ] Ensure `events.zig` enumerates keyboard characters, modifiers, function keys, mouse events, and cursor state.
- [ ] Maintain `Mouse` structs for coordinates, buttons, and modifiers.
- [ ] Keep `animation/animator.zig` easing utilities synchronized with widget animations.
- [ ] Guarantee `task` and `screen_interactive.zig` manage event loops, async posts, animation frames, selection APIs, piped input, and terminal control.
- [ ] Preserve `Loop` helpers for non-blocking iterations and `CapturedMouse` semantics for exclusive pointer capture.

## Screen Module
### Rendering Surface
- [x] Maintain `screen/image.zig` and `screen/screen.zig` pixel grid rendering, printing, clearing, cursor management, hyperlink registration, and shader hooks.
- [x] Keep `Box` geometric utilities consistent with layout logic.
- [x] Ensure `Pixel` structs store style flags, hyperlink identifiers, and UTF-8 graphemes accurately.

### Colors
- [x] Support `color.zig` palette (1/16/256) and true-color creation (RGB/HSV/RGBA/HSVA) with blending/interpolation helpers.
- [x] Expose `TerminalInfo` metadata for palette support, dimensions, and fallbacks.

### Strings & Utilities
- [x] Preserve UTF-8 helpers for conversion, width computation, glyph splitting, and cell-to-glyph mapping between `[]const u8` buffers.
- [ ] Maintain legacy wide-string APIs under `dom/screen/legacy.zig` gated by build options.
- [ ] Ensure utility helpers (`AutoReset`, `Ref`/`ConstRef`, `ConstStringRef`, `ConstStringListRef`, `Receiver`/`Sender`, Windows macro guards) remain available and documented.
