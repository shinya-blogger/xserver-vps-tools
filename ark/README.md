# ARK設定変更ツール

Xserver VPS の ARK サーバーの設定変更を補助するスクリプトです。
ARKマネージャーと同時に利用できます。

## 設定ツール
サーバー名や参加パスワード、管理パスワードを設定するツールです。

Xserver VPS で ARK サーバーをインストールした後、rootでログインして以下のコマンドを実行します。
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/shinya-blogger/xserver-vps-tools/main/ark/config.sh)"
```

### 以前のバージョンのARKサーバーでの動作について
以前のバージョンのARKサーバー（ARKマネージャー非対応）では、GameUserSettings.iniを有効化するツールとして機能します。
GameUserSettings.ini で次の項目を指定できるようになります。

- SessionName
- ServerPassword
- ServerAdminPassword


## マップ変更ツール
ARKのマップを変更するツールです。
以前のバージョンのARKサーバー（ARKマネージャー非対応）でのみ使用できます。
Xserver VPS で ARK サーバーをインストールした後、rootでログインして以下のコマンドを実行します。
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/shinya-blogger/xserver-vps-tools/main/ark/map.sh)"
```
※同時にGameUserSettings.ini 有効化ツールも適用されます。


## 仕様

当スクリプトは以下のファイルを更新します。

- /etc/systemd/system/ark-server.service

以前のバージョンのARKサーバーでは以下のファイルを更新します。

- /etc/systemd/system/ark-server.service.d/override.conf


## 解説記事

以下の記事で詳しい使い方を解説しています。

[https://kozenist.com/xserver-vps-ark-server/](https://kozenist.com/xserver-vps-ark-server/)


## ライセンス

MITライセンスです。

[https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE](https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE)