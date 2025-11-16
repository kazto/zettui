# FTXUI Example Mapping

This directory tracks which Zettui demo corresponds to each FTXUI showcase. Use the provided `zig build run:*` targets to compare behavior.

| FTXUI sample | Zettui equivalent | Run command | Notes |
| --- | --- | --- | --- |
| `component/button.cpp` | `examples/ftxui_gallery.zig` | `zig build run:ftxui-gallery` | Demonstrates plain/primary/framed/animated buttons. |
| `component/menu.cpp` | `examples/ftxui_gallery.zig` | `zig build run:ftxui-gallery` | Multi-select-ready menu with underline gallery and highlight color. |
| `dom/graph.cpp` | `examples/ftxui_gallery.zig` | `zig build run:ftxui-gallery` | Sparkline graph plus gauge styling. |
| `dom/table.cpp` | `examples/ftxui_table.zig` | `zig build run:ftxui-table` | Border/header variations for tables. |
| `dom/print_key_press.cpp` | `examples/print_key_press.zig` | `zig build run:print-key-press` | Raw terminal key logger mirroring `print_key_press`. |
| `dom/focus_cursor.cpp` | `examples/focus_cursor.zig` | `zig build run:focus-cursor` | Interactive focus + cursor navigation using arrow keys. |
