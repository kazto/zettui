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

## ターミナルコントロール API

ANSIエスケープシーケンスを抽象化したユーティリティ。インタラクティブなTUIアプリケーションで画面制御やカーソル操作を行う際に使用します。

### カーソル制御 (`zet.screen.Cursor`)

カーソルの表示/非表示、位置移動を制御するコンパイル時定数と関数。

```zig
const Cursor = zet.screen.Cursor;
var stdout = std.fs.File.stdout();

// カーソルの表示/非表示（定数）
try stdout.writeAll(Cursor.hide);    // カーソルを非表示
try stdout.writeAll(Cursor.show);    // カーソルを表示

// カーソル位置（定数）
try stdout.writeAll(Cursor.home);    // 左上 (1,1) に移動
try stdout.writeAll(Cursor.save);    // 現在位置を保存
try stdout.writeAll(Cursor.restore); // 保存位置に復元

// カーソル位置移動（バッファ必要）
var buf: [32]u8 = undefined;
try stdout.writeAll(Cursor.moveTo(&buf, 5, 10));  // 行5, 列10 に移動
try stdout.writeAll(Cursor.up(&buf, 3));          // 3行上に移動
try stdout.writeAll(Cursor.down(&buf, 2));        // 2行下に移動
try stdout.writeAll(Cursor.right(&buf, 5));       // 5列右に移動
try stdout.writeAll(Cursor.left(&buf, 1));        // 1列左に移動
```

| 定数/関数 | エスケープシーケンス | 説明 |
|-----------|---------------------|------|
| `hide` | `\x1b[?25l` | カーソルを非表示 |
| `show` | `\x1b[?25h` | カーソルを表示 |
| `home` | `\x1b[H` | カーソルを左上に移動 |
| `save` | `\x1b[s` | カーソル位置を保存 |
| `restore` | `\x1b[u` | カーソル位置を復元 |
| `moveTo(buf, row, col)` | `\x1b[row;colH` | 指定位置に移動 (1-indexed) |
| `up(buf, n)` | `\x1b[nA` | n行上に移動 |
| `down(buf, n)` | `\x1b[nB` | n行下に移動 |
| `right(buf, n)` | `\x1b[nC` | n列右に移動 |
| `left(buf, n)` | `\x1b[nD` | n列左に移動 |

### 画面制御 (`zet.screen.ScreenControl`)

画面のクリアやバッファ切り替えを制御する定数。

```zig
const ScreenCtl = zet.screen.ScreenControl;
var stdout = std.fs.File.stdout();

// 画面クリア
try stdout.writeAll(ScreenCtl.clear);           // 画面全体をクリア
try stdout.writeAll(ScreenCtl.clearAndHome);    // クリアして左上に移動
try stdout.writeAll(ScreenCtl.clearToEnd);      // カーソルから画面末尾までクリア
try stdout.writeAll(ScreenCtl.clearToBegin);    // 画面先頭からカーソルまでクリア

// 行クリア
try stdout.writeAll(ScreenCtl.clearLine);       // 現在行全体をクリア
try stdout.writeAll(ScreenCtl.clearLineToEnd);  // カーソルから行末までクリア
try stdout.writeAll(ScreenCtl.clearLineToBegin);// 行頭からカーソルまでクリア

// 代替スクリーンバッファ（全画面TUIアプリ向け）
try stdout.writeAll(ScreenCtl.enterAlternate);  // 代替バッファに切り替え
try stdout.writeAll(ScreenCtl.exitAlternate);   // 元のバッファに戻る
```

| 定数 | エスケープシーケンス | 説明 |
|------|---------------------|------|
| `clear` | `\x1b[2J` | 画面全体をクリア |
| `clearAndHome` | `\x1b[2J\x1b[H` | クリアして左上に移動 |
| `clearToEnd` | `\x1b[0J` | カーソルから画面末尾までクリア |
| `clearToBegin` | `\x1b[1J` | 画面先頭からカーソルまでクリア |
| `clearLine` | `\x1b[2K` | 現在行全体をクリア |
| `clearLineToEnd` | `\x1b[0K` | カーソルから行末までクリア |
| `clearLineToBegin` | `\x1b[1K` | 行頭からカーソルまでクリア |
| `enterAlternate` | `\x1b[?1049h` | 代替スクリーンバッファに切り替え |
| `exitAlternate` | `\x1b[?1049l` | 元のスクリーンバッファに戻る |

### テキストスタイル (`zet.screen.Style`)

テキストの装飾と色を制御する定数と関数。

