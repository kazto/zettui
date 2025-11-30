# Examples

zettui を初めて触るときは `showcase.zig` からどうぞ。80列程度のターミナルで動かすと一枚のキャンバスに DOM・Component・Screen の要素が並びます。

```bash
ZIG_GLOBAL_CACHE_DIR=./.zig-cache zig build run:showcase
# もしくはビルドステップを使わない場合:
ZIG_GLOBAL_CACHE_DIR=./.zig-cache zig run --dep zettui -Mroot=examples/showcase.zig -Mzettui=src/lib.zig
```

気になる領域を深掘りする場合:
- DOM: `examples/dom/*.zig` でレイアウト、グラフ、ボーダーなどを単体確認
- Component: `examples/component/*.zig` でボタン、モーダル、メニューなどの挙動を確認
- Screen: `examples/screen/*.zig` でスクリーン合成やカスタムループを確認
- 統合ビュー: `examples/integration/gallery.zig` は DOM/Component/Screen を小さなショールームとして並べています。
