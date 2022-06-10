#!/bin/bash

# ========== 使用方法 ===========

# ./2-rke-install.sh rke6 172.1.2.xx 172.1.2.xx 172.1.2.xx

# ==============================

# 传入要部署的rke版本，2.6版本输入rke6
RKE=$1

# 传入3个节点的内网IP
HOST_1=$2
HOST_2=$3
HOST_3=$4


# download rke for 2.4 2.5 2.6
wget https://github.com/rancher/rke/releases/download/v1.1.19/rke_linux-amd64
mv rke_linux-amd64 rke4

wget https://github.com/rancher/rke/releases/download/v1.2.20/rke_linux-amd64
mv rke_linux-amd64 rke5

wget https://github.com/rancher/rke/releases/download/v1.3.11/rke_linux-amd64
mv rke_linux-amd64 rke6

chmod +x rke*

cat>cluster.yml<<EOF
nodes:
  - address: $HOST_1
    user: ubuntu
    role: [controlplane,worker,etcd]
  - address: $HOST_2
    user: ubuntu
    role: [controlplane,worker,etcd]
  - address: $HOST_3
    user: ubuntu
    role: [controlplane,worker,etcd]

ingress:
  options:
    allow-snippet-annotations: "true" 

services:
  etcd:
    snapshot: true
    creation: 6h
    retention: 24h
EOF

./$RKE up

# install kubectl

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
mkdir -p ~/.local/bin/kubectl
mv ./kubectl ~/.local/bin/kubectl
kubectl version --client

sudo su -c 'echo "export KUBECONFIG=/root/.kube/config" >> /root/.profile'
sudo su -c 'source /root/.profile'
sudo su -c 'mkdir /root/.kube'

sudo su -c 'cp /home/ubuntu/kube_config_cluster.yml /root/.kube/config'
sudo su -c 'kubectl get node'
sudo su -c 'kubectl get pod -n kube-system'