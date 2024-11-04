---
title: "Remark42でブログにコメント欄を追加する"
date: 2024-09-30T20:39:25+09:00
tags: [remark42, blowfish]
categories: [blog]
isCJKLanguage: true
draft: false
---

## はじめに

Remark42を使って当ブログにコメント欄を設置します。:pray:  
<https://github.com/umputun/remark42>

CommentoとかIssoなど、他のコメントエンジンも検討しましたが、remark42は精力的にアップデートされており、匿名での投稿もできることから採用しました。

## Remark42のデプロイ

helm経由でデプロイを行います。当ブログではまだ紹介していませんが、私はraspberrypiを使ってkubernetesを構築しています（巷ではおうちk8sと言われるやつです)。  
公式から認知されているremark42のhelmチャートが存在するのでそちらを利用してデプロイをします。

```
# remark42.yaml

repositories:
- name: groundhog2k
  url: https://groundhog2k.github.io/helm-charts/

releases:
- name: remark42
  namespace: remark42
  chart: groundhog2k/remark42
  values:
    - values/remark42.yaml
  secrets:
    - secrets/remark42.yaml
```

```
helmfile -f remark42.yaml diff
helmfile -f remark42.yaml sync
```

ingressとかはいい感じに設定して、後はsecretKeyは設定しないと動かないのでそこだけ気をつければデプロイできます。

## コメント欄の設置

フロント側にコメント欄を設置する設定をします。
blowfishのlayouts/_default/single.htmlでコメントを表示するためのコードを見つけたので、設定していきます。

```html
<!-- layouts/_default/single.html -->

<footer class="pt-8 max-w-prose print:hidden">

    {{ partial "article-pagination.html" . }}
    {{ if .Params.showComments | default (.Site.Params.article.showComments | default false) }}
    {{ if templates.Exists "partials/comments.html" }}
    <div class="pt-3">
      <hr class="border-dotted border-neutral-300 dark:border-neutral-600" />
      <div class="pt-3">
        {{ partial "comments.html" . }}
      </div>
    </div>
    {{ else }}
    {{ warnf "[BLOWFISH] Comments are enabled for %s but no comments partial exists." .File.Path }}
    {{ end }}
    {{ end }}
  </footer>
```

.Params.showComments == trueにするため、params.tomlに以下の設定を加える。

```toml
# config/_default/params.toml 

[article]
  ...
  showComments = true
```

layouts/partials/comments.htmlを作成し、以下のようにscriptとdivを埋め込む.

```html
<!-- layouts/partials/comments.html -->

<script>
var remark_config = {
  host: 'YOUR_REMARK42_DOMAIN',
  site_id: 'YOUR_SITE_ID',
  components: ['embed', 'last-comments'],
  max_shown_comments: 100,
  theme: 'dark',
  locale: 'ja',
  show_email_subscription: false,
  simple_view: true,
  no_footer: false
}
</script>
<script>!function(e,n){for(var o=0;o<e.length;o++){var r=n.createElement("script"),c=".js",d=n.head||n.body;"noModule"in r?(r.type="module",c=".mjs"):r.async=!0,r.defer=!0,r.src=remark_config.host+"/web/"+e[o]+c,d.appendChild(r)}}(remark_config.components||["embed"],document);</script>


<div id="remark42"></div>
```

これでコメント欄の設置は完了です。

## まとめ

remark42でコメント用のサーバーをself-hostingし、ブログに設置しました。  
匿名によるコメントを許可しているので、どしどしコメントしてください。（一応次の記事はコメントお試し用の記事にします）

今後ですが、コメントサーバに割り当てたstrageが10Giなので、どのくらいの容量が使われているかとか監視したいなーと思います。  
あと画像とか記事に貼れるようにしたい。
