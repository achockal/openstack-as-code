#!/usr/bin/env bash

P3_PROJECT=${1:-rtpplay}
BASTION_IP=${2:-64.102.181.58}
IP_FILE=$P3_PROJECT.txt

if [ ! -f ../config/${P3_PROJECT}.sh ]; then
    # Oops, something went wrong
    echo "The value provided for P3_PROJECT (${P3_PROJECT}) is invalid!"
    exit 25
fi
source ../config/${P3_PROJECT}.sh

for host in $(cat $IP_FILE) 
do
    scp -o ProxyCommand="ssh ubuntu@${BASTION_IP} nc %h %p" authorized_keys.slim ubuntu@$host:.ssh/authorized_keys
done
