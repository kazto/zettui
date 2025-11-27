# Screen 機能とサンプル

※ 各コードは `const gpa = std.heap.page_allocator; const std = @import("std"); const zet = @import("zettui");` を前提とします。

- スクリーン描画 (`Screen.init`/`clear`/`drawStyledString`/`present`)
```zig
var screen = try zet.screen.Screen.init(gpa, 20, 5);
defer gpa.free(screen.image.pixels);
screen.clear(.{ .glyph = " ", .fg = 0xFFFFFF, .bg = 0x000000 });
screen.drawStyledString(0, 0, "hello", .{ .fg = 0x22D3EE });
try screen.present(std.fs.File.stdout());
```

- 色とグラデーション (`Color.rgb`/`Color.blend`/`Gradient`)
```zig
const red = zet.screen.Color.rgb(255, 0, 0);
const blue = zet.screen.Color.rgb(0, 0, 255);
const mid = zet.screen.Color.blend(red, blue, 0.5);
const gradient = zet.screen.Gradient.init(&[_]zet.screen.GradientStop{
    .{ .position = 0.0, .color = red },
    .{ .position = 1.0, .color = blue },
});
var colors = try gradient.generate(gpa, 4);
defer gpa.free(colors);
```

- 端末情報 (`TerminalInfo`/`Terminal`)
```zig
const term = zet.screen.Terminal.init();
const info = term.queryInfo();
if (info.supports_true_color) { /* true-color 端末 */ }
```

- 文字列ユーティリティ (`utf8` helpers)
```zig
const width = zet.screen.utf8.width("あいう");
const sliced = try zet.screen.utf8.sliceGlyphs(gpa, "emoji 😊", 0, 3);
defer gpa.free(sliced);
```

- ScreenInteractive ループ (`customLoop`/`ScreenInteractive`)
```zig
var interactive = try zet.screen.ScreenInteractive.init(gpa, 40, 10);
defer interactive.deinit();
const Loop = struct {
    fn fetch(_: *zet.screen.ScreenInteractive, _: ?*anyopaque) anyerror!?zet.screen.LoopEvent {
        return null; // イベントが無ければ終了
    }
    fn handle(_: *zet.screen.ScreenInteractive, _: zet.screen.LoopEvent, _: ?*anyopaque) anyerror!bool {
        return false;
    }
};
var loop = zet.screen.customLoop(&interactive, Loop.fetch, Loop.handle, null);
try loop.run();
```

- ユーティリティ (`AutoReset`/`Ref`/`Receiver`/`Sender`/`Pixel`)
```zig
var auto = zet.screen.util.AutoReset(bool).init(false);
auto.set(true);
auto.deinit(); // 元の false に戻る
var rx = zet.screen.util.Receiver(u8).init(gpa);
defer rx.deinit();
const tx = zet.screen.util.Sender(u8){ .receiver = &rx };
try tx.send(7);
const got = rx.recv();
var pixel = zet.screen.Pixel{ .style = .{}, .glyph = "A" };
```
