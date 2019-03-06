#!/usr/bin/env bash

P3_PROJECT="${1:-rtpplay}"

if [ ! -f ../config/${P3_PROJECT}.sh ]; then
    # Oops, something went wrong
    echo "The value provided for P3_PROJECT (${P3_PROJECT}) is invalid!"
    exit 25
fi
source ../config/${P3_PROJECT}.sh

openstack server list -f csv | awk -F'","' '{print $4}' | cut -d'=' -f 2 | cut -d',' -f 1 | grep -v 'Networks' | tee ./${P3_PROJECT}.txt
