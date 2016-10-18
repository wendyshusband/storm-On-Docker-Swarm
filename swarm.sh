#!/bin/bash

# first script argument: the servers in the ZooKeeper ensemble:
ZOOKEEPER_SERVERS=$1
docker ps

# launch the ZooKeeper ensemble:
# Put all ZooKeeper server IPs into an array:
IFS=', ' read -r -a ZOOKEEPER_SERVERS_ARRAY <<< "$ZOOKEEPER_SERVERS"
for index in "${!ZOOKEEPER_SERVERS_ARRAY[@]}"; do
    ZKID=$(($index+1))
    ZK=${ZOOKEEPER_SERVERS_ARRAY[index]}
    docker -H tcp://$ZK:2375 run -d --restart=always -p 2181:2181 -p 2888:2888 -p 3888:3888 -v /var/lib/zookeeper:/var/lib/zookeeper -v /var/log/zookeeper:/var/log/zookeeper --name zk$ZKID wendyhusband/zooKeeper $ZOOKEEPER_SERVERS $ZKID
done

echo "let's wait a little..."
sleep 10

#launch the swarm manager
docker run -d --restart=always --label role=manager -p 2376:2375 swarm manage zk://$ZOOKEEPER_SERVERS

echo "let's wait a little..."
sleep 10

#check zookeeper health:
for index in "${!ZOOKEEPER_SERVERS_ARRAY[@]}";
do
	ZKID=$(($index+1))
	ZKIP=${ZOOKEEPER_SERVERS_ARRAY[index]}
	ZK=zk$ZKID
	echo "checking $ZK:"
	docker -H tcp://$ZKIP:2375 exec -it $ZK bin/zkServer.sh status
done
docker ps

cat << EOF | tee -a ~/.bash_profile
 	# this node is the master and therefore should be able to talk to the Swarm cluster:
    export DOCKER_HOST=tcp://127.0.0.1:2376
EOF
export DOCKER_HOST=tcp://127.0.0.1:2376
docker restart $(docker ps -a --no-trunc --filter "label=role=manager" | awk '{if(NR>1)print $1;}')
echo "let's wait a little..."
sleep 10

docker info 

