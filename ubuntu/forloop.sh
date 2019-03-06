#!/usr/bin/env bash

declare -A port=( ["gate"]="6379" ["fiat"]="6380" ["orca"]="6381" ["clouddriver"]="6382" ["igor"]="6383" ["rosca"]="6384" ["kayenta"]="6385" )

for ms in gate fiat orca clouddriver igor rosca kayenta
do
    echo $ms: ${port[$ms]}
    mkdir -p /tmp/etc/redis/$ms-${port[$ms]}
    mkdir -p /tmp/var/lib/redis/$ms-${port[$ms]}
    cp redis.conf /tmp/etc/redis/$ms-${port[$ms]}
    cd /tmp/etc/redis/$ms-${port[$ms]}
    gsed -i 's/^bind/#bind/g' redis.conf
    gsed -i 's/^supervised no/supervised systemd/g' redis.conf
    gsed -i "s/^dir \.\//dir \/var\/lib\/redis\/$ms-${port[$ms]}/g" redis.conf
    gsed -i 's/^# requirepass.*/requirepass c0der0cks!/g' redis.conf
    gsed -i 's/^appendonly no/appendonly yes/g' redis.conf
    gsed -i "s/^appendfilename.*/appendfilename redis-$ms-${port[$ms]}-ao.aof/g" redis.conf

done

chown -R anasharm:staff /tmp/etc/redis
chown -R anasharm:staff /tmp/var/lib/redis
chmod -R 770 /tmp/var/lib/redis
