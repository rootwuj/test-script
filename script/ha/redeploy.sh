#!/bin/bash

# ========== 使用方法 ===========

# ./redeploy.sh $rke $chart $version $tpye
# ./redeploy.sh rke6 pandaria-rc v2.6.5-ent-rc4 3 172.x.x.x

# ==============================

rke=$1 # rke的版本，输入rke名称
chart=$2 # 2.5:pandaria，2.6的rc：pandaria-rc，2.6的正式版本：pandaria-stabel
version=$3 # 企业版版本：v2.6.5-ent-rc5
type=$4 # 部署rancher的方式
dbhost=$5 # 数据库IP


# 卸载rke集群
echo y | ./$rke remove --config cluster.yml

echo '================成功删除集群================'

# 重新部署rke集群
./$rke up

echo '================集群部署完成================'

sudo su -c 'rm -rf /root/.kube/config'
sudo su -c 'cp /home/ubuntu/kube_config_cluster.yml /root/.kube/config'



funCaDomain(){
	# 设置ca证书 域名
	sudo su -c 'kubectl create namespace cattle-system'
	sudo su -c 'kubectl -n cattle-system create secret tls tls-rancher-ingress --cert=/root/ca/tls.crt --key=/root/ca/tls.key'
	sudo su -c 'kubectl -n cattle-system create secret generic tls-ca --from-file=/root/ca/cacerts.pem'

	sudo su -c 'helm repo update'

}

funCaLocalhost(){
	# 设置ca证书 localhost
	sudo su -c 'kubectl create namespace cattle-system'
	sudo su -c 'kubectl -n cattle-system create secret tls tls-rancher-ingress --cert=/root/ca-local/tls.crt --key=/root/ca-local/tls.key'
	sudo su -c 'kubectl -n cattle-system create secret generic tls-ca --from-file=/root/ca-local/cacerts.pem'

	sudo su -c 'helm repo update'
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
	sudo su -c 'kubectl create namespace cattle-system'
	sudo su -c 'kubectl get pods --namespace cert-manager'

}



# 部署rancher

