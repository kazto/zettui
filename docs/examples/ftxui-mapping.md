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
| `border.cpp` | `examples/dom/borders.zig` (`run:dom-borders`) | In progress — frame variations rendered. |
| `border_colored.cpp` | `examples/dom/borders.zig` | In progress — palette/true-color samples. |
| `border_style.cpp` | `examples/dom/borders.zig` | In progress — rounded/double/heavy frames. |
| `separator.cpp` | `examples/dom/borders.zig` | In progress — horizontal/vertical separators shown. |
| `separator_style.cpp` | `examples/dom/borders.zig` | In progress — dashed separator sample included. |
| `size.cpp` | `examples/dom/borders.zig` | In progress — explicit width/height frame demo. |
| `vbox_hbox.cpp` | `examples/dom/layouts.zig` (`run:dom-layouts`) | In progress — vbox/hbox/flexbox dashboard. |
| `gridbox.cpp` | `examples/dom/layouts.zig` | In progress — gridbox table rendered to stdout. |
| `hflow.cpp` | `examples/dom/layouts.zig` | In progress — `hflowOwned` sample. |
| `vflow.cpp` | `examples/dom/layouts.zig` | In progress — columnar `vflowOwned`. |
| `dbox.cpp` | `examples/dom/layouts.zig` | Done — overlaid dbox with framed base and overlay window. |
| `html_like.cpp` | `examples/dom/layouts.zig` | In progress — `htmlLikeOwned` tree representing package manager. |
| `package_manager.cpp` | `examples/dom/layouts.zig` | In progress — tree/table hybrid mirrored via html_like. |
| `table.cpp` | `examples/dom/layouts.zig` | Done — tableOwned rendered with selection highlighting. |
| `canvas.cpp` | `examples/dom/canvas_and_gauges.zig` (`run:dom-canvas`) | In progress — ASCII canvas tree rendered. |
| `gauge.cpp` | `examples/dom/canvas_and_gauges.zig` | In progress — gaugeStyled bar plus label. |
| `gauge_direction.cpp` | `examples/dom/canvas_and_gauges.zig` | Done — vertical gauge variant added. |
| `graph.cpp` | `examples/dom/canvas_and_gauges.zig` | In progress — sparkline sample rendered. |
| `spinner.cpp` | `examples/dom/canvas_and_gauges.zig` | In progress — spinner animation loop. |
| `linear_gradient.cpp` | `examples/dom/colors_and_styles.zig` (`run:dom-colors`) | In progress — gradient text sample. |
| `color_gallery.cpp` | `examples/dom/colors_and_styles.zig` | In progress — palette + true-color listing. |
| `color_info_palette256.cpp` | `examples/dom/colors_and_styles.zig` | Done — 256-color xterm table rendered. |
| `color_info_sorted_2d.ipp` | `examples/dom/colors_and_styles.zig` | Done — 6x6x6 color cube rows output. |
| `color_truecolor_RGB.cpp` | `examples/dom/colors_and_styles.zig` | In progress — true-color strings included. |
| `color_truecolor_HSV.cpp` | `examples/dom/colors_and_styles.zig` | Done — HSV sweep rendered via true-color swatches. |
| `style_gallery.cpp` | `examples/dom/colors_and_styles.zig` | In progress — typography attributes enumerated. |
| `style_bold.cpp` | `examples/dom/colors_and_styles.zig` | In progress — bold sample. |
| `style_dim.cpp` | `examples/dom/colors_and_styles.zig` | In progress — dim sample. |
| `style_color.cpp` | `examples/dom/colors_and_styles.zig` | In progress — fg/bg combos. |
| `style_blink.cpp` | `examples/dom/colors_and_styles.zig` | In progress — blinking sample. |
| `style_hyperlink.cpp` | `examples/dom/text_and_links.zig` (`run:dom-text`) | Done — hyperlink style uses OSC 8 when allowed. |
| `style_inverted.cpp` | `examples/dom/colors_and_styles.zig` | In progress — inverse sample. |
| `style_italic.cpp` | `examples/dom/colors_and_styles.zig` | In progress — italic sample. |
| `style_strikethrough.cpp` | `examples/dom/colors_and_styles.zig` | In progress — strikethrough sample. |
| `style_underlined.cpp` | `examples/dom/colors_and_styles.zig` | In progress — underline sample. |
| `style_underlined_double.cpp` | `examples/dom/colors_and_styles.zig` | In progress — double underline sample. |
| `paragraph.cpp` | `examples/dom/text_and_links.zig` | In progress — paragraph width demo. |

## Component Samples (`references/FTXUI/examples/component`)

| FTXUI sample | Zettui demo | Status / Notes |
| --- | --- | --- |
| `button.cpp` | `examples/component/buttons.zig` (`run:component-buttons`) | In progress — plain/primary buttons rendered. |
| `button_style.cpp` | `examples/component/buttons.zig` | In progress — visual variants demonstrated. |
| `button_in_frame.cpp` | `examples/component/buttons.zig` | In progress — `buttonInFrame` sample. |
| `button_animated.cpp` | `examples/component/buttons.zig` | In progress — animated pulse example. |
| `checkbox.cpp` | `examples/component/selectors.zig` (`run:component-selectors`) | In progress — checkbox states shown. |
| `checkbox_in_frame.cpp` | `examples/component/selectors.zig` | In progress — framed checkbox sample. |
| `toggle.cpp` | `examples/component/selectors.zig` | In progress — toggle sample. |
| `radiobox.cpp` | `examples/component/selectors.zig` | In progress — radio group sample. |
| `radiobox_in_frame.cpp` | `examples/component/selectors.zig` | In progress — extend selectors with framed style. |
| `selection.cpp` | `examples/component/selectors.zig` | Pending — highlight/selection metadata still minimal. |
| `slider.cpp` | `examples/component/inputs_and_sliders.zig` (`run:component-inputs`) | In progress — horizontal slider sample. |
| `slider_direction.cpp` | `examples/component/inputs_and_sliders.zig` | In progress — vertical slider included. |
| `slider_rgb.cpp` | `examples/component/inputs_and_sliders.zig` | Done — RGB sliders with stepped mixing demo. |
| `input.cpp` | `examples/component/inputs_and_sliders.zig` | In progress — base text input sample. |
| `input_in_frame.cpp` | `examples/component/inputs_and_sliders.zig` | In progress — bordered placeholder example. |
| `input_style.cpp` | `examples/component/inputs_and_sliders.zig` | In progress — password + multiline sample. |
| `textarea.cpp` | `examples/component/inputs_and_sliders.zig` | In progress — multiline stub. |
| `dropdown.cpp` | `examples/component/menus_and_dropdowns.zig` (`run:component-menus`) | In progress — open dropdown sample. |
| `dropdown_custom.cpp` | `examples/component/menus_and_dropdowns.zig` | In progress — custom renderer hook. |
| `menu.cpp` | `examples/component/menus_and_dropdowns.zig` | In progress — base menu. |
| `menu2.cpp` | `examples/component/menus_and_dropdowns.zig` | In progress — second menu variant. |
| `menu_entries.cpp` | `examples/component/menus_and_dropdowns.zig` | In progress — multiple entries. |
| `menu_entries_animated.cpp` | `examples/component/menus_and_dropdowns.zig` | In progress — animation enabled. |
| `menu_in_frame.cpp` | `examples/component/menus_and_dropdowns.zig` | Done — framed vertical menu added. |
| `menu_in_frame_horizontal.cpp` | `examples/component/menus_and_dropdowns.zig` | Done — inline horizontal menu framed. |
| `menu_multiple.cpp` | `examples/component/menus_and_dropdowns.zig` | In progress — multi-select sample. |
| `menu_style.cpp` | `examples/component/menus_and_dropdowns.zig` | In progress — highlight color usage. |
| `menu_underline_animated_gallery.cpp` | `examples/component/menus_and_dropdowns.zig` | In progress — underline gallery toggled. |
| `canvas_animated.cpp` | `examples/component/visual_gallery.zig` (`run:component-visual`) | In progress — gallery component includes canvas sample. |
| `linear_gradient_gallery.cpp` | `examples/component/visual_gallery.zig` | In progress — gradient panel. |
| `gallery.cpp` | `examples/integration/gallery.zig` (`run:integration-gallery`) | In progress — DOM+Component hybrid. |
| `homescreen.cpp` | `examples/integration/homescreen.zig` (`run:integration-homescreen`) | In progress — `widgets.homescreen`. |
| `flexbox_gallery.cpp` | `examples/component/layouts_and_tabs.zig` (`run:component-layouts`) | In progress — split layout. |
| `tab_horizontal.cpp` | `examples/component/layouts_and_tabs.zig` | In progress — horizontal tabs sample. |
| `tab_vertical.cpp` | `examples/component/layouts_and_tabs.zig` | In progress — vertical tabs sample. |
| `resizable_split.cpp` | `examples/component/layouts_and_tabs.zig` | In progress — split showcase. |
| `resizable_split_clamp.cpp` | `examples/component/layouts_and_tabs.zig` | Done — clamp min/max events demonstrated. |
| `window.cpp` | `examples/component/dialogs_and_windows.zig` (`run:component-dialogs`) | In progress — window sample. |
| `modal_dialog.cpp` | `examples/component/dialogs_and_windows.zig` | In progress — modal sample. |
| `modal_dialog_custom.cpp` | `examples/component/dialogs_and_windows.zig` | Done — deploy summary modal with custom body. |
| `collapsible.cpp` | `examples/component/dialogs_and_windows.zig` | In progress — collapsible demo. |
| `menu_in_frame_horizontal.cpp` | `examples/component/menus_and_dropdowns.zig` | Done — horizontal inline renderer in frame. |
| `scrollbar.cpp` | `examples/component/navigation_and_scroll.zig` (`run:component-navigation`) | In progress — scrollbar events. |
| `focus.cpp` | `examples/component/navigation_and_scroll.zig` | Done — hover wrapper focus/blur events shown. |
| `focus_cursor.cpp` | `examples/component/navigation_and_scroll.zig` | Done — multiline input cursor navigation demoed. |
| `selection.cpp` | `examples/component/navigation_and_scroll.zig` | Done — hover state and cursor movement illustrated. |
| `composition.cpp` | `examples/component/composition.zig` (`run:component-composition`) | In progress — renderer decorator. |
| `renderer.cpp` | `examples/component/composition.zig` | In progress — custom renderer sample. |
| `maybe.cpp` | `examples/component/composition.zig` | In progress — `maybe` toggling. |
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
