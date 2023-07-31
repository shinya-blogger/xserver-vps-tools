# Valheim設定変更ツール

Xserver VPS の Valheim サーバーの設定変更を補助するスクリプトです。

## 機能
以下の項目を設定できます。

- サーバー名
- パスワード
- ワールド
- 管理者
- BepInExインストール・アンインストール
- Valheim自動バージョンアップの有効・無効

## 使い方
Xserver VPS で Valheim サーバーをインストールした後、rootでログインして以下のコマンドを実行します。
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/shinya-blogger/xserver-vps-tools/main/valheim/config.sh)"
```


## 仕様

当スクリプトは以下のファイルを作成または更新します（BepInEx本体を除く）。

- /home/steam/.config/unity3d/IronGate/Valheim/adminlist.txt
- /home/steam/Valheim/valheim_server.sh
- /home/steam/Valheim/valheim_server_bepinex.sh
- /etc/systemd/system/valheim_server.service.d/override.conf

BepInExインストール後は、valheim_serverサービスの起動スクリプトをvalheim_server_bepinex.shに変更します。


## 解説記事

以下の記事で詳しい使い方を解説しています。

[https://kozenist.com/xserver-vps-valheim-server/](https://kozenist.com/xserver-vps-valheim-server/)


## ライセンス

MITライセンスです。

[https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE](https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE)