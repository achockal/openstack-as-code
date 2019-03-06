#!/usr/bin/env bash

P3_PROJECT=${1:-rtpplay}
BASTION_IP=${2:-64.102.181.58}

if [ ! -f ../config/${P3_PROJECT}.sh ]; then
    # Oops, something went wrong
    echo "The value provided for P3_PROJECT (${P3_PROJECT}) is invalid!"
    exit 25
fi
source ../config/${P3_PROJECT}.sh

for host in $(openstack server list -f csv | awk -F'","' '{print $4}' | cut -d'=' -f 2 | cut -d',' -f 1 | grep -v 'Networks') 
do
    scp -o ProxyCommand="ssh ubuntu@${BASTION_IP} nc %h %p" authorized_keys.slim ubuntu@$host:.ssh/authorized_keys
done
