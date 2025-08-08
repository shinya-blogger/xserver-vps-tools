# FiveM設定変更ツール

Xserver VPS の FiveM サーバーのセットアップを補助するスクリプトです。

## 機能
以下の機能があります。

- PIN表示（初期設定）
- サーバーアップデート
- サーバー再起動


## 使い方
Xserver VPS で FiveM サーバーをインストールした後、rootでログインして以下のコマンドを実行します。
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/shinya-blogger/xserver-vps-tools/main/fivem/setup.sh)"
```

## 仕様

サーバーアップデートでは、LATEST RECOMMENDEDバージョンへの更新を行います。


## 解説記事

以下の記事で詳しい使い方を解説しています。

[https://kozenist.com/xserver-vps-fivem-server/](https://kozenist.com/xserver-vps-fivem-server/)


## ライセンス

MITライセンスです。

[https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE](https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE)