#!/bin/bash

# ========== 使用方法 ===========

# ./1-rke-prepare.sh v2.6.5-ent

# ==============================

# 传入企业版版本
PANDARIA_VERSION=$1

# 传入3个节点的内网IP
# HOST_1=$2
# HOST_2=$3
# HOST_3=$4


# 分别在rke集群的3个节点执行，注意在ubuntu用户下执行

# docker user group
sudo groupadd docker
sudo usermod -aG docker ubuntu

ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# ssh 信任，没整明白，暂时手动吧
# ssh-copy-id $HOST_1 
# ssh-copy-id $HOST_2 
# ssh-copy-id $HOST_3

# install docker 
curl https://releases.rancher.com/install-docker/19.03.sh | sh

# docker login
#sudo docker login -u xxx -p xxx
sudo docker pull cnrancher/rancher:$PANDARIA_VERSION

