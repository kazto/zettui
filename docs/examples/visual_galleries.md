# Visual Gallery Components

> Related tasks: [docs/tasks.md#ftxui-parity-coverage](../tasks.md#ftxui-parity-coverage) — indexed via [docs/examples/README.md](README.md) and planned for `examples/component/visual_gallery.zig` / `examples/integration/gallery.zig`.

Zettui の Component モジュールでは、`widgets.visualGallery` を使って Canvas / Linear Gradient / Hover / Focus の各ギャラリーを一括でレンダリングできます。

```zig
const gallery = try zettui.component.widgets.visualGallery(allocator, "Demo Gallery");
try gallery.render();
```

あわせて `widgets.splitWithClampIndicator` や `widgets.homescreen` を利用することで、FTXUI の `canvas_animated` や `linear_gradient` ギャラリーに近い構成を Zettui でも再現できます。
```zig
const canvas_panel = try zettui.component.widgets.visualGallery(allocator, "Canvas Showcase");
const hover_panel = try zettui.component.widgets.hoverWrapper(allocator, canvas_panel, .{});
const layout = try zettui.component.widgets.splitWithClampIndicator(allocator, hover_panel, gallery, .{});
try layout.render();
```

`docs/tasks.md` の FTXUI Parity セクションに列挙されているギャラリー系サンプルの不足分は、これらの高レベルコンポーネントを組み合わせることでカバーできます。
