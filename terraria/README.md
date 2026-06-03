# Terraria サーバーセットアップツール

Xserver VPS で構築した Terraria サーバーのセットアップや設定変更を簡単に行うためのコマンドラインツールです。

## 機能

- **サーバーアップデート**: サーバーを最新版に更新します。
- **サーバー再起動**: サーバーを再起動します。
- **ワールド切り替え**: プレイするワールドを変更します。
- **tModLoaderインストール**: tModLoaderをインストールします。
- **tModLoaderアンインストール**: tModLoaderをアンインストールし、バニラに戻します。


## 使い方

1. Xserver VPS で Terraria サーバーをインストールします。
2. rootでSSHログインします。
3. 以下のコマンドを実行します。
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/shinya-blogger/xserver-vps-tools/main/terraria/setup.sh)"
```

## 注意事項

- このツールは Xserver VPS の Terraria イメージ専用に設計されています。

## 解説記事

以下の記事で詳しい使い方を解説しています。

[https://kozenist.com/xserver-vps-terraria-server/](https://kozenist.com/xserver-vps-terraria-server/)
[https://kozenist.com/xserver-vps-tmodloader-server/](https://kozenist.com/xserver-vps-tmodloader-server/)


## ライセンス

MITライセンスです。

[https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE](https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE)