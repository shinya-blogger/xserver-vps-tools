# Starboundインストーラー

Xserver VPS の Ubuntu に Satisfactory サーバーを建てるスクリプトです。

## 使い方
Xserver VPS で Ubuntu 22.04 (64bit) をインストールした後、rootでログインして以下のコマンドを実行します。
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/shinya-blogger/xserver-vps-tools/main/satisfactory/install.sh)"
```


## 仕様

- インストール先は /home/sfserver
- sfserver ユーザーを作成
- systemdサービスに登録（自動起動）


## 解説記事

以下の記事で詳しい使い方を解説しています。

[https://kozenist.com/xserver-vps-satisfactory-server/](https://kozenist.com/xserver-vps-satisfactory-server/)


## ライセンス

MITライセンスです。

[https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE](https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE)