---
presentationID: 1lx3n9Xfgwqo5jeTC-HsdihmYmmy0V791d4pdxHOPXJ4
title: ncursesの後継者たち
---

# ncursesの後継者たち

## 2025-11-28 Terminal Night #1<br>kazto (@kazto_dev)

---

# ターミナルの描画制御といえば

* 長らくNcursesでした
* だいたいのUnix/Linux環境にはデフォルトでインストールされているはず

---

# しかし

* いい加減古くないか？
* 最近ならもっといい感じのライブラリがないか

---

# ありました

* C++
  * [Notcurses](https://github.com/dankamongmen/notcurses)
  * [FTXUI](https://github.com/ArthurSonzogni/FTXUI)
  * [imtui](https://github.com/ggerganov/imtui)
* Rust
  * [Ratatui](https://ratatui.rs/)
  * [Crossterm](https://github.com/crossterm-rs/crossterm)

- - -

* Go
  * [BubbleTea](https://github.com/charmbracelet/bubbletea)
  * [Tcell](https://github.com/gdamore/tcell)
* JS/TS
  * [Ink](https://github.com/vadimdemedes/ink-ui)
  * [Blessed](https://github.com/chjj/blessed)
  * [Neo-Blessed](https://github.com/embarklabs/neo-blessed)

まぁこれくらいはAIに聞けば出てくる

<!-- {"layout": "2 列（タイトルあり）"} -->

---

# いっぱいある。でもさ

* ポータブルじゃなくない？
* 各言語にロックインされてて他言語から使いにくい
* やはりcdeclで呼び出せないと

---

# C言語で？今さら？

<!-- {"layout": "セクション ヘッダー"} -->

---

# Zigでしょ！<br><br><br>

![Zig-logo](./zig-mark.png)

<!-- {"layout": "セクション ヘッダー"} -->

---

# まぁでもどうせもうあるっしょ？

* [zig-spoon](https://sr.ht/~leon_plickat/zig-spoon/)
  * GPL3...😢
* [Tuile](https://github.com/akarpovskii/tuile)
  * Public archived...😢

---

# やるなら今しかねぇ～

* [Zettui](https://github.com/kazto/zettui)
  * https://github.com/kazto/zettui

```qr
https://github.com/kazto/zettui
```

---

# 進捗報告



---

# 次のネタ

* [Task' em all](https://github.com/kazto/taskemall)
  * https://github.com/kazto/taskemall

```qr
https://github.com/kazto/taskemall
```

---

# 俺たちの戦いはこれからだ

<!-- {"layout": "セクション ヘッダー"} -->

---

# thanks

* [k1LoW/deck](https://github.com/k1LoW/deck)
  * https://github.com/k1LoW/deck

```qr
https://github.com/k1LoW/deck
```