```zig
const Style = zet.screen.Style;
var stdout = std.fs.File.stdout();

// 装飾（定数）
try stdout.writeAll(Style.bold);          // 太字開始
try stdout.writeAll("Bold text");
try stdout.writeAll(Style.reset);         // すべてリセット

try stdout.writeAll(Style.underline);     // 下線
try stdout.writeAll(Style.italic);        // 斜体
try stdout.writeAll(Style.dim);           // 薄暗い
try stdout.writeAll(Style.blink);         // 点滅
try stdout.writeAll(Style.reverse);       // 反転
try stdout.writeAll(Style.hidden);        // 非表示
try stdout.writeAll(Style.strikethrough); // 取り消し線

// 8色（バッファ必要）
var buf: [32]u8 = undefined;
try stdout.writeAll(Style.fg(&buf, Style.Color.red));     // 前景色: 赤
try stdout.writeAll(Style.bg(&buf, Style.Color.blue));    // 背景色: 青

// 256色
try stdout.writeAll(Style.fg256(&buf, 208));   // 前景色: オレンジ (256色パレット)
try stdout.writeAll(Style.bg256(&buf, 17));    // 背景色: 濃い青

// 24bit RGB
try stdout.writeAll(Style.fgRgb(&buf, 255, 128, 64));  // 前景色: RGB
try stdout.writeAll(Style.bgRgb(&buf, 30, 30, 30));    // 背景色: RGB
```

| 定数/関数 | エスケープシーケンス | 説明 |
|-----------|---------------------|------|
| `reset` | `\x1b[0m` | すべての属性をリセット |
| `bold` | `\x1b[1m` | 太字 |
| `dim` | `\x1b[2m` | 薄暗い |
| `italic` | `\x1b[3m` | 斜体 |
| `underline` | `\x1b[4m` | 下線 |
| `blink` | `\x1b[5m` | 点滅 |
| `reverse` | `\x1b[7m` | 反転 |
| `hidden` | `\x1b[8m` | 非表示 |
| `strikethrough` | `\x1b[9m` | 取り消し線 |
| `fg(buf, color)` | `\x1b[3Xm` | 前景色 (8色) |
| `bg(buf, color)` | `\x1b[4Xm` | 背景色 (8色) |
| `fg256(buf, n)` | `\x1b[38;5;nm` | 前景色 (256色) |
| `bg256(buf, n)` | `\x1b[48;5;nm` | 背景色 (256色) |
| `fgRgb(buf, r, g, b)` | `\x1b[38;2;r;g;bm` | 前景色 (24bit) |
| `bgRgb(buf, r, g, b)` | `\x1b[48;2;r;g;bm` | 背景色 (24bit) |

**基本カラーコード (`Style.Color`):**
| 定数 | 値 | 色 |
|------|----|----|
| `black` | 0 | 黒 |
| `red` | 1 | 赤 |
| `green` | 2 | 緑 |
| `yellow` | 3 | 黄 |
| `blue` | 4 | 青 |
| `magenta` | 5 | マゼンタ |
| `cyan` | 6 | シアン |
| `white` | 7 | 白 |

### TerminalWriter ラッパー

`std.fs.File` をラップし、メソッドチェーン風に操作できる便利なラッパー。

```zig
const TerminalWriter = zet.screen.TerminalWriter;

// stdout用インスタンスを取得
var tw = TerminalWriter.stdout();

// カーソル操作
try tw.hideCursor();
try tw.showCursor();
try tw.cursorHome();
try tw.cursorMoveTo(10, 5);  // 行10, 列5
try tw.saveCursor();
try tw.restoreCursor();

// 画面操作
try tw.clearScreen();
try tw.clearScreenAndHome();
try tw.clearLine();
try tw.enterAlternateScreen();
try tw.exitAlternateScreen();

// スタイル操作
try tw.setBold();
try tw.setUnderline();
try tw.setFgColor(Style.Color.green);
try tw.setBgColor(Style.Color.blue);
try tw.setFgRgb(255, 200, 100);
try tw.setBgRgb(40, 40, 40);
try tw.resetStyle();

// 任意のバイト列出力
try tw.write("Hello, World!\n");
```

### 使用例: インタラクティブTUIアプリ

```zig
const std = @import("std");
const zet = @import("zettui");

const Cursor = zet.screen.Cursor;
const ScreenCtl = zet.screen.ScreenControl;
const Style = zet.screen.Style;

pub fn main() !void {
    var stdout = std.fs.File.stdout();

    // 初期化: カーソル非表示、画面クリア
    try stdout.writeAll(Cursor.hide);
    defer stdout.writeAll(Cursor.show) catch {};
    try stdout.writeAll(ScreenCtl.clearAndHome);

    // メインループ
    var running = true;
    while (running) {
        try stdout.writeAll(Cursor.home);  // 同じ位置で再描画

        // スタイル付きテキスト
        try stdout.writeAll(Style.bold);
        try stdout.writeAll("=== My App ===");
        try stdout.writeAll(Style.reset);
        try stdout.writeAll("\n");

        var buf: [32]u8 = undefined;
        try stdout.writeAll(Style.fg(&buf, Style.Color.green));
        try stdout.writeAll("Status: OK");
        try stdout.writeAll(Style.reset);
        try stdout.writeAll("\n");

        // ... 入力処理 ...
        running = false;  // デモ用
    }

    // 終了: 画面クリア
    try stdout.writeAll(ScreenCtl.clearAndHome);
    try stdout.writeAll("Goodbye!\n");
}
```
