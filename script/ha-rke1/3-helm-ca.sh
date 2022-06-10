#!/bin/bash

# ========== 使用方法 ===========

# ./3-helm-ca.sh 172.1.2.xx 172.1.2.xx 172.1.2.xx

# ==============================


# 传入3个节点的内网IP
HOST_1=$1
HOST_2=$2
HOST_3=$3


# 生成域名证书
mkdir /root/ca
cd /root/ca
wget https://raw.githubusercontent.com/rootwuj/test-script/main/script/ha-rke1/tls.sh
chmod +x tls.sh

./tls.sh self.wujing.site $HOST_1 $HOST_2 $HOST_3

# 生成localhost证书
mkdir /root/ca-local
cd /root/ca-local
wget https://raw.githubusercontent.com/rootwuj/test-script/main/script/ha-rke1/tls.sh
chmod +x tls.sh

./tls.sh localhost $HOST_1 $HOST_2 $HOST_3


# 安装helm
cd /root

# 适用于2.4和2.5环境
# wget https://get.helm.sh/helm-v3.6.3-linux-amd64.tar.gz
# tar -zxvf helm-v3.6.3-linux-amd64.tar.gz

# 适用于2.5和2.6环境
wget https://get.helm.sh/helm-v3.8.2-linux-amd64.tar.gz
tar -zxvf helm-v3.8.2-linux-amd64.tar.gz

mv linux-amd64/helm /usr/local/bin/helm
helm version

helm repo add pandaria http://pandaria-releases.cnrancher.com/server-charts/latest
helm repo add pandaria-rc http://pandaria-releases.cnrancher.com/2.6-charts/dev
helm repo add pandaria-stable http://pandaria-releases.cnrancher.com/2.6-charts/latest

helm repo update







