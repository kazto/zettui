# Border Style Demo

> Related tasks: [docs/tasks.md#ftxui-parity-coverage](../tasks.md#ftxui-parity-coverage) — indexed via [docs/examples/README.md](README.md) and slated for `examples/dom/borders.zig`.

```zig
const frame_double = try zettui.dom.elements.frameStyledOwned(a, zettui.dom.elements.text("Double border"), .{
    .charset = .double,
    .fg_palette = .bright_cyan,
});
const frame_color = try zettui.dom.elements.frameStyledOwned(a, zettui.dom.elements.text("Colored single border"), .{
    .fg = 0xF97316,
});
```
