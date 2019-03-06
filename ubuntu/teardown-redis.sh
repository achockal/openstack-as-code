#!/usr/bin/env bash

SUFFIX="${1:-prd}"
P3_PROJECT="${2:-allnpoc}"

echo "About to teardown \"$SUFFIX\" lifecycle in $P3_PROJECT..."
read -p "Should we continue? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Quitting!!"
    exit 1
fi

if [ ! -f ../config/${P3_PROJECT}.sh ]; then
    # Oops, something went wrong
    echo "The value provided for P3_PROJECT (${P3_PROJECT}) is invalid!"
    exit 25
fi
source ../config/${P3_PROJECT}.sh

echo "Deleting the Redis Master and Slave VMs..."
for ms in orca clouddriver others 
do
    echo "Deleting ${ms}-redis-${SUFFIX}..."
    ./openstack-delete $P3_PROJECT ${ms}-redis-${SUFFIX}
    if [ $ms == "orca" ]; then
        echo "Deleting ${ms}-redis-slave-${SUFFIX}..."
        ./openstack-delete $P3_PROJECT ${ms}-redis-slave-${SUFFIX}
    elif [ $ms == "clouddriver" ]; then
        echo "Deleting ${ms}-redis-slave-${SUFFIX}..."
        ./openstack-delete $P3_PROJECT ${ms}-redis-slave-${SUFFIX}
    fi
done

echo "Deleting the proxies..."
./openstack-delete $P3_PROJECT code-proxy-$SUFFIX
./openstack-delete $P3_PROJECT code-proxy-$SUFFIX-s

echo "Sleeping for 15 secs..."
sleep 15

echo "Checking status..."
openstack server list


