#!/bin/bash

# ========== 使用方法 ===========

# ./5-ha-redeploy.sh rke6 pandaria-stable v2.6.5-ent 172.1.1.1 3

# ==============================

# 传入参数参考README.md
RKE_NAME=$1 # 输入集群环境中rke的名称，例如：rke6
CHART_NAME=$2 # 输入chart名称 - 2.5:pandaria，- 2.6的rc版：pandaria-rc，- 2.6的正式版本：pandaria-stable
PANDARIA_VERSION=$3 # 企业版版本 例如：v2.6.5-ent
DB_HOST=$4 # 数据库内网IP
DEPLOY_METHOD=$5 # HA部署方式 例如：3

# 卸载rke集群
echo y | ./$RKE_NAME remove --config cluster.yml

echo '================成功删除集群================'

# 重新部署rke集群
./$RKE_NAME up

echo '================集群部署完成================'

sudo su -c 'rm -rf /root/.kube/config'
sudo su -c 'cp /home/ubuntu/kube_config_cluster.yml /root/.kube/config'

sudo su -c 'helm repo update'
sudo su -c 'kubectl create namespace cattle-system'


funCaDomain(){
  # 设置ca证书 域名
  sudo su -c 'kubectl -n cattle-system create secret tls tls-rancher-ingress --cert=/root/ca/tls.crt --key=/root/ca/tls.key' # ca位置根据实际情况修改
  sudo su -c 'kubectl -n cattle-system create secret generic tls-ca --from-file=/root/ca/cacerts.pem' # ca位置根据实际情况修改

  echo '=============这里会等待1分钟============='

  sleep 60

}

funCaLocalhost(){
  # 设置ca证书 localhost
  sudo su -c 'kubectl -n cattle-system create secret tls tls-rancher-ingress --cert=/root/ca-local/tls.crt --key=/root/ca-local/tls.key' # ca位置根据实际情况修改
  sudo su -c 'kubectl -n cattle-system create secret generic tls-ca --from-file=/root/ca-local/cacerts.pem' # ca位置根据实际情况修改

}

funCertManager(){

  # 部署certmanager
  sudo su -c 'kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.7.1/cert-manager.crds.yaml'
  sudo su -c 'helm repo add jetstack https://charts.jetstack.io'
  sudo su -c 'helm repo update'
  sudo su -c 'helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version v1.7.1'
  sudo su -c 'kubectl get pods --namespace cert-manager'

}



# 部署rancher

case $DEPLOY_METHOD in
    1)  
    # 1. deployment 使用自签名证书：部署成功，可以通过域名访问

    funCaDomain

    sudo su -c '
    helm install rancher '$CHART_NAME'/rancher \
      --namespace cattle-system \
      --set hostname=self.wujing.site \
      --set ingress.tls.source=secret \
      --set privateCA=true \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost='$DB_HOST' \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=day\
      --set auditLogServer.archive.cronType=server \
      --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
      --version '$PANDARIA_VERSION'
    '

    echo 'deployment 使用自签名证书，通过 self.wujing.site 域名访问'

    ;;
    2)  
    # 2. deployment 使用自签名证书+NodePort：部署成功，可以通过30443端口访问

    funCaLocalhost

    sudo su -c '
    helm install rancher '$CHART_NAME'/rancher \
      --namespace cattle-system \
      --set service.type=NodePort \
      --set service.ports.nodePort=30443  \
      --set ingress.tls.source=secret \
      --set privateCA=true \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost='$DB_HOST' \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=week\
      --set auditLogServer.archive.cronType=server \
      --set auditLogServer.archive.cronSpec="0 */1 * * * ?" \
      --version '$PANDARIA_VERSION'
    '

    echo 'deployment 使用自签名证书+NodePort，可以通过30443端口访问'


    ;;
    3)  
    # 3. deployment 使用默认 CA ：部署成功，可以通过域名访问

    funCertManager

    sudo su -c '
    helm install rancher '$CHART_NAME'/rancher \
      --namespace cattle-system \
      --set hostname=ca.wujing.site \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost='$DB_HOST' \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=month\
      --set auditLogServer.archive.cronType=server \
      --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
      --version '$PANDARIA_VERSION'
    '

    echo 'deployment 使用默认 CA，可以通过域名 ca.wujing.site 访问'

    ;;
    4)  

    # 4. deployment 使用默认 CA + NodePort：部署成功，可以通过30443端口访问

    funCertManager

    sudo su -c '
    helm install rancher '$CHART_NAME'/rancher \
      --namespace cattle-system \
      --set service.type=NodePort \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost='$DB_HOST' \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=quarter\
      --set auditLogServer.archive.cronType=server \
      --set auditLogServer.archive.cronSpec="0 */10 * * * ?" \
      --version '$PANDARIA_VERSION'
    '

    echo 'deployment 使用默认 CA + NodePort：部署成功，可以通过30443端口访问'


    ;;
    5)  

    # 5. deployment 使用Let's Encrypt证书：部署成功，可以通过域名访问

    funCertManager

    sudo su -c '
    helm install rancher '$CHART_NAME'/rancher \
      --namespace cattle-system \
      --set hostname=let.wujing.site \
      --set ingress.tls.source=letsEncrypt \
      --set letsEncrypt.email=me@example.org \
      --set letsEncrypt.ingress.class=nginx \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost='$DB_HOST' \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=day\
      --set auditLogServer.archive.cronType=mysql \
      --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
      --version '$PANDARIA_VERSION'
    '

    echo 'deployment 使用Lets Encrypt证书：部署成功，可以通过 let.wujing.site 访问'



    ;;
    6)  

    # 6. DaemonSet 使用默认 CA：部署成功，可以通过域名访问

    funCertManager

    sudo su -c '
    helm install rancher '$CHART_NAME'/rancher \
      --namespace cattle-system \
      --set hostname=ca.wujing.site \
      --set rancherDeployType=DaemonSet \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost='$DB_HOST' \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=week\
      --set auditLogServer.archive.cronType=mysql \
      --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
      --version '$PANDARIA_VERSION'
    '

    echo 'DaemonSet 使用默认 CA：部署成功，可以通过域名 ca.wujing.site 访问'


    ;;
    7)  

    # 7. DaemonSet使用默认 CA+NodePort：部署成功，可以通过30443端口访问

    funCertManager

    sudo su -c '
    helm install rancher '$CHART_NAME'/rancher \
      --namespace cattle-system \
      --set service.type=NodePort \
      --set rancherDeployType=DaemonSet \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost='$DB_HOST' \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=month\
      --set auditLogServer.archive.cronType=mysql \
      --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
      --version '$PANDARIA_VERSION'
    '

    echo 'DaemonSet使用默认 CA+NodePort：部署成功，可以通过30443端口访问'

    ;;
    8)  

    # 8. DaemonSet 使用默认 CA+HostPort：部署成功，可以通过10443端口访问

    funCertManager

    sudo su -c '
    helm install rancher '$CHART_NAME'/rancher \
      --namespace cattle-system \
      --set service.type=HostPort \
      --set rancherDeployType=DaemonSet \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost='$DB_HOST' \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=quarter\
      --set auditLogServer.archive.cronType=mysql \
      --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
      --version '$PANDARIA_VERSION'
    '

    echo 'DaemonSet 使用默认 CA+HostPort：部署成功，可以通过10443端口访问'

    ;;
    9)  

    # 9. DaemonSet 使用自签名证书：部署成功，可以通过域名访问

    funCaDomain

    sudo su -c '
    helm install rancher '$CHART_NAME'/rancher \
      --namespace cattle-system \
      --set hostname=self.wujing.site \
      --set ingress.tls.source=secret \
      --set privateCA=true \
      --set rancherDeployType=DaemonSet \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost='$DB_HOST' \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=day\
      --set auditLogServer.archive.cronType=server \
      --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
      --version '$PANDARIA_VERSION'
    '

    echo 'DaemonSet 使用自签名证书：部署成功，可以通过域名 self.wujing.site  访问'

    ;;
    10)  

    # 10. DaemonSet 使用自签名证书+NodePort：部署成功，可以通过30443端口访问

    funCaLocalhost

    sudo su -c '
    helm install rancher '$CHART_NAME'/rancher \
      --namespace cattle-system \
      --set service.type=NodePort \
      --set ingress.tls.source=secret \
      --set privateCA=true \
      --set rancherDeployType=DaemonSet \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost='$DB_HOST' \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=day\
      --set auditLogServer.archive.cronType=server \
      --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
      --version '$PANDARIA_VERSION'
    '

    echo 'DaemonSet 使用自签名证书+NodePort：部署成功，可以通过30443端口访问'

    ;;
    11)  

    # 11. DaemonSet 使用自签名证书+HostPort：部署成功，可以通过10443端口访问

    funCaLocalhost

    sudo su -c '
    helm install rancher '$CHART_NAME'/rancher \
      --namespace cattle-system \
      --set service.type=HostPort \
      --set ingress.tls.source=secret \
      --set privateCA=true \
      --set rancherDeployType=DaemonSet \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost='$DB_HOST' \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=day\
      --set auditLogServer.archive.cronType=server \
      --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
      --version '$PANDARIA_VERSION'
    '

    echo 'DaemonSet 使用自签名证书+HostPort：部署成功，可以通过10443端口访问'

    ;;
    *)  echo 'ERROR: 你没有输入正确的部署方式代码，请参考 README.md 传参说明输入'
    ;;
esac




