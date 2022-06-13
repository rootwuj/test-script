#!/bin/bash

# ========== 使用方法 ===========

# ./ha-autok3s.sh pandaria-stable v2.6.5-ent 172.1.1.1 3

# ==============================

# 传入参数参考README.md
CHART_NAME=$1 # 输入chart名称 - 2.5:pandaria，- 2.6的rc版：pandaria-rc，- 2.6的正式版本：pandaria-stable
PANDARIA_VERSION=$2 # 企业版版本 例如：v2.6.5-ent
DB_HOST=$3 # 数据库内网IP
DEPLOY_METHOD=$4 # HA部署方式 例如：3


# 设置docker login
docker login -u xxx -p xxx
# 设置要测试的版本
docker pull cnrancher/rancher:$PANDARIA_VERSION

# helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

helm repo add pandaria http://pandaria-releases.cnrancher.com/server-charts/latest
helm repo add pandaria-rc http://pandaria-releases.cnrancher.com/2.6-charts/dev
helm repo add pandaria-stable http://pandaria-releases.cnrancher.com/2.6-charts/latest
helm repo update

kubectl create namespace cattle-system

funCaDomain(){
  # 设置ca证书 域名
   kubectl -n cattle-system create secret tls tls-rancher-ingress --cert=/root/ca/tls.crt --key=/root/ca/tls.key # ca位置根据实际情况修改
   kubectl -n cattle-system create secret generic tls-ca --from-file=/root/ca/cacerts.pem # ca位置根据实际情况修改

}

funCaLocalhost(){
  # 设置ca证书 localhost
   kubectl -n cattle-system create secret tls tls-rancher-ingress --cert=/root/ca-local/tls.crt --key=/root/ca-local/tls.key # ca位置根据实际情况修改
   kubectl -n cattle-system create secret generic tls-ca --from-file=/root/ca-local/cacerts.pem # ca位置根据实际情况修改

}

funCertManager(){

  # 部署certmanager
   kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.7.1/cert-manager.crds.yaml
   helm repo add jetstack https://charts.jetstack.io
   helm repo update
   helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version v1.7.1
   kubectl create namespace cattle-system
   kubectl get pods --namespace cert-manager

}



# 部署rancher

