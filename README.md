# Zettui - TUI library written in Ziglang

Zettui は Zig で書かれたターミナル UI ツールキットです。`src/` 以下に DOM / Component / Screen モジュールを分割し、`zig build` でライブラリ・テスト・例をビルドできます。

## Examples

- `zig build run` – メインデモ (`examples/demo.zig`)
- `zig build run:layout` – DOM を Screen に描画するレイアウトデモ
- `zig build run:style-gallery` – `styleOwned`/`styleColorOwned` を使ったタイポ/カラーギャラリー
- `zig build run:widgets` – スライダー・ラジオなどのウィジェット出力
- `zig build run:widgets-interactive` – 入力イベントを送って状態遷移を確認
- `zig build run:spin` – スピナーアニメーション
- `zig build run:interaction` – キー/マウスコマンドでメニュー選択とボタンクリックをシミュレート
- `docs/examples/gauge_variants.md` – 水平/垂直ゲージのスニペットと参照デモ

`zig build run:style-gallery` は stdout に ANSI カラー付きで見出しを描画するため、Screen アダプタを介さずに新しいスタイリング API を確認できます。

```
$ zig build run:style-gallery
Zettui style & color gallery

== Typography ==
Bold / Strong
Italic emphasis
Single underline
Double underline
Strike through
Blink cursor sample
Dim accent
Inverse focus block

== Colors ==
Crimson
Emerald
Azure
Sunset on charcoal
Neon on midnight
Lavender underline
```

実際の出力は ANSI エスケープで彩色されます (例: Crimson 行は赤、Sunset 行は FG/BG を変更)。

`zig build run:interaction` は実行中に端末を一時的に raw モードへ切り替え、矢印キーや Enter でメニューを移動・選択できます。スペースまたは SGR マウスイベント（クリック）でボタンを点滅させ、`q` で終了します。
