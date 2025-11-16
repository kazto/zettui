# FTXUI Example Mapping

Zettui が再現している FTXUI サンプルを一覧化した索引です。`zig build run:*` で実行できるターゲットをまとめ、`docs/tasks.md#ftxui-parity-coverage` のチェックボックスと連動させています。

## Command Cheatsheet

| FTXUI sample | Zettui equivalent | Run command | Notes |
| --- | --- | --- | --- |
| `component/button.cpp` | `examples/ftxui_gallery.zig` | `zig build run:ftxui-gallery` | Demonstrates plain/primary/framed/animated buttons. |
| `component/menu.cpp` | `examples/ftxui_gallery.zig` | `zig build run:ftxui-gallery` | Multi-select-ready menu with underline gallery and highlight color. |
| `dom/graph.cpp` | `examples/ftxui_gallery.zig` | `zig build run:ftxui-gallery` | Sparkline graph plus gauge styling. |
| `dom/table.cpp` | `examples/ftxui_table.zig` | `zig build run:ftxui-table` | Border/header variations for tables. |
| `dom/print_key_press.cpp` | `examples/print_key_press.zig` | `zig build run:print-key-press` | Raw terminal key logger mirroring `print_key_press`. |
| `dom/focus_cursor.cpp` | `examples/focus_cursor.zig` | `zig build run:focus-cursor` | Interactive focus + cursor navigation using arrow keys. |

## DOM Coverage
- `examples/style_gallery.zig` (`zig build run:style-gallery`) — Typography, gradients, palette controls, and border variations. See also [border_styles.md](border_styles.md).
- `examples/layout_demo.zig` (`zig build run:layout`) — Gridbox, table, hflow/vflow, html-like tree, and window/frame styling parity.
- `examples/spinner_loop.zig` (`zig build run:spin`) — Canvas animation helpers plus spinner widgets.
- `examples/ftxui_gallery.zig` — `linear_gradient`, `gauge` direction, DOM color galleries, and sparkline graphs.

## Component Coverage
- `examples/widgets_demo.zig` (`zig build run:widgets`) — Buttons, checkboxes, sliders, radio boxes, toggles, dropdowns, menus.
- `examples/widgets_interactive.zig` (`zig build run:widgets-interactive`) — Text input (single/multiline/password/placeholder) and reactive animation hooks.
- `examples/interaction_demo.zig` (`zig build run:interaction`) — Scrollbar, menu interactions, `CapturedMouse` behavior.
- `examples/ftxui_gallery.zig` — Tabs, dropdown/menu custom renderers, hover wrappers, animated menus, window composition.
- [visual_galleries.md](visual_galleries.md) — `widgets.visualGallery`, `widgets.splitWithClampIndicator`, canvas/gradient/hover/focus galleries for parity with `canvas_animated` and related FTXUI demos.

## Screen & Input Coverage
- `examples/demo.zig` (`zig build run`) — DOM to Screen rendering pipeline covering `Pixel` fg/bg/style metadata.
- `examples/focus_cursor.zig` — Focus/cursor navigation and viewport tuning.
- `examples/print_key_press.zig` — Event-driven loop equivalent to FTXUI’s `print_key_press`.
- `examples/ftxui_gallery.zig` + `examples/spinner_loop.zig` — Animation loops, nested screens, restored IO behavior.

## References
- `references/FTXUI/examples`
- `../tasks.md#ftxui-parity-coverage`
