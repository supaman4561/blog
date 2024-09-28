---
title: "Hugo+Blowfishで個人ブログを作成する"
date: 2024-09-27T04:17:57+09:00
tags: [hugo, blowfish]
categories: [blog]
draft: false
---

n番煎じという感じですが、このブログ作成時の備忘録として残しておきます。

## ツール類の紹介
---

### Hugo
Static Site Generatorの一つです。  
ブログをmarkdownで執筆できる & テーマを選ぶだけでそれっぽいブログを構築できることから今回採用しました。  
https://gohugo.io/

### Blowfish
Hugoのテーマの一つです。  
Tag, Category機能がある & Postsをカード表示できてモダンな感じがするので採用しました。  
あとは好みです。  
https://github.com/nunocoracao/blowfish

## ローカルサーバーの立ち上げ
---
Blowfishのドキュメントを見ながら構築していきます。  
整備されていてありがたい :sparkles:

Hugo自体のインストール
```sh
brew install hugo
```

新規サイトの構築
```sh
hugo new site mySite
```

既存のディレクトリ上にサイトを構築する場合は以下のコマンドで作成できます。  
github等で先にリポジトリを作成してからサイトを構築する場合に使えます。
```
hugo new site . --force
```

サイトを作成したらgit submoduleでBlowfishを導入します。
```sh
cd mySite
git init
git submodule add -b main https://github.com/nunocoracao/blowfish.git themes/blowfish
```

次に`themes/blowfish/config`ディレクトリをプロジェクトのルートにコピーします。
```
cp -r themes/blowfish/config/ .
```

`config/_default/hugo.toml`を編集します。
theme = "blowfish"のコメントアウトを解除します。
```toml:hugo.toml
...
theme = "blowfish"

```

これでブログとしては見える状態になりました。  
サーバーを立ち上げて確認してみます。
```
hugo server -D
```

## コンテンツの追加
---

あとはconfig/のtomlファイルたちをいじってタイトルや見た目を変えたり、contentにmarkdownを追加すればいい感じになります。
contentの追加のコマンドは以下でできます。
```
hugo new <new markdown path>
```

自分はcontent/posts/以下にディレクトリを切って作成しているので、こんな感じで作ってます。
```
hugo new posts/yyyymmdd_<title>/index.md
```

ここまででローカル上でのblogの構築が完了しました。
気分が乗ればどうデプロイしているのかの話を書き連ねようと思いますが、それはまた別のpostで...
