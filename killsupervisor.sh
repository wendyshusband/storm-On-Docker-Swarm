#!/bin/bash

#IP of the machine running supervisor
IP=$1

#container ID of supervisor
ID=$2

docker -H tcp://$IP:2375 stop $ID
docker -H tcp://$IP:2375 rm $ID
echo "kill success"
docker ps -a
