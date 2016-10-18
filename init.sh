#!/bin/bash
# first script argument: the servers in the ZooKeeper ensemble:
ZOOKEEPER_SERVERS=$1
# second script argument: the role of this node:
# ("manager" for the Swarm manager node; leave empty else)
ROLE=$2
# the IP address of this machine:
PRIVATE_IP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
# define label for the manager node:
if [[ $ROLE == "manager" ]];then LABELS="--label server=manager";else LABELS="";fi
# define default options for Docker Swarm:
echo "DOCKER_OPTS=\"-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --cluster-advertise eth0:2375 $LABELS --cluster-store zk://$ZOOKEEPER_SERVERS\"" | sudo tee /etc/default/docker
# restart the service to apply new options:
sudo service docker restart

echo "let's wait a little..."
sleep 10
# make this machine join the Docker Swarm cluster:
docker run -d --restart=always swarm join --advertise=$PRIVATE_IP:2375 zk://$ZOOKEEPER_SERVERS
