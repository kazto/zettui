# Zettui Task Coverage

This tracker consolidates specification-driven milestones and FTXUI parity checks—consult this file before marking an item complete or adding a new demo.

## Specification Coverage

### Overview
- [x] Mirror `src/` package namespaces across `dom`, `component`, and `screen`, ensuring the `zet.*` exports listed in `docs/specification.md` stay aligned.
- [x] Keep `build.zig` targets current for the library, examples (`zig build run:*` as documented in `docs/examples/README.md`), docs, tests, fuzzers, and benchmarks.
- [x] Curate `examples/` alongside the docs in `docs/examples/` so demos such as `examples/style_gallery.zig` and `examples/ftxui_gallery.zig` remain representative.
- [ ] Enforce formatting via `zig fmt src/ examples/ docs/` and keep helper scripts under `tools/` for linting or automation.
- [ ] Ensure `zig build --global-cache-dir=./.zig-cache test` covers all modules and document known gaps.

### DOM Module

#### Core
- [x] Implement the `Node` tagged union APIs for layout (`computeRequirement`, `setBox`), validation (`check`), rendering (`render`), and selection (`select`, `getSelectedContent`). Refer to the walkthrough in `docs/specification.md` and `examples/demo.zig`.
- [x] Maintain the `Requirement` struct and focus metadata so `examples/layout_demo.zig` continues to render properly sized panes.
- [x] Keep `Selection` structures wired into focus, cursor, and accessibility flows (see `examples/focus_cursor.zig`).

#### Layout & Widgets
- [x] Provide element builders in `dom/elements.zig` (`text`, `paragraph*`, `window`, `gauge*`, `spinner`, `graph`, `canvas`, border/separator helpers) with parity verified in `examples/style_gallery.zig` and `docs/examples/border_styles.md`.
  - [x] `text`
  - [x] `paragraph`
  - [x] `window`
  - [x] `gauge`
  - [x] `spinner`
  - [x] `separator`
  - [x] `graph`
  - [x] `canvas`
  - [x] border helpers
- [ ] Support container combinators (`hbox`, `vbox`, `dbox`, `flexbox`) plus flow utilities (`flex*`, `filler`, `size`, `frame`, `focus`, cursor modifiers) returning fully configured `Node` values so `zig build run:layout` keeps exercising them.
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
- [x] Maintain decorators for typography, color/gradient layers, selection styling, hyperlinks, centering helpers, and `automerge`. Examples: `zig build run:style-gallery`, `docs/examples/visual_galleries.md`.
- [ ] Expose viewport tuning via `FocusPosition` enums and scroll indicator helpers; wire into demos such as `examples/focus_cursor.zig`.

#### Advanced
- [ ] Keep `Canvas` drawing APIs rendering lines, circles, ellipses, text, and bitmap data (targets: `examples/spinner_loop.zig`, `examples/ftxui_gallery.zig`).
- [ ] Preserve `Table` features for cell selection, decoration, borders, and alternating styles (`zig build run:ftxui-table`).
- [ ] Align `FlexboxConfig`, `Direction`, `Axis`, and `Constraint` enums with layout overrides highlighted in `docs/specification.md`.

### Component Module

#### Component Base & Composition
- [x] Uphold `ComponentBase` hooks for rendering, event handling, animation, child management, and focus navigation (see `examples/widgets_interactive.zig`).
- [ ] Maintain `Component` factory helpers and `ComponentDecorator` wrappers used by `widgets.visualGallery` and `widgets.homescreen`.

#### Widgets
- [ ] Deliver interactive widgets (buttons, checkboxes, text inputs with placeholder/password/multiline, sliders, radio boxes, dropdowns, toggles, menus including animated, resizable splits, modals, collapsibles, hover wrappers, windows) across demos like `zig build run:widgets` and `zig build run:interaction`.
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
- [ ] Support renderer bridges and conditional presentation via `maybe` wrappers (`examples/ftxui_gallery.zig` and `docs/examples/visual_galleries.md` highlight missing hooks).

#### Configuration
- [ ] Keep option structs (`ButtonOptions`, `MenuOptions`, `InputOptions`, `SliderOptions`, `WindowOptions`, etc.) synchronized with animation settings (e.g., `UnderlineOption`, `AnimatedColorOption`) and callback hooks demonstrated in `examples/widgets_demo.zig`.
  - [x] `ButtonOptions`
  - [x] `WindowOptions`
  - [x] `CheckboxOptions`
  - [x] `ToggleOptions`
  - [x] `MenuOptions`
  - [x] `InputOptions`
  - [x] `SliderOptions`
  - [x] `RadioOptions`

#### Events & Looping
- [ ] Ensure `events.zig` enumerates keyboard characters, modifiers, function keys, mouse events, and cursor state with parity to `examples/print_key_press.zig`.
  - [x] Keyboard characters and modifiers
  - [x] Function keys (F1-F12)
  - [x] Arrow keys (up, down, left, right)
  - [x] Mouse events and cursor state
