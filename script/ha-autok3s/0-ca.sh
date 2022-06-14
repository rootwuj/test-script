#!/bin/bash

# ========== 使用方法 ===========

# ./0-ca.sh 172.1.2.xx,172.1.2.xx,172.1.2.xx

# ==============================


# 传入3个节点的内网IP
HOST=$1


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


