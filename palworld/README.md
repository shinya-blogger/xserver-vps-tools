# Palworld 設定変更ツール

Xserver VPS の Palworld サーバーの設定変更を補助するスクリプトです。

## 機能
以下の項目を設定できます。

- コミュニティサーバー有効化／無効化
- サーバー名
- サーバーパスワード
- 管理パスワード
- サーバー参加人数
- RCONの有効化／無効化


## 使い方
Xserver VPS で Palworld サーバーをインストールした後、rootでログインして以下のコマンドを実行します。
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/shinya-blogger/xserver-vps-tools/main/palworld/config.sh)"
```

## 仕様

当スクリプトは以下のファイルを更新します。

- /etc/systemd/system/palworld-server.service.d/override.conf
- /home/steam/Palworld/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini


## 解説記事

以下の記事で詳しい使い方を解説しています。

[https://kozenist.com/xserver-vps-palworld-server/](https://kozenist.com/xserver-vps-palworld-server/)


## ライセンス

MITライセンスです。

[https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE](https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE)