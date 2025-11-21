# Zettui Task Coverage

This tracker consolidates specification-driven milestones and FTXUI parity checks—consult this file before marking an item complete or adding a new demo.

## Specification Coverage

### Overview
- [x] Mirror `src/` package namespaces across `dom`, `component`, and `screen`, ensuring the `zet.*` exports listed in `docs/specification.md` stay aligned.
- [x] Keep `build.zig` targets current for the library, examples (new `run:*` suite documented in `docs/examples/ftxui-mapping.md`), docs, tests, fuzzers, and benchmarks.
- [ ] Rebuild `examples/` following the plan in `docs/examples/README.md` so each new `run:*` target maps to the refreshed FTXUI parity lists (DOM + Component + Screen + Integration have baseline coverage; fill remaining FTXUI gaps).
- [ ] Enforce formatting via `zig fmt src/ examples/ docs/` and keep helper scripts under `tools/` for linting or automation.
- [ ] Ensure `zig build --global-cache-dir=./.zig-cache test` covers all modules and document known gaps.

### DOM Module

#### Core
- [x] Implement the `Node` tagged union APIs for layout (`computeRequirement`, `setBox`), validation (`check`), rendering (`render`), and selection (`select`, `getSelectedContent`). Refer to the walkthrough in `docs/specification.md`; future showcase lives under `examples/dom/layouts.zig`.
- [x] Maintain the `Requirement` struct and focus metadata so upcoming demos such as `run:dom-layouts` remain correct.
- [x] Keep `Selection` structures wired into focus, cursor, and accessibility flows (to be exercised again via `examples/component/navigation_and_scroll.zig`).

#### Layout & Widgets
- [x] Provide element builders in `dom/elements.zig` (`text`, `paragraph*`, `window`, `gauge*`, `spinner`, `graph`, `canvas`, border/separator helpers) with parity verified in `docs/examples/border_styles.md` and scheduled to surface again through `examples/dom/borders.zig` / `examples/dom/canvas_and_gauges.zig`.
  - [x] `text`
  - [x] `paragraph`
  - [x] `window`
  - [x] `gauge`
  - [x] `spinner`
  - [x] `separator`
  - [x] `graph`
  - [x] `canvas`
  - [x] border helpers
- [ ] Support container combinators (`hbox`, `vbox`, `dbox`, `flexbox`) plus flow utilities (`flex*`, `filler`, `size`, `frame`, `focus`, cursor modifiers) returning fully configured `Node` values once `examples/dom/layouts.zig` (`run:dom-layouts`) is wired up.
  - [x] `hbox`
  - [x] `vbox`
  - [x] `dbox`
  - [x] `flexbox`
  - Flow utilities:
    - [x] `frame`
    - [x] `flex*`
    - [x] `filler`
    - [x] `size`
    - [x] `focus`
    - [x] cursor modifiers

#### Styling
- [x] Maintain decorators for typography, color/gradient layers, selection styling, hyperlinks, centering helpers, and `automerge`. Reference `docs/examples/visual_galleries.md`; the replacement demo will live under `examples/dom/colors_and_styles.zig`.
- [ ] Expose viewport tuning via `FocusPosition` enums and scroll indicator helpers; exercises will return via `examples/component/navigation_and_scroll.zig`.

#### Advanced
- [ ] Keep `Canvas` drawing APIs rendering lines, circles, ellipses, text, and bitmap data (targets: `examples/dom/canvas_and_gauges.zig`, `examples/integration/gallery.zig`).
- [ ] Preserve `Table` features for cell selection, decoration, borders, and alternating styles (`examples/dom/layouts.zig` will contain the table showcase).
- [ ] Align `FlexboxConfig`, `Direction`, `Axis`, and `Constraint` enums with layout overrides highlighted in `docs/specification.md`.

### Component Module

#### Component Base & Composition
- [x] Uphold `ComponentBase` hooks for rendering, event handling, animation, child management, and focus navigation (to be exercised via `examples/component/inputs_and_sliders.zig`).
- [ ] Maintain `Component` factory helpers and `ComponentDecorator` wrappers used by `widgets.visualGallery` and `widgets.homescreen` (mapped to `examples/component/visual_gallery.zig` / `examples/integration/homescreen.zig`).

