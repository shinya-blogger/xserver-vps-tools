# Mastodon簡単セットアップ

Xserver VPS で Mastodon の初期セットアップ作業を簡単に行えるスクリプトです。

## 事前準備
- Xserver VPS でイメージタイプ Mastodon を選んでサーバーを作成しておく
- ドメインのAレコードを Xserver VPS のIPアドレスに設定しておく
- ドメインのTXTレコードを `v=spf1 +ip4:【IPアドレス】 ~all` のように設定しておく

## セットアップ手順
Xserver VPS で Mastodon アプリケーションをインストールした後、rootでログインして以下のコマンドを実行します。
```
curl -s https://raw.githubusercontent.com/shinya-blogger/xserver-vps-tools/main/mastodon/setup.sh | bash -s <ドメイン名> <メールアドレス>
```
以下が実行例です。
```
curl -s https://raw.githubusercontent.com/shinya-blogger/xserver-vps-tools/main/mastodon/setup.sh | bash -s example.com x@gmail.com
```
- 基本はXserver VPSのマニュアル通りのセットアップを自動で行います
- メールサーバーはローカルのPostfixを使用します
- メールアドレスにはLet's Encryptの証明書期限切れ通知とバウンスメールが送信されます


## 解説記事

以下の記事で詳しい使い方を解説しています。

[https://kozenist.com/mastodon-server/](https://kozenist.com/mastodon-server/)


## ライセンス

MITライセンスです。

[https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE](https://github.com/shinya-blogger/xserver-vps-tools/blob/main/LICENSE)