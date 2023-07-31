# Rust設定変更ツール

Xserver VPS の Rust サーバーの設定変更を補助するスクリプトです。

## 機能
以下の項目を設定できます。

- サーバー名
- マップ
- ワールドサイズ
- 最大プレイヤー数
- PvE
- Oxideインストール

## 使い方
Xserver VPS で Rust サーバーをインストールした後、rootでログインして以下のコマンドを実行します。
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/shinya-blogger/xserver-vps-tools/main/rust/config.sh)"
```


## 解説記事

以下の記事で詳しい使い方を解説しています。

[https://kozenist.com/xserver-vps-rust-server/](https://kozenist.com/xserver-vps-rust-server/)


## ライセンス

MITライセンスです。

[https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE](https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE)