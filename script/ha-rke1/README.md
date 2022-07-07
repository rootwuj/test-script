# 脚本说明

验证企业版所有支持的HA部署方式，为了节省资源，测试方式为在现有HA集群重新部署。

- 如果已经存在RKE1的HA集群，可以直接执行 5-ha-redeploy.sh 脚本（需要根据自身环境输入参数）。

- 如果还没有HA环境，可以按下面流程创建一个HA环境，再验重新部署rke集群验证其他启动方式。

HA部署/重新部署：

1. 创建3个ec2实例，规格t3a.medium

2. 在3台主机上分别在Ubuntu用户下执行 1-rke-perpare.sh。

```
wget https://raw.githubusercontent.com/rootwuj/test-script/main/script/ha-rke1/1-rke-prepare.sh

chmod +x 1-rke-prepare.sh

# 修改脚本，设置docker login

# ./1-rke-prepare.sh 企业版版本
./1-rke-prepare.sh v2.6.5-ent

# 执行脚本后设置ssh信任
```

3. 选择一个节点，在Ubuntu用户下执行脚本，部署rke集群

```
# 验证新版本，需要先确认一下脚本的rke版本是否为最新
wget https://raw.githubusercontent.com/rootwuj/test-script/main/script/ha-rke1/2-rke-install.sh

chmod +x 2-rke-install.sh 

# ./2-rke-install.sh rke名称 节点1 节点2 节点3
./2-rke-install.sh rke6 172.1.2.xx 172.1.2.xx 172.1.2.xx
```

4. 切到root用户下，部署helm、设置证书

```
sudo su -

wget https://raw.githubusercontent.com/rootwuj/test-script/main/script/ha-rke1/3-helm-ca.sh

chmod +x 3-helm-ca.sh

# ./3-helm-ca.sh 节点1,节点2,节点3
./3-helm-ca.sh rke4 172.1.2.xx,172.1.2.xx,172.1.2.xx

```

5. 自签名域名访问需要nginx，创建一个ec2实例，部署nginx服务。

```
sudo su -

wget https://raw.githubusercontent.com/rootwuj/test-script/main/script/ha-rke1/4-nginx-l4.sh

chmod +x 4-nginx-l4.sh

# ./4-nginx-l4.sh 节点1 节点2 节点3
./4-nginx-l4.sh  172.1.2.xx 172.1.2.xx 172.1.2.xx
```

6. 部署mysql，为部署审计日志做准备

> 为了节省资源可以在部署nginx的主机上安装mysql

```
# 启动
docker run --name mysql --restart=unless-stopped -p 3306:3306 -e MYSQL_ROOT_PASSWORD=Rancher@123 -d mysql

# 进入容器
docker exec -it mysql bash

# 登录mysql
mysql -uroot -p

# 创建数据库
create database rancher;
```

7. 部署企业版/重新部署企业版

- 如果只希望部署一个新的HA环境，这里也可以直接用helm install命令部署。（使用脚本会先卸载rke再重新安装）

- 为了验证多种部署方式，可以使用脚本 5-ha-redeploy.sh

```
# 在Ubuntu用户下执行

wget https://raw.githubusercontent.com/rootwuj/test-script/main/script/ha-rke1/5-ha-redeploy.sh

chmod +x 5-ha-redeploy.sh

# ./5-ha-redeploy.sh rke名称 chart 企业版版本 mysql地址 部署方式
./5-ha-redeploy.sh rke6 pandaria-stable v2.6.5-ent 172.1.1.1 3
```

传参说明：

- RKE_NAME 输入集群环境中rke的名称，例如：rke6 rke5 rke4

- CHART_NAME=$2 输入chart名称 

    - 2.5:pandaria

    - 2.6的rc版：pandaria-rc

    - 2.6的正式版本：pandaria-stable

- PANDARIA_VERSION 企业版版本 例如：v2.6.5-ent v2.6.5-ent-rc7 v2.5.14-ent

- DB_HOST 第6步设置的数据库内网IP

- DEPLOY_METHOD HA部署方式 例如：3 代表按照deployment使用默认CA方式部署

参数 | 部署方式 | 访问方式
---|---|---
1 | deployment 使用自签名证书 | 使用域名`self.wujing.site`访问
2 | deployment 使用自签名证书+NodePort | 使用`ip:30443`访问
3 | deployment 使用默认 CA | 使用域名`ca.wujing.site`访问
4 | deployment 使用默认 CA + NodePort | 使用`ip:30443`访问
5 | deployment 使用Let's Encrypt证书| 使用域名`let.wujing.site`访问
6 | Daemonset 使用默认 CA | 使用域名`ca.wujing.site`访问
7 | Daemonset 使用默认 CA+NodePort |  使用`ip:30443`访问
8 | Daemonset 使用默认 CA+HostPort |  使用`ip:10443`访问
9 | Daemonset 使用自签名证书 | 使用域名`self.wujing.site`访问
10 | Daemonset 使用自签名证书+NodePort |  使用`ip:30443`访问
11 | Daemonset 使用自签名证书+HostPort |  使用`ip:10443`访问


8. 配置域名映射

- 自签名部署方式: `self.wujing.site`（nginx节点IP映射到域名）

- rancher默认ca: `ca.wujing.site` （集群任意节点IP映射到域名）

- Let's Encrypt: `let.wujing.site`（集群任意节点IP映射到域名）

9. 访问企业版(登录密码为bootstrapPassword设置的密码)

10. 设置审计日志

```
http://rancher-auditlog-server.cattle-system:9000
```

11. 检查内容

- 可以部署成功，能够通过UI访问

- 检查证书是否正确

- 导入集群，确认集群可以active
