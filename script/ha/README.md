# 重新部署脚本说明

脚本 redeploy.sh 适用于rke1集群的重新部署，使用时需要如下前置条件：

部署企业版HA环境：
1. 创建3个ec2实例，规格t3a.medium
2. 在3台主机上分别执行 rke-perpare.sh。ssh 信任还没有弄好，暂时手动设置
```
curl https://raw.githubusercontent.com/rootwuj/test-script/main/script/ha/rke-prepare.sh

修改脚本，设置docker login

./rke-prepare.sh v2.6.5-ent

```
3. 选择一个节点，部署rke集群
```
curl https://raw.githubusercontent.com/rootwuj/test-script/main/script/ha/rke-install.sh

./rke-install.sh  rke6 172.31.25.xx 172.31.16.xx 172.31.28.xx
```




2. 部署helm。 不同的k8s版本需要对应不同的helm版本。参考 helm.sh
3. 为了测试自签名方式，需要提前准备域名证书和localhost证书。域名证书放到/root/ca下，localhost证书放到/root/ca-local下。脚本参考 tls.sh
4. 自签名域名访问需要nginx，提前准备nginx服务。参考nginx.sh
5. 




### 已经存在的环境

环境要求：
1. rke部署HA集群，



重新部署redeploy.md 前置条件：

# 前置条件：
# 已经存在HA环境，此脚本为删除重建的过程
# 在ca下有hatest的域名证书
# 在ca-local下有localhost证书


传参：
1. deployment 使用自签名证书
2. deployment 使用自签名证书+NodePort
3. deployment 使用默认 CA 
4. deployment 使用默认 CA + NodePort
5. deployment 使用Let's Encrypt证书
6. Daemonset 使用默认 CA
7. Daemonset 使用默认 CA+NodePort
8. Daemonset 使用默认 CA+HostPort
9. Daemonset 使用自签名证书
10. Daemonset 使用自签名证书+NodePort
11. Daemonset 使用自签名证书+HostPort
