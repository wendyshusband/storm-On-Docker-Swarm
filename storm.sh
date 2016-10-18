#!/bin/bash

# first script argument: the servers in the ZooKeeper ensemble:
ZOOKEEPER_SERVERS=$1

# second script argument: number of supervisors to launch
SUPERVISORS=$2

#if no valid number was given: just assume 1 as default
if ! [[ $SUPERVISORS =~ ^[0-9]+ ]] ; then
        echo "no number was provided (\"$SUPERVISORS\"). Will proceed with 1 supervisor."
        SUPERVISORS=1
fi

#create a overlay network
docker network create --driver overlay stormnet
docker network ls

#nimbus
docker run -d --label cluster=storm --label role=nimbus -e constraint:server=manager -e STORM_ZOOKEEPER_SERVERS=$ZOOKEEPER_SERVERS --net stormnet --restart=always --name nimbus -p 6627:6627 wendyhusband/storm nimbus

#ui
docker run -d --label cluster=storm --label role=ui -e constraint:server=manager -e STORM_ZOOKEEPER_SERVERS=$ZOOKEEPER_SERVERS --net stormnet --restart=always --name ui -p 8080:8080 wendyhusband/storm ui

#supervisor
for((i=0; i <= $SUPERVISORS; i++));
do
        docker run --label cluster=storm --label role=supervisor -e affinity:role!=supervisor -e STORM_ZOOKEEPER_SERVERS=$ZOOKEEPER_SERVERS --net stormnet --restart=always wendyhusband/storm supervisor
done

docker ps
docker -H tcp://127.0.0.1:2376 info
