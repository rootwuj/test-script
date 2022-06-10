#!/bin/bash

# ========== 使用方法 ===========

# ./4-nginx.sh  172.1.2.xx 172.1.2.xx 172.1.2.xx

# ==============================

# 传入3个节点的内网IP
HOST_1=$1
HOST_2=$2
HOST_3=$3


curl https://releases.rancher.com/install-docker/19.03.sh | sh

cat>nginx.conf<<EOF
worker_processes 4;
worker_rlimit_nofile 40000;
    
events {
    worker_connections 8192;
}
    
stream {
    upstream rancher_servers_http {
        least_conn;
        server $HOST_1:80 max_fails=3 fail_timeout=5s;
        server $HOST_2:80 max_fails=3 fail_timeout=5s;
        server $HOST_3:80 max_fails=3 fail_timeout=5s;
    }
    server {
        listen     80;
        proxy_pass rancher_servers_http;
    }
    
    upstream rancher_servers_https {
        least_conn;
        server $HOST_1:443 max_fails=3 fail_timeout=5s;
        server $HOST_2:443 max_fails=3 fail_timeout=5s;
        server $HOST_3:443 max_fails=3 fail_timeout=5s;
    }
    server {
        listen     443;
        proxy_pass rancher_servers_https;
    }
}
EOF

docker run -d --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  -v /root/nginx.conf:/etc/nginx/nginx.conf \
  nginx

