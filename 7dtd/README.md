# 7 Days to Die設定変更ツール

Xserver VPS の 7 Days to Die サーバーの設定変更を補助するスクリプトです。

## 機能
以下の項目を設定できます。

- サーバー名
- パスワード
- 地域
- 言語
- 難易度
- マップ
- 管理者

## 使い方
Xserver VPS で 7 Days to Die サーバーをインストールした後、rootでログインして以下のコマンドを実行します。
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/shinya-blogger/xserver-vps-tools/main/7dtd/config.sh)"
```

## 仕様

当スクリプトは以下のファイルを更新します。

- /home/steam/7dtd/serverconfig.xml
- /home/steam/.local/share/7DaysToDie/Saves/serveradmin.xml


## 解説記事

以下の記事で詳しい使い方を解説しています。

[https://kozenist.com/xserver-vps-7dtd-server/](https://kozenist.com/xserver-vps-7dtd-server/)


## ライセンス

MITライセンスです。

[https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE](https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE)