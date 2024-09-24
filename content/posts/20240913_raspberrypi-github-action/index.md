---
title: "github-actionからraspberrypiで構築したk8sにアプリをデプロイする" 
date: 2024-09-13T18:00:00+09:00
tags: [raspberrypi, CI/CD]
categories: [k8s]
draft: true
---

## やりたいこと
本ブログのリポジトリを更新したタイミングで、もしpost/に更新があれば反映し、rapberrypiでホストしているブログの更新行いたい。

## 構想
1. 別ブランチでpostの更新を行う
1. mainにマージする
1. CIが動いてraspberrypi上で動いているブログを更新する。

## 調査事項
- [ ] どのようにアプリケーションをgithub actionsと連携してデプロイするか調査
    - github actions controllerとかいうのがあるので、それをデプロイして連携すればよさそう？

## 実施内容
- [ ] action runner controllerをk8s上にデプロイする
- [ ] harborをデプロイする。


## harborのデプロイ
raspberrypiで動かす制約上、arm64版しか使えないので、bitnami社製のhelmを利用

### sso連携
参考
https://goharbor.io/docs/1.10/administration/configure-authentication/oidc-auth/

```
$ docker login https://harbor.supaperman.net
Username: <Username>
Password: <Password>
```

tag
```
$ docker tag $IMAGE_NAME:$TAG https://harbor.supaperman.net/$PROJECT_NAME/$IMAGE_NAME:$TAG
$ docker push https://harbor.supaperman.net/$PROJECT_NAME/$IMAGE_NAME:$TAG
```

## Action Items
- https://qiita.com/gretchi/items/1032a25c5e1a1e77aee8

