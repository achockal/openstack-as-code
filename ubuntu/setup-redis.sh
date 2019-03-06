#!/usr/bin/env bash

SUFFIX="${1:-prd}"
P3_PROJECT="${2:-allnpoc}"

echo "About to setup \"$SUFFIX\" lifecycle in $P3_PROJECT..."
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

#declare -A port=( ["gate"]="6379" ["fiat"]="6380" ["orca"]="6381" ["clouddriver"]="6382" ["igor"]="6383" ["rosca"]="6384" ["kayenta"]="6385" )
declare -A port=( ["orca"]="6381" ["clouddriver"]="6382" ["others"]="6380" )
declare -A ports=( ["orca"]="16381" ["clouddriver"]="16382" )

# Spin up Redis (Master) Instances
export FLAVOR_NAME="8vCPUx16GB"
for ms in orca clouddriver others
do
    gsed -i "s/^REDIS_PORT=.*/REDIS_PORT=${port[$ms]}/g" redis.sh
    ./openstack-create $P3_PROJECT ${ms}-redis-${SUFFIX} redis
done

echo "Sleeping for 60 secs before continuing..."
sleep 60

# Grab the IP addresses of the Redis (Master) Instances
ORCA_IP=$(openstack server show -c addresses --format value orca-redis-${SUFFIX} | cut -d "=" -f 2)
echo "orca=$ORCA_IP"
CLOUDDRIVER_IP=$(openstack server show -c addresses --format value clouddriver-redis-${SUFFIX} | cut -d "=" -f 2)
echo "clouddriver=$CLOUDDRIVER_IP"
OTHERS_IP=$(openstack server show -c addresses --format value others-redis-${SUFFIX} | cut -d "=" -f 2)
echo "others=$OTHERS_IP"


read -p "Should we continue? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Quitting!!"
    exit 1
fi

# Spin up Redis Slave Instances. In order to spin them up, each instance needs to know the Master IP, Master Port and its own Port
export FLAVOR_NAME="8vCPUx16GB"
for ms in orca clouddriver
do
    gsed -i "s/^REDIS_SLAVE_PORT=.*/REDIS_SLAVE_PORT=${ports[$ms]}/g" sredis.sh
    gsed -i "s/^MASTER_PORT=.*/MASTER_PORT=${port[$ms]}/g" sredis.sh
    if [ $ms == "orca" ]; then
        gsed -i "s/^MASTER_IP=.*/MASTER_IP=${ORCA_IP}/g" sredis.sh
        echo "Checking sredis.sh...."
        grep -i MASTER_IP= -A 1 sredis.sh
        ./openstack-create $P3_PROJECT ${ms}-redis-slave-${SUFFIX} sredis
    else 
        gsed -i "s/^MASTER_IP=.*/MASTER_IP=${CLOUDDRIVER_IP}/g" sredis.sh
        echo "Checking sredis.sh...."
        grep -i MASTER_IP= -A 1 sredis.sh
        ./openstack-create $P3_PROJECT ${ms}-redis-slave-${SUFFIX} sredis
    fi

done

echo "Sleeping for 60 secs before continuing..."
sleep 60

# Grab the IP addresses of the Redis Slave Instances
ORCA_SLAVE_IP=$(openstack server show -c addresses --format value orca-redis-slave-${SUFFIX} | cut -d "=" -f 2)
echo "orca-s=$ORCA_SLAVE_IP"
CLOUDDRIVER_SLAVE_IP=$(openstack server show -c addresses --format value clouddriver-redis-slave-${SUFFIX} | cut -d "=" -f 2)
echo "clouddriver-s=$CLOUDDRIVER_SLAVE_IP"

# Set all the Redis (Master) Instance IP Addresses as environment variables in redisproxy.sh by sed-ing the values into redisproxy.sh
gsed -i "s/^ORCA_IP=.*/ORCA_IP=${ORCA_IP}/g" redisproxy.sh
gsed -i "s/^CLOUDDRIVER_IP=.*/CLOUDDRIVER_IP=${CLOUDDRIVER_IP}/g" redisproxy.sh
gsed -i "s/^OTHERS_IP=.*/OTHERS_IP=${OTHERS_IP}/g" redisproxy.sh

echo "Checking redisproxy.sh changes..."
grep -i -B 3 -A 3 CLOUDDRIVER_IP= redisproxy.sh

# Set all the Redis Slave Instance IP Addresses as environment variables in sredisproxy.sh by sed-ing the values into sredisproxy.sh
gsed -i "s/^ORCA_SLAVE_IP=.*/ORCA_SLAVE_IP=${ORCA_SLAVE_IP}/g" sredisproxy.sh
gsed -i "s/^CLOUDDRIVER_SLAVE_IP=.*/CLOUDDRIVER_SLAVE_IP=${CLOUDDRIVER_SLAVE_IP}/g" sredisproxy.sh

echo "Checking sredisproxy.sh changes..."
grep -i -B 2 -A 1 CLOUDDRIVER_SLAVE_IP= sredisproxy.sh

read -p "Should we continue? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Quitting!!"
    exit 1
fi

# Spin up Proxy for the Redis (Master) Instances. In order to spin the Proxy for Redis Master, you need
# - All Redis (Master) Instance IP Addresses
# - As for Ports, the "port" hashmap defined at the top of this file is also defined in redisproxy.sh. Make sure the two are in sync always
echo "Creating Spin Proxy for Redis Masters on Stage..."
export FLAVOR_NAME="4vCPUx8GB"
./openstack-create $P3_PROJECT code-proxy-$SUFFIX redisproxy

# Spin up Proxy for the Redis Slave Instances. In order to spin the Proxy for Redis Master, you need
# - Redis Slave Instance IP Addresses
# - As for Ports, the "ports" hashmap defined at the top of this file is also defined in sredisproxy.sh. Make sure the two are in sync always
echo "Creating Spin Proxy for Redis Slaves on Stage..."
export FLAVOR_NAME="4vCPUx8GB"
./openstack-create $P3_PROJECT code-proxy-$SUFFIX-s sredisproxy

