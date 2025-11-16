# Visual Gallery Components

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

`docs/tasks-ver2.md` の Component セクションに記載されていたギャラリー系サンプルの不足分は、これらの高レベルコンポーネントを組み合わせることでカバーできます。

