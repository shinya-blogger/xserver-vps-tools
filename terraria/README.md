# Terraria サーバーセットアップツール

Xserver VPS で構築された Terraria サーバーの設定を簡単に変更するためのコマンドラインツールです。

## 機能

- **tModLoaderインストール**: tModLoaderをインストールします。
- **tModLoaderアップデート**: tModLoaderを最新版に更新します。
- **tModLoaderアンインストール**: tModLoaderをアンインストールし、バニラに戻します。
- **ワールド切り替え**: プレイするワールドを変更します。


## 使い方

1. Xserver VPS で Terraria サーバーをインストールします。
2. rootでSSHログインします。
3. 以下のコマンドを実行します。
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/shinya-blogger/xserver-vps-tools/main/terraria/setup.sh)"
```

## 注意事項

- このツールは Xserver VPS の Terraria イメージ専用に設計されています。
