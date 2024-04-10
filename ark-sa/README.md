# ARK: Survival Ascended サーバーインストーラー

Xserver VPS の Ubuntu に ARK: Survival Ascended サーバーを建てるスクリプトです。

## 使い方
Xserver VPS で Ubuntu 22.04 (64bit) をインストールした後、rootでログインして以下のコマンドを実行します。
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/shinya-blogger/xserver-vps-tools/main/ark-sa/install.sh)"
```


## 仕様

- インストール先は /home/steam/steamapps/common/ARK Survival Ascended Dedicated Server
- steam ユーザーを作成
- systemdサービスに登録（自動起動）
- サーバーログイン時にサーバー情報を表示（/etc/motd）


## 解説記事

以下の記事で詳しい使い方を解説しています。

[https://kozenist.com/xserver-vps-ark-sa-server/](https://kozenist.com/xserver-vps-ark-sa-server/)


## ライセンス

MITライセンスです。

[https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE](https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE)