#!/bin/bash

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
        server <IP_NODE_1>:80 max_fails=3 fail_timeout=5s;
        server <IP_NODE_2>:80 max_fails=3 fail_timeout=5s;
        server <IP_NODE_3>:80 max_fails=3 fail_timeout=5s;
    }
    server {
        listen     80;
        proxy_pass rancher_servers_http;
    }
    
    upstream rancher_servers_https {
        least_conn;
        server <IP_NODE_1>:443 max_fails=3 fail_timeout=5s;
        server <IP_NODE_2>:443 max_fails=3 fail_timeout=5s;
        server <IP_NODE_3>:443 max_fails=3 fail_timeout=5s;
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

