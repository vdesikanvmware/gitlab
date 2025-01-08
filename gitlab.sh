#!/usr/bin/env bash

set -meuo pipefail

mkdir -p /home/kubo/gitlab
export GITLAB_HOME=/home/kubo/gitlab
export TEST_DOMAIN='tanzu.io'
export LOCAL_IP_ADDRESS=$(/sbin/ip -o -4 addr list eth1 | awk '{print $4}' | cut -d/ -f1)
cd

wait_for_gitlab_container_to_be_healthy(){
    while :; do
    IS_GITLAB_HEALTHY=$(docker ps | grep gitlab | grep healthy | wc -l || :)
    if [[ $IS_GITLAB_HEALTHY == "1"  ]]; then
        break
    else
        echo "Waiting 30 seconds for gitlab container to be ready"
        sleep 30
    fi
    done
}

docker run --detach   --hostname gitlab.tanzu.io --name gitlab --publish 445:443 \
      --publish 85:80   --restart always   --volume $GITLAB_HOME/config:/etc/gitlab \
      --volume $GITLAB_HOME/logs:/var/log/gitlab --volume $GITLAB_HOME/data:/var/opt/gitlab \
      --shm-size 256m quay.io/tpapps/gitlab:latest

wait_for_gitlab_container_to_be_healthy

sudo mkdir  -p $GITLAB_HOME/config/ssl
sudo chmod 755 $GITLAB_HOME/config/ssl
sudo cp /home/kubo/certs/ca.crt /home/kubo/certs/ca.key  $GITLAB_HOME/config/ssl/

sudo cat <<EOT | sudo tee -a $GITLAB_HOME/config/gitlab.rb
external_url "https://gitlab.tanzu.io"
nginx['redirect_http_to_https'] = true
nginx['ssl_certificate'] = "/etc/gitlab/ssl/ca.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/ca.key" 
letsencrypt['enable'] = false
EOT

docker restart gitlab
wait_for_gitlab_container_to_be_healthy

echo 'configure DNS for gitlab'
cat <<-EOF | nsupdate -k /etc/bind/externaldns-key.key
server 127.0.0.1 5353
zone ${TEST_DOMAIN}
update add gitlab.${TEST_DOMAIN} 604800 A ${LOCAL_IP_ADDRESS}
send
quit
EOF

# Copying gitlab root password to airgap_jumper VM
docker exec -t gitlab grep 'Password:' /etc/gitlab/initial_root_password | tee -a /home/kubo/gitlab_root_password
