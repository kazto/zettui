# FTXUI Example Mapping & Rebuild Plan

`references/FTXUI/examples` を網羅するための割り当て表です。各行は FTXUI の `.cpp` と Zettui 側の `examples/*.zig` を対応させ、現在のステータスを示します。

## ディレクトリ別ランコマンド

| Directory | 説明 | 主な `zig build run:*` |
| --- | --- | --- |
| `examples/dom/` | DOM ノード、レイアウト、スタイル、キャンバス。 | `run:dom-borders`, `run:dom-colors`, `run:dom-layouts`, `run:dom-canvas`, `run:dom-text` |
| `examples/component/` | ボタン/メニュー/入力/選択/ビジュアル/レイアウト。 | `run:component-buttons`, `run:component-menus`, `run:component-inputs`, `run:component-selectors`, `run:component-layouts`, `run:component-visual`, `run:component-navigation`, `run:component-composition`, `run:component-dialogs` |
| `examples/screen/` | `Screen` ベースのループ、入力ロガー、IO 復元。 | `run:screen-loop`, `run:screen-input`, `run:screen-nested`, `run:screen-restored-io` |
| `examples/integration/` | DOM × Component × Screen の複合ケース。 | `run:integration-gallery`, `run:integration-homescreen` |

## DOM Samples (`references/FTXUI/examples/dom`)

| FTXUI sample | Zettui demo | Status / Notes |
| --- | --- | --- |
| `border.cpp` | `examples/dom/borders.zig` (`run:dom-borders`) | Done — frame variations rendered. |
| `border_colored.cpp` | `examples/dom/borders.zig` | Done — palette/true-color samples. |
| `border_style.cpp` | `examples/dom/borders.zig` | Done — rounded/double/heavy frames. |
| `separator.cpp` | `examples/dom/borders.zig` | Done — horizontal/vertical separators shown. |
| `separator_style.cpp` | `examples/dom/borders.zig` | Done — dashed separator sample included. |
| `size.cpp` | `examples/dom/borders.zig` | Done — explicit width/height frame demo. |
| `vbox_hbox.cpp` | `examples/dom/layouts.zig` (`run:dom-layouts`) | Done — vbox/hbox/flexbox dashboard. |
| `gridbox.cpp` | `examples/dom/layouts.zig` | Done — gridbox table rendered to stdout. |
| `hflow.cpp` | `examples/dom/layouts.zig` | Done — `hflowOwned` sample. |
| `vflow.cpp` | `examples/dom/layouts.zig` | Done — columnar `vflowOwned`. |
| `dbox.cpp` | `examples/dom/layouts.zig` | Done — overlaid dbox with framed base and overlay window. |
| `html_like.cpp` | `examples/dom/layouts.zig` | Done — `htmlLikeOwned` tree representing package manager. |
| `package_manager.cpp` | `examples/dom/layouts.zig` | Done — tree/table hybrid mirrored via html_like. |
| `table.cpp` | `examples/dom/layouts.zig` | Done — tableOwned rendered with selection highlighting. |
| `canvas.cpp` | `examples/dom/canvas_and_gauges.zig` (`run:dom-canvas`) | Done — ASCII canvas tree rendered. |
| `gauge.cpp` | `examples/dom/canvas_and_gauges.zig` | Done — gaugeStyled bar plus label. |
| `gauge_direction.cpp` | `examples/dom/canvas_and_gauges.zig` | Done — vertical gauge variant added. |
| `graph.cpp` | `examples/dom/canvas_and_gauges.zig` | Done — sparkline sample rendered. |
| `spinner.cpp` | `examples/dom/canvas_and_gauges.zig` | Done — spinner animation loop. |
| `linear_gradient.cpp` | `examples/dom/colors_and_styles.zig` (`run:dom-colors`) | Done — gradient text sample. |
| `color_gallery.cpp` | `examples/dom/colors_and_styles.zig` | Done — palette + true-color listing. |
| `color_info_palette256.cpp` | `examples/dom/colors_and_styles.zig` | Done — 256-color xterm table rendered. |
| `color_info_sorted_2d.ipp` | `examples/dom/colors_and_styles.zig` | Done — 6x6x6 color cube rows output. |
| `color_truecolor_RGB.cpp` | `examples/dom/colors_and_styles.zig` | Done — true-color strings included. |
| `color_truecolor_HSV.cpp` | `examples/dom/colors_and_styles.zig` | Done — HSV sweep rendered via true-color swatches. |
| `style_gallery.cpp` | `examples/dom/colors_and_styles.zig` | Done — typography attributes enumerated. |
| `style_bold.cpp` | `examples/dom/colors_and_styles.zig` | Done — bold sample. |
| `style_dim.cpp` | `examples/dom/colors_and_styles.zig` | Done — dim sample. |
| `style_color.cpp` | `examples/dom/colors_and_styles.zig` | Done — fg/bg combos. |
| `style_blink.cpp` | `examples/dom/colors_and_styles.zig` | Done — blinking sample. |
| `style_hyperlink.cpp` | `examples/dom/text_and_links.zig` (`run:dom-text`) | Done — hyperlink style uses OSC 8 when allowed. |
| `style_inverted.cpp` | `examples/dom/colors_and_styles.zig` | Done — inverse sample. |
| `style_italic.cpp` | `examples/dom/colors_and_styles.zig` | Done — italic sample. |
| `style_strikethrough.cpp` | `examples/dom/colors_and_styles.zig` | Done — strikethrough sample. |
| `style_underlined.cpp` | `examples/dom/colors_and_styles.zig` | Done — underline sample. |
| `style_underlined_double.cpp` | `examples/dom/colors_and_styles.zig` | Done — double underline sample. |
| `paragraph.cpp` | `examples/dom/text_and_links.zig` | Done — paragraph width demo. |

