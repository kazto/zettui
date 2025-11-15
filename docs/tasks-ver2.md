# FTXUI Parity Checklist

Zettui と FTXUI の例を比較して不足している機能を分類したチェックリスト。

## DOM
- [x] スタイル装飾 (bold/italic/underline/double underline/strikethrough/dim/blink/inverted/hyperlink/color/gradient)
- [ ] パレット/true-color などの色指定サポート
- [ ] 線スタイルつき border / border_colored
- [ ] gridbox/table/hflow/vflow/html_like/tree (package_manager) などのレイアウト
- [ ] linear_gradient DOM ノード
- [ ] gauge の方向 (horizontal/vertical)・バリエーション
- [ ] canvas のアニメーション/描画ユーティリティ
- [ ] size/separator/border のスタイルバリエーション
- [ ] DOM 中での color gallery / style gallery を再現する API

## Components
- [ ] button のスタイル/アニメーション/枠 (button_style/button_animated/button_in_frame)
- [ ] tabs (tab_horizontal/tab_vertical)
- [ ] scrollbar コンポーネント
- [ ] textarea (複数行入力) 機能強化
- [ ] input のスタイル/パスワード/placeholder 表現
- [ ] menu の複数選択/アニメーション/underline ギャラリー
- [ ] toggle/checkbox/radiobox の Frame 版
- [ ] dropdown_custom、menu_custom、renderer/maybe デコレータ
- [ ] resizable split clamp / window composition / homescreen 等の複合ウィジェット
- [ ] Canvas/linear gradient/hover/focus gallery などビジュアル系サンプル

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
