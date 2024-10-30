---
title: "minioでブログ用の画像を保存する"
date: 2024-10-25T00:16:44+09:00
tags: []
categories: []
draft: true
---

ブログに画像を貼らないのもどうかなと思うので、minioで画像を保存するスペースを別途確保しました。  

## minioについて

---

S3 bucketのようなオブジェクトストレージです。  
正直画像を保存できてURLで配信できればなんでも良かったのですが、  

- S3のようにバケットポリシーが設定できる。
- 画像以外にも何かしらのファイルを置いておく場所として使える。
- キャッチアップの必要性が恐らくない(S3 compatibleとか言ってるので)

以上の理由からminioをデプロイすることに決めました。

## 環境

---

kubernetes v1.28.7  
helm v3.15.2  
helmfile 0.166.0  

## minioのデプロイ

---

### helm manifest

minioはoperatorとtenantの2つをデプロイする必要があります。  
今回はtenantを一つしか作ってないですが、複数作れば権限分離とかしやすくなるのかな〜なんて思っています。

```yaml
# minio.yaml

repositories:
  - name: minio-operator
    url: https://operator.min.io

releases:
  - name: operator
    namespace: minio
    chart: minio-operator/operator
    version: 6.0.4
    values:
      - values/minio.yaml
  - name: tenant
    namespace: minio
    chart: minio-operator/tenant
    version: 6.0.4
    secrets:
      - secrets/minio.yaml
    values:
      - values/minio.yaml
```

values/minio.yamlは長くなり過ぎてしまうのでここでは載せませんが、
基本的にはminioの公式valuesを持ってきて適宜変更を加えればよいです。  
secrets/minio.yamlにはadminの認証情報をsops暗号化したものを載せています。

#### operator

<https://min.io/docs/minio/kubernetes/upstream/reference/operator-chart-values.html>

#### tenant

<https://min.io/docs/minio/kubernetes/upstream/reference/tenant-chart-values.html>

### command

資材の準備ができたらhelmfile syncでデプロイします！

```cmd
helmfile -f minio.yaml sync
```

デプロイできたら、コンソール画面にアクセスしてみます。

![login](https://minio.supaperman.net/blog-images/Capture-2024-10-31-013139.png)

できました!! :star:  
次に、secretで設定したadminの認証情報を使ってログインします。

## バケットの作成

---

ログインできたら、ブログの画像用のバケットを作っていきます。
このバケットは外から見える必要があるため、そのようにBucketPolicyを設定しました。

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "*"
                ]
            },
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::blog-images"
            ]
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "*"
                ]
            },
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::blog-images/*"
            ]
        }
    ]
}
```

こうしてみると本当にS3みたいですね。  
ちなみにわざわざBucketPolicyを設定せずとも、GUIからanonymousからの権限を絞ることができました。

![bucketpolicy](https://minio.supaperman.net/blog-images/Capture-2024-10-31-014602.png)

これで、バケットの設定が完了し、画像を保存すれば外から見れるようになりました。  
画像の見方ですが、`https://<minioのcli用のURL>/<bucket名>/<ファイル名>`にアクセスすると閲覧できます。  
consoleではなく、CLIのエンドポイントにアクセスしなければいけないのがつまづきポイントですね！

これでなんとかブログの画像を外部で管理することができました。めでたしめでたし。
