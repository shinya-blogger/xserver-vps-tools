# Counter-Strike 2設定変更ツール

Xserver VPS の Counter-Strike 2 サーバーの設定変更を補助するスクリプトです。

## 機能
以下の項目を設定できます。

- サーバー名
- 参加パスワード
- RCONパスワード


## 使い方
Xserver VPS で Counter-Strike 2 サーバーをインストールした後、rootでログインして以下のコマンドを実行します。
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/shinya-blogger/xserver-vps-tools/main/cs2/config.sh)"
```


## 仕様

当スクリプトは以下のファイルを更新します。

- /home/steam/cs2_server/game/csgo/cfg/server.cfg


## 解説記事

以下の記事で詳しい使い方を解説しています。

[https://kozenist.com/xserver-vps-cs2-server/](https://kozenist.com/xserver-vps-cs2-server/)


## ライセンス

MITライセンスです。

[https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE](https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE)