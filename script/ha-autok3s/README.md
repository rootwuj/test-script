# 脚本使用方法

## 在autok3s中创建k3s的HA集群

在`k3s options`中 `enable cluster`，`master`设置为3个节点。其他配置和单节点设置相同。

## 在集群中部署企业版
```
# 在root用户下执行

# 如果使用自签名证书部署，需要先生成证书
# ./0-ca.sh 172.1.2.xx,172.1.2.xx,172.1.2.xx

# 部署企业版
./ha-autok3s.sh pandaria-stable v2.6.5-ent 172.1.1.1 3

```

## 在另外两个节点Pull镜像
```
PANDARIA_VERSION=""

# 设置docker login
docker login -u xxx -p xxx
# 设置要测试的版本
docker pull cnrancher/rancher:$PANDARIA_VERSION

```

## 访问企业版

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
