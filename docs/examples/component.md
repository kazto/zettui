# Component 機能とサンプル

※ 各コードは `const gpa = std.heap.page_allocator; const std = @import("std"); const zet = @import("zettui");` を前提とします。

- 基本コンポーネント (`ComponentBase`/`container`)
```zig
const child = try zet.component.widgets.label(gpa, "Hello");
const group = try zet.component.widgets.container(gpa, &[_]zet.component.Component{ child });
```

- カスタムレンダリング (`decorators.rendererBridge`/`decorators.maybe`)
```zig
const bridge = try zet.component.decorators.rendererBridge(
    gpa,
    (fn (ud: ?*anyopaque, w: std.fs.File.Writer) anyerror!void {
        _ = ud;
        try w.writeAll("custom");
    }),
    null,
    null,
);
const maybe = try zet.component.decorators.maybe(gpa, child, true);
zet.component.decorators.maybeSetActive(maybe, false);
```

- ボタン系 (`button`/`buttonStyled`/`buttonAnimated`/`buttonInFrame`/`label`)
```zig
const btn = try zet.component.widgets.button(gpa, .{ .label = "OK", .is_default = true });
const primary = try zet.component.widgets.buttonStyled(gpa, "Save", .primary);
const animated = try zet.component.widgets.buttonAnimated(gpa, "Pulse", .{ .start_color = 0x22D3EE, .end_color = 0xF472B6, .duration_ms = 600 });
const framed_btn = try zet.component.widgets.buttonInFrame(gpa, "Framed", .{ .border = true });
const text_label = try zet.component.widgets.label(gpa, "Static text");
```

- 入力系 (`textInput`/`textArea`/`slider`)
```zig
const input = try zet.component.widgets.textInput(gpa, .{ .placeholder = "type...", .max_length = 32 });
const textarea = try zet.component.widgets.textArea(gpa, .{ .placeholder = "multi", .multiline = true });
const slider = try zet.component.widgets.slider(gpa, .{ .value = 0.5, .horizontal = true });
```

- 選択系 (`checkbox`/`checkboxFramed`/`toggle`/`toggleFramed`/`radioGroup`/`radioGroupFramed`)
```zig
const check = try zet.component.widgets.checkbox(gpa, .{ .label = "Enable" });
const check_boxed = try zet.component.widgets.checkboxFramed(gpa, .{ .label = "Box" }, .{});
const tog = try zet.component.widgets.toggle(gpa, .{ .on_label = "ON", .off_label = "OFF" });
const tog_box = try zet.component.widgets.toggleFramed(gpa, .{ .on_label = "Y", .off_label = "N" }, .{});
const radios = try zet.component.widgets.radioGroup(gpa, .{ .labels = &[_][]const u8{ "A", "B" } });
const radios_box = try zet.component.widgets.radioGroupFramed(gpa, .{ .labels = &[_][]const u8{ "X", "Y" } }, .{});
```

- ドロップダウン (`dropdown`/`dropdownCustom`)
```zig
const dd = try zet.component.widgets.dropdown(gpa, .{ .items = &[_][]const u8{ "red", "blue" }, .placeholder = "pick" });
const dd_custom = try zet.component.widgets.dropdownCustom(gpa, .{ .items = &[_][]const u8{ "raw" } }, (fn ([]const u8) []const u8 {
    return "★";
}));
```

- メニュー (`menu`/`menuCustom`)
```zig
const menu = try zet.component.widgets.menu(gpa, .{ .items = &[_][]const u8{ "File", "Edit" }, .loop_navigation = true });
const menu_custom = try zet.component.widgets.menuCustom(gpa, .{ .items = &[_][]const u8{ "A" }, .underline_gallery = true }, (fn (idx: usize, label: []const u8) []const u8 {
    _ = idx;
    return label;
}));
```

- タブ・スクロールバー (`tabHorizontal`/`tabVertical`/`scrollbar`)
```zig
const tabs_h = try zet.component.widgets.tabHorizontal(gpa, .{ .labels = &[_][]const u8{ "Home", "Logs" } });
const tabs_v = try zet.component.widgets.tabVertical(gpa, .{ .labels = &[_][]const u8{ "A", "B" } });
const bar = try zet.component.widgets.scrollbar(gpa, .{ .content_length = 100, .viewport_length = 10, .position = 20 });
```

- スプリット (`split`/`splitWithClampIndicator`)
```zig
const split = try zet.component.widgets.split(gpa, child, text_label, .{ .ratio = 0.3, .orientation = .horizontal });
const split_clamped = try zet.component.widgets.splitWithClampIndicator(gpa, child, text_label, .{ .ratio = 0.5, .handle = "||" });
```

- ウィンドウ合成 (`window`/`windowComposition`/`homescreen`)
```zig
const windowed = try zet.component.widgets.window(gpa, child, .{ .title = "Pane" });
const composed = try zet.component.widgets.windowComposition(gpa, &[_]zet.component.Component{ btn, input }, "Dashboard");
const home = try zet.component.widgets.homescreen(gpa, "Header", &[_][]const u8{ "Section" }, &[_]zet.component.Component{ btn });
```

- 視覚ギャラリー/モーダル/折り畳み/ホバー (`visualGallery`/`modal`/`collapsible`/`hoverWrapper`)
```zig
const gallery = try zet.component.widgets.visualGallery(gpa, "Samples");
const modal = try zet.component.widgets.modal(gpa, child, .{ .title = "Modal", .is_open = true });
const collapsible = try zet.component.widgets.collapsible(gpa, child, .{ .label = "Details", .expanded = false });
const hover = try zet.component.widgets.hoverWrapper(gpa, child, .{ .hover_text = "hover", .idle_text = "idle" });
```

- レンダラーデコレータ (`renderer`/`maybe`)
```zig
const rendered = try zet.component.widgets.renderer(gpa, child, (fn (w: std.fs.File.Writer, inner: zet.component.Component) anyerror!void {
    try w.writeAll("[wrap]");
    try inner.render();
}));
const maybe_widget = try zet.component.widgets.maybe(gpa, child, true);
```

- オプションとアニメーション (`ButtonOptions`/`MenuOptions`/`InputOptions`/`SliderOptions`/`WindowOptions`/`UnderlineOption`/`AnimatedColorOption`)
```zig
const opts: zet.component.ButtonOptions = .{ .label = "Underline", .underline = .{ .thickness = 2 } };
const anim_opt: zet.component.AnimatedColorOption = .{ .start_color = 0x22D3EE, .end_color = 0xF472B6, .duration_ms = 400 };
const styled_btn = try zet.component.widgets.buttonAnimated(gpa, "Anim", anim_opt);
```

- イベント/ループ/マウス (`events.Event`/`screen_interactive.EventLoop`/`CapturedMouse`/`Loop`)
```zig
var loop = zet.screen_interactive.EventLoop.init(gpa);
defer loop.deinit();
try loop.postEvent(.{ .key = .{ .codepoint = 'q' } });
var cap = try zet.captured_mouse.CapturedMouse.acquire();
loop.bindMouse(&cap);
```
