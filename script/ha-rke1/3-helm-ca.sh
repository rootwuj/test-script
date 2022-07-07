#!/bin/bash

# ========== 使用方法 ===========

# ./3-helm-ca.sh rke4 172.1.2.xx,172.1.2.xx,172.1.2.xx

# ==============================


# 传入rke版本，部署对应的helm
RKE_VERSION=$1
# 传入3个节点的内网IP
HOST=$2

# 生成域名证书
mkdir /root/ca
cd /root/ca
wget https://raw.githubusercontent.com/rootwuj/test-script/main/script/ha-rke1/tls.sh
chmod +x tls.sh

./tls.sh self.wujing.site $HOST

# 生成localhost证书
mkdir /root/ca-local
cd /root/ca-local
wget https://raw.githubusercontent.com/rootwuj/test-script/main/script/ha-rke1/tls.sh
chmod +x tls.sh

./tls.sh localhost $HOST


# 安装helm
cd /root


case $RKE_VERSION in
    1)  
    # 2.4 需要使用3.4.x及以下版本helm
    wget https://get.helm.sh/helm-v3.4.1-linux-amd64.tar.gz
    tar -zxvf helm-v3.4.1-linux-amd64.tar.gz

    ;;
    2)  
    # 适用于2.5环境
    wget https://get.helm.sh/helm-v3.6.3-linux-amd64.tar.gz
    tar -zxvf helm-v3.6.3-linux-amd64.tar.gz

    ;;
    3)  
    # 适用于2.6环境
    wget https://get.helm.sh/helm-v3.8.2-linux-amd64.tar.gz
    tar -zxvf helm-v3.8.2-linux-amd64.tar.gz

    ;;
    *)  echo 'ERROR: 你没有输入正确的版本，例如rke4(2.4的rke)'
    ;;
esac


mv linux-amd64/helm /usr/local/bin/helm
helm version

helm repo add pandaria http://pandaria-releases.cnrancher.com/server-charts/latest
helm repo add pandaria-rc http://pandaria-releases.cnrancher.com/2.6-charts/dev
helm repo add pandaria-stable http://pandaria-releases.cnrancher.com/2.6-charts/latest

helm repo update







