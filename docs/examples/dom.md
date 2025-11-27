# DOM 機能とサンプル

※ 各コードは `const gpa = std.heap.page_allocator; const std = @import("std"); const zet = @import("zettui");` を前提とします。

- `Node` レイアウト計算 (`computeRequirement`/`setBox`/`render`/`select`)
```zig
const node = zet.dom.elements.text("hi");
const req = node.computeRequirement(); // min_width/min_height などを取得
```

- テキスト系 (`text`/`paragraph`/`window`)
```zig
const t = zet.dom.elements.text("hello");
const p = zet.dom.elements.paragraph("long paragraph", 20);
const w = zet.dom.elements.window("Status");
```

- 仕切り (`separator`/`separatorHorizontal`/`separatorVertical`/`separatorStyled`)
```zig
const plain = zet.dom.elements.separator(.horizontal);
const heavy = zet.dom.elements.separatorStyled(.vertical, .dashed, 6);
```

- コンテナ (`hbox`/`vbox`/`dbox`/`flexboxRow`/`flexboxColumn`)
```zig
const row = zet.dom.elements.hbox(&[_]zet.dom.Node{ t, p });
const col = zet.dom.elements.vbox(&[_]zet.dom.Node{ w, row });
const overlay = zet.dom.elements.dbox(&[_]zet.dom.Node{ t, w });
const flex_row = zet.dom.elements.flexboxRow(&[_]zet.dom.Node{ t, p }, 1);
```

- フレックス/サイズ/フォーカス/カーソル (`flex`/`flexGrow`/`flexGrowShrink`/`filler`/`sizeOwned`/`focusPtr`/`cursorPtr`/`centerPtr`/`scrollIndicatorPtr`)
```zig
const grow = zet.dom.elements.flexGrow(2);
const tuned = zet.dom.elements.flexGrowShrink(2, 0.5);
const fixed = try zet.dom.elements.sizeOwned(gpa, t, 12, 3);
const focused = zet.dom.elements.focusPtr(&t, .center);
const with_cursor = zet.dom.elements.cursorPtr(&t, 2);
const centered = zet.dom.elements.centerPtr(&t, 20);
const scroll = zet.dom.elements.scrollIndicatorPtr(&t, .{ .top = true, .bottom = true });
```

- 枠線/サイズ/自動マージ (`frameOwned`/`frameStyledPtr`/`automerge`)
```zig
const framed = try zet.dom.elements.frameOwned(gpa, p);
const lined = zet.dom.elements.frameStyledPtr(&t, .double);
const merged = zet.dom.elements.automerge(&[_]zet.dom.Node{ t, p, w });
```

- カスタムレンダラー (`custom`)
```zig
const custom = zet.dom.elements.custom(
    (fn (ud: ?*anyopaque, _: *zet.dom.RenderContext) anyerror!void {
        _ = ud;
        try std.fs.File.stdout().writeAll("[custom node]");
    }),
    null,
);
```

- ゲージ (`gauge`/`gaugeWidth`/`gaugeVertical`/`gaugeStyled`)
```zig
const g1 = zet.dom.elements.gauge(0.42);
const g2 = zet.dom.elements.gaugeWidth(0.9, 20);
const g3 = zet.dom.elements.gaugeVertical(0.3, 6);
const g4 = zet.dom.elements.gaugeStyled(0.56, .{ .label = "CPU", .show_percentage = true });
```

- スピナー (`spinner`/`spinnerAdvance`)
```zig
var spin = zet.dom.elements.spinner();
_ = zet.dom.elements.spinnerAdvance(&spin); // フレームを進める
```

- グラフ (`graph`/`graphWidth`)
```zig
const values = [_]f32{ 0.1, 0.4, 0.9, 0.3 };
const spark = zet.dom.elements.graph(&values, 4);
const spark_w = zet.dom.elements.graphWidth(&values, 16, 4);
```

- キャンバス (`canvas`/`canvasSized`/`CanvasBuilder`/`canvasAnimation`/`canvasAnimationAdvance`)
```zig
const art_rows = [_][]const u8{ " /\\", "/__" };
const art = zet.dom.elements.canvas(&art_rows);
const art_box = zet.dom.elements.canvasSized(&art_rows, 6, 2);
var builder = try zet.dom.elements.CanvasBuilder.init(gpa, 6, 4);
defer builder.deinit();
builder.drawLine(0, 0, 5, 3, '#');
const canvas_node = try builder.toNode();
var anim = zet.dom.elements.canvasAnimation(&[_]zet.dom.Canvas{
    .{ .rows = &art_rows }, .{ .rows = &art_rows },
});
_ = zet.dom.elements.canvasAnimationAdvance(&anim);
```

- フロー/グリッド (`gridboxOwned`/`tableOwned`/`hflowOwned`/`vflowOwned`)
```zig
const grid = try zet.dom.elements.gridboxOwned(gpa, &[_][]const zet.dom.Node{
    &[_]zet.dom.Node{ t, p },
}, .{ .border = true });
const tbl = try zet.dom.elements.tableOwned(gpa, &[_]zet.dom.Node{ t, p }, &[_][]const zet.dom.Node{ &[_]zet.dom.Node{ w, t } }, .{});
const flow_h = try zet.dom.elements.hflowOwned(gpa, &[_]zet.dom.Node{ t, p, w }, .{ .wrap = 12, .gap = 1 });
const flow_v = try zet.dom.elements.vflowOwned(gpa, &[_]zet.dom.Node{ t, p, w }, .{ .wrap = 2, .gap = 1 });
```

- HTML/ツリー (`htmlLikeOwned`/`treeOwned`)
```zig
const html = try zet.dom.elements.htmlLikeOwned(gpa, .{
    .tag = "div",
    .children = &[_]zet.dom.elements.HtmlNode{ .{ .tag = "p", .text = "hello" } },
});
const tree = try zet.dom.elements.treeOwned(gpa, &[_]zet.dom.elements.TreeEntry{
    .{ .label = "root", .children = &[_]zet.dom.elements.TreeEntry{.{ .label = "child" }} },
});
```

- 表形式 (`table`/`tableSelectable`)
```zig
const plain_table = zet.dom.elements.table(&[_][]const u8{ "A", "B" }, &[_][]const []const u8{ &[_][]const u8{ "1", "2" } });
const selectable = zet.dom.elements.tableSelectable(&[_][]const u8{ "A" }, &[_][]const []const u8{ &[_][]const u8{ "x" } }, 0, 0);
```

- スタイル (`styleOwned`/`stylePaletteOwned`/`bold`/`hyperlink`/`linearGradient`)
```zig
const styled = try zet.dom.elements.styleOwned(gpa, t, .{ .bold = true, .fg = 0x22D3EE, .bg = 0x0F172A });
const palette = try zet.dom.elements.stylePaletteOwned(gpa, p, .{ .light_blue = {} }, null);
const strong = zet.dom.elements.bold(&t);
const link = zet.dom.elements.hyperlink(&t, "https://example.com");
const grad = zet.dom.elements.linearGradient("RAINBOW", 0xFF0000, 0x0000FF);
```

- フォーカス/スクロール/カーソル (`focusOwned`/`scrollIndicatorOwned`/`cursorOwned`)
```zig
const focus_top = try zet.dom.elements.focusOwned(gpa, p, .start);
const scrollable = try zet.dom.elements.scrollIndicatorOwned(gpa, t, .{ .top = true, .bottom = true });
const caret = try zet.dom.elements.cursorOwned(gpa, t, 1);
```
