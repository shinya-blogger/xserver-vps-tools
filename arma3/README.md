# Arma 3設定変更ツール

Xserver VPS の Arma 3 サーバーの設定変更を補助するスクリプトです。

## 機能
以下の項目を設定できます。

- サーバー名
- 参加パスワード
- 管理パスワード
- RCONの有効化／無効化
- modの有効化／無効化
- アップデート


## 使い方
Xserver VPS で Arma 3 サーバーをインストールした後、rootでログインして以下のコマンドを実行します。
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/shinya-blogger/xserver-vps-tools/main/arma3/config.sh)"
```

## 仕様

当スクリプトは以下のファイルを更新します。

- /etc/systemd/system/arma3-server.service.d/override.conf
- /home/steam/arma3/server.cfg
- /home/steam/arma3/battleye/launch/battleye/beserver.cfg


## 解説記事

以下の記事で詳しい使い方を解説しています。

[https://kozenist.com/xserver-vps-arma3-server/](https://kozenist.com/xserver-vps-arma3-server/)


## ライセンス

MITライセンスです。

[https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE](https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE)