# ARK設定変更ツール

Xserver VPS の ARK サーバーの設定変更を補助するスクリプトです。

## GameUserSettings.ini 有効化ツール
GameUserSettings.ini で次の項目を指定できるようにするツールです。

- SessionName
- ServerPassword
- ServerAdminPassword

Xserver VPS で ARK サーバーをインストールした後、rootでログインして以下のコマンドを実行します。
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/shinya-blogger/xserver-vps-tools/main/ark/config.sh)"
```

## マップ変更ツール
ARKのマップを変更するツールです。
Xserver VPS で ARK サーバーをインストールした後、rootでログインして以下のコマンドを実行します。
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/shinya-blogger/xserver-vps-tools/main/ark/map.sh)"
```
※同時にGameUserSettings.ini 有効化ツールも適用されます。