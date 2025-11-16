# FTXUI Parity Checklist

Zettui と FTXUI の例を比較して不足している機能を分類したチェックリスト。

## DOM
- [x] スタイル装飾 (bold/italic/underline/double underline/strikethrough/dim/blink/inverted/hyperlink/color/gradient)
- [x] パレット/true-color などの色指定サポート
- [x] 線スタイルつき border / border_colored
- [x] gridbox/table/hflow/vflow/html_like/tree (package_manager) などのレイアウト
- [x] linear_gradient DOM ノード
- [x] gauge の方向 (horizontal/vertical)・バリエーション
- [x] canvas のアニメーション/描画ユーティリティ
- [x] size/separator/border のスタイルバリエーション
- [x] DOM 中での color gallery / style gallery を再現する API

## Components
- [x] button のスタイル/アニメーション/枠 (button_style/button_animated/button_in_frame)
- [x] tabs (tab_horizontal/tab_vertical)
- [x] scrollbar コンポーネント
- [x] textarea (複数行入力) 機能強化
- [x] input のスタイル/パスワード/placeholder 表現
- [x] menu の複数選択/アニメーション/underline ギャラリー
- [x] toggle/checkbox/radiobox の Frame 版
- [x] dropdown_custom、menu_custom、renderer/maybe デコレータ
- [x] resizable split clamp / window composition / homescreen 等の複合ウィジェット
- [x] Canvas/linear gradient/hover/focus gallery などビジュアル系サンプル

## Screen / Rendering
- [x] Pixel に fg/bg/style を保持し DOM/Component が色を設定できるようにする
- [ ] グラデーション・色補間ヘルパー
- [ ] ScreenInteractive / CapturedMouse 相当の入力ループ
- [ ] nested_screen / restored_io / custom_loop の足場
- [ ] アニメーションループ (canvas_animated など) を支える API

## その他
- [ ] DOM/Component/Screen それぞれの例を FTXUI と同等に網羅するドキュメント
- [ ] references/FTXUI/examples の各サンプルに対応する Zettui 例 (button/menu/graph/table 等)
- [ ] イベント駆動の入力ハンドリング (print_key_press/focus_cursor)