case $DEPLOY_METHOD in
    1)  
    # 1. deployment 使用自签名证书：部署成功，可以通过域名访问

    funCaDomain

     
    helm install rancher $CHART_NAME/rancher \
      --namespace cattle-system \
      --set hostname=self.wujing.site \
      --set ingress.tls.source=secret \
      --set privateCA=true \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost=$DB_HOST \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=day\
      --set auditLogServer.archive.cronType=server \
      --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
      --version $PANDARIA_VERSION
    

    echo  'deployment 使用自签名证书，通过 self.wujing.site 域名访问 '

    ;;
    2)  
    # 2. deployment 使用自签名证书+NodePort：部署成功，可以通过30443端口访问

    funCaLocalhost

     
    helm install rancher  $CHART_NAME/rancher \
      --namespace cattle-system \
      --set service.type=NodePort \
      --set service.ports.nodePort=30443  \
      --set ingress.tls.source=secret \
      --set privateCA=true \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost=$DB_HOST  \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=week\
      --set auditLogServer.archive.cronType=server \
      --set auditLogServer.archive.cronSpec="0 */1 * * * ?" \
      --version  $PANDARIA_VERSION 
     

    echo  'deployment 使用自签名证书+NodePort，可以通过30443端口访问 '


    ;;
    3)  
    # 3. deployment 使用默认 CA ：部署成功，可以通过域名访问

    funCertManager

     
    helm install rancher  $CHART_NAME/rancher \
      --namespace cattle-system \
      --set hostname=ca.wujing.site \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost=$DB_HOST  \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=month\
      --set auditLogServer.archive.cronType=server \
      --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
      --version  $PANDARIA_VERSION 
     

    echo  'deployment 使用默认 CA，可以通过域名 ca.wujing.site 访问 '

    ;;
    4)  

    # 4. deployment 使用默认 CA + NodePort：部署成功，可以通过30443端口访问

    funCertManager

     
    helm install rancher  $CHART_NAME/rancher \
      --namespace cattle-system \
      --set service.type=NodePort \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost=$DB_HOST  \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=quarter\
      --set auditLogServer.archive.cronType=server \
      --set auditLogServer.archive.cronSpec="0 */10 * * * ?" \
      --version  $PANDARIA_VERSION 
     

    echo  'deployment 使用默认 CA + NodePort：部署成功，可以通过30443端口访问 '


    ;;
    5)  

    # 5. deployment 使用Let s Encrypt证书：部署成功，可以通过域名访问

    funCertManager

     
    helm install rancher  $CHART_NAME/rancher \
      --namespace cattle-system \
      --set hostname=let.wujing.site \
      --set bootstrapPassword=admin \
      --set ingress.tls.source=letsEncrypt \
      --set letsEncrypt.email=me@example.org \
      --set letsEncrypt.ingress.class=nginx \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost=$DB_HOST  \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=day\
      --set auditLogServer.archive.cronType=mysql \
      --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
      --version  $PANDARIA_VERSION 
     

    echo  'deployment 使用Lets Encrypt证书：部署成功，可以通过 let.wujing.site 访问 '



    ;;
    6)  

    # 6. DaemonSet 使用默认 CA：部署成功，可以通过域名访问

    funCertManager

     
    helm install rancher  $CHART_NAME/rancher \
      --namespace cattle-system \
      --set hostname=ca.wujing.site \
      --set rancherDeployType=DaemonSet \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost=$DB_HOST  \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=week\
      --set auditLogServer.archive.cronType=mysql \
      --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
      --version  $PANDARIA_VERSION 
     

    echo  'DaemonSet 使用默认 CA：部署成功，可以通过域名 ca.wujing.site 访问 '


    ;;
    7)  

    # 7. DaemonSet使用默认 CA+NodePort：部署成功，可以通过30443端口访问

    funCertManager

     
    helm install rancher  $CHART_NAME/rancher \
      --namespace cattle-system \
      --set service.type=NodePort \
      --set rancherDeployType=DaemonSet \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost=$DB_HOST  \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=month\
      --set auditLogServer.archive.cronType=mysql \
      --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
      --version  $PANDARIA_VERSION 
     

    echo  'DaemonSet使用默认 CA+NodePort：部署成功，可以通过30443端口访问 '

    ;;
    8)  

    # 8. DaemonSet 使用默认 CA+HostPort：部署成功，可以通过10443端口访问

    funCertManager

     
    helm install rancher  $CHART_NAME/rancher \
      --namespace cattle-system \
      --set service.type=HostPort \
      --set rancherDeployType=DaemonSet \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost=$DB_HOST  \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=quarter\
      --set auditLogServer.archive.cronType=mysql \
      --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
      --version  $PANDARIA_VERSION 
     

    echo  'DaemonSet 使用默认 CA+HostPort：部署成功，可以通过10443端口访问 '

    ;;
    9)  

    # 9. DaemonSet 使用自签名证书：部署成功，可以通过域名访问

    funCaDomain

     
    helm install rancher  $CHART_NAME/rancher \
      --namespace cattle-system \
      --set hostname=self.wujing.site \
      --set ingress.tls.source=secret \
      --set privateCA=true \
      --set rancherDeployType=DaemonSet \
      --set bootstrapPassword=Rancher@123456 \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost=$DB_HOST  \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=day\
      --set auditLogServer.archive.cronType=server \
      --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
      --version  $PANDARIA_VERSION 
     

    echo  'DaemonSet 使用自签名证书：部署成功，可以通过域名 self.wujing.site  访问 '

    ;;
    10)  

    # 10. DaemonSet 使用自签名证书+NodePort：部署成功，可以通过30443端口访问

    funCaLocalhost

     
    helm install rancher  $CHART_NAME/rancher \
      --namespace cattle-system \
      --set service.type=NodePort \
      --set ingress.tls.source=secret \
      --set privateCA=true \
      --set rancherDeployType=DaemonSet \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost=$DB_HOST  \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=day\
      --set auditLogServer.archive.cronType=server \
      --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
      --version  $PANDARIA_VERSION 
     

    echo  'DaemonSet 使用自签名证书+NodePort：部署成功，可以通过30443端口访问 '

    ;;
    11)  

    # 11. DaemonSet 使用自签名证书+HostPort：部署成功，可以通过10443端口访问

    funCaLocalhost

     
    helm install rancher  $CHART_NAME/rancher \
      --namespace cattle-system \
      --set service.type=HostPort \
      --set ingress.tls.source=secret \
      --set privateCA=true \
      --set rancherDeployType=DaemonSet \
      --set auditLogServer.serverPort=9000 \
      --set auditLog.destination=server \
      --set auditLog.level=3 \
      --set auditLogServer.DBHost=$DB_HOST  \
      --set auditLogServer.DBPort=3306 \
      --set auditLogServer.DBUser=root \
      --set auditLogServer.DBPassword=Rancher@123 \
      --set auditLogServer.DBName=rancher \
      --set auditLogServer.DBTimeout=5m \
      --set auditLogServer.DBReadTimeout=5m \
      --set auditLogServer.archive.type=day\
      --set auditLogServer.archive.cronType=server \
      --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
      --version  $PANDARIA_VERSION 
     

    echo 'DaemonSet 使用自签名证书+HostPort：部署成功，可以通过10443端口访问'

    ;;
    *)  echo  'ERROR: 你没有输入正确的部署方式代码，请参考 README.md 传参说明输入 '
    ;;
esac




# rancher lb service

kubectl create -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: rancher
  name: rancher-lb-svc
  namespace: cattle-system
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
  - name: https
    port: 443
    protocol: TCP
    targetPort: 443
  selector:
    app: rancher
  sessionAffinity: None
  type: LoadBalancer
EOF