# Gauge Variants

縦横それぞれのゲージを DOM エレメント API で組み立てる例です。

```zig
const horizontal = zettui.dom.elements.gaugeWidth(0.82, 16);
const vertical = zettui.dom.elements.gaugeVerticalHeight(0.6, 9);
```

`zig build run:layout` や `zig build run` (demo) を実行すると、水平方向ゲージとともに縦方向ゲージの塗りつぶしが確認できます。
