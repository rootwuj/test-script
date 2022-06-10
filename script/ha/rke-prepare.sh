#!/bin/bash

# ========== 使用方法 ===========

# ./rke-prepare.sh $node1 $node2 $node3
# ./rke-prepare.sh 172.31.25.153 172.31.16.76 172.31.28.76

# ==============================

# 传入3个节点的内网IP
node1=$1
node2=$2
node3=$3

# 分别在rke集群的3个节点执行，注意在ubuntu用户下执行

# docker user group
sudo groupadd docker
sudo usermod -aG docker ubuntu

# ssh 信任
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

ssh-copy-id $node1 
ssh-copy-id $node2 
ssh-copy-id $node3

# install docker 
curl https://releases.rancher.com/install-docker/19.03.sh | sh

