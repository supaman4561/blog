---
title: "Hugo+Blowfishで個人ブログを作成する"
date: 2024-09-27T04:17:57+09:00
tags: [hugo, blowfish]
categories: [blog]
draft: false
---

n番煎じという感じですが、このブログ作成時の備忘録として残しておきます。

## What is

### Hugo
Static Site Generatorの一つです。  
ブログをmarkdownで執筆できる & テーマを選ぶだけでそれっぽいブログを構築できることから今回採用しました。  
https://gohugo.io/

### Blowfish
Hugoのテーマの一つです。  
Tag, Category機能がある & Postsをカード表示できてモダンな感じがするので採用しました。  
あとは好みです。  
https://github.com/nunocoracao/blowfish

## Build
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

今回はgit submoduleでBlowfishを導入します。
```sh
cd mySite
git init
git submodule add -b main https://github.com/nunocoracao/blowfish.git themes/blowfish
```