- [x] Maintain `Mouse` structs for coordinates, buttons, and modifiers.
- [ ] Keep `animation/animator.zig` easing utilities synchronized with widget animations (see `zig build run:widgets-interactive`).
- [ ] Guarantee `task` and `screen_interactive.zig` manage event loops, async posts, animation frames, selection APIs, piped input, and terminal control for demos launched via `zig build run`.
- [ ] Preserve `Loop` helpers for non-blocking iterations and `CapturedMouse` semantics mirroring `examples/interaction_demo.zig`.

### Screen Module

#### Rendering Surface
- [x] Maintain `screen/image.zig` and `screen/screen.zig` pixel-grid rendering, printing, clearing, cursor management, hyperlink registration, and shader hooks (demonstrated by `examples/demo.zig`).
- [x] Keep `Box` geometric utilities consistent with layout logic validated by `examples/layout_demo.zig`.
- [x] Ensure `Pixel` structs store style flags, hyperlinks, and UTF-8 graphemes (reference `docs/specification.md`).

#### Colors
- [x] Support `color.zig` palette/true-color helpers (see `docs/examples/visual_galleries.md`, `zig build run:style-gallery`).
- [x] Expose `TerminalInfo` metadata for palette support, dimensions, and fallbacks.

#### Strings & Utilities
- [x] Preserve UTF-8 helpers for conversion, width computation, glyph splitting, and cell-to-glyph mapping between `[]const u8` buffers.
- [ ] Maintain legacy wide-string APIs under `dom/screen/legacy.zig` gated by build options.
- [ ] Ensure utility helpers (`AutoReset`, `Ref`/`ConstRef`, `ConstStringRef`, `ConstStringListRef`, `Receiver`/`Sender`, Windows macro guards) remain available and documented.

## FTXUI Parity Coverage

The checklist formerly in `docs/tasks-ver2.md` now resides here. Cross-reference `docs/examples/ftxui-mapping.md` for the command cheatsheet.

### DOM
- [x] Style decorations (bold/italic/underline/double underline/strikethrough/dim/blink/inverted/hyperlink/color/gradient) — `examples/style_gallery.zig`.
- [x] Palette / true-color controls — `zig build run:style-gallery`.
- [x] Line-styled `border` / `border_colored` variants — see `docs/examples/border_styles.md`.
- [x] Layout suites (gridbox/table/hflow/vflow/html_like/tree) — `zig build run:layout`.
- [x] `linear_gradient` DOM node showcase — `examples/ftxui_gallery.zig`.
- [x] `gauge` direction and variants (horizontal/vertical) — `docs/examples/ftxui-mapping.md#dom`.
- [x] `canvas` animation / drawing utilities — `examples/spinner_loop.zig`.
- [x] `size` / `separator` / `border` style variations — `examples/style_gallery.zig`.
- [x] DOM color & style galleries covering FTXUI APIs — `zig build run:ftxui-gallery`.

### Components
- [x] Button styling / animation / frames (`examples/ftxui_gallery.zig`, `zig build run:widgets`).
- [x] Tabs (horizontal / vertical) available via `examples/widgets_demo.zig`.
- [x] Scrollbar component — `examples/interaction_demo.zig`.
- [x] Textarea (multiline) upgrades — `examples/widgets_interactive.zig`.
- [x] Input style/password/placeholder variants — `zig build run:widgets-interactive`.
- [x] Menu multi-select / animation / underline gallery — `examples/ftxui_gallery.zig`.
- [x] Toggle / checkbox / radiobox frame variants — `examples/widgets_demo.zig`.
- [x] `dropdown_custom`, `menu_custom`, renderer/maybe decorators — `examples/ftxui_gallery.zig` (requires `ComponentDecorator` work above).
- [x] Resizable split clamp / window composition / homescreen composite widgets — see `docs/examples/visual_galleries.md`.
- [x] Canvas / linear gradient / hover / focus galleries — `zig build run:ftxui-gallery`.

### Screen / Rendering
- [x] `Pixel` with `fg/bg/style` exposed to DOM/Component layers — validated via `examples/demo.zig`.
- [x] Gradient & color interpolation helpers — `docs/examples/visual_galleries.md`.
- [x] `ScreenInteractive` / `CapturedMouse` equivalents — `examples/interaction_demo.zig`.
- [x] `nested_screen` / `restored_io` / `custom_loop` scaffolding — `examples/print_key_press.zig`, `examples/focus_cursor.zig`.
- [x] Animation loop APIs backing `canvas_animated` — `examples/spinner_loop.zig`.

### その他
- [x] DOM/Component/Screen examples documented against FTXUI — see `docs/examples/README.md`.
- [x] `references/FTXUI/examples` parity pointers mirrored by `docs/examples/ftxui-mapping.md`.
- [x] Event-driven input handling demos (`examples/print_key_press.zig`, `examples/focus_cursor.zig`).

> Update both specification and parity sections whenever a new feature, example, or doc is added.
