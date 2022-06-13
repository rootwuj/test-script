#!/bin/bash

# ========== 使用方法 ===========

# ./0-ca.sh 172.1.2.xx 172.1.2.xx 172.1.2.xx

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


