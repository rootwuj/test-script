# 重新部署脚本说明

脚本 redeploy.sh 适用于rke1集群的重新部署，使用时需要如下前置条件：

部署企业版HA环境：
1. 创建3个ec2实例，规格t3a.medium
2. 在3台主机上分别在Ubuntu用户下执行 1-rke-perpare.sh。
```
wget https://raw.githubusercontent.com/rootwuj/test-script/main/script/ha/1-rke-prepare.sh
chmod +x 1-rke-prepare.sh

修改脚本，设置docker login

./1-rke-prepare.sh v2.6.5-ent

执行脚本后设置ssh信任
```
3. 选择一个节点，在Ubuntu用户下执行脚本，部署rke集群
```
wget https://raw.githubusercontent.com/rootwuj/test-script/main/script/ha/2-rke-install.sh 
chmod +x 2-rke-install.sh 

./2-rke-install.sh rke6 172.1.2.xx 172.1.2.xx 172.1.2.xx | sh -
```
4. 切到root用户下，部署helm、设置证书
```
sudo su -
wget https://raw.githubusercontent.com/rootwuj/test-script/main/script/ha/3-helm-ca.sh 
chmod +x 3-helm-ca.sh

./3-helm-ca.sh ./3-helm-ca.sh 172.1.2.xx 172.1.2.xx 172.1.2.xx
```
5. 自签名域名访问需要nginx，创建一个ec2实例，部署nginx服务。
```
sudo su -
wget https://raw.githubusercontent.com/rootwuj/test-script/main/script/ha/4-nginx.sh 
chmod +x 4-nginx.sh

./4-nginx.sh  172.1.2.xx 172.1.2.xx 172.1.2.xx
```
6. 部署rancher 




测试使用的几个域名：
- 自签名部署方式: `self.wujing.site`
- rancher默认ca: `ca.wujing.site`
- Let's Encrypt: `let.wujing.site`


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
