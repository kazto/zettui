# Zettui Examples vs FTXUI

This document catalogs Zettui examples covering the FTXUI parity checklist. Each section lists demo binaries, the source files under `examples/`, and the referenced commands from `build.zig` so reviewers can run the equivalent scenarios side-by-side.

## DOM
- `examples/style_gallery.zig` (`zig build run:style-gallery`) — typography, color palettes, linear gradients, borders.
- `examples/layout_demo.zig` (`zig build run:layout`) — gridbox, table, hflow/vflow, html-like tree, window/frame styling.
- `examples/spinner_loop.zig` (`zig build run:spin`) — canvas animation helpers and progress spinners.

## Component
- `examples/widgets_demo.zig` (`zig build run:widgets`) — sliders, radio groups, tabulated states.
- `examples/widgets_interactive.zig` (`zig build run:widgets-interactive`) — slider/radio/onEvent showcase.
- `examples/interaction_demo.zig` (`zig build run:interaction`) — mouse/keyboard driven menu + button interactions.

## Screen & Input
- `examples/demo.zig` (`zig build run`) — DOM to screen pipeline including border/styling controls.
- `examples/ftxui_gallery.zig` (see references/FTXUI/examples, detailed below) — button/menu/graph/table parity showcase.
- `examples/focus_cursor.zig` — focus-cursor handling using the new event-driven loop.
- `examples/print_key_press.zig` — key event logger mirroring FTXUI's `print_key_press` example.

## References
Supplementary material mapping FTXUI examples to Zettui equivalents is located under `references/FTXUI/examples`. Each entry points back to the relevant `examples/*.zig` file.