case $type in
    1)  
		# 1. deployment 使用自签名证书：部署成功，可以通过域名访问

		funCaDomain

		sudo su -c '
		helm install rancher '$chart'/rancher \
		  --namespace cattle-system \
		  --set hostname=hatest.wujing.site \
		  --set ingress.tls.source=secret \
		  --set privateCA=true \
		  --set bootstrapPassword=Rancher@123456 \
		  --set auditLogServer.serverPort=9000 \
    	  --set auditLog.destination=server \
    	  --set auditLog.level=3 \
    	  --set auditLogServer.DBHost='$dbhost' \
    	  --set auditLogServer.DBPort=3306 \
    	  --set auditLogServer.DBUser=root \
    	  --set auditLogServer.DBPassword=Rancher@123 \
    	  --set auditLogServer.DBName=rancher \
    	  --set auditLogServer.DBTimeout=5m \
    	  --set auditLogServer.DBReadTimeout=5m \
    	  --set auditLogServer.archive.type=day\
    	  --set auditLogServer.archive.cronType=server \
    	  --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
		  --version '$version'
		'

		echo 'deployment 使用自签名证书，通过 hatest.wujing.site 域名访问'

    ;;
    2)  
		# 2. deployment 使用自签名证书+NodePort：部署成功，可以通过30443端口访问

		funCaLocalhost

		sudo su -c '
		helm install rancher '$chart'/rancher \
		  --namespace cattle-system \
		  --set service.type=NodePort \
		  --set service.ports.nodePort=30443  \
		  --set ingress.tls.source=secret \
		  --set privateCA=true \
		  --set bootstrapPassword=Rancher@123456 \
		  --set auditLogServer.serverPort=9000 \
    	  --set auditLog.destination=server \
    	  --set auditLog.level=3 \
    	  --set auditLogServer.DBHost='$dbhost' \
    	  --set auditLogServer.DBPort=3306 \
    	  --set auditLogServer.DBUser=root \
    	  --set auditLogServer.DBPassword=Rancher@123 \
    	  --set auditLogServer.DBName=rancher \
    	  --set auditLogServer.DBTimeout=5m \
    	  --set auditLogServer.DBReadTimeout=5m \
    	  --set auditLogServer.archive.type=week\
    	  --set auditLogServer.archive.cronType=server \
    	  --set auditLogServer.archive.cronSpec="0 */1 * * * ?" \
		  --version '$version'
		'

		echo 'deployment 使用自签名证书+NodePort，可以通过30443端口访问'


    ;;
    3)  
		# 3. deployment 使用默认 CA ：部署成功，可以通过域名访问

		funCertManager

		sudo su -c '
		helm install rancher '$chart'/rancher \
		  --namespace cattle-system \
		  --set hostname=ha.wujing.site \
		  --set bootstrapPassword=Rancher@123456 \
		  --set auditLogServer.serverPort=9000 \
    	  --set auditLog.destination=server \
    	  --set auditLog.level=3 \
    	  --set auditLogServer.DBHost='$dbhost' \
    	  --set auditLogServer.DBPort=3306 \
    	  --set auditLogServer.DBUser=root \
    	  --set auditLogServer.DBPassword=Rancher@123 \
    	  --set auditLogServer.DBName=rancher \
    	  --set auditLogServer.DBTimeout=5m \
    	  --set auditLogServer.DBReadTimeout=5m \
    	  --set auditLogServer.archive.type=month\
    	  --set auditLogServer.archive.cronType=server \
    	  --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
		  --version '$version'
		'

		echo 'deployment 使用默认 CA，可以通过域名 ha.wujing.site 访问'

    ;;
    4)  

		# 4. deployment 使用默认 CA + NodePort：部署成功，可以通过30443端口访问

		funCertManager

		sudo su -c '
		helm install rancher '$chart'/rancher \
          --namespace cattle-system \
          --set service.type=NodePort \
		  --set bootstrapPassword=Rancher@123456 \
		  --set auditLogServer.serverPort=9000 \
    	  --set auditLog.destination=server \
    	  --set auditLog.level=3 \
    	  --set auditLogServer.DBHost='$dbhost' \
    	  --set auditLogServer.DBPort=3306 \
    	  --set auditLogServer.DBUser=root \
    	  --set auditLogServer.DBPassword=Rancher@123 \
    	  --set auditLogServer.DBName=rancher \
    	  --set auditLogServer.DBTimeout=5m \
    	  --set auditLogServer.DBReadTimeout=5m \
    	  --set auditLogServer.archive.type=quarter\
    	  --set auditLogServer.archive.cronType=server \
    	  --set auditLogServer.archive.cronSpec="0 */10 * * * ?" \
		  --version '$version'
		'

		echo 'deployment 使用默认 CA + NodePort：部署成功，可以通过30443端口访问'


    ;;
    5)  

		# 5. deployment 使用Let's Encrypt证书：部署成功，可以通过域名访问

		funCertManager

		sudo su -c '
		helm install rancher '$chart'/rancher \
  		  --namespace cattle-system \
  		  --set hostname=perf.wujing.site \
  		  --set bootstrapPassword=admin \
  		  --set ingress.tls.source=letsEncrypt \
  		  --set letsEncrypt.email=me@example.org \
  		  --set letsEncrypt.ingress.class=nginx \
		  --set bootstrapPassword=Rancher@123456 \
		  --set auditLogServer.serverPort=9000 \
    	  --set auditLog.destination=server \
    	  --set auditLog.level=3 \
    	  --set auditLogServer.DBHost='$dbhost' \
    	  --set auditLogServer.DBPort=3306 \
    	  --set auditLogServer.DBUser=root \
    	  --set auditLogServer.DBPassword=Rancher@123 \
    	  --set auditLogServer.DBName=rancher \
    	  --set auditLogServer.DBTimeout=5m \
    	  --set auditLogServer.DBReadTimeout=5m \
    	  --set auditLogServer.archive.type=day\
    	  --set auditLogServer.archive.cronType=mysql \
    	  --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
		  --version '$version'
		'

		echo 'deployment 使用Lets Encrypt证书：部署成功，可以通过域名访问'



    ;;
    6)  

		# 6. DaemonSet 使用默认 CA：部署成功，可以通过域名访问

		funCertManager

		sudo su -c '
		helm install rancher '$chart'/rancher \
    	  --namespace cattle-system \
    	  --set hostname=ha.wujing.site \
    	  --set rancherDeployType=DaemonSet \
		  --set bootstrapPassword=Rancher@123456 \
		  --set auditLogServer.serverPort=9000 \
    	  --set auditLog.destination=server \
    	  --set auditLog.level=3 \
    	  --set auditLogServer.DBHost='$dbhost' \
    	  --set auditLogServer.DBPort=3306 \
    	  --set auditLogServer.DBUser=root \
    	  --set auditLogServer.DBPassword=Rancher@123 \
    	  --set auditLogServer.DBName=rancher \
    	  --set auditLogServer.DBTimeout=5m \
    	  --set auditLogServer.DBReadTimeout=5m \
    	  --set auditLogServer.archive.type=week\
    	  --set auditLogServer.archive.cronType=mysql \
    	  --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
		  --version '$version'
		'

		echo 'DaemonSet 使用默认 CA：部署成功，可以通过域名访问'


    ;;
    7)  

		# 7. DaemonSet使用默认 CA+NodePort：部署成功，可以通过30443端口访问

		funCertManager

		sudo su -c '
		helm install rancher '$chart'/rancher \
    	  --namespace cattle-system \
    	  --set service.type=NodePort \
    	  --set rancherDeployType=DaemonSet \
		  --set bootstrapPassword=Rancher@123456 \
		  --set auditLogServer.serverPort=9000 \
    	  --set auditLog.destination=server \
    	  --set auditLog.level=3 \
    	  --set auditLogServer.DBHost='$dbhost' \
    	  --set auditLogServer.DBPort=3306 \
    	  --set auditLogServer.DBUser=root \
    	  --set auditLogServer.DBPassword=Rancher@123 \
    	  --set auditLogServer.DBName=rancher \
    	  --set auditLogServer.DBTimeout=5m \
    	  --set auditLogServer.DBReadTimeout=5m \
    	  --set auditLogServer.archive.type=month\
    	  --set auditLogServer.archive.cronType=mysql \
    	  --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
		  --version '$version'
		'

		echo 'DaemonSet使用默认 CA+NodePort：部署成功，可以通过30443端口访问'

    ;;
    8)  

		# 8. DaemonSet 使用默认 CA+HostPort：部署成功，可以通过10443端口访问

		funCertManager

		sudo su -c '
		helm install rancher '$chart'/rancher \
    	  --namespace cattle-system \
    	  --set service.type=HostPort \
    	  --set rancherDeployType=DaemonSet \
		  --set bootstrapPassword=Rancher@123456 \
		  --set auditLogServer.serverPort=9000 \
    	  --set auditLog.destination=server \
    	  --set auditLog.level=3 \
    	  --set auditLogServer.DBHost='$dbhost' \
    	  --set auditLogServer.DBPort=3306 \
    	  --set auditLogServer.DBUser=root \
    	  --set auditLogServer.DBPassword=Rancher@123 \
    	  --set auditLogServer.DBName=rancher \
    	  --set auditLogServer.DBTimeout=5m \
    	  --set auditLogServer.DBReadTimeout=5m \
    	  --set auditLogServer.archive.type=quarter\
    	  --set auditLogServer.archive.cronType=mysql \
    	  --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
		  --version '$version'
		'

		echo 'DaemonSet 使用默认 CA+HostPort：部署成功，可以通过10443端口访问'

    ;;
    9)  

		# 9. DaemonSet 使用自签名证书：部署成功，可以通过域名访问

		funCaDomain

		sudo su -c '
		helm install rancher '$chart'/rancher \
    	  --namespace cattle-system \
    	  --set hostname=hatest.wujing.site \
    	  --set ingress.tls.source=secret \
    	  --set privateCA=true \
    	  --set rancherDeployType=DaemonSet \
		  --set bootstrapPassword=Rancher@123456 \
		  --set auditLogServer.serverPort=9000 \
    	  --set auditLog.destination=server \
    	  --set auditLog.level=3 \
    	  --set auditLogServer.DBHost='$dbhost' \
    	  --set auditLogServer.DBPort=3306 \
    	  --set auditLogServer.DBUser=root \
    	  --set auditLogServer.DBPassword=Rancher@123 \
    	  --set auditLogServer.DBName=rancher \
    	  --set auditLogServer.DBTimeout=5m \
    	  --set auditLogServer.DBReadTimeout=5m \
    	  --set auditLogServer.archive.type=day\
    	  --set auditLogServer.archive.cronType=server \
    	  --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
		  --version '$version'
		'

		echo 'DaemonSet 使用自签名证书：部署成功，可以通过域名访问'

    ;;
    10)  

		# 10. DaemonSet 使用自签名证书+NodePort：部署成功，可以通过30443端口访问

		funCaLocalhost

		sudo su -c '
		helm install rancher '$chart'/rancher \
    	  --namespace cattle-system \
		  --set service.type=NodePort \
    	  --set ingress.tls.source=secret \
    	  --set privateCA=true \
    	  --set rancherDeployType=DaemonSet \
		  --set auditLogServer.serverPort=9000 \
    	  --set auditLog.destination=server \
    	  --set auditLog.level=3 \
    	  --set auditLogServer.DBHost='$dbhost' \
    	  --set auditLogServer.DBPort=3306 \
    	  --set auditLogServer.DBUser=root \
    	  --set auditLogServer.DBPassword=Rancher@123 \
    	  --set auditLogServer.DBName=rancher \
    	  --set auditLogServer.DBTimeout=5m \
    	  --set auditLogServer.DBReadTimeout=5m \
    	  --set auditLogServer.archive.type=day\
    	  --set auditLogServer.archive.cronType=server \
    	  --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
		  --version '$version'
		'

		echo 'DaemonSet 使用自签名证书+NodePort：部署成功，可以通过30443端口访问'

    ;;
    11)  

		# 11. DaemonSet 使用自签名证书+HostPort：部署成功，可以通过10443端口访问

		funCaLocalhost

		sudo su -c '
		helm install rancher '$chart'/rancher \
    	  --namespace cattle-system \
		  --set service.type=HostPort \
    	  --set ingress.tls.source=secret \
    	  --set privateCA=true \
          --set rancherDeployType=DaemonSet \
		  --set auditLogServer.serverPort=9000 \
    	  --set auditLog.destination=server \
    	  --set auditLog.level=3 \
    	  --set auditLogServer.DBHost='$dbhost' \
    	  --set auditLogServer.DBPort=3306 \
    	  --set auditLogServer.DBUser=root \
    	  --set auditLogServer.DBPassword=Rancher@123 \
    	  --set auditLogServer.DBName=rancher \
    	  --set auditLogServer.DBTimeout=5m \
    	  --set auditLogServer.DBReadTimeout=5m \
    	  --set auditLogServer.archive.type=day\
    	  --set auditLogServer.archive.cronType=server \
    	  --set auditLogServer.archive.cronSpec="0 */5 * * * ?" \
		  --version '$version'
		'

		echo 'DaemonSet 使用自签名证书+HostPort：部署成功，可以通过10443端口访问'

    ;;
    *)  echo '你没有输入正确的部署方式代码，请参考readme输入'
    ;;
esac





