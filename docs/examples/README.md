# Example Documentation Index

`docs/examples/` には Zettui の主要デモを補完するハウツー資料をまとめています。各項目は `zig build run:*` コマンドと `examples/*.zig` にリンクしており、進捗は `../tasks.md` のチェックリストで追跡します。

## DOM
- [border_styles.md](border_styles.md) — `examples/style_gallery.zig` / `zig build run:style-gallery` で利用しているフレーム/ボーダーのカタログ。
- [visual_galleries.md](visual_galleries.md) — `examples/ftxui_gallery.zig` と `widgets.visualGallery` で使うキャンバス/グラデーション/ホバー/フォーカスギャラリーのまとめ。

## Component
- `examples/widgets_demo.zig` (`zig build run:widgets`) と `examples/widgets_interactive.zig` (`zig build run:widgets-interactive`) の UI パターン整理は、随時このフォルダに追加してください。
- `widgets.homescreen` や `widgets.splitWithClampIndicator` を扱う資料も本フォルダで管理し、FTXUI パリティに貢献する内容は [ftxui-mapping.md](ftxui-mapping.md) にリンクしてください。

## Screen & Input
- `examples/demo.zig`, `examples/focus_cursor.zig`, `examples/print_key_press.zig` の背景説明を新規追加する際は、この README を更新し参照先を明示します。

## FTXUI Mapping
- [ftxui-mapping.md](ftxui-mapping.md) — FTXUI 各サンプルに対応する Zettui デモ、実行コマンド、関連ファイルの索引。`references/FTXUI/examples` と `../tasks.md#ftxui-parity-coverage` からもリンクされています。
