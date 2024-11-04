---
title: "Rust+AxumでPrometheus metrics監視デモ"
date: 2024-11-03T17:56:34+09:00
tags: []
categories: []
isCJKLanguage: true
draft: false
---

axumでwebサーバーを立ち上げ、/metricsにprometheusで監視したいデータを配信する。
prometheusからそのデータを追従できるようになればゴールです。

## metrics配信サーバーの構築

---

### アプリケーションの作成

axumのサンプルでPrometheus metricsのテンプレがあったので、今回はこれを使います。

<https://github.com/tokio-rs/axum/blob/main/examples/prometheus-metrics/src/main.rs>

`metrics-sample`プロジェクトを用意し、サンプルをそのままコピペして実行してみることに。

```sh
cargo new metrics-sample
```

3000番ポートで解放している`/fast`, `/slow`にアクセスしたメトリクスが`:3001/metrics`から確認できる感じのようです。

```sh
curl http://localhost:3000/fast
curl http://localhost:3000/slow
```

```sh
curl http://localhost:3001/metrics

# TYPE http_requests_total counter
http_requests_total{method="GET",path="/fast",status="200"} 3
http_requests_total{method="GET",path="/slow",status="200"} 1

# TYPE http_requests_duration_seconds summary
http_requests_duration_seconds{method="GET",path="/fast",status="200",quantile="0"} 0.000014042
http_requests_duration_seconds{method="GET",path="/fast",status="200",quantile="0.5"} 0.000014041405714754268
http_requests_duration_seconds{method="GET",path="/fast",status="200",quantile="0.9"} 0.000014041405714754268
http_requests_duration_seconds{method="GET",path="/fast",status="200",quantile="0.95"} 0.000014041405714754268
http_requests_duration_seconds{method="GET",path="/fast",status="200",quantile="0.99"} 0.000014041405714754268
http_requests_duration_seconds{method="GET",path="/fast",status="200",quantile="0.999"} 0.000014041405714754268
http_requests_duration_seconds{method="GET",path="/fast",status="200",quantile="1"} 0.000014042
http_requests_duration_seconds_sum{method="GET",path="/fast",status="200"} 0.000080042
http_requests_duration_seconds_count{method="GET",path="/fast",status="200"} 3
http_requests_duration_seconds{method="GET",path="/slow",status="200",quantile="0"} 1.005358
http_requests_duration_seconds{method="GET",path="/slow",status="200",quantile="0.5"} 1.0053140648369352
http_requests_duration_seconds{method="GET",path="/slow",status="200",quantile="0.9"} 1.0053140648369352
http_requests_duration_seconds{method="GET",path="/slow",status="200",quantile="0.95"} 1.0053140648369352
http_requests_duration_seconds{method="GET",path="/slow",status="200",quantile="0.99"} 1.0053140648369352
http_requests_duration_seconds{method="GET",path="/slow",status="200",quantile="0.999"} 1.0053140648369352
http_requests_duration_seconds{method="GET",path="/slow",status="200",quantile="1"} 1.005358
http_requests_duration_seconds_sum{method="GET",path="/slow",status="200"} 1.005358
http_requests_duration_seconds_count{method="GET",path="/slow",status="200"} 1
```

### Dockerfile

次はDockerfileを作成します。kubernetes上にあげたいので。  
初めてRustでDockerfileを作成したので一悶着ありましたが、最終的にできたファイルは以下です。

```Dockerfile
FROM rust:1.82-alpine AS builder
WORKDIR /usr/src/metrics-sample
COPY . .
RUN apk update
RUN apk add pkgconfig musl-dev

RUN rustup target add aarch64-unknown-linux-musl
RUN rustup toolchain install stable-aarch64-unknown-linux-musl

RUN cargo build --target aarch64-unknown-linux-musl --release

FROM alpine:3.8
COPY --from=builder /usr/src/metrics-sample/target/aarch64-unknown-linux-musl/release/metrics-sample /usr/local/bin/metrics-sample
EXPOSE 3000
EXPOSE 3001
CMD ["metrics-sample"]
```

docker buildでイメージ焼いてcontainer registryにpushします。  
私は自前でrepository server(harbor)を立ち上げているのでそこにpushしています。  

## kubernetesにデプロイ

---

`kubectl apply`でPodとServiceを立ち上げます。

```sh
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: metrics-server
  namespace: metrics-sample
  labels:
    app.kubernetes.io: metrics-server
spec:
  containers:
  - name: metrics-server
    image: <image>:<tag>
---
apiVersion: v1
kind: Service
metadata:
  name: app-server
  namespace: metrics-sample
spec:
  selector:
    app.kubernetes.io: metrics-server
  ports:
  - name: app
    protocol: TCP
    port: 3000
    targetPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: metrics-server
  namespace: metrics-sample
spec:
  selector:
    app.kubernetes.io: metrics-server
  ports:
  - name: metrics
    protocol: TCP
    port: 3001
    targetPort: 3001
EOF
```

リソースを作成したら、serviceにport-forwardし、正常にmetricsが取れていることを確認します。  

```sh
kubectl port-forward -n metrics-sample service/app-server 3000:app &
kubectl port-forward -n metrics-sample service/metrics-server 3001:metrics &
```

```sh
curl http://localhost:3000/fast
curl http://localhost:3000/slow
curl http://localhost:3001/metrics
```

## Prometheusの設定

---

`additional-scrape-config.ymal`に設定をしていきます。
上で作成したserviceに対してtargetsを貼れば良いです。  

私はhelmfileでデプロイしているので、valuesファイルを編集する形でjobを追加しました。

```yaml
additional-scrape-configs.yaml: |-
  - job_name: metrics-sample
    metrics_path: /metrics
    static_configs:
    - targets:
      - metrics-server.metrics-sample.svc.cluster.local:3001
```

うまくできると、prometheusの画面からpromqlを叩いてmetricsのデータが閲覧できるようになります。  

![promql](https://minio.supaperman.net/blog-images/Capture-2024-11-04-022328.png)  

## Grafana上で表示してみる

---

最後に、取得したmetricsをgrafana上でグラフとして表示してみます。  

![grafana](https://minio.supaperman.net/blog-images/Capture-2024-11-04-164205.png)  

一応作成したPromQLを載せておきます。(正直好みの世界なので参考になればという程度ですが...)

```promql
http_requests_total{job="metrics-sample", path="/slow", status="200"}
```

```promql
http_requests_total{job="metrics-sample", path="/fast", status="200"}
```

```promql
http_requests_duration_seconds{job="metrics-sample"}
```

## まとめ

---

metrics配信サーバーをRust+Axumで構築し、Prometheusでデータ取得、Grafanaのダッシュボード上で表示という一連の流れを構築しました。
