#!/bin/bash

# ========== 使用方法 ===========

# ./redeploy.sh $rke $chart $version $tpye
# ./redeploy.sh rke6 pandaria-rc v2.6.5-ent-rc4 3

# 前置条件：
# 已经存在HA环境，此脚本为删除重建的过程
# 在ca下有hatest的域名证书
# 在ca-local下有localhost证书

# ==============================

rke=$1 # rke的版本，输入rke名称
chart=$2 # 2.5:pandaria，2.6的rc：pandaria-rc，2.6的正式版本：pandaria-stabel
version=$3 # 企业版版本：v2.6.5-ent-rc5
type=$4 # 部署rancher的方式

: "
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
"



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
		# deployment 使用自签名证书：部署成功，可以通过域名访问

		funCaDomain

		sudo su -c '
		helm install rancher '$chart'/rancher \
		  --namespace cattle-system \
		  --set hostname=hatest.wujing.site \
		  --set ingress.tls.source=secret \
		  --set privateCA=true \
		  --version '$version'
		'

		echo 'deployment 使用自签名证书，通过 hatest.wujing.site 域名访问'

    ;;
    2)  
		# deployment 使用自签名证书+NodePort：部署成功，可以通过30443端口访问

		funCaLocalhost

		sudo su -c '
		helm install rancher '$chart'/rancher \
		  --namespace cattle-system \
		  --set service.type=NodePort \
		  --set service.ports.nodePort=30443  \
		  --set ingress.tls.source=secret \
		  --set privateCA=true \
		  --version '$version'
		'

		echo 'deployment 使用自签名证书+NodePort，可以通过30443端口访问'


    ;;
    3)  
		# deployment 使用默认 CA ：部署成功，可以通过域名访问

		funCertManager

		sudo su -c '
		helm install rancher '$chart'/rancher \
		  --namespace cattle-system \
		    --namespace cattle-system \
		    --set hostname=ha.wujing.site \
		  --version '$version'
		'

		echo 'deployment 使用默认 CA，可以通过域名 ha.wujing.site 访问'

    ;;
    4)  

		# deployment 使用默认 CA + NodePort

		funCertManager

		sudo su -c '
		helm install rancher '$chart'/rancher \
		  --namespace cattle-system \
		    --namespace cattle-system \
		    --set hostname=ha.wujing.site \
		  --version '$version'
		'

		echo 'deployment 使用默认 CA，可以通过域名 ha.wujing.site 访问'


    ;;
    5)  






    ;;
    6)  






    ;;
    7)  






    ;;
    8)  






    ;;
    9)  






    ;;
    10)  






    ;;
    11)  






    ;;
    *)  echo '你没有输入正确的部署方式代码'
    ;;
esac