#### Widgets
- [ ] Deliver interactive widgets (buttons, checkboxes, text inputs with placeholder/password/multiline, sliders, radio boxes, dropdowns, toggles, menus including animated, resizable splits, modals, collapsibles, hover wrappers, windows) across the new suite (`examples/component/buttons.zig`, `examples/component/menus_and_dropdowns.zig`, `examples/component/layouts_and_tabs.zig`, etc.).
  - [x] Button
  - [x] Checkbox
  - [x] Toggle
  - [x] Text input (single-line)
  - [x] Text inputs (placeholder/password/multiline)
  - [x] Sliders
  - [x] Radio boxes
  - [x] Dropdowns
  - [x] Menus (animated)
  - [x] Resizable splits
  - [x] Modals
  - [x] Collapsibles
  - [x] Hover wrappers
  - [x] Windows
- [ ] Support renderer bridges and conditional presentation via `maybe` wrappers (`examples/component/composition.zig` and `docs/examples/visual_galleries.md` describe the requirements).

#### Configuration
- [ ] Keep option structs (`ButtonOptions`, `MenuOptions`, `InputOptions`, `SliderOptions`, `WindowOptions`, etc.) synchronized with animation settings (e.g., `UnderlineOption`, `AnimatedColorOption`) and callback hooks as documented in the upcoming `examples/component/inputs_and_sliders.zig` showcase.
  - [x] `ButtonOptions`
  - [x] `WindowOptions`
  - [x] `CheckboxOptions`
  - [x] `ToggleOptions`
  - [x] `MenuOptions`
  - [x] `InputOptions`
  - [x] `SliderOptions`
  - [x] `RadioOptions`

#### Events & Looping
- [ ] Ensure `events.zig` enumerates keyboard characters, modifiers, function keys, mouse events, and cursor state with parity to the planned `examples/screen/input_logger.zig`.
  - [x] Keyboard characters and modifiers
  - [x] Function keys (F1-F12)
  - [x] Arrow keys (up, down, left, right)
  - [x] Mouse events and cursor state
- [x] Maintain `Mouse` structs for coordinates, buttons, and modifiers.
- [ ] Keep `animation/animator.zig` easing utilities synchronized with widget animations (validated once `examples/component/visual_gallery.zig` returns).
- [ ] Guarantee `task` and `screen_interactive.zig` manage event loops, async posts, animation frames, selection APIs, piped input, and terminal control for the `examples/screen/*` demos described in `docs/examples/README.md`.
- [ ] Preserve `Loop` helpers for non-blocking iterations and `CapturedMouse` semantics mirrored by `examples/component/navigation_and_scroll.zig`.

### Screen Module

#### Rendering Surface
- [x] Maintain `screen/image.zig` and `screen/screen.zig` pixel-grid rendering, printing, clearing, cursor management, hyperlink registration, and shader hooks (the rebuilt `examples/integration/gallery.zig` will exercise these paths).
- [x] Keep `Box` geometric utilities consistent with layout logic validated by `examples/dom/layouts.zig`.
- [x] Ensure `Pixel` structs store style flags, hyperlinks, and UTF-8 graphemes (reference `docs/specification.md`).

#### Colors
- [x] Support `color.zig` palette/true-color helpers (see `docs/examples/visual_galleries.md` and the planned `examples/dom/colors_and_styles.zig`).
- [x] Expose `TerminalInfo` metadata for palette support, dimensions, and fallbacks.

#### Strings & Utilities
- [x] Preserve UTF-8 helpers for conversion, width computation, glyph splitting, and cell-to-glyph mapping between `[]const u8` buffers.
- [ ] Maintain legacy wide-string APIs under `dom/screen/legacy.zig` gated by build options.
- [ ] Ensure utility helpers (`AutoReset`, `Ref`/`ConstRef`, `ConstStringRef`, `ConstStringListRef`, `Receiver`/`Sender`, Windows macro guards) remain available and documented.

## FTXUI Parity Coverage

The checklist formerly in `docs/tasks-ver2.md` now resides here. Cross-reference `docs/examples/ftxui-mapping.md` for the command cheatsheet.

