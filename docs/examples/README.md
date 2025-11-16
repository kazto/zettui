# Example Documentation Index

`examples/` は `references/FTXUI/examples` 全体を Zettui で再現するための実行可能ファイル群です。`build.zig` には各デモへ対応する `zig build run:*` ステップが登録されており、進捗は `docs/examples/ftxui-mapping.md` と `docs/tasks.md#ftxui-parity-coverage` で追跡します。

## ディレクトリ構成

| Directory | 役割 | 主な `zig build run:*` |
| --- | --- | --- |
| `examples/dom/` | DOM ノード/レイアウト/スタイル/キャンバスをカテゴリ別に紹介。 | `run:dom-borders`, `run:dom-colors`, `run:dom-layouts`, `run:dom-canvas`, `run:dom-text` |
| `examples/component/` | コンポーネント (ボタン/メニュー/入力/タブ/ビジュアル) のギャラリー。 | `run:component-buttons`, `run:component-menus`, `run:component-inputs`, `run:component-*` |
| `examples/screen/` | `ScreenInteractive`、イベントループ、IO 復元など低レベル機能。 | `run:screen-loop`, `run:screen-input`, `run:screen-nested`, `run:screen-restored-io` |
| `examples/integration/` | DOM × Component × Screen の複合シナリオ (gallery/homescreen)。 | `run:integration-gallery`, `run:integration-homescreen` |

## 実装済み DOM デモ

- `run:dom-borders` (`examples/dom/borders.zig`): `docs/examples/border_styles.md` を反映したフレーム/セパレータ/サイズ API のサンプル。
- `run:dom-colors` (`examples/dom/colors_and_styles.zig`): タイポグラフィ、スタイル属性、パレット/true-color、グラデーションを列挙。
- `run:dom-layouts` (`examples/dom/layouts.zig`): Flexbox/hbox/vbox、gridbox、hflow/vflow、html_like、focus/cursor の複合デモ。
- `run:dom-canvas` (`examples/dom/canvas_and_gauges.zig`): グラフ、ゲージ、キャンバス ASCII アート、スピナーアニメーション。
- `run:dom-text` (`examples/dom/text_and_links.zig`): paragraph、ハイライト付き文字列、擬似リンクのテキストフロー。

## 実装済み Component デモ

- `run:component-buttons` (`examples/component/buttons.zig`): ボタン・ウィンドウ。
- `run:component-menus` (`examples/component/menus_and_dropdowns.zig`): メニュー/ドロップダウン/カスタムレンダラー。
- `run:component-inputs` (`examples/component/inputs_and_sliders.zig`): スライダー/テキスト入力/イベントシミュレーション。
- `run:component-selectors` (`examples/component/selectors.zig`): チェックボックス/トグル/ラジオ。
- `run:component-layouts` (`examples/component/layouts_and_tabs.zig`): タブ系 + リサイズ split。
- `run:component-visual` (`examples/component/visual_gallery.zig`): `widgets.visualGallery` と hover/split 組み合わせ。
- `run:component-navigation` (`examples/component/navigation_and_scroll.zig`): メニューとスクロールバーのナビゲーション挙動。
- `run:component-composition` (`examples/component/composition.zig`): `renderer`/`maybe` デコレータ。
- `run:component-dialogs` (`examples/component/dialogs_and_windows.zig`): ウィンドウ/モーダル/コラプシブル。

## 実装済み Screen / Integration デモ

- `run:screen-loop` (`examples/screen/custom_loop.zig`): `Screen` を手動ループで更新。
- `run:screen-input` (`examples/screen/input_logger.zig`): `print_key_press` 相当の生入力ロガー。
- `run:screen-nested` (`examples/screen/nested_screen.zig`): 親子 Screen の描画。
- `run:screen-restored-io` (`examples/screen/with_restored_io.zig`): raw モードの復元デモ。
- `run:integration-gallery` (`examples/integration/gallery.zig`): DOM + Component + Screen の複合ギャラリー。
- `run:integration-homescreen` (`examples/integration/homescreen.zig`): `widgets.homescreen` を使った複合ウィンドウ構成。

## 次ステップ

- `docs/examples/ftxui-mapping.md` で `Pending` の行 (例: `dom/dbox.cpp`, `menu_in_frame_horizontal.cpp`, `screen_interactive` 系) を埋める。
- 各デモ追加/更新時は README・`docs/examples/ftxui-mapping.md`・`docs/tasks.md` を同期させ、`zig build run:*` コマンドが有効であることを確認してください。