## Component Samples (`references/FTXUI/examples/component`)

| FTXUI sample | Zettui demo | Status / Notes |
| --- | --- | --- |
| `button.cpp` | `examples/component/buttons.zig` (`run:component-buttons`) | Done — plain/primary buttons rendered. |
| `button_style.cpp` | `examples/component/buttons.zig` | Done — visual variants demonstrated. |
| `button_in_frame.cpp` | `examples/component/buttons.zig` | Done — `buttonInFrame` sample. |
| `button_animated.cpp` | `examples/component/buttons.zig` | Done — animated pulse example. |
| `checkbox.cpp` | `examples/component/selectors.zig` (`run:component-selectors`) | Done — checkbox states shown. |
| `checkbox_in_frame.cpp` | `examples/component/selectors.zig` | Done — framed checkbox sample. |
| `toggle.cpp` | `examples/component/selectors.zig` | Done — toggle sample. |
| `radiobox.cpp` | `examples/component/selectors.zig` | Done — radio group sample. |
| `radiobox_in_frame.cpp` | `examples/component/selectors.zig` | Done — extend selectors with framed style. |
| `selection.cpp` | `examples/component/selectors.zig` | Done — multi-select selection flow simulated with toggle and select-all/clear events. |
| `slider.cpp` | `examples/component/inputs_and_sliders.zig` (`run:component-inputs`) | Done — horizontal slider sample. |
| `slider_direction.cpp` | `examples/component/inputs_and_sliders.zig` | Done — vertical slider included. |
| `slider_rgb.cpp` | `examples/component/inputs_and_sliders.zig` | Done — RGB sliders with stepped mixing demo. |
| `input.cpp` | `examples/component/inputs_and_sliders.zig` | Done — base text input sample. |
| `input_in_frame.cpp` | `examples/component/inputs_and_sliders.zig` | Done — bordered placeholder example. |
| `input_style.cpp` | `examples/component/inputs_and_sliders.zig` | Done — password + multiline sample. |
| `textarea.cpp` | `examples/component/inputs_and_sliders.zig` | Done — multiline stub. |
| `dropdown.cpp` | `examples/component/menus_and_dropdowns.zig` (`run:component-menus`) | Done — open dropdown sample. |
| `dropdown_custom.cpp` | `examples/component/menus_and_dropdowns.zig` | Done — custom renderer hook. |
| `menu.cpp` | `examples/component/menus_and_dropdowns.zig` | Done — base menu. |
| `menu2.cpp` | `examples/component/menus_and_dropdowns.zig` | Done — second menu variant. |
| `menu_entries.cpp` | `examples/component/menus_and_dropdowns.zig` | Done — multiple entries. |
| `menu_entries_animated.cpp` | `examples/component/menus_and_dropdowns.zig` | Done — animation enabled. |
| `menu_in_frame.cpp` | `examples/component/menus_and_dropdowns.zig` | Done — framed vertical menu added. |
| `menu_in_frame_horizontal.cpp` | `examples/component/menus_and_dropdowns.zig` | Done — inline horizontal menu framed. |
| `menu_multiple.cpp` | `examples/component/menus_and_dropdowns.zig` | Done — multi-select sample. |
| `menu_style.cpp` | `examples/component/menus_and_dropdowns.zig` | Done — highlight color usage. |
| `menu_underline_animated_gallery.cpp` | `examples/component/menus_and_dropdowns.zig` | Done — underline gallery toggled. |
| `canvas_animated.cpp` | `examples/component/visual_gallery.zig` (`run:component-visual`) | Done — gallery component includes canvas sample. |
| `linear_gradient_gallery.cpp` | `examples/component/visual_gallery.zig` | Done — gradient panel. |
| `gallery.cpp` | `examples/integration/gallery.zig` (`run:integration-gallery`) | Done — DOM graph/gradient + package tree + clamp split. |
| `homescreen.cpp` | `examples/integration/homescreen.zig` (`run:integration-homescreen`) | Done — sectioned dashboard with package tree and clamp window. |
| `flexbox_gallery.cpp` | `examples/component/layouts_and_tabs.zig` (`run:component-layouts`) | Done — split layout. |
| `tab_horizontal.cpp` | `examples/component/layouts_and_tabs.zig` | Done — horizontal tabs sample. |
| `tab_vertical.cpp` | `examples/component/layouts_and_tabs.zig` | Done — vertical tabs sample. |
| `resizable_split.cpp` | `examples/component/layouts_and_tabs.zig` | Done — split showcase. |
| `resizable_split_clamp.cpp` | `examples/component/layouts_and_tabs.zig` | Done — clamp min/max events demonstrated. |
| `window.cpp` | `examples/component/dialogs_and_windows.zig` (`run:component-dialogs`) | Done — window sample. |
| `modal_dialog.cpp` | `examples/component/dialogs_and_windows.zig` | Done — modal sample. |
| `modal_dialog_custom.cpp` | `examples/component/dialogs_and_windows.zig` | Done — deploy summary modal with custom body. |
| `collapsible.cpp` | `examples/component/dialogs_and_windows.zig` | Done — collapsible demo. |
| `menu_in_frame_horizontal.cpp` | `examples/component/menus_and_dropdowns.zig` | Done — horizontal inline renderer in frame. |
| `scrollbar.cpp` | `examples/component/navigation_and_scroll.zig` (`run:component-navigation`) | In progress — scrollbar events. |
| `focus.cpp` | `examples/component/navigation_and_scroll.zig` | Done — hover wrapper focus/blur events shown. |
| `focus_cursor.cpp` | `examples/component/navigation_and_scroll.zig` | Done — multiline input cursor navigation demoed. |
| `selection.cpp` | `examples/component/navigation_and_scroll.zig` | Done — hover state and cursor movement illustrated. |
| `composition.cpp` | `examples/component/composition.zig` (`run:component-composition`) | Done — renderer decorator. |
| `renderer.cpp` | `examples/component/composition.zig` | Done — custom renderer sample. |
| `maybe.cpp` | `examples/component/composition.zig` | Done — `maybe` toggling. |
| `custom_loop.cpp` | `examples/screen/custom_loop.zig` (`run:screen-loop`) | In progress — manual loop. |
| `nested_screen.cpp` | `examples/screen/nested_screen.zig` (`run:screen-nested`) | In progress — nested screens. |
| `with_restored_io.cpp` | `examples/screen/with_restored_io.zig` (`run:screen-restored-io`) | In progress — raw mode restore. |
| `print_key_press.cpp` | `examples/screen/input_logger.zig` (`run:screen-input`) | Complete — raw key logger reinstated. |

## Screen / Integration Samples (non-component)

| FTXUI sample | Zettui demo | Status / Notes |
| --- | --- | --- |
| `component/custom_loop.cpp` | `examples/screen/custom_loop.zig` | In progress — manual redraw loop. |
| `component/with_restored_io.cpp` | `examples/screen/with_restored_io.zig` | In progress — raw mode toggle. |
| `component/nested_screen.cpp` | `examples/screen/nested_screen.zig` | In progress — embedding child screens. |
| `component/print_key_press.cpp` | `examples/screen/input_logger.zig` | Complete — input logger parity. |
| `component/gallery.cpp` | `examples/integration/gallery.zig` | In progress — combined gallery. |
| `component/homescreen.cpp` | `examples/integration/homescreen.zig` | In progress — sectioned dashboard. |

> 今後の変更: `Pending` 行を優先して実装し、完了後は `Status / Notes` 列を `Done` や詳細説明に更新してください。