### DOM
- [ ] Style decorations (bold/italic/underline/double underline/strikethrough/dim/blink/inverted/hyperlink/color/gradient) — to return via `examples/dom/colors_and_styles.zig`.
- [ ] Palette / true-color controls — same as above; see `docs/examples/ftxui-mapping.md#dom`.
- [ ] Line-styled `border` / `border_colored` variants — `examples/dom/borders.zig` will cover this (`docs/examples/border_styles.md` already describes the API).
- [ ] Layout suites (gridbox/table/hflow/vflow/html_like/tree) — scheduled for `examples/dom/layouts.zig`.
- [ ] `linear_gradient` DOM node showcase — part of `examples/dom/canvas_and_gauges.zig`.
- [ ] `gauge` direction and variants (horizontal/vertical) — `examples/dom/canvas_and_gauges.zig`.
- [ ] `canvas` animation / drawing utilities — `examples/dom/canvas_and_gauges.zig`.
- [ ] `size` / `separator` / `border` style variations — captured in `examples/dom/borders.zig`.
- [ ] DOM color & style galleries covering FTXUI APIs — aggregated by `examples/dom/colors_and_styles.zig`.

### Components
- [x] Button styling / animation / frames — `examples/component/buttons.zig`.
- [x] Tabs (horizontal / vertical) — `examples/component/layouts_and_tabs.zig`.
- [x] Scrollbar / focus / cursor demos — `examples/component/navigation_and_scroll.zig`.
- [x] Textarea + multiline input upgrades — `examples/component/inputs_and_sliders.zig`.
- [x] Input style/password/placeholder variants — `examples/component/inputs_and_sliders.zig`.
- [x] Menu multi-select / animation / underline gallery — `examples/component/menus_and_dropdowns.zig`.
- [x] Toggle / checkbox / radiobox frame variants — `examples/component/selectors.zig`.
- [x] `dropdown_custom`, `menu_custom`, renderer/maybe decorators — `examples/component/composition.zig`.
- [x] Resizable split clamp / window composition / homescreen composite widgets — `examples/component/layouts_and_tabs.zig` + `examples/integration/homescreen.zig`.
- [x] Canvas / linear gradient / hover / focus galleries — `examples/component/visual_gallery.zig` + `examples/integration/gallery.zig`.

### Screen / Rendering
- [x] `Pixel` with `fg/bg/style` exposed to DOM/Component layers — exercised in `examples/integration/gallery.zig`.
- [x] Gradient & color interpolation helpers — tracked via `docs/examples/visual_galleries.md` and implemented in `examples/dom/colors_and_styles.zig`.
- [x] `ScreenInteractive` / `CapturedMouse` equivalents — `examples/screen/custom_loop.zig` and `examples/component/navigation_and_scroll.zig`.
- [x] `nested_screen` / `restored_io` / `custom_loop` scaffolding — `examples/screen/nested_screen.zig`, `examples/screen/with_restored_io.zig`, `examples/screen/custom_loop.zig`.
- [x] Animation loop APIs backing `canvas_animated` — `examples/component/visual_gallery.zig`.

### その他
- [x] DOM/Component/Screen examples documented against FTXUI — `docs/examples/README.md` lists the current run targets.
- [x] `references/FTXUI/examples` parity pointers mirrored by `docs/examples/ftxui-mapping.md`.
- [x] Event-driven input handling demos (`examples/screen/input_logger.zig`, `examples/screen/custom_loop.zig`) — baseline coverage restored.

> Update both specification and parity sections whenever a new feature, example, or doc is added.

#### Pending Work Items
- [x] DOM: Implement outstanding parity items marked `Pending` in `docs/examples/ftxui-mapping.md` (dbox/table/vertical gauge/256-color/HSV/hyperlink samples now covered).
- [ ] Component: Finish remaining samples (`selection.cpp` in selectors) and update `examples/component/*` plus any missing API hooks.
- [ ] Screen: Expand `examples/screen/*` to include richer `ScreenInteractive` behavior, capturing `custom_loop`, `nested_screen`, and restored IO parity, then mark the entries as Done.
- [ ] Integration: Extend `examples/integration/gallery.zig` / `homescreen.zig` with package-manager style trees, resizable clamp indicators, and other FTXUI hybrid demos still marked pending.
