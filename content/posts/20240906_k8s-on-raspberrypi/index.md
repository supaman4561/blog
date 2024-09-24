---
title: "k8s on raspberrypi"
date: 2024-09-06T04:52:30+09:00
tags: [k8s, raspberrypi]
categories: [k8s]
draft: false
---

### 環境
```
Raspberry Pi 3 Model B
Raspberry Pi OS(Legacy, 64-bit) Lite

Raspberry Pi 4
Raspberry Pi OS(Legacy, 64-bit) Lite
```

#### 参考元
https://www.technicalife.net/raspberry-pi-kubernetes/
## Install raspberry pi os
---

```cmd
$ sudo apt update
$ sudo apt dist-upgrade
```
以下を`/boot/cmdline.txt`に書き込む。
```
cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1
```


## swap無効化
---
k8sがスワップ無効化を要求するため
```sh
$ sudo dphys-swapfile swapoff
$ sudo systemctl stop dphys-swapfile
$ sudo systemctl disable dphys-swapfile
```

## ホスト名の変更
---
```
$ sudo hostnamectl set-hostname k8s-master
```

## IP固定化
---
ipを調べる
```
$ ip addr
```
ipを固定化する
```
$ sudo vi /etc/dhcpcd.conf
```

```/etc/dhcp.conf
interface eth0
static ip_address=192.168.40.101/24
static routers=192.168.40.1
static domain_name_servers=192.168.40.1
```


/etc/hostsに対応表を記載
```/etc/hosts
127.0.0.1 localhost 
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes 
ff02::2 ip6-allrouters 

127.0.1.1 k8s-master 
192.168.40.101 k8s-master 
192.168.40.102 k8s-worker1 
```

### sudo nmtui
```ad-note
LegacyじゃないOSでは`sudo nmtui`で設定した。
```
Edit a connection > Wired connection 1 > IPv4 Configuration

**一旦再起動をかけておく**
## OSの準備
---
```sh
$ sudo apt install -y apt-transport-https curl ebtables arptables

# change iptables settings
$ sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
$ sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
$ sudo update-alternatives --set arptables /usr/sbin/arptables-legacy
$ sudo update-alternatives --set ebtables /usr/sbin/ebtables-legacy

$ sudo -i
# cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# modprobe overlay
# modprobe br_netfilter
# cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# sysctl --system
```

## Install containerd
---
```sh
$ sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
```
### register repositories
```sh
$ curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
$ echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
$ sudo mkdir -p /etc/apt/keyrings
$ curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
$ sudo apt update
```
### Install
```sh
$ sudo apt install containerd.io

$ sudo mkdir -p /etc/containerd
$ containerd config default | sudo tee /etc/containerd/config.toml
$ sudo systemctl restart containerd
$ sudo systemctl enable containerd
```

### cgroups設定を変更
```
$ sudo vi /etc/containerd/config.toml
```
SystemdCgroupがfalseなので
```/etc/containerd/config.toml
	SystemdCgroup = true
```
に変更

#### kubernetesのインストール
---

参考
> https://kubernetes.io/ja/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

```shell
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet=1.28.2-1.1 kubeadm=1.28.2-1.1 kubectl=1.28.2-1.1
sudo apt-mark hold kubelet kubeadm kubectl
```
入れたバージョンは1.28.2

#### クラスタを作成
---
### master Nodeでのみ実行
flannelを使用するため cidr に 10.244.0.0/16 を設定
```
$ sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

```
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

flannelをインスコ
```
$ kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

### worker Nodeで実行
worker node 追加コマンド
(kubeadm を実行すると発行される)
```
kubeadm join 192.168.40.101:6443 --token ifys4k.v2qbbbs7ce9e34fi \
        --discovery-token-ca-cert-hash sha256:acac3d22c2d8d1b70254b01dce0e5a6233b1a629f94627460fa9b38464d469f0
```
再生成は以下のコマンド
```
$ kubeadm token create --print-join-command
```


#### ssh接続
---
raspberry pi側でsshを起動
```raspberry pi
$ sudo systemctl start ssh
$ sudo systemctl enable ssh
```

PC側で鍵を作成
```PC
# 鍵の作成
$ ssh-keygen

# 鍵の移送
$ ssh-copy-id -i <公開鍵のパス> [raspberrypiのusername]@[raspberrypiのIPアドレス]
```

.ssh/configを編集
```
Host k8s-master
	HostName 192.168.40.101
	User supaman
	Port 22
	IdentityFile ~/.ssh/k8s/id_rsa_master
```

raspberrypiにログイン
```
ssh k8s-master
```
パスワード接続を無効化
```/etc/ssh/sshd_config
PasswordAuthentication no
```

- [x] kubectlをlocal上で動かせるようにする
.kube/configをlocalに持ってきたらいけた
`.kube/config`にはcluster, contexts, usersを登録する.
その一覧をlocal PCで持っておけばいい
```
$ scp supaman@192.168.40.101:~/.kube/config ~/.kube/config
```

#### metrics-serverを導入する
---
cluster内のリソース使用状況データを集約する
```
$ kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```
deploymentに以下を追記
```diff_deployment.yaml
spec:
	template:
		spec:
			containers:
			- name: metrics-server
+			  command:
+				- /metrics-server
+				- --kubelet-insecure-tls
+				- --kubelet-preferred-address-types=InternalIP
```

#### master nodeにもdeployするようにする
---
```
$ k describe node k8s-master
...
Taints: node-role.kubernetes.io/control-plane:NoSchedule
```

この状態ではMaster Nodeには何もデプロイされない
taintsの値の後ろに`-`をつける
```
# kubectl taint nodes k8s-master node-role.kubernetes.io/control-plane:NoSchedule-
```

#### nerdctl install
---
```
wget https://github.com/containerd/nerdctl/releases/download/v1.7.4/nerdctl-1.7.4-linux-arm64.tar.gz

sudo tar Cxzvvf /usr/local/bin nerdctl-1.7.4-linux-arm64.tar.gz
```
